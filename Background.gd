#controls the background of the world
#applies to all background nodes in the game
extends Node

#function activates when the player is in spirit form
#changes the world background between the two forms
func _on_Player_is_human():
	$SpiritWorld.visible = false
	$HumanWorld.visible = true

#function activates when the player is in human form
#changes the world background between the two forms
func _on_Player_is_spirit():
	$HumanWorld.visible = false
	$SpiritWorld.visible = true

