extends Node2D
class_name SubScene

@export var entry_message: String
@export var exit_message: String
@export var keep_items_on_exit: bool = false

var has_returned_from_scene = false

func get_persistent_data():
	return {}

func load_persistent_data(p):
	pass
	
func should_return_from_scene():
	return true

func _ready():
	add_to_group("PersistentNodes")
	GameEngine.pause()
	var _ignore = $StartSceneTimer.connect("timeout",Callable(self,"unpause"))
	_ignore = $EndSceneTimer.connect("timeout",Callable(self,"call_return_to_scene"))
	if entry_message != "": GameEngine.message(entry_message)

func _process(_delta):
	if GameEngine.is_paused(): return
	if should_return_from_scene() and not has_returned_from_scene:
		has_returned_from_scene = true
		$EndSceneTimer.start()

func unpause():
	GameEngine.resume()

func call_return_to_scene():
	call_deferred("scene_completed")

func scene_completed():
	if exit_message != "": GameEngine.message(exit_message)
	GameEngine.return_to_scene(keep_items_on_exit)
