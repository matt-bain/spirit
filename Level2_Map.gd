#controls level 2
extends Node

signal earth_collect #emits when the player collects the earth
signal level_complete #emits when the player completes the level
signal message_to_player(message, timeout) #display a messsage to the player 

var code_input = [] #code the player has input for the puzzle
var correct_input = ["P2","P1","P4","P3"] #correct input

#active states of the 3 switches
var switch1_active = false
var switch2_active = false
var switch3_active = false

#complete states of the different level sections
var puzzle_complete = false
var jump_complete = false
var level_complete = false

#variables to display the messages only once
var puzzle_message_seen = false
var jump_message_seen = false

#on level load, start the platforms moving
func _ready():
	emit_signal("message_to_player", "[center]LEVEL 2[/center]", 3)
	$HPlatform/Movement.play("horizontal")
	$HPlatform3/Movement.play("horizontal")
	$HPlatform5/Movement.play("horizontal")
	$VPlatform/Movement.play("vertical")
	#space out the timings by 1 second to make for harder jumps
	yield(get_tree().create_timer(1), "timeout")
	$HPlatform4/Movement.play("horizontal")
	$HPlatform2/Movement.play("horizontal")
	$LevelMusic.play()
	
#game loop every frame
func _process(delta):
	
	#when player presses interact by a switch, activate the switch
	if Input.is_action_just_pressed("interact"):
		if $JumpSwitch1.able_to_interact:
			var current = $JumpSwitch1/SwitchState.animation
			if current == "red":
				$JumpSwitch1/SwitchSound.play()
				$JumpSwitch1/SwitchState.animation = "green"
				switch1_active = true
		if $JumpSwitch2.able_to_interact:
			var current = $JumpSwitch2/SwitchState.animation
			if current == "red":
				$JumpSwitch2/SwitchSound.play()
				$JumpSwitch2/SwitchState.animation = "green"
				switch2_active = true
		if $JumpSwitch3.able_to_interact:
			var current = $JumpSwitch3/SwitchState.animation
			if current == "red":
				$JumpSwitch3/SwitchSound.play()
				$JumpSwitch3/SwitchState.animation = "green"
				switch3_active = true
				
		#when all switches are active, open the door
		if switch1_active && switch2_active && switch3_active:
			$DoorOpenSound.play()
			$JumpDoor.hide()
			jump_complete = true
			
#hide the spirit world in human form
func _on_Player_is_human():
	$SpiritWorld.visible = false
	$HumanWorld.visible = true
	$HumanWorld.collision_layer = 1
	$HumanWorld.collision_mask = 1
	$SpiritWorld.collision_layer = 0
	$SpiritWorld.collision_mask = 0
	$Solution.animation = "human"
	$HPlatform.visible = true
	$HPlatform2.visible = true
	$HPlatform3.visible = true
	$HPlatform4.visible = true
	$HPlatform5.visible = true
	$VPlatform.visible = true
	$Checkpoint2.visible = true
	$Checkpoint4.visible = true
	$Checkpoint5.visible = true
	$JumpSwitch1.visible = true
	$JumpSwitch2.visible = true
	$JumpSwitch3.visible = true
	if !jump_complete:
		$JumpDoor.visible = true
	if !puzzle_complete:
		$PuzzleDoor.visible = true
	if !level_complete:
		$EndDoor.visible = true
	
#hide the human world in spirit form
func _on_Player_is_spirit():
	$HumanWorld.visible = false
	$SpiritWorld.visible = true
	$HumanWorld.collision_layer = 0
	$HumanWorld.collision_mask = 0
	$SpiritWorld.collision_layer = 1
	$SpiritWorld.collision_mask = 1
	$Solution.animation = "spirit"
	$HPlatform.visible = false
	$HPlatform2.visible = false
	$HPlatform3.visible = false
	$HPlatform4.visible = false
	$HPlatform5.visible = false
	$VPlatform.visible = false
	$Checkpoint2.visible = false
	$Checkpoint4.visible = false
	$Checkpoint5.visible = false
	$JumpSwitch1.visible = false
	$JumpSwitch2.visible = false
	$JumpSwitch3.visible = false
	$JumpDoor.visible = false
	$PuzzleDoor.visible = false
	$EndDoor.visible = false

#if pyres are hit by fire, pass the pyre to a function
func _on_PyrePuzzle1_body_entered(body):
	if body.get_name().find("ProjectileFire", 0) != -1:
		pyre_hit($P1)

func _on_PyrePuzzle2_body_entered(body):
	if body.get_name().find("ProjectileFire", 0) != -1:
		pyre_hit($P2)

