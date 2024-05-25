extends Label

func _process(_delta):
	text = GameEngine.current_time_string()
