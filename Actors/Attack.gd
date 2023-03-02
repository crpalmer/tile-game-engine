extends Thing
class_name Attack

@export var to_hit_modifier = 0
@export var damage_dice = { "n": 1, "d": 1, "plus": 0 }
@export var attack_range = 3

func get_persistent_data():
	var p = super.get_persistent_data()
	p.merge({
		"to_hit_modifier": to_hit_modifier,
		"damage_dice": damage_dice
	})
	return p

func load_persistent_data(p):
	super.load_persistent_data(p)
	to_hit_modifier = p.to_hit_modifier
	damage_dice = p.damage_dice

func get_display_name():
	if display_name != "": return display_name
	var parent = get_parent()
	if parent is Actor: return parent.display_name
	if parent is Thing: return parent.get_display_name()
	return ""
