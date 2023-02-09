extends Area2D
class_name ActorRandomMovement

export(String) var shape_node = "CollisionShape2D"
export(float, 100) var minimum_distance_percent = 50.0
export(bool) var stay_in_area = false

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

func clamp_to_area(destination):
	if stay_in_area:
		destination.x = clamp(destination.x, start_position.x - shape.shape.extents.x, start_position.x + shape.shape.extents.x)
		destination.y = clamp(destination.y, start_position.y - shape.shape.extents.y, start_position.y + shape.shape.extents.y)
	return destination
