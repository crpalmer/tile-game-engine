extends InventoryHolder

func add_thing(_thing):
	return false

func _drop_data(pos, data):
	super._drop_data(pos, data)
	data.thing.get_parent().remove_child(data.thing)
	data.thing.global_position = GameEngine.player.global_position
	GameEngine.current_scene.add_child(data.thing)
