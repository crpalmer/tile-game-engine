extends InventoryHolder

func drop_data(position, data):
	.drop_data(position, data)
	data.thing.get_parent().remove_child(data.thing)
	data.thing.position = GameEngine.player.position
	GameEngine.current_scene.add_child(data.thing)
