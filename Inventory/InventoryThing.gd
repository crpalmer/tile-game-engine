extends Thing
class_name InventoryThing

@export var plural:String
@export var group:String
@export var reveal_text: String

@export var findable: bool = true

@export var combinable = false
@export var value = 1
@export var n = 1
@export var weight = 0
@export var ac = 0
@export var ac_modifier = 0

@export var always_equipped = false

@export var acceptable:GameEngine.BodyParts # (GameEngine.BodyParts, FLAGS)

var findable_shape

func get_persistent_data():
	var p = super.get_persistent_data()
	p.merge({
		"n": n,
		"visible": visible
	})
	return p

func load_persistent_data(p):
	super.load_persistent_data(p)
	n = p.n
	visible = p.visible
	visibility_changed()

func _ready():
	super()
	visibility_changed()
	if plural == "": plural = display_name
	add_to_group("InventoryThings")
	add_to_group("Ephemeral")
	if group != "": add_to_group(group)
	
func get_display_name():
	if n > 1: return String(n) + " " + plural
	else: return display_name

func looked_at():
	if not visible and findable:
		if reveal_text != "": GameEngine.message(reveal_text, true)
		visible = true
		visibility_changed()

func visibility_changed():
	if findable_shape == null: 	findable_shape = $FindableCollisionShape2D
	findable_shape.set_deferred("disabled", visible)
