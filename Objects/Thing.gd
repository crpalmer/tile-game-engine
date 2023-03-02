extends PhysicsBody2D
class_name Thing

@export var display_name:String : get = get_display_name
@export var long_description:String # (String, MULTILINE)
@export var max_uses = -1
@export var use_time = 0.05
@export var minutes_between_uses = 0.2

var next_use_at = 0

func get_persistent_data():
	return {
		"next_use_at": next_use_at,
	}

func load_persistent_data(p):
	next_use_at = p.next_use_at

func _ready():
	add_to_group("PersistentNodes")
	add_to_group("Trackables")
	add_to_group("Things")
	if display_name == "": display_name = name
	if minutes_between_uses < use_time: minutes_between_uses = use_time

func get_display_name():
	return display_name

func used_by(_thing):
	if max_uses > 0: max_uses -= 1
	next_use_at = GameEngine.time_in_minutes + minutes_between_uses

func capitalized_display_name():
	var lower_case_name = get_display_name()
	return lower_case_name[0].to_upper() + lower_case_name.substr(1)

func description():
	if visible: return long_description
	return ""

func may_use():
	return max_uses != 0 and GameEngine.time_in_minutes >= next_use_at
