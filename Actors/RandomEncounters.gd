extends Node2D

export(Array, String, FILE) var monsters
export var check_every_hours = 24.0
export var test_roll = 20

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
	var _err = connect("body_entered", self, "_on_body_entered")
	_err = connect("body_exited", self, "_on_body_exited")

func set_next_check():
	if monsters.size() > 0:
		next_check_at = GameEngine.time_in_minutes + check_every_hours*60
	else:
		next_check_at = INF

func allowed_to_generate():
	return player_in_area > 0

func _physics_process(_delta):
	if next_check_at == 0: set_next_check()
	if GameEngine.time_in_minutes >= next_check_at:
		set_next_check()
		if allowed_to_generate() and GameEngine.roll_d20() >= test_roll:
			var m = GameEngine.instantiate(GameEngine.current_scene, monsters[randi() % monsters.size()])
			m.place_near_player()

func _on_body_entered(body):
	if body == GameEngine.player: player_in_area += 1

func _on_body_exited(body):
	if body == GameEngine.player: player_in_area -= 1
