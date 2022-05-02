#controls spirit form
extends KinematicBody2D

signal damage_taken(damage) #emits when the player takes damage

export var spirit_speed = 200.0 #speed spirit will fly at
export var frozen = true #is the spirit frozen
var velocity = Vector2.ZERO #velocity of the spirit

#preloaded resources to create projectiles
var firePath = preload("res://ProjectileFire.tscn")
var earthPath = preload("res://ProjectileEarth.tscn")

#primative state machine variables
var dead = false
var inAttack = false
var inSecondAttack = false

#if the spirit has certain powers
var has_fire = false
var has_earth = false

var current_power = "fire"

#play animations and hide tooltips on spawn
func _ready():
	$AnimatedSprite.play()
	$InteractHelp.visible = false

#physics game loop every frame
func _physics_process(_delta):
	
	#primative state machine code
	if !frozen: #if the spirit is not frozen
		if !dead: #if the spirit is not dead
			
			#if player inputs a movement
			if Input.is_action_pressed("move_right"):
				velocity.x = spirit_speed
			if Input.is_action_pressed("move_left"):
				velocity.x = -spirit_speed
			if Input.is_action_pressed("jump"):
				velocity.y = -spirit_speed
			if Input.is_action_pressed("crouch"):
				velocity.y = spirit_speed
			
			#if an attack is performed
			if Input.is_action_just_pressed("attack"):
				hide_help()
				if has_fire || has_earth: #if the player has either fire or earth powers
					if !inAttack && !inSecondAttack: #if not attacking
						inAttack = true #set in attack
						$AnimatedSprite.animation = "spirit_attack_1" #play first attack animation
						fire(!$AnimatedSprite.flip_h) #fire a projectile
						yield($AnimatedSprite, "animation_finished") #wait for animation to finish
						inAttack = false #end attack
					elif !inSecondAttack: #if in first attack
						inSecondAttack = true #set in second attack
						$AnimatedSprite.animation = "spirit_attack_2" #play second attack animation
						fire(!$AnimatedSprite.flip_h) #fire projectile
						yield($AnimatedSprite, "animation_finished") #wait for animation to finish
						inSecondAttack = false #end second attack
						inAttack = false #end attack
			else: #if not attacking, idle the player
				if !inAttack && !inSecondAttack:
					$AnimatedSprite.animation = "spirit_idle"
				
			#move the player with applied velocity
			velocity = move_and_slide(velocity)
				
			#if the player is moving flip them in the direction of travel
			if velocity.x != 0:
				$AnimatedSprite.flip_h = velocity.x < 0
				
			#move projectile firing point based on direction faced
			if $AnimatedSprite.flip_h:
				$FirePoint.position.x = -10
			else:
				$FirePoint.position.x = 10
	
	#bring player to smooth halt after movement
	velocity.y = lerp(velocity.y, 0, 1)
	velocity.x = lerp(velocity.x, 0, 1)

#fire a projectile in a direction
func fire(var right):
	var projectile #store projectile
	#instance the projectile the player has selected
	if current_power == "fire":
		projectile = firePath.instance()
		if !$Fire.playing:
			$Fire.play()
		elif !$Fire2.playing:
			$Fire2.play()
	else:
		projectile = earthPath.instance()
		if !$RockThrow.playing:
			$RockThrow.play()
		elif !$RockThrow2.playing:
			$RockThrow2.play()
	projectile.right = right #decide on direction the projectile will fire
	#spawn the projectile
	owner.add_child(projectile)
	projectile.global_position = $FirePoint.global_position

#set player dead upon death
func _on_Player_is_dead():
	dead = true

#set player undead
func _on_Player_respawned():
	dead = false

#provide tooltip to assist player
func show_help(help):
	$InteractHelp.animation = help
	$InteractHelp.visible = true
	
#hide tooltip
func hide_help():
	$InteractHelp.visible = false
	
#animation finish calls to prevent animation overlaps and crashing
func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "spirit_damage" || $AnimatedSprite.animation == "spirit_death":
		frozen = false #remove player from frozen state
