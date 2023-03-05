extends Attack
class_name MeleeAttack

@export var damage_dice = { "n": 1, "d": 1, "plus": 0 }
@export var damage_modifier = 0

func attack(from:Actor, to:Actor) -> bool:
	var hits = super(from, to)
	if hits:
		var dice = damage_dice.duplicate()
		dice.plus += damage_modifier
		var damage = GameEngine.roll(dice)
		to.take_damage(damage, from, self)
	else:
		GameEngine.message("%s misses %s with a %s" % [ from.capitalized_display_name(), to.display_name, display_name ])
		to.damage_popup(false, 0, from)
	return hits
