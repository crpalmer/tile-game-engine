extends CanvasLayer

func get_persistent_data():
	var p = {}
	for c in get_children():
		if c.is_in_group("InventoryContainers") or c.is_in_group("InventoryHolders"):
			var d = c.get_persistent_data()
			if d: p.merge({ c.name: d })
	return p

func load_persistent_data(p):
	for c in get_children():
		if p.has(c.name): c.load_persistent_data(p[c.name])

func _ready():
	hide()
	add_to_group("InventoryContainers")

func _process(_delta):
	if Input.is_action_just_released("show_inventory"):
		if visible: make_visible(false)
		elif not GameEngine.is_paused(): make_visible(true)
	elif visible and Input.is_action_just_released("exit"):
		make_visible(false)

func make_visible(is_visible):
	visible = is_visible
	if is_visible: GameEngine.pause()
	else: GameEngine.resume()

func add_thing(thing):
	for c in get_children():
		if c.is_in_group("InventoryContainers") and c.add_thing(thing):
			return true
	for c in get_children():
		if c.is_in_group("InventoryHolders") and c.add_thing(thing):
			return true
	return false

func has_a(thing):
	for c in get_children():
		if (c.is_in_group("InventoryHolders") or c.is_in_group("InventoryContainers")) and c.has_a(thing):
			return true
	return false

func has_a_thing_in_group(group_name):
	for c in get_children():
		if (c.is_in_group("InventoryHolders") or c.is_in_group("InventoryContainers")) and c.has_a_thing_in_group(group_name):
			return true
	return false

func get_equipped_things():
	var things = []
	for c in get_children():
		if c.is_in_group("InventoryContainers")  or c.is_in_group("InventoryThings"):
			var new_things = c.get_equipped_things()
			if new_things: things.append_array(new_things)
	return things

func get_ac():
	var max_ac = 0
	var ac_modifier = 0
	for t in get_equipped_things():
		if t and t.ac > max_ac: max_ac = t.ac
		ac_modifier += t.ac_modifier
	return max_ac + ac_modifier

func get_to_hit_modifier():
	var to_hit_modifier = 0
	for t in get_equipped_things():
		if not t.can_attack_with: to_hit_modifier += t.to_hit_modifier
	return to_hit_modifier
