#handles ogre
extends KinematicBody2D
#declare ogre as a class so it can be compared to a type
class_name Ogre

signal killed() #emit when the ogre is killed

onready var detection_zone = $PlayerDetection #set the detection zone for finding the player
var pathfinder:Navigation2D #stores the pathfinding 
var health = 100 #stores ogre health 
var speed = 170 #ogre's horizontal speed
var velocity = Vector2.ZERO #ogre's velocity
var gravity = 20 #gravity acting on the ogre
var path = [] #pathfinding path the ogre will take
var attack_range = 20 #range ogre must be within to attack
var target:KinematicBody2D #target of the ogre
var dist_to_target #stores the distance to the current target
var rng = RandomNumberGenerator.new()
var dead = false #is the ogre dead
var is_hit = false #is the ogre hit

#state machine
enum state{idle, moving, attacking, dead, stunned}
var current_state = state.idle

#pick a random speed for the ogre and start playing the animation
func _ready():
	rng.randomize()
	speed = rng.randi_range(170, 210)
	$AnimatedSprite.play()
	
#physics loop every frame 
func _physics_process(delta):
	
	if !dead: #if the ogre is not dead
		if target && !target.frozen: #if there is a target and the target is active
			#find the distance to the target and make the ogre face the target
			dist_to_target = (target.global_position - global_position).length()
			$AnimatedSprite.flip_h = global_position.x - target.global_position.x > 0
		elif target && target.frozen: #if the target becomes frozen get a new target 
				$PlayerDetection/PlayerDetector.disabled = true
				$PunchBox/DamageBox.disabled = true
				yield(get_tree().create_timer(0.1), "timeout")
				$PlayerDetection/PlayerDetector.disabled = false
				$PunchBox/DamageBox.disabled = false
	
	#state machine code
	match current_state:
		#if the ogre is moving
		state.moving:
			$AnimatedSprite.animation = "idle"
			move(delta) #move along a path
		#if the ogre is attacking
		state.attacking:
			if !dead: #if the ogre is alive (stops attacks going through when the ogre has died)
				$AnimatedSprite.animation = "attack"
				move(delta) #move along a path
				if dist_to_target > attack_range: #if the player is out of range
					current_state = state.moving #keep moving
			else: #if ogre is dead, make the state dead
				current_state = state.dead
		#if the ogre is dead
		state.dead:
			$AnimatedSprite.animation = "death"
			velocity.y += gravity #apply gravity so ogre falls
			velocity = move_and_slide(velocity, Vector2.UP)
			current_state = state.dead
		#if the ogre is stunned
		state.stunned:
			$AnimatedSprite.animation = "stunned" #stun the ogre

#move ogre along path to target
func move(delta):
	if dist_to_target: #if there is a distance to the target
		if dist_to_target <= attack_range: #if the target is in attack range
			current_state = state.attacking #move to attack state
		else: #otherwise move
			if pathfinder: #if the pathfinder is active
				if path.size() == 0 && target: #if there is no path and there is a target
					path = pathfinder.get_simple_path(global_position, target.global_position, false) #create a path to the target
			if path.size() > 0: #if there is a path
				#get the first point in the path and remove it if it's too close
				var dist_to_first = global_position.distance_to(path[0])
				if dist_to_first < 16:
					path.remove(0)
				#if the path isn't too close, move the ogre towards the target
				else:
					var direction_to_next = global_position.direction_to(path[0])
					position += direction_to_next * speed * delta

#when an enitiy enters the ogre hitbox
func on_body_entered(body, damage):
	if !dead: #if the ogre is not dead (this stops the ogre from coming back to a 'zombie state' if stunned after death)
		#if the entity is a fire projectile, do damage and destroy the projectile
		if body_is_projectile(body) == "fire":
			if !projectile_hit(body):
				body.velocity = Vector2.ZERO
				body.has_hit = true
				body.kill()
				$HitSound.play()
				hit(damage)
		#if the entity is a earth projectile, stun the ogre and destroy the projectile
		elif body_is_projectile(body) == "earth":
			if !projectile_hit(body):
				body.velocity = Vector2.ZERO
				body.has_hit = true
				body.kill()
				current_state = state.stunned
				yield(get_tree().create_timer(2), "timeout")
				if current_state == state.stunned:
					current_state = state.moving

#take damage if not dead. if the health loss kills the ogre, move the state to dead
func hit(damage):
	if !dead:
		is_hit = true
		health -= damage
		dead = health <= 0
		$Health.frame += 4
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
	if body.is_in_group("player"):
		if !body.frozen:
			target = body
			current_state = state.moving

#if a player leaves the detection zone, finish current path and remove target
func _on_PlayerDetection_body_exited(body):
	if body.is_in_group("player"):
		if !body.frozen && target:
			path = pathfinder.get_simple_path(global_position, target.global_position, false)
			target = null

#when animations finish this is called
func _on_AnimatedSprite_animation_finished():
	#clear the memory of the ogre once the ogre dies
	if $AnimatedSprite.animation == "death":
		emit_signal("killed")
		queue_free()
	#reset the attack animation to attack again
	elif $AnimatedSprite.animation == "attack":
		$AnimatedSprite.frame = 0
