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

@export var always_equipped = false

@export var acceptable:GameEngine.BodyParts # (GameEngine.BodyParts, FLAGS)

func get_persistent_data():
	var p = super.get_persistent_data()
	p.merge({
		"n": n,
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
	
func get_display_name() -> String:
	if n > 1: return super() + " (x%d)" % n
	else: return super()

func used_by(thing) -> bool:
	if super(thing):
		n -= 1
		if n > 0: reset_uses()
		else: return true
	return false
