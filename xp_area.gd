extends Area2D

@export var message:String
@export var xp:int

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", Callable(self, "on_body_entered"))

func on_body_entered(body):
	if body == GameEngine.player and xp:
		if message: GameEngine.message(message)
		if xp > 0: GameEngine.player.add_xp(xp)
		if xp < 0: GameEngine.player.lose_xp(-xp)
		#xp = 0
