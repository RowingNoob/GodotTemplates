extends KinematicBody2D

#movement vars

var gravity : float = 20 #gravity to be applied to the player
var max_gravity : int = 800 #how fast the player can fall
var grounded : bool = false #if the player is on the ground

var kayote_jump_time : float = 0.25 #how long can the player jump after walking off the ground
var kayote_jump : bool = false #if the player should do a kayote jump
var jump_power : int = -300 #how high the player jumps
var max_jump_count : int = 1 #max amount of double jumps
var jump_count : int = 0 #how many double jumps done so far
var jump_pressed : bool = false #if jump has been pressed
var jump_time : float = 0.15 #the time jump_pressed stays true after the jump button is pressed

var on_wall : bool = false #if the player is on the wall
var do_wall_jump : bool = true #if the player pressed wall jump
var wall_jump_power : int = 226 #the amount of velocity applied away from the wall
var max_wall_speed : int = 200 #max wall slide speed
var wall_friction : float = 0.1 #wall slide speed, gravity * wall_friction
var wall_direction : int = 1 #the direction the wall is facing
var wall_input_delay : float = 0.1 #the amount of time the player can't move after walljumping

var do_input : bool = true #if the player can move (does not include jumping)
var max_speed : float = 140 #max walk speed
var accel : float = 16 #acceleration speed
var friction : float = 20 #slowing down speed
var air_accel : float = 0.5 #accel * air_accel
var air_friction : float = 0.3 #friction * air_friction

#stats

var max_health : int = 3 #the highest amount of health the player can have
var health : int = max_health #the players current health

var hit : bool = false #if the player has been hit, this includes the amount the time the player can't move, and the amount of time the player flashes white
var dead : bool = false #if the player is dead
var invincible : bool = false #if the player is currently invincible

var hit_time : float = 0.125 #the amount of time the hit variable stays true after being hit
var time_til_respawn : float = 1.75 #self explanatory
var invincibility_time : float = 0.75 #self explanatory

var unstretch_speed : float = 0.2 #the speed the sprite resizes back to its original size (1,1)
var wall_stretch := Vector2(0.6, 1.4) #the size the sprites stretch to when landing on a wall
var jump_stretch := Vector2(0.7, 1.3) #the size the sprites stretch to when jumping
var land_stretch := Vector2(1.25, 0.75) #the size the sprites stretch to when landing
var walk_off_stretch := Vector2(0.9, 1.1) #the size the sprites stretch to when walking off a ledge

#children

onready var camera : Camera2D = $Camera2D #path to the camera
onready var animation_player : AnimationPlayer = $Animation/AnimationPlayer #path to the animation player
onready var character : Node2D = $Character #path to the character node(contains all sprites and other related items)
onready var sprites : Node2D = $Character/Sprites #path to the sprites
onready var raycasts : Node2D = $Raycasts #path to all the raycasts

onready var wall_cast : RayCast2D = $Raycasts/WallCast #path to the wall raycast, used for checking if the player is on the wall

#input

var velocity = Vector2() #the speed the player is moving
var input = Vector2() #the direction of input
var look_dir : int = 1 #the direction the player is facing

var inps = [ #list of inputs used in Input_map
	"Left", #0
	"Right", #1
	"Jump", #2
	"DropDown", #3
	"Restart", #4
]
#states

enum{ #states the player has
	MOVE,
	AIR,
	WALL,
	HIT,
	DYING
}
var state = MOVE #the starting state

#functions

func _ready():
	#adding variables to the debug screen
	Debugger.add_data("health", self)
	Debugger.add_data("velocity", self)
	Debugger.add_data("jump_pressed", self)
	Debugger.add_data("grounded", self)
	Debugger.add_data("state", self)
	Debugger.add_data("position", self)
	Debugger.add_data("on_wall", self)
	Debugger.add_data("jump_count", self)
	Debugger.add_data("do_input", self)
	Debugger.add_data("kayote_jump", self)

