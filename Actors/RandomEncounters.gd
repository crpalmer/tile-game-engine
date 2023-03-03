extends Area2D

@export var monsters = []
@export var check_every_hours = 24.0
@export var test_roll = 20
@export var area_priority = 0
@export var min_distance = 2
@export var max_distance = 10

var next_check_at = 0
var player_in_area = 0

func get_persistent_data():
	return {
		"next_check_at": next_check_at
	}

func load_persistent_data(p):
	next_check_at = p.next_check_at

func _ready():
	add_to_group("PersistentNodes")
	add_to_group("RandomEncounters")
	var _err = connect("body_entered",Callable(self,"_on_body_entered"))
	_err = connect("body_exited",Callable(self,"_on_body_exited"))

func set_next_check():
	if monsters.size() > 0:
		next_check_at = GameEngine.time_in_minutes + check_every_hours*60
	else:
		next_check_at = INF

func allowed_to_generate():
	if player_in_area <= 0: return false
	for r in get_tree().get_nodes_in_group("RandomEncounters"):
		if r.area_priority > area_priority and r.player_in_area > 0:
			return false
	return true

func _physics_process(_delta):
	if next_check_at == 0: set_next_check()
	if GameEngine.time_in_minutes >= next_check_at:
		set_next_check()
		if allowed_to_generate() and GameEngine.roll_d20() >= test_roll:
			call_deferred("generate_a_monster")

func generate_a_monster():
	var step_size = (max_distance - min_distance) / 10
	var distances = range(min_distance, max_distance, step_size if step_size > 1 else 1)
	await GameEngine.spawn_near_player(monsters[randi() % monsters.size()], distances)

func _on_body_entered(body):
	if body == GameEngine.player: player_in_area += 1

func _on_body_exited(body):
	if body == GameEngine.player: player_in_area -= 1
