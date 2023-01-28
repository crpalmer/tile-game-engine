extends Thing
class_name Currency

export(String) var plural
export(float) var unit_value = 1.0
export(int) var n_units
export(int) var random_min
export(int) var random_max

func copy_sprite(name, position):
	var new_sprite = $Sprite.duplicate()
	new_sprite.name = name
	new_sprite.position = position
	add_child(new_sprite)
	return new_sprite
	
func _ready():
	add_to_group("Trackables")
	if random_max > 0:
		n_units = randi() % (random_max - random_min + 1) + random_min
		if n_units < 0: n_units = 0
	if n_units == 2:
		copy_sprite("Sprite2", Vector2(5, 5))
		$Sprite.position = Vector2(-5, -5)
	elif n_units > 2:
		copy_sprite("Sprite2", Vector2(5, 5))
		copy_sprite("Sprite3", Vector2(-5, 5))
		$Sprite.position = Vector2(0, -5)

func value():
	return n_units * unit_value

func used_by(who):
	if who.has_method("add_currency"): who.add_currency(self)

func description():
	if n_units > 1: return "%d %s" % [ n_units, plural if plural != "" else display_name ]
	elif n_units == 1: return "a " + display_name
