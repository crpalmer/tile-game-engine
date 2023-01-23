extends Node

var scenes:Dictionary
var player
var paused:int = 0
var current_scene
var time = 0.0
var pixels_per_foot = 4.0

func pause():
	paused += 1

func resume():
	if paused > 0: paused -= 1

func is_paused(): return paused > 0

func get_fade_anim():
	return player.get_node("Camera2D/HUD/Fade/AnimationPlayer")

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
	var anim
	
	if not player: player = load("res://Player.tscn").instance()
	else:
		anim = get_fade_anim()
		anim.play("Fade")
		yield(anim, "animation_finished")
	
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
		
	anim = get_fade_anim()
	anim.play_backwards("Fade")

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

func Dice(n, d, plus): return { "n": n, "d" : d, "plus": plus }
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
