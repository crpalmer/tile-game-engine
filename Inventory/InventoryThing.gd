extends Thing
class_name InventoryThing

export var n = 1
export var plural:String
export var singular:String
export var group:String

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

func weight(): return 0
func ac_modifier(): return 0
func attack_modifier(): return 0
func damage_dice(): return []
