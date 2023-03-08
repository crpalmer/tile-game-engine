extends Thing
class_name Attack

@export var to_hit_modifier = 0
@export var min_range_feet = 0
@export var max_range_feet = 5

var min_range
var max_range

func _ready():
	super()
	min_range = GameEngine.feet_to_pixels(min_range_feet)
	max_range = GameEngine.feet_to_pixels(max_range_feet)

func get_display_name():
	if super() != "": return super()
	var parent = get_parent()
	if parent is Actor: return parent.display_name
	if parent is Thing: return parent.display_name
	if parent is Attack: return parent.display_name
	return ""

func attack(from:Actor, to:Actor) -> bool:
	to.was_attacked_by(from)
	used_by_with_scale(from, 1.0/from.attacks_per_round)
	return GameEngine.roll_test(to.ac, from.attack_modifier + to_hit_modifier, true)

func may_attack(from:Actor, to:Actor) -> bool:
	if not may_use(): return false
	var distance = to.global_position.distance_to(from.global_position)
	if distance < min_range or distance > max_range: return false
	return true