func _physics_process(delta):
	
	setting_vars()
	
	#state
	
	match state: #functions that should play depending on which state the player is in
		MOVE:
			move_state(delta)
		AIR:
			air_state(delta)
		WALL:
			wall_state(delta)
		HIT:
			hit_state(delta)
		DYING:
			dying_state(delta)
	
	velocity = move_and_slide(velocity, Vector2.UP) #moving the player

func _input(event):
	if Input.is_action_just_pressed(inps[4]) && !dead: #if the player presses the restart button, and the player is not already dead
		die()

func set_input() -> void:
	if do_input: #if the player can move left and right
		input.x = Input.get_action_strength(inps[1]) - Input.get_action_strength(inps[0]) #setting input direction
		
		if sign(input.x) != 0: #if the player is trying to move 
			character.scale.x = sign(input.x) #setting the direction chracter faces
			raycasts.scale.x = sign(input.x) #setting the direction raycasts faces

func setting_vars() -> void:
	on_wall = wall_cast.is_colliding() #changing if the player is on a wall depending on if the wall_cast is colliding or not
	grounded = is_on_floor() #setting the grounded to the correct value
	sprites.scale = lerp(sprites.scale, Vector2(1,1), unstretch_speed) #moving the scale of the sprite back to it's original state
	look_dir = character.scale.x #changing the look direction to the direction the character is facing
	if grounded: #if the player is on the ground set the jump count to 0
		jump_count = 0

#state

func move_state(delta):
	#calling initial functions
	jump(delta)
	set_input()
	
	if input.x != 0: # if the player is moving
		velocity.x = move_toward(velocity.x, input.x * max_speed, accel) #move the players velocity to the correst speed
		animation_player.play("Walk") #play the walking animation
	else: #if the player isn't moving
		velocity.x = move_toward(velocity.x, 0, friction) #move the players velocity to 0
		animation_player.play("Idle") #play the idle animation
	
	velocity.y = move_toward(velocity.y, max_gravity, gravity) #applying gravity to the player
	
	#jumping
	
	if !grounded && velocity.y >= 0: #if the player is not on the ground, and the player is moving down (stepping off a ledge)
		go_air(delta) 
	elif !grounded: #if the player is not on the ground, and the player is moving up (jumping)
		state = AIR
		kayote_jump = false

func air_state(delta):
	#calling initial functions
	jump(delta)
	go_to_wall(delta)
	set_input()
	land(delta)
	
	if input.x != 0: #if the player is moving
		velocity.x = move_toward(velocity.x, input.x * max_speed, accel * air_accel) #move the players velocity to the correct speed
	else: #if the player is not moving
		velocity.x = move_toward(velocity.x, 0, friction * air_friction) # move the players velocity to 0
	
	velocity.y = move_toward(velocity.y, max_gravity, gravity) #applying gravity to the player
	
	#animation
	
	if velocity.y > 0: #if player is falling
		animation_player.play("Fall")
	else: #if the player is moving up
		animation_player.play("Jump")

func wall_state(delta):
	
	velocity.x = wall_direction * -1 #pushing the player against the wall
	velocity.y = move_toward(velocity.y, max_wall_speed, gravity * (wall_friction)) #applying gravity
	do_input = true #making sure the player can do input
	
	animation_player.play("WallSlide")
	if on_wall && !grounded && !Input.is_action_pressed(inps[3]): #if the player is on a wall, not on the ground, and is not pressing down
		if Input.is_action_just_pressed(inps[2]): #if the player pressed jump
			velocity.x = wall_jump_power * wall_direction #kicking the player away from the wall
			velocity.y = jump_power #kicking the player away from the wall
			
			sprites.scale = jump_stretch #applying squash and stretch
			character.scale.x = wall_direction #making sure the character is looking in the right direction
			raycasts.scale.x = wall_direction #making sure the raycasts are orientated in the right direction
			
			jump_count = 0 #setting jump count back to 0
			do_input = false #making it where the player can not put in input
			UsefulFuncs.timer(wall_input_delay, "do_input", true, self) #setting a timer to change do_input back to true
			
			state = AIR
	else: #if the play is not on a wall, is grounded, or is holding down
		state = AIR

