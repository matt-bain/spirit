#controls level 1
extends Node

signal fire_collect #emitted when fire is collected by the player
signal spirit_unlocked #emitted when the player unlocks spirit form
signal level_complete #emitted when the player completes the level
signal message_to_player(message, timeout) #emits a essage to the player which times out after a specified duration

var boss_fight = false #is the boss fight active
var boss_is_dead = false #is the boss dead

#when level loaded
func _ready():
	emit_signal("message_to_player", "[center]LEVEL 1[/center]", 3) #display the level to the player
	reset() #reset the world
	$BossDoor.hide() #hide the boss door. this is seperate to reset, to stop the player from going back to the boss until they have fire
	$LevelMusic.play()

#reset the world by moving the bull back and hiding it from the player
func reset():
	$Bull.visible = false
	$Bull.active = false
	boss_fight = false
	$Bull.target = null
	$Bull.current_state = $Bull.state.idle
	$Bull.reset()
	$Bull.global_position = $BullSpawn.global_position
	$Bull.collision_layer = 0
	$Bull.set_collision_mask_bit(4, false)

#game loop for every frame
func _process(delta):
	if Input.is_action_just_pressed("interact"): #if interact is pressed
		if $Switch.able_to_interact: #if the switch is interactable
			var current = $Switch/SwitchState.animation
			$Switch/SwitchSound.play()
			#switch the switch between states
			if current == "red":
				$Switch/SwitchState.animation = "green"
				$DoorOpenSound.play()
				$SwitchDoor.hide()
			else:
				$Switch/SwitchState.animation = "red"
				$SwitchDoor.show()
	
	#hide the boss door and remove the end door when the boss is dead
	if $Pyre.is_active() && boss_is_dead:
		$DoorOpenSound.play()
		$EndDoor.hide()
		$BossDoor.hide()

#hide spirit world when player is human
func _on_Player_is_human():
	$SpiritWorld.visible = false
	$HumanWorld.visible = true
	$HumanWorld.collision_layer = 1
	$HumanWorld.collision_mask = 1
	$SpiritWorld.collision_layer = 0
	$SpiritWorld.collision_mask = 0
	$BossDoor/Texture.animation = "human"
	$EndDoor/Texture.animation = "human"
	$SwitchDoor/Texture.animation = "human"

#hide human world when player is spirit
func _on_Player_is_spirit():
	$HumanWorld.visible = false
	$SpiritWorld.visible = true
	$HumanWorld.collision_layer = 0
	$HumanWorld.collision_mask = 0
	$SpiritWorld.collision_layer = 1
	$SpiritWorld.collision_mask = 1
	$BossDoor/Texture.animation = "spirit"
	$EndDoor/Texture.animation = "spirit"
	$SwitchDoor/Texture.animation = "spirit"

#when player collects the fire, notify the player about the fire
func _on_StaticFire_body_entered(body):
	if body.get_name() == "Spirit":
		emit_signal("fire_collect")
		$StaticFire.queue_free()
		emit_signal("message_to_player", "[center]Fire can be used to damage enemies and activate pyres[/center]", 7)
		$DoorOpenSound.play()
		$BossDoor.hide() #allow the player to fight the boss again
	
#show the player how to press a switch
func _on_Switch_body_entered(body):
	if body.get_name() == "Human":
		$Switch.able_to_interact = true
		body.show_help("e")

#hide the tooltip
func _on_Switch_body_exited(body):
	if body.get_name() == "Human":
		$Switch.able_to_interact = false
		body.hide_help()

#spawn the bull when the spawn are is entered
func _on_SpawnBullArea_body_entered(body):
	if boss_fight == false:
		if body.get_name() == "Human" || body.get_name() == "Spirit":
			boss_fight = true
			$Bull.visible = true
			$BossDoor.show()
			$Bull/PunchBox.monitoring = true
			$Bull/PunchBox.set_deferred("monitorable", true)

#notify the player of how to turn into the spirit form
func _on_SpiritGate_body_entered(body):
	if body.get_name() == "Human":
		if(body.first_boss_death):
			body.show_help("q")
			emit_signal("spirit_unlocked")
	#don't let the player through into the boss zone without fire
	if body.get_name() == "Spirit":
		if(body.has_fire):
			$BossDoor.hide()
			
#hide tooltip
func _on_SpiritGate_body_exited(body):
	if body.get_name() == "Human":
		body.hide_help()

#activate a pyre when fire hits it
func _on_Pyre_body_entered(body):
	if body.get_name().find("ProjectileFire", 0) != -1:
		if!$Pyre.is_active():
			$Pyre.activate()

#when bull dies, set the variable to reflect
func _on_Bull_is_dead():
	boss_is_dead = true

#move player spawn to the checkpoint
func _on_Checkpoint_body_entered(body):
	if body.is_in_group("player"):
		$RespawnPoint.global_position = $Checkpoint.global_position - Vector2(0, 5)
		$Checkpoint.activate()

#prompt the player to jump
func _on_WZone_body_entered(body):
	if body.get_name() == "Human":
		body.show_help("w")

#hide tooltip
func _on_WZone_body_exited(body):
	if body.get_name() == "Human":
		body.hide_help()

#prompt the player to move
func _on_DZone_body_entered(body):
	if body.get_name() == "Human":
		body.show_help("d")

#hide tooltip
func _on_DZone_body_exited(body):
	if body.get_name() == "Human":
		body.hide_help()

#move the player on to the next level when they enter the end zone
func _on_EndOfLevel_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("level_complete")
