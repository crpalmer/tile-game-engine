extends Node2D
class_name SubSceneTrigger


export(String, FILE) var sub_scene
export(String) var entry_point = "EntryPoint"

func should_enter_scene():
	return true

func on_triggered():
	pass

func _ready():
	for c in get_children():
		if c is Area2D:
			c.connect("body_entered", self, "body_entered")

func body_entered(body):
	if body == GameEngine.player and should_enter_scene():
		on_triggered()
		GameEngine.call_deferred("enter_sub_scene", sub_scene, entry_point)
