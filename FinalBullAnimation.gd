#controls the animation of the bull enemy
extends AnimatedSprite

var currenthit = null #target of the punch
var has_been_hit = false #has the target been hit? (prevents multiple hits in quick succession)

#physics game loop
func _physics_process(delta):
	if owner.isHit: #if the bull is hit
		modulate = Color(1.0, 0.0, 0.0, 1.0) #flash red for a frame
		yield(self, "frame_changed") #frame changes
		owner.isHit = false #stop the bull being hit
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0) #remove red flash
	
	#if an attack animation is playing
	if animation == "attack" || animation == "attack_up" || animation == "attack_down":
		#if an attacking frame is playing
		if frame == 2 || frame == 3 || frame == 4:
			if currenthit && !has_been_hit: #if there is an unhit target
				has_been_hit = true #target has been hit
				currenthit.emit_signal("damage_taken", 50)
				yield(self, "animation_finished") #after attack animation
				has_been_hit = false #allow player to be hit again
				
#called when player enters the damage box. sets the target of the punch
func _on_PunchBox_body_entered(body):
	if (body.get_name() == "Human" || body.get_name() == "Spirit") && !body.frozen:
		currenthit = body

#called when player leaves the damage box. removes the target of the punch
func _on_PunchBox_body_exited(body):
	if (body.get_name() == "Human" || body.get_name() == "Spirit") && !body.frozen:
		currenthit = null
