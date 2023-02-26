extends PointLight2D

@export var radius = 30
@export var brightness_percent = 100

func _ready():
	set_radius(radius)
	set_brightness(brightness_percent)
	
func set_radius(r):
	radius = r
	texture_scale = GameEngine.feet_to_pixels(radius) / 50

func set_brightness(percent):
	brightness_percent = percent
	var c = brightness_percent/100.0
	set_color(Color(c, c, c))	
