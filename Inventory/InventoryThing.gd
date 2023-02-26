extends Thing
class_name InventoryThing

@export var plural:String
@export var group:String

@export var combinable = false
@export var value = 1
@export var n = 1
@export var weight = 0
@export var ac = 0
@export var ac_modifier = 0
@export var to_hit_modifier = 0
@export var damage_dice = { "n": 1, "d": 4, "plus": 0}

@export var can_attack_with = false
@export var always_equipped = false

@export var acceptable:GameEngine.BodyParts # (GameEngine.BodyParts, FLAGS)

func get_persistent_data():
	var p = super.get_persistent_data()
	p.merge({
		"n": n
	})
	return p

func load_persistent_data(p):
	super.load_persistent_data(p)
	n = p.n

func _ready():
	super()
	if plural == "": plural = display_name
	add_to_group("InventoryThings")
	add_to_group("Ephemeral")
	if group != "": add_to_group(group)
	
func get_display_name():
	if n > 1: return String(n) + " " + plural
	else: return display_name
