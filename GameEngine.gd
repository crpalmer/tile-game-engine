extends Node

signal player_created # A new player scene was instanced
signal message
signal new_game      # A new game is being created

enum BodyParts { HANDS = 1, HEAD = 2, BODY = 4, FEET = 8, NECK = 16 }

var scene_state:Dictionary
var player
var paused:int = 0
var current_scene
var game_seconds_per_elapsed_second = 6
var time_in_minutes = 0.0
var fade_canvas
var fade_animation_player

var config:GameConfiguration
var scene_config:SceneConfiguration
var currency_ascending = []
var currency_descending = []
var conversation
var current_scene_root

var completed_milestones = {}

class CurrencySorter:
	static func currency_sort_asc(a, b):
		return a.unit_value < b.unit_value
	static func currency_sort_des(a, b):
		return not currency_sort_asc(a, b)

func _ready():
	config = ResourceLoader.load("res://GameConfiguration.tres") #  "GameConfiguration")
	fade_canvas = load("%s/Fade.tscn" % config.root).instance()
	for c in config.currency:
		var currency = load(c).instance()
		currency_ascending.push_back(currency)
		currency_descending.push_back(currency)
	currency_ascending.sort_custom(CurrencySorter, "currency_sort_asc")
	currency_descending.sort_custom(CurrencySorter, "currency_sort_des")
	current_scene_root = get_tree().current_scene

func modulate(on):
	get_tree().current_scene.get_node("CanvasModulate").visible = on

func pause():
	paused += 1

func resume():
	if paused > 0: paused -= 1

func is_paused(): return paused > 0

func complete_milestone(name, data = {}):
	completed_milestones[name] = data

func has_completed_milestone(name):
	return completed_milestones.has(name)

func get_completed_milestone(name):
	if has_completed_milestone(name):
		return completed_milestones[name]
	else:
		return null

func currency_value_to_string(value:float):
	var text = ""
	for c in currency_descending:
		var amount = floor(value/c.unit_value + .0001)
		if amount > 0:
			value -= amount * c.unit_value
			if text.length() > 0: text += " "
			text += "%d%s" % [amount, c.abbreviation]
	return text

func get_scene_node(path):
	return current_scene.get_node(path)

func get_scene_node_or_null(path):
	return current_scene.get_node_or_null(path)

func remove_player_from_scene():
	if player and player.get_parent(): player.get_parent().remove_child(player)

func new_game():
	clear_game()
	time_in_minutes = config.game_start_time_in_hours * 60
	
func clear_game():
	emit_signal("new_game")
	create_player()
	Engine.time_scale = 1
	paused = 0
	scene_state = {}
	completed_milestones = {}
	if current_scene:
		current_scene.queue_free()
		current_scene = null

func create_player():
	remove_player_from_scene()
	if player: player.call_deferred("free")
	player = load(config.player).instance()
	get_tree().current_scene.add_child(player)
	emit_signal("player_created")

func is_child_of_persistent_node(node):
	var parent = node.get_parent()
	if parent:
		if parent.is_in_group("PersistentNodes"): return true
		return is_child_of_persistent_node(parent)
	return false

func get_persistent_nodes():
	var persistent_nodes = []
	for node in get_tree().get_nodes_in_group("PersistentNodes"):
		if not is_child_of_persistent_node(node):
			persistent_nodes.append(node)
	return persistent_nodes

func get_current_scene_state():
	var nodes_data = {}
	for node in get_persistent_nodes():
		if node != player:
			nodes_data.merge({
				current_scene.get_path_to(node): {
				"filename": node.filename,
				"data": node.get_persistent_data(),
				"global_position": node.global_position
			}})
	return {
		"nodes": nodes_data
	}

func get_save_data():
	scene_state[current_scene.filename] = get_current_scene_state()
	return {
		"current_scene": current_scene.filename,
		"player": player.get_persistent_data(),
		"player_global_position": player.global_position,
		"time_in_minutes": time_in_minutes,
		"completed_milestones": completed_milestones,
		"scene_state": scene_state
	}

func save_game(filename):
	var res = load("%s/SaveGameTemplate.tres" % config.root)
	res.version = 1
	res.data = get_save_data()
	var _err = Directory.new().remove(filename)
	return ResourceSaver.save(filename, res) == 0

func load_scene_state(p):
	for node in get_persistent_nodes():
		var path = current_scene.get_path_to(node)
		if node == player:
			pass
		elif not p.nodes.has(path):
			node.queue_free()
		else:
			var data = p.nodes[path]
			node.load_persistent_data(data.data)
			node.global_position = data.global_position
			if node.has_method("stop_navigating"): node.stop_navigating()
			p.nodes.erase(path)
	for path in p.nodes.keys():
		var data = p.nodes[path]
		instantiate(current_scene, data.filename, data.data, data.global_position)

func load_save_data(p):
	clear_game()
	scene_state = p.scene_state
	if current_scene: current_scene.queue_free()
	yield(get_tree(), "idle_frame")
	current_scene = null
	time_in_minutes = p.time_in_minutes
	completed_milestones = p.completed_milestones
	create_player()
	enter_scene(p.current_scene)
	current_scene.add_child(player)
	player.load_persistent_data(p.player)
	player.global_position = p.player_global_position

func load_saved_game(filename):
	var file = File.new()
	if not file.file_exists(filename): return false
	var save_data = load(filename)
	assert(save_data.version == 1)
	load_save_data(save_data.data)
	paused = 0
	return true

