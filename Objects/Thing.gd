extends KinematicBody2D
class_name Thing

export var display_name:String

func _ready():
	if not display_name or display_name == "": display_name = name

func used_by(_thing):
	pass

func to_string():
	return display_name
