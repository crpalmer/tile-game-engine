extends Node

signal player_created
signal message
signal conversation_started
signal conversation_ended
signal new_game

var scene_state:Dictionary
var player
var paused:int = 0
var current_scene
var time = 0.0
var pixels_per_foot = 4.0

var fade_anim

func pause():
	paused += 1

func resume():
	if paused > 0: paused -= 1

func is_paused(): return paused > 0

func remove_player_from_scene():
	if player and player.get_parent() and current_scene: current_scene.remove_child(player)

func new_game(scene:String, entry_point:String):
	clear_game()
	enter_scene(scene, entry_point)
	time = 0
	
func clear_game():
	emit_signal("new_game")
	create_player()
	paused = 0
	scene_state = {}
	if current_scene:
		current_scene.queue_free()
		current_scene = null

func create_player():
	remove_player_from_scene()
	if player: player.call_deferred("free")
	player = load("res://Player.tscn").instance()
	emit_signal("player_created")

func get_current_scene_state():
	var actor_data = {}
	var thing_data = {}
	for a in get_tree().get_nodes_in_group("PersistentActors"):
		if a != player:
			actor_data.merge({
				a.name: {
				"data": a.get_persistent_data(),
				"position": a.position
			}})
	for t in current_scene.get_children():
		if t.is_in_group("PersistentThings"):
			thing_data.merge({
				t.name: {
				"filename": t.filename,
				"data": t.get_persistent_data(),
				"position": t.position
			}})
	return {
		"actors": actor_data,
		"things": thing_data
	}

func get_save_data():
	scene_state[current_scene.filename] = get_current_scene_state()
	return {
		"current_scene": current_scene.filename,
		"scene_state": scene_state,
		"player": player.get_persistent_data(),
		"player_position": player.position,
		"time": time
	}

func save_game(filename):
	var res = load("res://GameEngine/SaveGameTemplate.tres")
	res.version = 1
	res.data = get_save_data()
	Directory.new().remove(filename)
	return ResourceSaver.save(filename, res) == 0

func load_scene_state(p):
	for a in get_tree().get_nodes_in_group("PersistentActors"):
		if p.actors.has(a.name):
			var d = p.actors[a.name]
			a.load_persistent_data(d.data)
			a.position = d.position
		else: a.queue_free()
	for t in current_scene.get_children():
		if t.is_in_group("PersistentThings"): t.queue_free()
	for n in p.things.keys():
		var t = p.things[n]
		current_scene.add_child(instantiate_thing(t.filename, t.data, t.position))

func load_save_data(p):
	clear_game()
	scene_state = p.scene_state
	if current_scene: current_scene.queue_free()
	current_scene = null
	create_player()
	enter_scene(p.current_scene)
	current_scene.add_child(player)
	player.load_persistent_data(p.player)
	player.position = p.player_position
	time = p.time

func load_saved_game(filename):
	var file = File.new()
	if not file.file_exists(filename): return false
	var save_data = load(filename)
	assert(save_data.version == 1)
	load_save_data(save_data.data)
	paused = 0
	return true

func instantiate_thing(filename, data, position = null):
	var thing = load(filename).instance()
	thing.load_persistent_data(data)
	if position: thing.position = position
	return thing

func enter_scene(scene:String, entry_point = null):
	pause()
	if current_scene and fade_anim:
		fade_anim.play("Fade")
		yield(fade_anim, "animation_finished")
	
	if current_scene:
		remove_player_from_scene()
		scene_state[current_scene.filename] = get_current_scene_state()
		current_scene.get_parent().remove_child(current_scene)
		current_scene.queue_free()
	
	get_tree().paused = true

	current_scene = load(scene).instance()
	get_tree().current_scene.add_child(current_scene)
	if scene_state.has(scene): load_scene_state(scene_state[scene])
	
	if entry_point:
		var entry_node = current_scene.get_node(entry_point)
		current_scene.add_child(player)
		player.position = entry_node.position
		player.enter_current_scene()

	get_tree().paused = false
		
	if fade_anim: fade_anim.play_backwards("Fade")
	resume()

func add_scene_at(path:String, position:Vector2):
	var to_add = load(path).instance()
	add_node_at(to_add, position)
	return to_add

func add_node_at(to_add:Node, position:Vector2):
	to_add.position = position
	to_add.visible = true
	if to_add.get_parent(): to_add.get_parent().remove_child(to_add)
	current_scene.add_child(to_add)
	
func _process(delta): time += delta

func feet_to_pixels(feet): return feet * pixels_per_foot
func pixels_to_feet(pixels): return pixels / pixels_per_foot

func Dice(n, d, plus = 0): return { "n": n, "d" : d, "plus": plus }
func D(d): return Dice(1, d, 0)

func roll(dice):
	var total = dice.plus
	for i in dice.n:
		var roll = randi()%dice.d + 1
		total += roll
	return total

func roll_test(dice, success, always = null):
	var got = roll(dice)
	return got >= success or (always and got == always)

func ability_modifier(score):
	match score:
		1: return -5
		2, 3: return -4
		4, 5: return -3
		6, 7: return -2
		8, 9: return -1
		10, 11: return 0
		12, 13: return 1
		14, 15: return 2
		16, 17: return 3
		18, 19: return 4
		20, 21: return 5
		22, 23: return 6
		24, 25: return 7
		26, 27: return 8
		28, 29: return 9
		_: return 10

func message(msg):
	emit_signal("message", msg)

func start_conversation(conversation, name):
	emit_signal("conversation_started", conversation, name)
	GameEngine.pause()

func end_conversation():
	emit_signal("conversation_ended")
	GameEngine.resume()
