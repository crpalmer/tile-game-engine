extends Actor
class_name Monster

@export var hp_dice = { "n": 1, "d": 8, "plus":1 }

func _ready():
	super()
	hp = GameEngine.roll(hp_dice)
	max_hp = hp
