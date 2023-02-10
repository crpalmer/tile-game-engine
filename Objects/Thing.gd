extends PhysicsBody2D
class_name Thing

export var display_name:String setget , get_display_name
export(String, MULTILINE) var long_description
export(String) var reveal_text
export(bool) var findable = true
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
		"next_use_at": next_use_at,
		"visible": visible
	}

func load_persistent_data(p):
	yield(self, "ready")
	display_name = p.display_name
	max_uses = p.max_uses
	use_time = p.use_time
	minutes_between_uses = p.minutes_between_uses
	next_use_at = p.next_use_at
	visible = p.visible

func _ready():
	add_to_group("PersistentThings")
	add_to_group("Trackables")
	if not display_name or display_name == "": display_name = name
	if minutes_between_uses < use_time: minutes_between_uses = use_time

func get_display_name():
	return display_name

func used_by(_thing):
	if max_uses > 0: max_uses -= 1
	next_use_at = GameEngine.time_in_minutes + minutes_between_uses

func capitalized_display_name():
	return display_name[0].to_upper() + display_name.substr(1)

func description():
	if visible: return long_description
	return ""

func may_use():
	return max_uses != 0 and GameEngine.time_in_minutes >= next_use_at

func looked_at():
	if not visible and findable:
		if reveal_text != "": GameEngine.message(reveal_text)
		visible = true
