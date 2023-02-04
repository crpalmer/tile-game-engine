extends Node2D

export(Array, String, FILE) var monsters
export var check_every_hours = 24.0
export var test_roll = 20

var next_check_at = 0

func get_persistent_data():
	var active = []
	for c in get_children():
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
	next_check_at = p.next_check_at
	for c in p.active:
		add_child(GameEngine.instantiate(c.filename, c.data, c.global_position))

func _ready():
	add_to_group("PersistentOthers")

func set_next_check():
	if monsters.size() > 0:
		next_check_at = GameEngine.time_in_minutes + check_every_hours*60
	else:
		next_check_at = INF
	print("Next random number check at %f in %f with %f + %f" % [next_check_at, next_check_at - GameEngine.time_in_minutes, GameEngine.time_in_minutes, check_every_hours*60])

func place(m):
	for x in [ 0, 1, -1]:
		for y in [ -1, 1, 0]:
			m.global_position = GameEngine.player.global_position + Vector2(x, y)*GameEngine.feet_to_pixels(5)
			if m.player_is_in_sight():
				return

func _physics_process(_delta):
	if next_check_at == 0: set_next_check()
	if GameEngine.time_in_minutes >= next_check_at:
		set_next_check()
		if GameEngine.roll_d20() >= test_roll:
			var m = load(monsters[randi() % monsters.size()]).instance()
			add_child(m)
			place(m)
