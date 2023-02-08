extends Node2D
class_name SubScene

export(bool) var keep_items_on_exit = false

var return_to_scene
var return_to_position
var has_returned_from_scene = false

func get_persistent_data():
	return {
		"return_to_scene": return_to_scene,
		"return_to_position": return_to_position
	}

func load_persistent_data(p):
	return_to_scene = p.return_to_scene
	return_to_position = p.return_to_position

func should_return_from_scene():
	return true

func _ready():
	add_to_group("PersistentOthers")
	GameEngine.pause()
	var _ignore = $StartSceneTimer.connect("timeout", self, "unpause")
	_ignore = $EndSceneTimer.connect("timeout", self, "call_return_to_scene")

func _process(_delta):
	if GameEngine.is_paused(): return
	if should_return_from_scene() and not has_returned_from_scene:
		has_returned_from_scene = true
		$EndSceneTimer.start()

func unpause():
	GameEngine.resume()

func call_return_to_scene():
	GameEngine.call_deferred("return_to_scene", return_to_scene, return_to_position, keep_items_on_exit)
