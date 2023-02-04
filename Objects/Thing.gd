extends PhysicsBody2D
class_name Thing

export var display_name:String
export var long_description:String
export var max_uses = -1
export var use_time = 0
export var minutes_between_uses = 0.2

var next_use_at = 0

func get_persistent_data():
	return {
		"display_name": display_name,
		"max_uses": max_uses,
		"use_time": use_time,
		"minutes_between_uses": minutes_between_uses,
		"next_use_at": next_use_at
	}

func load_persistent_data(p):
	display_name = p.display_name
	max_uses = p.max_uses
	use_time = p.use_time
	minutes_between_uses = p.minutes_between_uses
	next_use_at = p.next_use_at

func _ready():
	add_to_group("PersistentThings")
	add_to_group("Trackables")
	if not display_name or display_name == "": display_name = name
	if minutes_between_uses < use_time: minutes_between_uses = use_time

func used_by(_thing):
	if max_uses > 0: max_uses -= 1
	next_use_at = GameEngine.time_in_minutes + minutes_between_uses

func description():
	return long_description

func may_use():
	return max_uses != 0 and GameEngine.time_in_minutes >= next_use_at
