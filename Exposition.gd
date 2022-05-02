extends CanvasLayer

export (PackedScene) var level_1 #reference to the first level of the game

func _process(delta):
	#player presses e
	if Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to(level_1) #level 1 is loaded
