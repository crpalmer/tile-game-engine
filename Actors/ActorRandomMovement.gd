extends Area2D
class_name ActorRandomMovement

export(String) var shape_node = "CollisionShape2D"
export(float, 100) var minimum_distance_percent = 50.0
onready var shape = get_node(shape_node)
onready var start_position = global_position

func random_point(center, extent:int):
	var delta = 0
	while abs(delta) < extent*minimum_distance_percent/100:
		delta = randi() % extent*2 - extent
	return center - delta

func new_destination():
	var pos = Vector2(random_point(start_position.x, shape.shape.extents.x), random_point(start_position.y, shape.shape.extents.y))
	return pos
