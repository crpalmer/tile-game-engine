extends SubSceneTrigger

var not_yet_triggered = true

func should_enter_scene():
	return not_yet_triggered

func on_triggered():
	not_yet_triggered = false

func get_persistent_data():
	return { "not_yet_triggered": not_yet_triggered }

func load_persistent_data(p):
	not_yet_triggered = p.not_yet_triggered

func _ready():
	add_to_group("PersistentNodes")
