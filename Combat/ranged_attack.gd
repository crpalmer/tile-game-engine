extends Attack
class_name RangedAttack

@export var damage_modifier = 0
@export var ammunition_group:String

var ammo:Missile

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

func set_time_scale(value:float) -> void:
	ammo.set_time_scale(value)
	super(value)

func used_by(by):
	if ammo and ammo.used_by(by):
		ammo.queue_free()
	return super(by)

func pick_ammo(from:Actor) -> Missile:
	for option in get_children():
		if option is Missile and option.may_use():
			return option as Missile
	var ammo_options = from.get_equipment_in_group(ammunition_group)
	for option in ammo_options:
		if option is Missile and option.may_use():
			return option as Missile
	return null

func may_attack(from:Actor, to:Actor) -> bool:
	if not super(from, to): return false
	ammo = pick_ammo(from)
	return ammo != null
