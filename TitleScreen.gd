extends Node2D

export (PackedScene) var startgame #holds the reference to the next scene
export (PackedScene) var credits #holds the reference to the credits scene

func _ready():
	$MenuMusic.play()

#start the game when "start game is pressed"
func _on_StartButton_pressed():
	get_tree().change_scene_to(startgame) #load first scene

#quit the game if "quit" button is pressed
func _on_QuitButton_pressed():
	get_tree().quit()

#show the credits when the credits button is pressed
func _on_Credits_pressed():
	get_tree().change_scene_to(credits) #load credits scene
