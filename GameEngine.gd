extends Node

var scenes:Dictionary
var player
var paused = false
var current_scene
var time = 0.0

func pause():
	paused = true

func resume():
	paused = false

func get_fade_anim():
	return player.get_node("Camera2D/HUD/Fade/AnimationPlayer")
	
func enter_scene(scene:String, entry_point:String):
	var anim
	
	if not player: player = load("res://GameEngine/Actors/Player.tscn").instance()
	else:
		anim = get_fade_anim()
		anim.play("Fade")
		yield(anim, "animation_finished")
	
	if not scenes.has(scene): scenes[scene] = load(scene).instance()
	
	if current_scene:
		current_scene.remove_child(player)
		current_scene.get_parent().remove_child(current_scene)
	
	get_tree().paused = true

	current_scene = scenes[scene]
	get_tree().current_scene.add_child(current_scene)
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
