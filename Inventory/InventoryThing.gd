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

func _ready():
	if not singular or singular == "": singular = name
	if not plural or plural == "": plural = singular
	add_to_group("InventoryThings")
	if group and group != "": add_to_group(group)
	
func to_string():
	if n > 1: return String(n) + " " + plural
	else: return singular
