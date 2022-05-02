#controls player healthbar
extends ProgressBar

#game loop every frame
func _process(delta):
	if value <= 100 && value > 50: #set health to green if between 50 and 100
		get("custom_styles/fg").set_bg_color(Color(0.04, 0.56, 0.29, 1.0))
	elif value <= 50 && value > 20:#set health yellow if health betwwen 20 and 50
		get("custom_styles/fg").set_bg_color(Color(1.00, 0.92, 0.0, 1.0))
	else:#set health red below 20
		get("custom_styles/fg").set_bg_color(Color(0.96, 0.01, 0.01, 1.0))