func instantiate(parent, filename, data = null, global_position = null):
	var thing = load(filename).instance()
	if data: thing.load_persistent_data(data)
	parent.add_child(thing)
	if global_position: thing.global_position = global_position
	if thing.has_method("stop_navigating"): thing.stop_navigating()
	return thing

func fade(leave_faded, from, to, duration = 0.5):
	pause()
	var animation_player = fade_canvas.get_node("Fade/AnimationPlayer")
	var animation = animation_player.get_animation("Fade")
	animation.track_set_key_value(0, 0, from)
	animation.track_set_key_value(0, 1, to)
	animation.track_set_key_time(0, 1, duration)
	animation.length = duration
	if fade_canvas.get_parent() == null:
		get_tree().current_scene.add_child(fade_canvas)
		yield(get_tree(), "idle_frame")
	animation_player.play("Fade")
	yield(animation_player, "animation_finished")
	if not leave_faded: get_tree().current_scene.remove_child(fade_canvas)
	resume()

func fade_color(leave_faded, color, from, to, duration = 0.5):
	var from_color = color
	var to_color = color
	from_color.a = from
	to_color.a = to
	fade(leave_faded, from_color, to_color, duration)

func fade_in(alpha = 255):
	fade_color(false, config.fade_color, alpha, 0)

func fade_out(alpha = 255):
	fade_color(true, config.fade_color, 0, alpha)

func fade_from_resting():
	fade_in(config.resting_alpha)

func fade_to_resting():
	fade_out(config.resting_alpha)

func enter_sub_scene(sub_scene, entry_point = null):
	var return_scene = current_scene.filename
	var position = GameEngine.player.global_position

	enter_scene(sub_scene, entry_point)

	current_scene.return_to_scene = return_scene
	current_scene.return_to_position = position

func return_to_scene(scene, entry_position, keep_items_on_return):
	var items = []
	if keep_items_on_return:
		for c in current_scene.get_children():
			if c.is_in_group("Things"):
				items.append(c)
				c.get_parent().remove_child(c)
	enter_scene(scene, null, entry_position)
	yield(get_tree(), "idle_frame")
	for item in items:
		current_scene.add_child(item)
		item.global_position = entry_position

func enter_scene(scene, entry_point = null, entry_position = null):
	pause()
	if current_scene: fade_out()

	get_tree().paused = true

	remove_player_from_scene()
	if current_scene:
		scene_state[current_scene.filename] = get_current_scene_state()
		current_scene.get_parent().remove_child(current_scene)
		current_scene.queue_free()

	current_scene = load(scene).instance()
	current_scene_root.add_child(current_scene)
	yield(get_tree(), "idle_frame")
	if scene_state.has(scene): load_scene_state(scene_state[scene])

	if entry_point or entry_position:
		current_scene.add_child(player)
		if entry_point:
			var entry_node = current_scene.get_node(entry_point)
			entry_position = entry_node.global_position
		player.global_position = entry_position
		player.enter_current_scene()

	scene_config = SceneConfiguration.new()
	for c in current_scene.get_children():
		if c is SceneConfiguration: scene_config = c

	get_tree().paused = false

	fade_in()
	resume()

func add_scene_at(path:String, global_position:Vector2):
	var to_add = load(path).instance()
	add_node_at(to_add, global_position)
	return to_add

func add_node_at(to_add:Node, global_position:Vector2):
	to_add.visible = true
	if to_add.get_parent(): to_add.get_parent().remove_child(to_add)
	current_scene.add_child(to_add)
	to_add.global_position = global_position

func real_time_to_game_time(t):
	return t * game_seconds_per_elapsed_second / 60.0

func add_to_game_time(minutes):
	time_in_minutes += minutes

func _process(delta): time_in_minutes += real_time_to_game_time(delta)

func player_traveled_for(delta):
	time_in_minutes += real_time_to_game_time(delta) * scene_config.travel_time_accelerator

func player_rested_for(delta):
	time_in_minutes += real_time_to_game_time(delta) * config.rest_time_accelerator

func feet_to_pixels(feet): return feet * config.pixels_per_foot
func pixels_to_feet(pixels): return pixels / config.pixels_per_foot

func Dice(n, d, plus = 0): return { "n": n, "d" : d, "plus": plus }
func D(d): return Dice(1, d, 0)

func roll_d20():
	return roll(D(20))

func roll(dice, extra_modifier = 0):
	var total = dice.plus + extra_modifier
	for i in dice.n:
		var roll = randi()%dice.d + 1
		total += roll
	if total < 1: return 1
	return total

func roll_test(success, modifier = 0, always = false):
	var got = roll(D(20), modifier)
	return got >= success or (always and got == 20)

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

func message(msg, beep = false):
	emit_signal("message", msg, beep)

func current_time_of(m):
	return {
		"seconds": (m - int(m))*60,
		"minutes": int(m) % 60,
		"hours": int(m/60) % 24,
		"days": int(m/(24*60))%365,
		"years": int(m/(365*24*60))
	}

func current_time(): return current_time_of(time_in_minutes)

func minutes_to_string(m):
	var t = current_time_of(m)
	return "%d year%s, %d day%s @ %s" % [
		t.years,
		"" if t.years == 1 else "s",
		t.days,
		"" if t.days == 1 else "s",
		time_of_day(m)
	]

func time_of_day(m):
	var t = current_time_of(m)
	return "%2d:%02d %s" % [
		12 if t.hours == 0 or t.hours == 12 else t.hours % 12,
		t.minutes,
		"am" if t.hours < 12 else "pm"
	]

func current_time_string():
	return minutes_to_string(time_in_minutes)
