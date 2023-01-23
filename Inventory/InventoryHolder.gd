extends Node2D
class_name InventoryHolder

export var requires_hands = false
export var requires_head = false
export var requires_neck = false
export var requires_body = false
export var requires_feet = false

func _ready():
	add_to_group("InventoryHolders")
	
func add_thing(thing):
	for c in get_children():
		if c is InventoryThing:
			return false
	if thing.get_parent(): thing.get_parent().remove_child(thing)
	thing.position = Vector2(32, 32)
	add_child(thing)
	return true

func has_a(thing):
	for c in get_children():
		if c == thing: return true
	return false

func has_a_thing_in_group(group_name):
	for c in get_children():
		if c.is_in_group(group_name): return true
	return false
