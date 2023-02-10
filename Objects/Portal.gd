extends Area2D

export(String, FILE) var scene
export(String) var entry_point

func _ready():
	yield(get_tree(), "idle_frame")
	var _err = connect("body_entered", self, "body_entered")

func body_entered(body):
	if body == GameEngine.player:
		GameEngine.call_deferred("enter_scene", scene, entry_point)
