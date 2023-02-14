extends Area2D

export(String, FILE) var scene
export(String) var entry_point
export(String) var required_milestone
export(String) var milestone_needed_message

func _ready():
	var _err = connect("body_entered", self, "body_entered")

func body_entered(body):
	if required_milestone != "" and not GameEngine.has_completed_milestone(required_milestone):
		GameEngine.message(milestone_needed_message, true)
	elif not GameEngine.is_paused() and body == GameEngine.player:
		GameEngine.call_deferred("enter_scene", scene, entry_point)
