extends InventoryThing
class_name Missile

@export var damage_dice = { "n": 1, "d": 1, "plus": 0}
@export var damage_modifier = 0

var shot:MissileShot

func _ready():
	super()
	for c in get_children():
		if c is MissileShot: shot = c

func roll_damage() -> int:
	var dice = damage_dice.duplicate()
	dice.plus += damage_modifier
	return GameEngine.roll(dice)

func shoot(from:Actor, to:Actor, damage_popup:DamagePopup) -> void:
	var new_shot = shot.duplicate()
	new_shot.add_child($CollisionShape2D.duplicate())
	new_shot.add_child($Sprite2D.duplicate())
	GameEngine.current_scene.add_child(new_shot)
	new_shot.shoot(from, to, damage_popup)
