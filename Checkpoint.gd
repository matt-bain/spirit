#controls the checkpoints in the game
extends Area2D

func _ready():
	$Sprite.animation = "static" #keep the animation static on load
	
#called when a player runs through the checkpoint
func activate():
	if !$ActivateSound.playing:
		$ActivateSound.play()
	$Sprite.play() #play animations
	$Sprite.animation = "active" #set the active animation to play
	yield($Sprite, "animation_finished") #once finished
	$Sprite.animation = "static" #go back to static
	$Sprite.stop() #save rendering a static frame over and over
