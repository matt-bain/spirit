extends KinematicBody2D

var speed = 500 #speed the projectile travels at
var right = true #if the projectile is travelling right
var velocity = Vector2.ZERO #velocity that will control the trajectory
var has_hit = false #has the projectile hit somethign

#control the direction the projectile spawns in
func _ready():
	if(!right):
		$AnimatedSprite.flip_v = true

#physics loop every frame
func _physics_process(delta):
	
	#if the fire is flying
	if !has_hit:
		#make the fire travel
		if(right):
			velocity.x = speed
		else:
			velocity.x = -speed
		
	#if the alive timer runs out
	if $Timer.get_time_left() == 0:
		kill() #destroy projectile
		
	velocity = move_and_slide(velocity) #move the projectile along its trajectory
	
	for i in get_slide_count(): #loop through all slides in the projectile's movement
		var collision = get_slide_collision(i)
		if collision: #if there was a collision in the slide
			#destroy the projectile if it hit a tile
			if collision.collider is TileMap:
				kill()
			#destroy the projectile if it hits a door or a pyre
			elif collision.collider is StaticBody2D:
				if collision.collider.get_name().find("Door", 0) != -1 || collision.collider.get_name().find("Pyre", 0) != -1 :
					kill()

#destroy the projectile
func kill():
	$AnimatedSprite.animation = "fire_death"
	yield($AnimatedSprite, "animation_finished")
	queue_free() #free memory
	
