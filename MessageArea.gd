extends Area2D

export(String, MULTILINE) var message
export(bool) var one_shot = true

var available = true

func get_persistent_data():
	return { "available": available }

func load_persistent_data(p):
	available = p.available

func _ready():
	var _err = connect("body_entered", self, "on_body_entered")
	add_to_group("PersistentNodes")

func on_body_entered(body):
	if available and body == GameEngine.player:
		GameEngine.message(message, true)
		if one_shot: available = false
