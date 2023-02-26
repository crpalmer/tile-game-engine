extends Area2D
class_name ActorRandomMovement

@export var shape_node: String = "CollisionPolygon2D"
@export var minimum_distance_percent = 50.0 # (float, 100)
@export var only_see_player_when_in_area: bool = true
@export var navigation_layer: int = 1

@onready var start_position = global_position

var actor
var circle : CircleShape2D
var rect : RectangleShape2D
var polygon : CollisionPolygon2D
var triangles : PackedInt32Array
var triangles_area
var player_is_in_area = 0

func _ready():
	var _err = connect("body_entered",Callable(self,"body_entered"))
	_err = connect("body_exited",Callable(self,"body_exited"))
	var shape = get_node(shape_node)
	if shape is CollisionShape2D:
		if shape.shape is CircleShape2D:
			circle = shape.shape
		elif shape.shape is RectangleShape2D:
			rect = shape.shape
	elif shape is CollisionPolygon2D:
		polygon = shape
		prepare_polygon()

func may_see_player():
	return not only_see_player_when_in_area or player_is_in_area > 0

func triangle_area(t):
	var p = polygon.polygon
	var p1 = p[triangles[t+0]]
	var p2 = p[triangles[t+1]]
	var p3 = p[triangles[t+2]]
	var l1 = (p2 - p1).length()
	var l2 = (p3 - p2).length()
	var l3 = (p1 - p3).length()
	var s = (l1+l2+l3)/2.0
	
	return sqrt(s*(s-l1)*(s-l2)*(s-l3))

func prepare_polygon():
	triangles = Geometry2D.triangulate_polygon(polygon.polygon)
	triangles_area = 0.0
	for t in range(0, triangles.size(), 3):
		triangles_area += triangle_area(t)

func pick_random_triangle():
	var A = randf() * triangles_area
	var t = 0
	while t < polygon.polygon.size():
		A -= triangle_area(t)
		if A <= 0: return t
		t += 3
	return t - 3

func pick_random_point_in_triangle(t):
	var p = polygon.polygon
	var p1 = p[triangles[t+0]]
	var p2 = p[triangles[t+1]]
	var p3 = p[triangles[t+2]]
	var r1 = randf()
	var r2 = randf()
	var point = Vector2.ZERO
	point.x = (1 - sqrt(r1)) * p1.x + (sqrt(r1) * (1 - r2)) * p2.x + (sqrt(r1) * r2) * p3.x
	point.y = (1 - sqrt(r1)) * p1.y + (sqrt(r1) * (1 - r2)) * p2.y + (sqrt(r1) * r2) * p3.y
	point += start_position
	return point

func get_persistent_data():
	return {}

func load_persistent_data(_p):
	pass

func random_point(center, extent):
	var delta = 0
	while abs(delta) < extent*minimum_distance_percent/100:
		delta = randf() * extent*2 - extent
	return center - delta

func new_destination():
	if circle:
		var angle = randi()%360
		var vector = Vector2(0, randf() * circle.radius).rotated(angle)
		return start_position + vector
	elif rect:
		var pos = Vector2(random_point(start_position.x, rect.extents.x), random_point(start_position.y, rect.extents.y))
		return pos
	elif polygon:
		var t = pick_random_triangle()
		return pick_random_point_in_triangle(t)
	return actor.global_position

func body_entered(body):
	if body == GameEngine.player: player_is_in_area += 1

func body_exited(body):
	if body == GameEngine.player: player_is_in_area -= 1
