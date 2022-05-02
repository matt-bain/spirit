#controls level 3
extends Node

signal game_over #emits when the game is over
signal update_boss_health(health) #emits to change the boss health bar to the new health
signal boss_spawned #emits when the boss is spawned
signal boss_dead #emits when the boss dies
signal message_to_player(message, timeout) #sends a message to the player with a timeout
signal arena_complete #emits when the arena is complete

#complete states
var puzzle_complete = false
var secret_complete = false
var arena_complete = false
var boss_complete = false
var sub_boss_complete = false

var boss_message_played = false #makes sure the boss message is only played once

func _ready():
	message_to_player("[center]LEVEL 3[/center]", 3) 
	$LevelMusic.play()

#reset the arena and the final boss's
func reset():
	if !arena_complete:
		$WaveManager.reset()
	if !boss_complete:
		$FinalBull.reset()
		$FinalBull.global_position = $BullSpawn.global_position
		if !sub_boss_complete:
			$SubBoss.reset()
			$SubBoss.global_position = $SubSpawn.global_position

#hide spirit world when in human form
func _on_Player_is_human():
	$Pathfinding/SpiritWorld.visible = false
	$HumanWorld.visible = true
	$HumanWorld.collision_layer = 1
	$HumanWorld.collision_mask = 1
	$Pathfinding/SpiritWorld.set_collision_layer_bit(0, false)
	$Pathfinding/SpiritWorld.set_collision_mask_bit(1, false)
	$Child.visible = true
	if !puzzle_complete:
		$PuzzleDoor.show()
	if !secret_complete:
		$SecretDoor.show()
	if !arena_complete:
		$WaveDoor.show()
	if !boss_complete:
		$EndDoor.show()
	
#hide human world when in spirit form
func _on_Player_is_spirit():
	$HumanWorld.visible = false
	$Pathfinding/SpiritWorld.visible = true
	$HumanWorld.collision_layer = 0
	$HumanWorld.collision_mask = 0
	$Pathfinding/SpiritWorld.set_collision_layer_bit(0, true)
	$Pathfinding/SpiritWorld.set_collision_mask_bit(1, true)
	$PuzzleDoor.hide()
	$SecretDoor.hide()
	$WaveDoor.hide()
	$EndDoor.hide()
	$Child.visible = false

#open the door when the sliding puzzle is beaten
func _on_SlidePuzzle_puzzle_complete():
	puzzle_complete = true
	$DoorOpenSound.play()
	$PuzzleDoor.hide()
	
#open the door when the rock hits the pillar
func _on_Pillar_body_entered(body):
	if body.get_name().find("ProjectileEarth", 0) != -1:
		if!$Pillar.is_active():
			$Pillar.activate()
			$DoorOpenSound.play()
			$SecretDoor.hide()
			secret_complete = true

#announce the arena is complete after the waves are killed
func _on_WaveManager_arena_complete():
	arena_complete = true
	emit_signal("arena_complete")
	message_to_player("[center]WAVES COMPLETE[/center]", 3)
	$DoorOpenSound.play()
	$WaveDoor.hide()

#plays out the final endings
#bad ending if sub-boss was killed and good ending otherwise
func _on_PlayEndAnim_body_entered(body):
	if body.get_name() == "Human":
		emit_signal("game_over")
		body.damaged = true
		if sub_boss_complete:
			$BadEnd.play()
			body.get_node("AnimatedSprite").animation = "idle"
			yield(get_tree().create_timer(3), "timeout")
			message_to_player("[center]YOUR CHILD IS LOST...[/center]", 20)
			body.get_node("AnimatedSprite").animation = "despair"
		else:
			body.visible = false
			$Child.animation = "revive"
			$Child.play()
			yield(get_tree().create_timer(1.3), "timeout")
			$GoodEnd.play()
			yield(get_tree().create_timer(2.7), "timeout")
			message_to_player("[center]YOU SAVED YOUR CHILD[/center]", 20)

#set player spawn points to the checkpoint locations when a player touches them
func _on_Checkpoint_body_entered(body):
	if body.is_in_group("player"):
		$RespawnPoint.global_position = $Checkpoint.global_position - Vector2(0, 5)
		$Checkpoint.activate()
		
func _on_Checkpoint2_body_entered(body):
	if body.is_in_group("player"):
		$RespawnPoint.global_position = $Checkpoint2.global_position - Vector2(0, 5)
		$Checkpoint2.activate()

#display tooltip to tell the player to use the arrow keys on the puzzle
func _on_PuzzleHelp_body_entered(body):
	if body.get_name() == "Human" && !puzzle_complete:
		body.show_help("right")
		yield(get_tree().create_timer(4), "timeout")
		body.hide_help()

#spawn the bull when the player enters the bull spawn area
func _on_SpawnBullArea_body_entered(body):
	if body.get_name() == "Human" || body.get_name() == "Spirit":
		$FinalBull/PunchBox.monitoring = true
		$FinalBull/PunchBox.set_deferred("monitorable", true)
		if !boss_message_played:
			boss_message_played = true
			emit_signal("message_to_player", "[center]Slay the BULL OF WRATH to free your child[/center]", 5)

#update bull's health upon a change
func _on_FinalBull_update_health(health):
	emit_signal("update_boss_health", health)

func _on_FinalBull_boss_spawned():
	emit_signal("boss_spawned")

#announce the bull is dead and make the final door vanish
func _on_FinalBull_is_dead():
	emit_signal("boss_dead")
	boss_complete = true
	$LevelMusic.stop()
	$DoorOpenSound.play()
	$EndDoor.hide()

#emit a message to the player with a timeout
func message_to_player(wave, timeout):
	emit_signal("message_to_player", wave, timeout)

#set a variable to declare the subboss is killed if the subboss dies
func _on_SubBoss_killed():
	sub_boss_complete = true
