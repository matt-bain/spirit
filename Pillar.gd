#controls pillars
extends StaticBody2D

signal body_entered(body) #emit if projectile hits pillar
var active = false #is the pillar activated?

#set inactive on load
func _ready():
	$AnimatedSprite.animation = "inactive"
	$AnimatedSprite.play()

#return if pillar is active
func is_active():
	return active

#activate the pillar
func activate():
	active = true
	$AnimatedSprite.animation = "hit" #play hit animation
	yield($AnimatedSprite, "animation_finished") #wait for hit to finish
	$AnimatedSprite.animation = "active" #play active animation

#deactivate the pillar
func deactivate():
	active = false
	$AnimatedSprite.animation = "inactive" #play inactive animation

#if projectile enters the pillar, emit the entered signal
func _on_HitArea_body_entered(body):
	emit_signal("body_entered", body)
