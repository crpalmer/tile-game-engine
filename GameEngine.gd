extends Node

signal player_created
signal message
signal conversation_started
signal conversation_ended

var scenes:Dictionary
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
	if player and player.get_parent(): current_scene.remove_child(player)

func new_game(scene:String, entry_point:String):
	clear_game()
	paused = 0
	enter_scene(scene, entry_point)
	
func clear_game():
	remove_player_from_scene()
	if player: player.call_deferred("free")
	player = null
	for scene_key in scenes.keys():
		scenes[scene_key].call_deferred("free")
	scenes = {}

func enter_scene(scene:String, entry_point = null):
	if not player:
		player = load("res://Player.tscn").instance()
		emit_signal("player_created")
	else:
		if fade_anim:
			fade_anim.play("Fade")
			yield(fade_anim, "animation_finished")
	
	if not scenes.has(scene): scenes[scene] = load(scene).instance()
	
	if current_scene:
		remove_player_from_scene()
		current_scene.get_parent().remove_child(current_scene)
	
	get_tree().paused = true

	current_scene = scenes[scene]
	get_tree().current_scene.add_child(current_scene)
	if entry_point:
		var entry_node = current_scene.get_node(entry_point)
		current_scene.add_child(player)
		player.position = entry_node.position
		player.enter_current_scene()

	get_tree().paused = false
		
	if fade_anim: fade_anim.play_backwards("Fade")

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
