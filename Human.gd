#controls the players human form
extends KinematicBody2D

export var speed = 150.0 #speed the player moves left and right
export var crouch_speed = 75.0 #speed when crouching
export var jump_speed = -330.0 #jump momentum. fine tuned to allow precise jumping in game
export var gravity = 20 #gravity applied every frame
var first_boss_death = false #has the player died to the first boss
var velocity = Vector2.ZERO #velocity the player will move at

#primative state machine
var inCombat = false #is the player in combat
var crouching = false #is the player crouching
var dead = false #is the player dead
var damaged = false #is the player damaged
var frozen = false #is the player frozen

var able_to_interact = false #is able to interact with an interactable

signal damage_taken(damage) #emit signal when damage taken

#when spawned
func _ready():
	$AnimatedSprite.play() #start animations
	$InteractHelp.visible = false #hide help tooltips

#physics game loop runs every frame
func _physics_process(_delta):
			
	velocity.y = velocity.y + gravity #apply gravity to player
	
	#primative state machine code
	if !damaged: #if the player is not in the middle of being hit
		if !frozen: #if the player is not frozen (in spirit form)
			if !dead: #if the player is not currently dead
				
				#if player presses right or left, apply the expected speed to the velocity
				if Input.is_action_pressed("move_right"):
					if crouching:
						velocity.x = crouch_speed
					else:
						velocity.x = speed
				
				if Input.is_action_pressed("move_left"):
					if crouching:
						velocity.x = -crouch_speed
					else:
						velocity.x = -speed
					
				#if the player presses jump, apply the jump velocity to launch them into the air
				if Input.is_action_just_pressed("jump"):
					if(is_on_floor()): #only possible if player is on the floor. no double jumping here
						velocity.y = jump_speed
						$JumpSound.play() #play jump sound
				
				#old attack code for when the player could attack
				#
				#if Input.is_action_just_pressed("attack"):
				#	if(!inCombat && !crouching):
				#		inCombat = true
				#		$AnimatedSprite.animation = "attack_ground"
				#		yield($AnimatedSprite, "animation_finished")
				#		inCombat = false
			
				#if player presses crouch
				if Input.is_action_pressed("crouch"):
					if (velocity.x == crouch_speed || velocity.x == -crouch_speed): #if the player moves simultaneously
						$AnimatedSprite.animation = "crouch_move" #play the crouch move animation
					else: #if the player is still
						$AnimatedSprite.animation = "crouch" #play the regular crouch animation
					crouching = true #set crouching true
				elif Input.is_action_just_released("crouch"): #if player stops crouching
					crouching = false #release crouch
				elif (velocity.y < 0 || !is_on_floor()) && !inCombat: #if player is in the air and not in a fight
					$AnimatedSprite.animation = "jump" #play jump animation
				elif (velocity.x == speed || velocity.x == -speed) && !inCombat: #if player is running and not in a fight
					$AnimatedSprite.animation = "run" #play running animation
				elif !inCombat: #if player is standing still and not in combat
					$AnimatedSprite.animation = "idle" #play idle animation
					
				#if player is moving
				if velocity.x != 0:
					$AnimatedSprite.flip_h = velocity.x < 0 #flip based on the direction of movement
					
				for i in get_slide_count(): #look through the slide movements of the player
					var collision = get_slide_collision(i) #set collision to the current slide
					if collision: #if there was a collision
						if collision.collider is TileMap: #if the player collided with a tile
							var tile_position = collision.collider.world_to_map(global_position) #get the position of the tile
							tile_position += Vector2(0, 1) #look slightly further down to select the correct tile
							var tile = collision.collider.get_cellv(tile_position) #get the block at that position
							if tile == 14: #is the block lava?
								emit_signal("damage_taken", 100) #kill the player
							elif tile == 18 || tile == 20 || tile == 21: #is the block a ground or wall spike?
								emit_signal("damage_taken", 20) #apply 20 damage
							tile_position += Vector2(0, -2) #look above the player
							tile = collision.collider.get_cellv(tile_position) #get the tile at the new position
							if tile == 19: #is the block a roof spike?
								emit_signal("damage_taken", 20) #deal 20 damage
			else: #player is dead
				crouching = false #set player to not be crouching. this fixed a bug where the player would respawn with low velocity if they died crouching
		else: #player is in spirit form
			$AnimatedSprite.animation = "release" #play release animation where player falls to the floor
	
	velocity = move_and_slide(velocity, Vector2.UP) #move the player with velocity
	
	#slow the player down differently depending on location
	if !is_on_floor():
		velocity.x = lerp(velocity.x, 0, 0.2) #slow the player gradually in the air for a clean descent
	else:
		velocity.x = lerp(velocity.x, 0, 1) #slow the player quickly on the ground
		
#show the player help tooltip to give info to the player
func show_help(help):
	$InteractHelp.animation = help
	$InteractHelp.visible = true
	$InteractHelp.play()
	
#hide the player help tooltip
func hide_help():
	$InteractHelp.visible = false
	$InteractHelp.stop()

#make the player dead
func _on_Player_is_dead():
	$DeathSound.play()
	dead = true

#make the player not dead
func _on_Player_respawned():
	dead = false
	damaged = false

#animation finish calls to prevent animation overlaps and crashing
func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "damage" || $AnimatedSprite.animation == "death":
		damaged = false #remove the player from damaged state
