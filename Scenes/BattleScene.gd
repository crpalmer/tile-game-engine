extends SubScene

func should_return_from_scene():
	return GameEngine.n_hostile == 0

func _ready():
	for c in get_children():
		if c is Actor and c.mood != Actor.Mood.FRIENDLY:
			c.mood = Actor.Mood.HOSTILE
