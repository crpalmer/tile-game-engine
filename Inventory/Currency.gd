extends Thing
class_name Currency

@export var plural: String
@export var unit_value: float = 1.0
@export var n_units: int
@export var random_min: int
@export var random_max: int
@export var abbreviation: String

func get_persistent_data():
	var p = super.get_persistent_data()
	p.merge({
		"n_units": n_units
	})
	return p

func load_persistent_data(p):
	super.load_persistent_data(p)
	n_units = p.n_units

func copy_sprite(sprite_name, sprite_position):
	var new_sprite = $Sprite2D.duplicate()
	new_sprite.name = sprite_name
	new_sprite.position = sprite_position
	add_child(new_sprite)
	return new_sprite
	
func _ready():
	super()
	add_to_group("Trackables")
	add_to_group("Ephemeral")
	if random_max > 0:
		n_units = randi() % (random_max - random_min + 1) + random_min
		if n_units < 0: n_units = 0
	if n_units == 2:
		copy_sprite("Sprite2", Vector2(5, 5))
		$Sprite2D.position = Vector2(-5, -5)
	elif n_units > 2:
		copy_sprite("Sprite2", Vector2(5, 5))
		copy_sprite("Sprite3", Vector2(-5, 5))
		$Sprite2D.position = Vector2(0, -5)

func value():
	return n_units * unit_value

func get_display_name():
	if n_units > 1: return "%d %s" % [ n_units, plural if plural != "" else display_name ]
	elif n_units == 1: return "a " + display_name
