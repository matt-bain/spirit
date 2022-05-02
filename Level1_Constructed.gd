extends Node

export (PackedScene) var next_level_path #stores the path of the next level

#spawn the player at the spawn point
func _ready():
	$Player/Human.global_position = $Level1_Map/SpawnPoint.global_position

#reset the map and spawn the player at their respawn point
func _on_Player_respawned():
	$Level1_Map.reset()
	$Player/Spirit.global_position = $Level1_Map/RespawnPoint.global_position
	$Player/Human.global_position = $Level1_Map/RespawnPoint.global_position

#when level complete, move to the next level
func _on_Level1_Map_level_complete():
	get_tree().change_scene_to(next_level_path)
