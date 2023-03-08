extends PhysicsBody2D
class_name Thing

@export var display_name:String : get = get_display_name
@export_multiline var long_description:String
@export var findable = true
@export var reveal_text: String
@export var findable_shape_path = "FindableCollisionShape2D"
@export var max_uses:int = -1
@export var use_time:float = 0.05
@export var minutes_between_uses:float = 0.2

var next_use_at:float = 0
var cur_uses:int

var findable_shape

func get_persistent_data():
	return {
		"next_use_at": next_use_at,
		"cur_uses": cur_uses,
		"visible": visible
	}

func load_persistent_data(p):
	next_use_at = p.next_use_at
	cur_uses = p.cur_uses
	if p.has("visible"): visible = p.visible
	visibility_changed()

func _ready():
	add_to_group("PersistentNodes")
	add_to_group("Trackables")
	add_to_group("Things")
	findable_shape = get_node_or_null(findable_shape_path)
	if display_name == "": display_name = name
	if minutes_between_uses < use_time: minutes_between_uses = use_time
	reset_uses()
	visibility_changed()

func get_display_name() -> String:
	if cur_uses > 1: return "%d uses of %s" % [ cur_uses, display_name ]
	else: return display_name

func get_bare_display_name() -> String:
	return display_name

func used_by(thing) -> bool:
	return used_by_with_scale(thing, 1.0)

func used_by_with_scale(_thing, time_scale=1.0) -> bool:
	if cur_uses > 0: cur_uses -= 1
	next_use_at = GameEngine.time_in_minutes + minutes_between_uses*time_scale
	return cur_uses == 0

func looked_at():
	if not visible and findable:
		if reveal_text != "": GameEngine.message(reveal_text, true)
		visible = true
		visibility_changed()

func visibility_changed():
	if findable_shape: findable_shape.set_deferred("disabled", visible)

func capitalized_display_name() -> String:
	var lower_case_name = get_display_name()
	return lower_case_name[0].to_upper() + lower_case_name.substr(1)

func description() -> String:
	if visible and long_description != "": return long_description
	return ""

func may_use() -> bool:
	return cur_uses != 0 and GameEngine.time_in_minutes >= next_use_at

func reset_uses() -> void:
	cur_uses = max_uses
