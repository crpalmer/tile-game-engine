extends Area2D
class_name SubSceneTrigger


@export_file("*.tscn") var sub_scene
@export var entry_point: String = "EntryPoint"

func should_enter_scene():
	return true

func on_triggered():
	pass

func _ready():
	connect("body_entered",Callable(self,"body_entered"))

func body_entered(body):
	if body == GameEngine.player and should_enter_scene():
		on_triggered()
		GameEngine.call_deferred("enter_sub_scene", sub_scene, entry_point)
