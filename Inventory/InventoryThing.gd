extends Thing
class_name InventoryThing

export var plural:String
export var group:String

export var combinable = false
export var n = 1
export var weight = 0
export var ac = 0
export var ac_modifier = 0
export var to_hit_modifier = 0
export var damage_dice = { "n": 1, "d": 4, "plus": 0}

export var can_attack_with = false
export var always_equipped = false

export(GameEngine.BodyParts, FLAGS) var acceptable

func get_persistent_data():
	var p = .get_persistent_data()
	p.merge({
		"n": n
	})
	return p

func load_persistent_data(p):
	.load_persistent_data(p)
	n = p.n

func _ready():
	if not plural or plural == "": plural = display_name
	add_to_group("InventoryThings")
	if group != "": add_to_group(group)
	
func description():
	if n > 1: return String(n) + " " + plural
	else: return display_name
