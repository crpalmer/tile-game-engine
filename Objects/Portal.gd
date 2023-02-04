extends Area2D

export(String, FILE) var scene
export(String) var entry_point

func _ready():
	var _err = connect("body_entered", self, "body_entered")

func body_entered(body):
	if body is Player:
		GameEngine.call_deferred("enter_scene", scene, entry_point)
