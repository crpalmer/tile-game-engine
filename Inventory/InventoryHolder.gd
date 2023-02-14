extends Control
class_name InventoryHolder

signal inventory_changed

export var combinable = false
export var is_equipped = false

export(GameEngine.BodyParts, FLAGS) var requires

var mouse_in_control = 0

func get_persistent_data():
	var thing = get_thing()
	if thing:
		return {
			"filename": thing.filename,
			"data": thing.get_persistent_data(),
			"global_position": thing.global_position
		}
	else: return null

func load_persistent_data(p):
	var thing = GameEngine.instantiate(self, p.filename, p.data)
	set_thing_position(thing)

func _ready():
	add_to_group("InventoryHolders")
	var _err = connect("inventory_changed", GameEngine.player, "on_inventory_changed")
	_err = connect("mouse_entered", self, "on_mouse_entered")
	_err = connect("mouse_exited", self, "on_mouse_exited")

func get_thing():
	for c in get_children():
		if c is InventoryThing:
			return c
	return null

func can_accept_thing(thing):
	return not requires or (requires & thing.acceptable) != 0

func set_thing_position(thing):
	thing.position = rect_size/2

func add_thing(thing):
	if get_thing(): return false
	if not can_accept_thing(thing): return false
	if thing.get_parent(): thing.get_parent().remove_child(thing)
	set_thing_position(thing)
	add_child(thing)
	updated(thing)
	return true

func updated(thing):
	hint_tooltip = thing.display_name
	emit_signal("inventory_changed")

func has_a_thing_in_group(group_name):
	var my_thing = get_thing()
	return my_thing and my_thing.is_in_group(group_name)

func get_drag_data(_position):
	var my_thing:InventoryThing = get_thing()
	if my_thing:
		var preview = load("%s/Inventory/InventoryDragPreview.tscn" % GameEngine.config.root).instance()
		preview.add_thing(my_thing)
		get_parent().add_child(preview)
		return { "holder": self, "thing": my_thing }
	return false
	
func can_drop_data(_position, data):
	return get_thing() == null and can_accept_thing(data.thing)

func drop_data(_position, data):
	data.thing.get_parent().remove_child(data.thing)
	add_child(data.thing)
	emit_signal("inventory_changed")

func on_mouse_entered():
	mouse_in_control += 1

func on_mouse_exited():
	mouse_in_control -= 1

func _input(event:InputEvent):
	if mouse_in_control > 0 and event.is_action_pressed("look"):
		var thing = get_thing()
		if thing and thing.description() != "":
			GameEngine.message(thing.description())
