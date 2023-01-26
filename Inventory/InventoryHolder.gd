extends Control
class_name InventoryHolder

signal inventory_changed

export var drag_preview_path = "res://GameEngine/Inventory/InventoryDragPreview"
export var is_equipped = false
export var requires_hands = false
export var requires_head = false
export var requires_neck = false
export var requires_body = false
export var requires_feet = false

func get_persistent_data():
	var thing = get_thing()
	if thing:
		return {
			"filename": thing.filename,
			"data": thing.get_persistent_data(),
			"position": thing.position
		}
	else: return null

func load_persistent_data(p):
	var thing = GameEngine.instantiate(p.filename, p.data, p.position)
	add_child(thing)

func _ready():
	add_to_group("InventoryHolders")
	var _err = connect("inventory_changed", GameEngine.player, "on_inventory_changed")

func get_thing():
	for c in get_children():
		if c is InventoryThing:
			return c
	return null

func can_accept_thing(thing):
	if requires_hands and not thing.can_be_in_hands: return false
	if requires_head and not thing.can_be_on_head: return false
	if requires_neck and not thing.can_be_around_neck: return false
	if requires_body and not thing.can_be_on_body: return false
	if requires_feet and not thing.can_be_on_feet: return false
	return true

func add_thing(thing):
	if get_thing(): return false
	if not can_accept_thing(thing): return false
	if thing.get_parent(): thing.get_parent().remove_child(thing)
	thing.position = Vector2(32, 32)
	add_child(thing)
	emit_signal("inventory_changed")
	return true

func has_a(thing):
	var my_thing = get_thing()
	return my_thing and my_thing == thing

func has_a_thing_in_group(group_name):
	var my_thing = get_thing()
	return my_thing and my_thing.is_in_group(group_name)

func get_equipped_things():
	var thing = get_thing()
	if thing and (is_equipped or thing.always_equipped): return [ thing ]
	return null
	
func get_drag_data(_position):
	var my_thing:InventoryThing = get_thing()
	if my_thing:
		set_drag_preview(self.duplicate())
		return { "holder": self, "thing": my_thing }
	return false
	
func can_drop_data(_position, data):
	return get_thing() == null and can_accept_thing(data.thing)

func drop_data(_position, data):
	data.thing.get_parent().remove_child(data.thing)
	add_child(data.thing)
	emit_signal("inventory_changed")
