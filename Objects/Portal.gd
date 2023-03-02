extends Area2D

@export_file("*.tscn") var scene:String
@export var entry_point: String
@export var required_milestone: String
@export var milestone_needed_message: String

func _ready():
	var _err = connect("body_entered",Callable(self,"body_entered"))

func body_entered(body):
	if required_milestone != "" and not GameEngine.has_completed_milestone(required_milestone):
		GameEngine.message(milestone_needed_message, true)
	elif not GameEngine.is_paused() and body == GameEngine.player:
		GameEngine.call_deferred("enter_scene", scene, entry_point)
