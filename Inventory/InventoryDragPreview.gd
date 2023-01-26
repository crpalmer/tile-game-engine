extends CanvasLayer

func _process(_delta):
	$Thing.position = $Thing.get_global_mouse_position()
	if Input.is_action_just_released("left_mouse"):
		queue_free()

func add_thing(thing):
	duplicate_all_sprites(thing)

func duplicate_all_sprites(n):
	if n is Sprite:
		var sprite = n.duplicate()
		n.position = Vector2.ZERO
		$Thing.add_child(sprite)
	else:
		for c in n.get_children(): duplicate_all_sprites(c)
