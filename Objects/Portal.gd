extends Area2D

export var scene:String
export var entry_point:String

func _ready():
	var _err = connect("body_entered", self, "body_entered")

func body_entered(body):
	if body is Player:
		GameEngine.enter_scene(scene, entry_point)
