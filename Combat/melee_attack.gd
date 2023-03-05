extends Attack
class_name MeleeAttack

@export var damage_dice = { "n": 1, "d": 1, "plus": 0 }
@export var damage_modifier = 0

func get_cause_string():
	if display_name != "":
		var parent = get_parent()
		if parent is InventoryThing:
			return "%s from a %s" % [ display_name, parent.display_name ]
	return display_name

func get_weapon_string():
	var parent = get_parent()
	if parent is InventoryThing:
		return parent.display_name
	return display_name

func attack(from:Actor, to:Actor) -> bool:
	var hits = super(from, to)
	if hits:
		var dice = damage_dice.duplicate()
		dice.plus += damage_modifier
		var damage = GameEngine.roll(dice)
		to.take_damage(damage, from, get_cause_string())
	else:
		GameEngine.message("%s misses %s with a %s" % [ from.capitalized_display_name(), to.display_name, get_weapon_string() ])
		to.damage_popup(false, 0, from)
	return hits
