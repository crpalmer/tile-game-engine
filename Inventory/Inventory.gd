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
	add_to_group("InventoryContainers")
	hide()

func open():
	make_visible(true)
	
func _process(_delta):
	if visible and Input.is_action_just_released("exit"):
		make_visible(false)

func make_visible(is_visible):
	visible = is_visible
	if is_visible: GameEngine.pause()
	else: GameEngine.resume()

# We need to recurse to ensure that we keep the order of the top level
# containers and the holders within them, etc.

func get_all_containers(from = self):
	var containers = []
	for c in from.get_children():
		if c.is_in_group("InventoryContainers"): containers.push_back(c)
	for c in from.get_children():
		if not c.is_in_group("InventoryContainers"):
			containers.append_array(get_all_containers(c))
	return containers

func get_all_holders(from = self):
	var holders = []
	for c in from.get_children():
		if c.is_in_group("InventoryHolders"):
			holders.push_back(c)
	for c in from.get_children():
		holders.append_array(get_all_holders(c))
	return holders

func get_all_things():
	var things = []
	for holder in get_all_holders():
		var thing = holder.get_thing()
		if thing: things.push_back(thing)
	return things

func add_thing(thing):
	if thing.combinable:
		var holder = get_holder_of_thing(thing)
		if holder:
			var existing_thing = holder.get_thing()
			existing_thing.n += thing.n
			thing.queue_free()
			holder.updated(existing_thing)
			return true
	for holder in get_all_holders():
		if holder.add_thing(thing):
			return true
	return false

func get_holder_of_thing(thing):
	for holder in get_all_holders():
		var existing_thing = holder.get_thing()
		if existing_thing and existing_thing.filename == thing.filename:
			return holder
	return null

func has_a_thing_in_group(group_name):
	for thing in get_all_things():
		if thing and thing.is_in_group(group_name):
			return true
	return false

func get_equipped_things():
	var things = []
	for holder in get_all_holders():
		var thing = holder.get_thing()
		if thing and holder.is_equipped: things.push_back(thing)
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
