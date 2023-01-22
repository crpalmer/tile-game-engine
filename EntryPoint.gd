extends Node2D
class_name EntryPoint

export var ambient_light_percent = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	GameEngine.player.set_ambient_light(ambient_light_percent)
