extends Area2D

@export_multiline var message = ""
@export var is_important = false
@export var one_shot = true
@export var milestone_granted: String
@export var xp:int = 0

var available = true

func get_persistent_data():
	return { "available": available }

func load_persistent_data(p):
	available = p.available

func _ready():
	var _err = connect("body_entered",Callable(self,"on_body_entered"))
	add_to_group("PersistentNodes")

func on_body_entered(body):
	if available and body == GameEngine.player:
		if message != "": GameEngine.message(message, is_important)
		if milestone_granted != "": GameEngine.complete_milestone(milestone_granted)
		if one_shot: available = false
		if xp != 0:
			if xp > 0: GameEngine.player.add_xp(xp)
			if xp < 0: GameEngine.player.lose_xp(-xp)
			xp = 0      # Only grant the XP once!
