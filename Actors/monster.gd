extends Actor
class_name Monster

@export var hp_dice = { "n": 1, "d": 8, "plus":1 }
@export var n_missile_items = -1

func _ready():
	super()
	hp = GameEngine.roll(hp_dice)
	max_hp = hp
	if n_missile_items >= 0:
		for i in $Equipment.get_children():
			if i is Missile:
				if n_missile_items > 0: i.n = n_missile_items
				else: i.queue_free()
