extends Node2D

export(Array, String, FILE) var monsters
export var check_every_hours = 24.0
export var test_roll = 20

var next_check_at

func get_persistent_data():
	var active = []
	for c in get_children():
		active.append({
			"filename": c.filename,
			"data": c.get_persistent_data(),
			"position": c.position
		})
	return active

func load_persistent_data(p):
	for c in p:
		add_child(GameEngine.instantiate(c.filename, c.data, c.position))

func _ready():
	add_to_group("PersistentOthers")
	set_next_check()

func set_next_check():
	next_check_at = GameEngine.time_in_minutes + check_every_hours*60

func place(m):
	for x in [ 0, 1, -1]:
		for y in [ -1, 1, 0]:
			m.position = GameEngine.player.position + Vector2(x, y)*GameEngine.feet_to_pixels(10)
			if m.player_is_in_sight():
				var _collide = m.move_and_collide(Vector2(x, y) * GameEngine.feet_to_pixels(30))
				return

func _physics_process(_delta):
	if GameEngine.time_in_minutes >= next_check_at:
		set_next_check()
		if GameEngine.roll_d20() >= test_roll:
			var m = load(monsters[randi() % monsters.size()]).instance()
			add_child(m)
			place(m)
