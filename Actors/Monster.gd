extends Actor
class_name Monster

export var hp_dice = { "n": 1, "d": 8, "plus":1 }
export var gp_dice = { "n": 0, "d":0, "plus": 0}

func _ready():
	hp = GameEngine.roll(hp_dice)
	max_hp = hp

func died():
	var gp = GameEngine.roll(gp_dice)
	if gp > 0:
		var gp_thing:InventoryThing = GameEngine.add_scene_at("res://Inventory/GP.tscn", position)
		gp_thing.n = gp
	.died()
