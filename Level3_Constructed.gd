extends Node

var rng = RandomNumberGenerator.new() #create a rng

#spawn the player at the spawn point
func _ready():
	$Player/Human.global_position = $Level3_Map/SpawnPoint.global_position
	$Player.third_level()
	
	rng.randomize() #randomize the rng to get different outcomes

#spawn the player at their respawn point and reset the map
func _on_Player_respawned():
	$Player/Human.global_position = $Level3_Map/RespawnPoint.global_position
	$Player/Spirit.global_position = $Level3_Map/RespawnPoint.global_position
	$Player/HUD/Control/Boss.visible = false
	$Level3_Map.reset()
