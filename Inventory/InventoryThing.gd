extends Thing
class_name InventoryThing

export var n = 1
export var plural:String
export var singular:String
export var group:String

export var weight = 0
export var ac = 0
export var ac_modifier = 0
export var to_hit_modifier = 0
export var damage_dice = { "n": 1, "d": 4, "plus": 0}

export var can_attack_with = false
export var always_equipped = false
export var can_be_in_hands = false
export var requires_two_hands = false
export var can_be_on_head = false
export var can_be_around_neck = false
export var can_be_on_body = false
export var can_be_on_feet = false
# TODO: make those a bitmask and use export(int, "a", "b", "c") to set them!

func get_persistent_data():
	var p = .get_persistent_data()
	p.merge({
		"n": n,
		"plural": plural,
		"singular": singular,
		"group": group,
		"weight": weight,
		"ac": ac,
		"ac_modifier": ac_modifier,
		"to_hit_modifier": to_hit_modifier,
		"damage_dice": damage_dice,
		"can_attack_with": can_attack_with,
		"always_equipped": always_equipped,
		"requires_two_hands": requires_two_hands,
		"can_be_on_head": can_be_on_head,
		"can_be_around_neck": can_be_around_neck,
		"can_be_on_body": can_be_on_body,
		"can_be_on_feet": can_be_on_feet
	})
	return p

func load_persistent_data(p):
	.load_persistent_data(p)
	if group != "": remove_from_group(group)
	n = p.n
	plural = p.plural
	group = p.group
	weight = p.weight
	ac = p.ac
	to_hit_modifier = p.to_hit_modifier
	damage_dice = p.damage_dice
	can_attack_with = p.can_attack_with
	always_equipped = p.always_equipped
	requires_two_hands = p.requires_two_hands
	can_be_on_head = p.can_be_on_head
	can_be_around_neck = p.can_be_around_neck
	can_be_on_body = p.can_be_on_body
	can_be_on_feet = p.can_be_on_feet
	if group != "": add_to_group(group)

func _ready():
	if not singular or singular == "": singular = name
	if not plural or plural == "": plural = singular
	add_to_group("InventoryThings")
	if group != "": add_to_group(group)
	
func looked_at():
	if n > 1: return String(n) + " " + plural
	else: return singular
