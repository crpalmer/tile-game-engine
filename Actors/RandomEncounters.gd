extends Node2D

export(Array, String, FILE) var monsters
export var check_every_hours = 24.0
export var test_roll = 20
export var area_extents = Vector2.ZERO
onready var area = $Area2D
onready var shape = $Area2D/CollisionShape2D

var next_check_at = 0
var player_in_area = 0

func get_persistent_data():
	var active = []
	for c in get_children():
		if c is Actor:
			active.append({
				"filename": c.filename,
				"data": c.get_persistent_data(),
				"global_position": c.global_position
			})
	return {
		"next_check_at": next_check_at,
		"active": active
	}

func load_persistent_data(p):
	yield(self, "ready")
	next_check_at = p.next_check_at
	for c in p.active:
		add_child(GameEngine.instantiate(c.filename, c.data, c.global_position))

func _ready():
	add_to_group("PersistentOthers")
	if area_extents != Vector2.ZERO:
		shape.shape.extents = area_extents
		area.connect("body_entered", self, "_on_body_entered")
		area.connect("body_exited", self, "_on_body_exited")

func set_next_check():
	if monsters.size() > 0:
		next_check_at = GameEngine.time_in_minutes + check_every_hours*60
	else:
		next_check_at = INF

func place(m):
	var x_dir = [0, 1, -1]
	var y_dir = [0, 1, -1]
	x_dir.shuffle()
	y_dir.shuffle()
	for distance in [ 5, 3, 1]:
		for x in x_dir:
			for y in y_dir:
				if x != 0 or y != 0:
					var place = Vector2(x, y)*GameEngine.feet_to_pixels(distance)
					m.global_position = GameEngine.player.global_position + place
					var collide = m.move_and_collide(-2*place, true, true, true)
					if collide and collide.collider == GameEngine.player:
						return true

func allowed_to_generate():
	if area_extents == Vector2.ZERO: return true
	return player_in_area > 0

func _physics_process(_delta):
	if next_check_at == 0: set_next_check()
	if GameEngine.time_in_minutes >= next_check_at:
		set_next_check()
		if allowed_to_generate() and GameEngine.roll_d20() >= test_roll:
			var m = load(monsters[randi() % monsters.size()]).instance()
			add_child(m)
			place(m)

func _on_body_entered(body):
	if body == GameEngine.player: player_in_area += 1

func _on_body_exited(body):
	if body == GameEngine.player: player_in_area -= 1