func _on_PyrePuzzle3_body_entered(body):
	if body.get_name().find("ProjectileFire", 0) != -1:
		pyre_hit($P3)

func _on_PyrePuzzle4_body_entered(body):
	if body.get_name().find("ProjectileFire", 0) != -1:
		pyre_hit($P4)
			
func pyre_hit(pyre):
	#if the pyre is inactive
	if!pyre.is_active():
		pyre.activate() #activate pyre
		code_input.append(pyre.get_name()) #add the hit pyre to the code input
	
		#if 4 pyres have been hit
		if len(code_input) == 4:
			
			yield(pyre.get_node("AnimatedSprite"), "animation_finished")
			var correct = true
			
			#check if the code is correct
			for i in range(len(code_input)):
				if code_input[i] != correct_input[i]:
					correct = false
					
			#if pattern correct
			if correct:
				$DoorOpenSound.play()
				#remove the door
				$PuzzleDoor.hide()
				puzzle_complete = true
			else: #pattern wrong then deactivate all the pyres and clear the pattern for re-entry
				code_input.clear()
				$P1.deactivate()
				$P2.deactivate()
				$P3.deactivate()
				$P4.deactivate()

#control if the switches can be interacted with
func _on_JumpSwitch1_body_entered(body):
	if body.get_name() == "Human":
		$JumpSwitch1.able_to_interact = true

func _on_JumpSwitch1_body_exited(body):
	if body.get_name() == "Human":
		$JumpSwitch1.able_to_interact = false
		
func _on_JumpSwitch2_body_entered(body):
	if body.get_name() == "Human":
		$JumpSwitch2.able_to_interact = true

func _on_JumpSwitch2_body_exited(body):
	if body.get_name() == "Human":
		$JumpSwitch2.able_to_interact = false
		
func _on_JumpSwitch3_body_entered(body):
	if body.get_name() == "Human":
		$JumpSwitch3.able_to_interact = true

func _on_JumpSwitch3_body_exited(body):
	if body.get_name() == "Human":
		$JumpSwitch3.able_to_interact = false
		
#when player enters the checkpoints, change the spawn point to match the last touched checkpoint
func _on_Checkpoint_body_entered(body):
	if body.get_name() == "Human":
		$RespawnPoint.global_position = $Checkpoint.global_position - Vector2(0, 5)
		$Checkpoint.activate()

func _on_Checkpoint2_body_entered(body):
	if body.get_name() == "Human":
		$RespawnPoint.global_position = $Checkpoint2.global_position - Vector2(0, 5)
		$Checkpoint2.activate()

func _on_Checkpoint3_body_entered(body):
	if body.get_name() == "Human":
		$RespawnPoint.global_position = $Checkpoint3.global_position - Vector2(0, 5)
		$Checkpoint3.activate()

func _on_Checkpoint4_body_entered(body):
	if body.get_name() == "Human":
		$RespawnPoint.global_position = $Checkpoint4.global_position - Vector2(0, 5)
		$Checkpoint4.activate()

func _on_Checkpoint5_body_entered(body):
	if body.get_name() == "Human":
		$RespawnPoint.global_position = $Checkpoint5.global_position - Vector2(0, 5)
		$Checkpoint5.activate()

#when player picks up the rock, prompt the player on how to use them
func _on_StaticEarth_body_entered(body):
	if body.get_name() == "Spirit" || body.get_name() == "Human":
		emit_signal("earth_collect")
		$StaticEarth.queue_free()
		emit_signal("message_to_player", "[center]Rocks are used to stun smaller enemies and activate pillars[/center]", 7)

#if a rock hits a pillar deativate the end door
func _on_Pillar_body_entered(body):
	if body.get_name().find("ProjectileEarth", 0) != -1:
		if!$Pillar.is_active():
			$Pillar.activate()
			$DoorOpenSound.play()
			$EndDoor.hide()
			level_complete = true
	#if fire hits, inform the player this interaction has failed
	elif body.get_name().find("ProjectileFire", 0) != -1:
		emit_signal("message_to_player", "[center]Fire wont work on this pillar[/center]", 5)

#when next level zone is entered, take player to next level
func _on_NextLevel_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("level_complete")

#display hints to the player only once when they enter the specific areas
func _on_HelpBox_body_entered(body):
	if !puzzle_message_seen:
		puzzle_message_seen = true
		emit_signal("message_to_player", "[center]The frogs hold the answer...[/center]", 5)

func _on_SwitchHelpBox_body_entered(body):
	if !jump_message_seen:
		jump_message_seen = true
		emit_signal("message_to_player", "[center]Three swtiches open the door...[/center]", 5)
