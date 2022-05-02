#controls door functionality
extends StaticBody2D

#hides the door from view and disables collision
func hide():
	visible = false
	collision_layer = 0
	collision_mask = 0

#has the door reappear and enables world collision	
func show():
	visible = true
	collision_layer = 1
	collision_mask = 1

#when the slide puzzle is completed in level 3, hide the door
func _on_SlidePuzzle_puzzle_complete():
	hide()
