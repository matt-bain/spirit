#controls the animation of the ogre enemy
extends AnimatedSprite

var currenthit = null #target of the strike
var has_been_hit = false #has the target been hit? (prevents multiple hits in quick succession)

#physics game loop
func _physics_process(delta):
	if owner.is_hit: #if the ogre is hit
		modulate = Color(1.0, 0.0, 0.0, 1.0) #flash red for a frame
		yield(self, "frame_changed") #frame changes
		owner.is_hit = false #stop the ogre being hit
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0) #remove red flash
		
	#if attack animation is playing
	if animation == "attack":
		#if an attacking frame is playing
		if frame == 4 || frame == 5 || frame == 6 || frame == 7:
			if currenthit && !has_been_hit: #if there is an unhit target
				has_been_hit = true #target has been hit
				currenthit.emit_signal("damage_taken", 15) #apply 15 damage to the player
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

