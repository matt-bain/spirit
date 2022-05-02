extends Control

func _ready():
	$AnimationPlayer.play("scroll")
	
#when back pressed, go back to title screen
func _on_StartButton_pressed():
	get_tree().change_scene("res://TitleScreen.tscn")
