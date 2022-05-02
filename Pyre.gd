#controls pyres
extends StaticBody2D

signal body_entered(body) #emit if projectile hits pyre
var active = false #is the pyre activated?

#set inactive on load
func _ready():
	$AnimatedSprite.animation = "inactive"
	$AnimatedSprite.play()

#return if pyre is active
func is_active():
	return active

#activate the pyre
func activate():
	active = true
	$AnimatedSprite.animation = "hit" #play hit animation
	yield($AnimatedSprite, "animation_finished") #wait for hit to finish
	$AnimatedSprite.animation = "active" #play active animation

#deactivate the pyre
func deactivate():
	active = false
	$AnimatedSprite.animation = "inactive" #play inactive animation

#if projectile enters the pyre, emit the entered signal
func _on_HitArea_body_entered(body):
	emit_signal("body_entered", body)

