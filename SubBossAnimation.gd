#controls subboss animation
extends AnimatedSprite

#physics game loop
func _physics_process(delta):
	if owner.is_hit: #if the subboss is hit
		modulate = Color(1.0, 0.0, 0.0, 1.0) #flash red for a frame
		yield(self, "frame_changed") #frame changes
		owner.is_hit = false #stop the subboss being hit
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0) #remove red flash
