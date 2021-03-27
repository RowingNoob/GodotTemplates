extends Node


func timer(time : float, prop : String, new_value, prop_holder) -> void:
	#[amount of time to wait], [property to change], [value to change to], [the property holder]
	
	#running the timer----
	while time > 0.0:
		time -= get_physics_process_delta_time()
		yield(get_tree(), "idle_frame")
	#running the timer----
	
	prop_holder.set(prop, new_value) #getting the property holder, setting the property to the new value

var current_ss_priority : float = 0.0#current screen shake priority
func screen_shake(duration : float, severity : float, priority : float, recovery_speed : float = 0.25, shake_once : bool = false) -> void:
	#[amount of time the screen shakes], [how severe the screen shake is], [shaking priority], [speed the offset removes], [if the offset should be set once]
	
	var player : KinematicBody2D = get_tree().get_nodes_in_group("Player")[0] #getting the player
	var camera : Camera2D = player.camera #getting the player's camera
	var og_dur : float = duration #the original duration (duration counts down)
	var og_sev : float = severity #the original severity (severity decrease as duration counts down
	
	
	if priority >= current_ss_priority: #only doing screenshake if the priority is higher or equal to the current priority
		if !shake_once: #if the offset should be changing over time
			while duration > 0.0: 
				if !player: #making sure the player exists
					return
				
				current_ss_priority = priority #setting currenty priority to the current priority
				
				camera.offset.x = rand_range(-severity, severity) #shaking the camera
				camera.offset.y = rand_range(-severity, severity) #shaking the camera
				
				severity = (og_sev * (duration / og_dur)) #decrease the severity by the duration left
				duration -= get_physics_process_delta_time() #decreasing the duration
				
				yield(get_tree(), "idle_frame") #waiting a frame
		else: #if the offset should be set once
			if !player: #making sure the player exists
				return
			
			var dir := Vector2(rand_range(-1,1), rand_range(-1,1)).normalized() #picking a random direction to bounc the camera towards
			camera.offset = dir * severity #bouncing the camera
		
		current_ss_priority = 0.0 #setting priority back to 0
		
		while player && !camera.offset.is_equal_approx(Vector2.ZERO): #while player exists and the camera still has an offset
			if !player: #making sure the player exists
				return
			
			camera.offset = lerp(camera.offset, Vector2(0,0), recovery_speed)  #moving that offset back to 0
			yield(get_tree(), "idle_frame") #waiting a frame
		
		if !player: #making sure the player exists
			return
		
		camera.offset = Vector2(0,0) #making sure the camera's offset is equal to 0

