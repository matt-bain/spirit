#controls moving platforms
extends Node2D

#hides moving platforms and diables collision when called
func hide():
	visible = false
	$Platform.collision_layer = 0