func hit_state(delta):
	
	animation_player.play("Hit") #playing hit animation
	velocity.y = move_toward(velocity.y, max_gravity, gravity) #applying gravity
	
	if !hit: #if the hit timer is over
		state = MOVE

func dying_state(delta):
	sprites.modulate = Color(1,1,1,1) #making sure the player is at normal color
	
	velocity = lerp(velocity, Vector2(0,0), 0.075) #moving velocity towards 0

#movement funcs

func go_to_wall(delta):
	if on_wall && !grounded && do_wall_jump && velocity.y > -30 && !Input.is_action_pressed(inps[3]): #if the player is on a wall, is not grounding, and they're not moving up too fast
		if velocity.y > 10: #if the player is moving down too fast
			velocity.y = 0
		wall_direction = sign(wall_cast.get_collision_normal().x) #seting wall direction the direction the wall is facing
		sprites.scale = wall_stretch #making sure the sprite is facing the right direction
		state = WALL

func land(delta):
	if grounded: #if the player is on the ground
		if !Input.is_action_pressed("Left") && !Input.is_action_pressed("Right"): #if the player is not pressing anything and lands
			velocity.x = 0
		sprites.scale = land_stretch #squashing and stretching the player
		state = MOVE

func jump(delta):
	if jump_pressed: #if jump has been pressed
		if grounded: #if the player is on the ground
			velocity.y = jump_power
			sprites.scale = jump_stretch
			
			state = AIR
			kayote_jump = false
			jump_pressed = false
		elif kayote_jump: #if the player is not on the ground but should still jump (kayote jump)
			velocity.y = jump_power
			sprites.scale = jump_stretch
			
			state = AIR
			kayote_jump = false
			jump_pressed = false
		elif jump_count < max_jump_count: #if the player is not on the ground, shouldn't kayote jump, and still has mid-air jumps left
			velocity.y = jump_power
			jump_count += 1
			sprites.scale = jump_stretch
			
			state = AIR
			kayote_jump = false
			jump_pressed = false
	elif Input.is_action_just_pressed(inps[2]): #if the player pressed the jump button
		
		jump_pressed = true #setting jump_pressed to true
		UsefulFuncs.timer(jump_time, "jump_pressed", false, self) #setting a timer to set jump_pressed to false

func go_air(delta):
	kayote_jump = true #after first leaving the ground, set kayote_jump to true, so the player has a small window to still be able to jump
	UsefulFuncs.timer(kayote_jump_time, "kayote_jump", false, self) #setting a timer to set kayote_jump back to false
	sprites.scale = walk_off_stretch 
	state = AIR

func hit(knockback : float, dir : Vector2, damage : int, continue_knockback : bool = false):
	if !invincible && !dead: #if the player is not invincible, and is not dead
		
		health -= damage
		velocity = dir * knockback
		state = HIT
		jump_count = 0 #allows the player to mid-air jump again
		
		invincible = true #making sure the player is invincible
		hit = true #saying the player has been hit
		sprites.modulate = Color(100, 100, 100) #flashing the player white
		
		UsefulFuncs.screen_shake(0.0, 7.5, 3.0, 0.05, true) #shaking the screen
		UsefulFuncs.timer(invincibility_time, "invincible", false, self) #setting a timer to turn invincibility off
		UsefulFuncs.timer(invincibility_time, "modulate", Color(1, 1, 1, 1), sprites) #setting a timer to set the player's transparency back to normal
		UsefulFuncs.timer(hit_time, "hit", false, self) #setting a timer to say that the player is no longer hit
		UsefulFuncs.timer(hit_time, "modulate", Color(1, 1, 1, 0.75), sprites) #setting a timer to go from a white flash to a transparent color
		
		if health <= 0:
			die()
	elif continue_knockback: #if continue_knockback is true, the player will continue taking knockback even if they are invincible or dead
		velocity = dir * knockback

func die():
	dead = true #saying the player is dead
	state = DYING
	animation_player.play("Dying")
	UsefulFuncs.screen_shake(0.5, 4.5, 4.0)
	
	yield(get_tree().create_timer(time_til_respawn), "timeout") #waiting to respawn the player
	
	get_tree().reload_current_scene() #respawning the player












