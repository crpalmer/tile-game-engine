extends KinematicBody2D
class_name Thing

export var display_name:String
export var max_uses = -1
export var use_time = 0.25
export var time_between_uses = 0

var next_use_at = 0

func _ready():
	if not display_name or display_name == "": display_name = name

func used_by(_thing):
	if max_uses > 0: max_uses -= 1
	next_use_at = GameEngine.time + time_between_uses

func looked_at():
	return to_string()
	
func to_string():
	return display_name

func may_use():
	return max_uses != 0 and GameEngine.time >= next_use_at
