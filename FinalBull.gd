#bull script
extends KinematicBody2D

signal is_dead #signal to inform other nodes that the bull is dead
signal update_health(health) #signal to update health in the health bar
signal boss_spawned #signal to indicate the bull has spawned

var active = false #has the bull been activated?
var health = 100 
var dead = false #is the bull dead?
var isHit = false #is the bull in the process of being hit?
export var speed = 160.0 #the horizontal move speed of the bull
export var gravity = 20.0 #the gravity applied to the bull
var velocity = Vector2.ZERO #velocity will be the vector used to move the player. Starts at zero
enum state{moving, idle, attacking} #states that the bull can be in
var current_state = state.idle #current state the bull is in
var target = null #target of the bull
var angle = 0 #angle the target is at in relation to the bull

#ready is called when the node is loaded
func _ready():
	$Animation.play() #begin playing the animations
	reset() #reset the bull to default state

#function to reset the bull
func reset():
	health = 100
	emit_signal("update_health", health) #update healthbar node
	$PunchBox.monitorable = false #disable the punch hitbox, resets the target when reactivated
	$PunchBox.monitoring = false
	$PlayerDetection.monitoring = false #disable the player detection circle, resets the target when reactivated
	$PlayerDetection.monitorable = false
	set_collision_mask_bit(1, false) #stops the bull colliding with players
	set_collision_mask_bit(4, false) #stops the bull collidsing with projectiles
	active = false #deactivates the bull
	target = null #sets the target to none
	current_state = state.idle #sets the bull to idle mode

#physics loop runs every frame
func _physics_process(delta):
	
	velocity.y = velocity.y + gravity #apply gravity to the bull
	
	if !dead: #only run code if the bull is alive
		if health <= 0: #if health is less than 0 then the bull is dead 
			$DeathSound.play()
			dead = true
			isHit = true
			collision_layer = 0 #disable collision
			collision_mask = 0
			emit_signal("is_dead") #tell other nodes the bull is dead
			set_collision_mask_bit(0, true) #stop the bull colliding with the world
			$Animation.animation = "death" #play the death animation
			yield(get_tree().create_timer(3), "timeout") 
			visible = false #hide the bull
			queue_free() #clear the memory where the bull was held
			
		#state machine
		match current_state:
			state.moving: #bull is moving
				if target && !target.frozen: #if has a target and target is not frozen
					var distance = (global_position - target.global_position).length() #get the distance between the target and bull
					var direction = (target.global_position - global_position).normalized() #work out the direction of travel for the bull based on target location
					angle = rad2deg(direction.angle()) #work out the angle the target is at in comparison to the bull and convert that to degrees
					direction.y = 0 #nullify any vertical velocity
					velocity += speed * direction #move the bull at speed in the direction of the player
					if distance <= 150: #if the player is within punching distance
						$PunchBox.look_at(target.global_position) #move the punch box to the players location
						current_state = state.attacking
				elif target.frozen: #if the target is frozen, reset the detection areas. stops player cheating by slipping into a different form and leaving bull attacking old form
					$PlayerDetection/DetectionArea.disabled = true
					$PunchBox/DamageBox.disabled = true
					yield(get_tree().create_timer(0.1), "timeout")
					$PlayerDetection/DetectionArea.disabled = false
					$PunchBox/DamageBox.disabled = false
			state.attacking: #bull is attacking
				if $PunchTimer.time_left <= 0:
					$PunchSound.play()
					$PunchTimer.start(1)
				velocity = Vector2.ZERO #bring bull to a stop
				if (angle > 30 && angle <= 150): #if target is below the bull
					$Animation.animation = "attack_down"
				elif (angle <= 30 && angle > -30) || (angle <= -150 && angle >= -180) || (angle <= 180 && angle > 150): #if target is horizontal to the bull
					$Animation.animation = "attack"
				elif (angle <= -30 && angle > -150): #if target is above the bull
					$Animation.animation = "attack_up"
				else:
					print(angle) #test code to find uncovered angles. saves a crash if the angle is out of scope
		
		if velocity.x != 0: #if bull is horizontally moving
			$Animation.flip_h = velocity.x < 0 #flip the bull sprite if the bull is going left
			
		#adjust hitboxes based on bull's direction
		if $Animation.flip_h: 
			$LegArea/LeftLegHitBox.position.x = 13
			$LegArea/RightLegHitBox.position.x = -18
			$HeadArea/HeadHitBox.position.x = -2.5
			$SpriteCollision.position.x = -5.25
			$PlayerDetection/DetectionArea.position.x = -14.5
		else:
			$LegArea/LeftLegHitBox.position.x = -15
			$LegArea/RightLegHitBox.position.x = 21
			$HeadArea/HeadHitBox.position.x = 2.5
			$SpriteCollision.position.x = 5.25
			$PlayerDetection/DetectionArea.position.x = 14.5
				
		velocity = move_and_slide(velocity, Vector2.UP) #move the bull with velocity provided
		
		if !isHit && current_state != state.attacking: #if not being hit and not in an attack
			if (velocity.x != 0): #if bull has velocity
				$Animation.animation = "move" #move animation plays
			else: #bull is still
				$Animation.animation = "idle" #idle animation plays
			
			velocity.x = lerp(velocity.x, 0, 1) #bring bull to a gradual stop
			
#called when an entity enters the bull's body
func on_body_entered(body, damage):
	if body_is_projectile(body): #check if the entity was a projectile
		if !projectile_hit(body): #check the projectile has not hit already. prevents a double hit
			body.velocity = Vector2.ZERO #stop the projectile from moving
			body.has_hit=true #the projectile has hit
			body.kill() #call the kill function
			hit(damage) #apply damage

#applies damage after a hit to the bull
func hit(damage):
	if !dead: #only apply damage if bull is not dead
		isHit = true #set that the bull is being hit so no other action can occur
		health -= damage #take damage away from health
		emit_signal("update_health", health) #update healthbar
		if !$HitSound.playing:
			$HitSound.play()

#returns true if the entity is a projectile
func body_is_projectile(body):
	return body.get_name().find("Projectile") != -1 && active

#returns true if the projectile has already hit an entity
func projectile_hit(body):
	return body.has_hit

func _on_Animation_animation_finished():
	if $Animation.animation == "attack" || $Animation.animation == "attack_up" || $Animation.animation == "attack_down" :
		$Animation.frame = 0
		current_state = state.moving
		
#called when an entity enters then spawn area for the bull
func _on_SpawnBullArea_body_entered(body):
	if !active: #if the bull is not already active
		if body.get_name() == "Human" || body.get_name() == "Spirit": #if the entity is a player
			active = true #activate the bull
			set_collision_mask_bit(0, true) #activate collision with the world
			set_collision_mask_bit(3, true) #activate collision with doors
			
			emit_signal("boss_spawned") #activate healthbar
			
			$PlayerDetection.monitoring = true #start player detection to reset target
			$PlayerDetection.set_deferred("monitorable", true)

#called when an entity enters the player detection circle
func _on_PlayerDetection_body_entered(body):
	if active:
		if body.is_in_group("player") && !body.frozen: #if the entity is a player. checks if frozen to prevent a player switching forms to confuse the AI
			current_state = state.moving #set moving state
			target = body #set the entity as the target

#called when a player leaves the detection range
func _on_PlayerDetection_body_exited(body):
	if active:
		if body.is_in_group("player") && !body.frozen: #if the entity is a player. checks if frozen to prevent a player switching forms to confuse the AI
			current_state = state.idle #set the bull to idle
			target = null #remove the set target
