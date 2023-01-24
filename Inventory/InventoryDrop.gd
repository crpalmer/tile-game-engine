extends InventoryHolder

func drop_data(_position, data):
	data.thing.get_parent().remove_child(data.thing)
	data.thing.position = GameEngine.player.position
	GameEngine.current_scene.add_child(data.thing)
	emit_signal("inventory_changed")
