extends Attack
class_name RangedAttack

@export var damage_modifier = 0
@export var ammunition_group:String

var ammo:Missile

func used_by(who:Actor) -> bool:
	var res = super(who)
	if ammo.used_by(who):
		ammo.queue_free()
	return res

func attack(from:Actor, to:Actor) -> bool:
	var hits = super(from, to)
	var damage = 0
	if hits:
		damage = ammo.roll_damage() + damage_modifier
		to.take_damage(damage, from, ammo, false)
	else:
		GameEngine.message("%s misses %s with a %s from a %s" % [ from.capitalized_display_name(), to.display_name, ammo.display_name, display_name ])
	ammo.shoot(from, to, to.create_damage_popup(hits, damage, from))
	return hits

func pick_ammo(from:Actor) -> Missile:
	var ammo_options = from.get_equipment_in_group(ammunition_group)
	for option in ammo_options:
		if option is Missile and option.may_use():
			return option as Missile
	return null

func may_attack(from:Actor, to:Actor) -> bool:
	if not super(from, to): return false
	ammo = pick_ammo(from)
	return ammo != null
