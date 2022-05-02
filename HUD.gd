#controls player heads up display
extends CanvasLayer

signal respawn_pressed #signal for when player respawns

#game loop every frame
func _process(delta):
	if Input.is_action_just_pressed("respawn"): #player presses respawn key
		if $Control/OnDeath/Respawn.visible:
			emit_signal("respawn_pressed") #tell other nodes to respawn player

#updates health bar when player health changes
func _on_Player_update_health(new_health):
	$Control/Health.value = new_health

#show respawn button upon dealth
func _on_Player_is_dead():
	yield(get_tree().create_timer(1.0), "timeout")
	$Control/OnDeath/Respawn.visible = true
	$Control/OnDeath/Respawn.visible = true

#emit respawn signla when respawn button pressed
func _on_Respawn_pressed():
	emit_signal("respawn_pressed")

#hide respawn butten when player has respawned
func _on_Player_respawned():
	$Control/OnDeath/Respawn.visible = false
	$Control/OnDeath/Respawn.visible = false

#when player is a spirit, show the elenment in use
func _on_Player_is_spirit():
	$Control/CurrentElement.visible = true

#when player is a human, hide the element in use
func _on_Player_is_human():
	$Control/CurrentElement.visible = false

func _on_TitleScreen_pressed():
	get_tree().change_scene("res://TitleScreen.tscn")
