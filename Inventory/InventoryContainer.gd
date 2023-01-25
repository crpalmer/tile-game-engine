extends Node2D

func get_persistent_data():
	var p = {}
	for c in get_children():
		if c.is_in_group("InventoryHolders") or c.is_in_group("InventoryContainers"):
			var p_c = c.get_persistent_data()
			if p_c:
				p.merge({
					c.name: c.get_persistent_data()
				})
	return p
	
func load_persistent_data(p):
	for c in get_children():
		if p.has(c.name): c.load_persistent_data(p[c.name])

func _ready():
	add_to_group("InventoryContainers")
	
func add_thing(thing:InventoryThing):
	for c in get_children():
		if c.is_in_group("InventoryHolders") and c.add_thing(thing):
			return true
	for c in get_children():
		if c.is_in_group("InventoryContainers") and c.add_thing(thing):
			return true
	return false

func has_a(thing:InventoryThing):
	for c in get_children():
		if (c.is_in_group("InventoryContainers") or c.is_in_group("InventoryHolders")) and c.has_a(thing):
			return true
	return false

func has_a_thing_in_group(group_name):
	for c in get_children():
		if (c.is_in_group("InventoryContainers") or c.is_in_group("InventoryHolders")) and c.has_a_thing_in_group(group_name):
			return true
	return false

func get_equipped_things():
	var things = []
	for c in get_children():
		if c.is_in_group("InventoryContainers") or c.is_in_group("InventoryHolders"):
			var new_things = c.get_equipped_things()
			if new_things: things.append_array(new_things)
	return things
