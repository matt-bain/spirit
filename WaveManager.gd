#manages the waves in the arena
extends Node2D

signal arena_complete #emits when all waves are complete
signal wave_start(wave, timeout) #emits a message to the player announcing the wave number

var spawns #will hold all spawn points
export (PackedScene) var EnemyToSpawn #holds the enemy that will be spawned
export (NodePath) var PathfindingPath #holds the node path of where to access the pathfinding tiles
var Pathfinding #holds the pathfinding that the enemy will use

var enemies_to_spawn = 0 #enemies to spawn in each wave
var enemies_alive = 0 #enemies left in the wave
var waves = {1: 2, 2: 3, 3: 5} #dictionary storing the wave number and number of enemies to spawn in each wave
var current_wave = 1 #the wave in progress

var has_started = false #has the arena been started?

#on load, set the pathfinding for the enemy and load all spawns
func _ready():
	Pathfinding = get_node(PathfindingPath)
	spawns = get_children()
	
#reset the arena
func reset():
	for child in owner.get_children(): #for all nodes in the scene
		if child is Ogre: 
			child.queue_free() #destroy all ogres
	current_wave = 1 #set the wave back to 1
	enemies_to_spawn = 0 
	enemies_alive = 0
	has_started = false #arena is stopped
	
#spawn a wave of enemies
func spawn_wave():
	emit_signal("wave_start", "[center]WAVE " + str(current_wave) + "[/center]", 3)
	enemies_to_spawn = waves[current_wave]
	
	for n in enemies_to_spawn: #for each enemy to spawn
		var spawn_num = randi() % spawns.size() #pick a random spawn point
		if has_started: #stops enemies spawning after the player has died 
			spawn_enemy(spawns[spawn_num]) #spawn an enemy at the chosen point
			yield(get_tree().create_timer(3.0), "timeout") #wait 3 seconds to spawn the next enemy

#spawn an enemy in a chosen point
func spawn_enemy(spawn: Position2D):
	var enemy = EnemyToSpawn.instance() #create an instance of the enemy
	owner.call_deferred("add_child", enemy)
	enemy.global_position = spawn.global_position
	enemy.pathfinder = Pathfinding #apply pathfinding logic to the enemy
	enemies_alive += 1 #add an alive anemy
	
	enemy.connect("killed", self, "handle_killed") #set so when the enemy dies, the handle is called

#handle when an enemy dies
func handle_killed():
	enemies_alive -= 1 #take away an enemy
	
	#if the wave is over, start a new wave unless all waves are complete
	if (enemies_alive == 0):
		if (current_wave + 1 <= waves.size()):
			current_wave += 1
			spawn_wave()
		else:
			emit_signal("arena_complete")

#start the waves when a player enters the arena
func _on_ArenaStart_body_exited(body):
	if body.is_in_group("player") && !has_started:
		has_started = true
		spawn_wave()
