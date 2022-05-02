#handles ogre
extends KinematicBody2D

signal killed() #emit when the ogre is killed

onready var detection_zone = $PlayerDetection #set the detection zone for finding the player
export (NodePath) var pathfinding_path #stores the pathfinding node path
var active = false #is the sub-boss active?
var pathfinder:Navigation2D #stores the pathfinding 
var health = 100 #stores sub-boss health 
var speed = 250 #sub-boss speed
var velocity = Vector2.ZERO #velocity for the sub-boss to move with
var gravity = 20 #gravity acting on the sub-boss
var path = [] #pathfinding path the sub-boss will take
var attack_range = 1 #range sub-boss must be within to attack
var target:KinematicBody2D #target of the sub-boss
var dist_to_target #stores the distance to the current target

var dead = false #is the sub-boss dead
var is_hit = false #is the sub-boss hit
var currenthit = null #the sub-boss' current target
var has_hit = false #has the sub-boss hit the target

#state machine
enum state{idle, moving, dead, stunned}
var current_state = state.idle

#initialise the pathfinder and reset the sub-boss
func _ready():
	pathfinder = get_node(pathfinding_path)
	$AnimatedSprite.play()
	reset()
	
#reset the subboss to initial state and set idle
func reset():
	active = false
	health = 100
	$PunchBox.monitorable = false
	$PunchBox.monitoring = false
	$PlayerDetection.monitoring = false
	$PlayerDetection.monitorable = false
	set_collision_mask_bit(1, false)
	set_collision_mask_bit(4, false)
	active = false
	target = null
	dead = false
	has_hit = false
	current_state = state.idle
	
#physics loop every frame 
func _physics_process(delta):
	
	#if the sub-boss is active
	if active:
		if !dead: #if the sub-boss is not dead
			if target && !target.frozen: #if there is a target and the target is active
				#find the distance to the target and make the sub-boss face the target
				dist_to_target = (target.global_position - global_position).length()
				$AnimatedSprite.flip_h = global_position.x - target.global_position.x < 0
			elif target && target.frozen: #if the target becomes frozen get a new target 
					$PlayerDetection/PlayerDetector.disabled = true
					$PunchBox/DamageBox.disabled = true
					yield(get_tree().create_timer(0.1), "timeout")
					$PlayerDetection/PlayerDetector.disabled = false
					$PunchBox/DamageBox.disabled = false
		
		#state machine code
		match current_state:
			#if the sub-boss is moving
			state.moving:
				$AnimatedSprite.animation = "idle"
				move(delta) #move along a path
			#if the sub-boss is dead
			state.dead:
				$AnimatedSprite.animation = "death"
				yield($AnimatedSprite, "animation_finished")
				velocity.y += gravity #apply gravity so sub-boss falls
				velocity = move_and_slide(velocity, Vector2.UP)
				current_state = state.dead
			#if the sub-boss is stunned
			state.stunned:
				$AnimatedSprite.animation = "stunned" #stun the sub-boss
					
#move sub-boss along path to target
func move(delta):
	if dist_to_target: 
		if pathfinder: #if the pathfinder is active
			if path.size() == 0 && target: #if there is no path and there is a target
				path = pathfinder.get_simple_path(global_position, target.global_position, false) #create a path to the target
		if path.size() > 0: #if there is a path
			#get the first point in the path and remove it if it's too close
			var dist_to_first = global_position.distance_to(path[0])
			if dist_to_first < 16:
				path.remove(0)
			#if the path isn't too close, move the sub-boss towards the target
			else:
				var direction_to_next = global_position.direction_to(path[0])
				position += direction_to_next * speed * delta
					
#when an enitiy enters the sub-boss hitbox
func on_body_entered(body, damage):
	if !dead: #if the sub-boss is not dead (this stops the sub-boss from coming back to a 'zombie state' if stunned after death)
		#if the entity is a fire projectile, do damage and destroy the projectile
		if body_is_projectile(body) == "fire":
			if !projectile_hit(body):
				body.velocity = Vector2.ZERO
				body.has_hit = true
				body.kill()
				if !$HitSound.playing:
					$HitSound.play()
				hit(damage)
		#if the entity is a earth projectile, stun the sub-boss and destroy the projectile
		elif body_is_projectile(body) == "earth":
			if !projectile_hit(body):
				body.velocity = Vector2.ZERO
				body.has_hit = true
				body.kill()
				current_state = state.stunned
				yield(get_tree().create_timer(2), "timeout")
				if current_state == state.stunned:
					current_state = state.moving	
					
#take damage if not dead. if the health loss kills the sub-boss, move the state to dead
func hit(damage):
	if !dead:
		is_hit = true
		health -= damage
		dead = health <= 0
		$Health.frame += 1
		if dead:
			$Health.visible = false
			$DeathSound.play()
			current_state = state.dead
		
#return the type of projectile or return if the entity was not a projectile
func body_is_projectile(body):
	if body.get_name().find("ProjectileFire") != -1:
		return "fire"
	elif body.get_name().find("ProjectileEarth") != -1:
		return "earth"
	else:
		return "no"

#returns if the projectile has hit (prevents double hits)
func projectile_hit(body):
	return body.has_hit

#if a player enters the detection zone, begin moving towards it
func _on_PlayerDetection_body_entered(body):
	if body.is_in_group("player") && active:
		if !body.frozen:
			target = body
			current_state = state.moving

#if a player leaves the detection zone, finish current path and remove target
func _on_PlayerDetection_body_exited(body):
	if body.is_in_group("player") && active:
		if !body.frozen && target:
			path = pathfinder.get_simple_path(global_position, target.global_position, false)
			target = null

#when animations finish this is called
func _on_AnimatedSprite_animation_finished():
	#clear the memory of the sub-boss once the sub-boss dies or is freed
	if $AnimatedSprite.animation == "death":
		emit_signal("killed")
		queue_free()
	elif $AnimatedSprite.animation == "release":
		queue_free()

#called when player enters the damage box. sets the target and causes damage
func _on_PunchBox_body_entered(body):
	if body == target && !has_hit:
		has_hit = true
		target.call_deferred("emit_signal", "damage_taken", 15)
		yield(get_tree().create_timer(2), "timeout")
		has_hit = false

#called when player leaves the damage box. removes the target of the punch
func _on_PunchBox_body_exited(body):
	if (body.get_name() == "Human" || body.get_name() == "Spirit") && !body.frozen:
		currenthit = null

#called when an entity enters then spawn area for the sub-boss
func _on_SpawnBullArea_body_entered(body):
	if !active: #if the sub-boss is not already active
		if body.get_name() == "Human" || body.get_name() == "Spirit": #if the entity is a player
			active = true #activate the sub-boss
			set_collision_mask_bit(0, true) #activate collision with the world
			set_collision_mask_bit(3, true) #activate collision with doors
			
			$PlayerDetection.monitoring = true #start player detection to reset target
			$PlayerDetection.set_deferred("monitorable", true)
			$PunchBox.monitoring = true
			$PunchBox.set_deferred("monitorable", true)

#if bull dies and the spirit is still alive, release the spirit = good ending
func _on_FinalBull_is_dead():
	if !dead:
		active = false
		$AnimatedSprite.animation = "release"
