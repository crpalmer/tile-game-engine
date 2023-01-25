extends Thing
class_name Attack

export var to_hit_modifier = 0
export var damage_dice = { "n": 1, "d": 1, "plus": 0 }

func get_persistent_data():
	var p = .get_persistent_data()
	p.merge({
		"to_hit_modifier": to_hit_modifier,
		"damage_dice": damage_dice
	})
	return p

func load_persistent_data(p):
	.load_persistent_data(p)
	to_hit_modifier = p.to_hit_modifier
	damage_dice = p.damage_dice
