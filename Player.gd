#controls the player, made up of human and spirit
extends Node

var spirit_form = false #is the player a spirit
var can_change = true #can the player change form
var spirit_unlocked = false #is the spirit unlocked for the player

var health = 100 #player base health
var dead = false #is the player dead

signal is_spirit #emits when the player becomes a spirit
signal is_human #emits when the player is human
signal update_health(new_health) #updates the player health bar
signal is_dead #emits when the player is dead
signal respawned #emits when the player respawns

#starts the player as a human
func _ready():
	emit_signal("is_human")
	
#if the level is level 2, the player starts with fire
func second_level():
	spirit_unlocked = true
	$Spirit.has_fire = true
	$HUD/Control/CurrentElement.animation = "fire"
	$Spirit.current_power = "fire"

#if the level is level 3, the player starts with fire and earth
func third_level():
	spirit_unlocked = true
	$Spirit.has_fire = true
	$Spirit.has_earth = true
	$HUD/Control/CurrentElement.animation = "fire"
	$Spirit.current_power = "fire"

#game loop every frame
func _process(delta):
	
	#if health drops below 0, the player is dead
	if health <= 0:
		if !dead:
			dead = true
			emit_signal("is_dead")
			if spirit_form:
				$Spirit/AnimatedSprite.animation = "spirit_death"
			else:
				$Human/AnimatedSprite.animation = "death"
	
	#have the spirit constantly attached to the player
	if !spirit_form:
		$Spirit.global_position = $Human.global_position
		
	#move the human camera down when player is crouching
	if Input.is_action_pressed("crouch") && can_change:
		if $HumanCAM.offset_v < 1.5 && !dead:
			$HumanCAM.offset_v += delta
	#return the camera to the regular position
	if Input.is_action_just_released("crouch"):
		$HumanCAM.offset_v = 0
	
	#cycle between the unlocked powers when the user presses to change powers
	if Input.is_action_just_pressed("change_power"):
		if spirit_unlocked:
			if !dead:
				if $Spirit.has_fire && $Spirit.has_earth:
					$Spirit.hide_help()
					if $HUD/Control/CurrentElement.animation == "earth":
						$HUD/Control/CurrentElement.animation = "fire"
						$Spirit.current_power = "fire"
					else:
						$HUD/Control/CurrentElement.animation = "earth"
						$Spirit.current_power = "earth"
				elif $Spirit.has_fire:
						$HUD/Control/CurrentElement.animation = "fire"
						$Spirit.current_power = "fire"
					
	#if the player can switch form, switch the player from spirit to human or vice versa
	if Input.is_action_just_pressed("switch_form"):
		if spirit_unlocked:
			if !dead:
				if(can_change):
					spirit_form = not spirit_form
					#announce form change to other nodes
					if(spirit_form):
						emit_signal("is_spirit") 
						$Human2Spirit.play()
					else:
						emit_signal("is_human")
						$Spirit2Human.play()
					
					$Spirit.visible = spirit_form
					$Spirit.frozen = not spirit_form
					$Human/Recap.visible = spirit_form
					$Human/InteractHelp.visible = false
					$Human.frozen = spirit_form
					$HumanCAM.current = not spirit_form
					$SpiritCAM.current = spirit_form

#when the spirit enters the change aura, they can revert to human form
func _on_Area2D_body_entered(body):
	if body.get_name() == "Spirit":
		can_change = true
		$Human/Recap.animation = "success"

#when the spirit leaves the change area, they cna no longer revert
func _on_Area2D_body_exited(body):
	if body.get_name() == "Spirit":	
		can_change = false
		$Human/Recap.animation = "fail"

#activate use of fire when the player collects the fire power
func _on_Level1_Map_fire_collect():
	$Spirit.has_fire = true
	$Spirit.current_power = "fire"
	$Spirit.show_help("m")
	$HUD/Control/CurrentElement.visible = true
	$HUD/Control/CurrentElement.animation = "fire"
	
#activate use of rocks when the player collects the earth power	
func _on_Level2_Map_earth_collect():
	$Spirit.has_earth = true
	$Spirit.current_power = "earth"
	$Spirit.show_help("n")
	if spirit_form:
		$HUD/Control/CurrentElement.visible = true
	$HUD/Control/CurrentElement.animation = "earth"

#hurt the player when they take damage in human form
func _on_Human_damage_taken(damage):
	if !dead:
		if !$Human.frozen && !$Human.damaged: #stops the player getting stunlocked
			$Human.velocity.y = -150 #set velocity. adding to the velocity created a super jump from time to time
			#knock the player back in the opposite direction they're facing
			if $Human/AnimatedSprite.flip_h:
				$Human.velocity.x += 100
			else:
				$Human.velocity.x -= 100
			$Human/AnimatedSprite.animation = "damage"
			if !$HitSound.playing && health - damage > 0:
				$HitSound.play()
			$Human.damaged = true
			health -= damage
			update_healthbar()

#hurt the player when they take damage in spirit form
func _on_Spirit_damage_taken(damage):
	if !dead:
		if !$Spirit.frozen:
			$Spirit/AnimatedSprite.animation = "spirit_damage"
			if !$HitSound.playing && health - damage > 0:
				$HitSound.play()
			$Spirit.frozen = true
			health -= damage
			update_healthbar()
			
#reset stats when player respawns
func _on_HUD_respawn_pressed():
	health = 100
	update_healthbar()
	dead = false
	emit_signal("respawned")
	
#update the healthbar to the current stored health
func update_healthbar():
	emit_signal("update_health", health)
	
#unlock spirit after dying once in level 1
func _on_Level1_Map_spirit_unlocked():
	spirit_unlocked = true

#player can no longer change when the game is over
func _on_Level3_Map_game_over():
	can_change = false
	yield(get_tree().create_timer(15), "timeout")
	$HUD/Control/TitleScreen.visible = true
	
#set the boss health on the player HUD
func _on_Level3_Map_update_boss_health(health):
	$HUD/Control/Boss/BossHealth.value = health

#allow the player to see the boss' health on screen
func _on_Level3_Map_boss_spawned():
	$HUD/Control/Boss.visible = true

#when the boss dies, remove the bar from the HUD
func _on_Level3_Map_boss_dead():
	yield(get_tree().create_timer(3), "timeout")
	$HUD/Control/Boss.visible = false

#send a message to the player through the HUD with a set timeout
func message_to_player(message, timeout):
	$HUD/Control/MessageToPlayer.visible = true
	$HUD/Control/MessageToPlayer.bbcode_text = message
	yield(get_tree().create_timer(timeout), "timeout")
	$HUD/Control/MessageToPlayer.visible = false

#give the player full health after completing the arena
func _on_Level3_Map_arena_complete():
	health = 100
	update_healthbar()
