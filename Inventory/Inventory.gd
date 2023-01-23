extends CanvasLayer

func _ready():
	hide()
	add_to_group("InventoryContainers")

func _process(_delta):
	if Input.is_action_just_released("show_inventory"):
		make_visible(not visible)

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
