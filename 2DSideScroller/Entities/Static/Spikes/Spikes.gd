extends Area2D
class_name spikes

var knockback : float = 200 #knockback dealt to 
var hit_dir : Vector2 = Vector2(0, -1) #direction to hit player towards
var damage : int = 1 #damage to deal to the player
#var hit_timer : float = 0.5 
var size : Vector2 = Vector2(16, 16) #size of the scene

func _on_Spikes_body_entered(body):
	if body.has_method("hit"): #if the body hit has the method, "hit"
		if body.get("look_dir") != null: #if the body has a, "look_dir" variable
			body.hit(knockback, Vector2(hit_dir.x + (body.look_dir * -0.5), hit_dir.y).normalized(), damage, true) #knocking the body away from the direction they're facing
		else: #if the body does not have a, "look_dir" variable
			body.hit(knockback, (hit_dir + -(body.velocity.normalized() * 0.25)).normalized(), damage, true) #knocking the player up and the opposite of their velocity
