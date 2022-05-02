#handle projectile earth
extends KinematicBody2D

var speed = 350 #speed the projectile travels at
var gravity = 20 #gravity acting on the projectile
var spin_speed = 30 #speed the projectile spins at
var right = true #if the projectile is travelling right
var velocity = Vector2.ZERO #velocity that will control the trajectory
var has_hit = false #has the projectile hit somethign

var sound_played = false #stop the break sound from looping

#control the direction the projectile spawns in
func _ready():
	if(!right):
		$AnimatedSprite.flip_v = true

#physics loop every frame
func _physics_process(delta):
	
	velocity.y = velocity.y + gravity #apply gravity
	
	#if the rock is flying
	if!has_hit:
		rotation_degrees = rotation_degrees + spin_speed #spin the rock
		
		#make the rock travel
		if(right):
			velocity.x = speed
		else:
			velocity.x = -speed
		
	#if the alive timer runs out
	if $Timer.get_time_left() == 0:
		kill() #destroy the rock
		
	velocity = move_and_slide(velocity) #move the projectile along its trajectory
	
	for i in get_slide_count(): #loop through all slides in the projectile's movement
		var collision = get_slide_collision(i) 
		if collision: #if there was a collision in the slide
			#destroy the rock if it hit a tile
			if collision.collider is TileMap: 
				kill()
			#destroy the rock if it hits a door, pyre, or pillar
			elif collision.collider is StaticBody2D:
				if collision.collider.get_name().find("Door", 0) != -1 || collision.collider.get_name().find("Pyre", 0) != -1 || collision.collider.get_name().find("Pillar", 0) != -1  :
					kill()

#destroy the rock
func kill():
	has_hit = true
	velocity.x = 0 #stop the projectile
	spin_speed = 0 
	$AnimatedSprite.animation = "earth_death"
	if !sound_played:
		sound_played = true
		$RockBreak.play()
	yield($AnimatedSprite, "animation_finished")
	queue_free() #free memory
