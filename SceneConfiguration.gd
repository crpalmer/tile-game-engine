extends Node2D
class_name SceneConfiguration

export(float, 12) var dawn = 5.0
export(float, 12) var day = 6.0
export(float, 12) var dusk = 8.0
export(float, 12) var night = 9.0
export(float, 100) var day_light = 10.0
export(float, 100) var night_light = 10.0

var ambient_light = 0
var last_ambient_light = 0

func _ready():
	dusk += 12
	night += 12

func _process(_delta):
	var now = GameEngine.current_time()
	var hours = now.hours + now.minutes / 60.0 + now.seconds / 60.0 / 60.0
	if hours < dawn: ambient_light = night_light
	elif hours < day: ambient_light = (day_light - night_light)/(day - dawn)*(hours - dawn) + night_light
	elif hours < dusk: ambient_light = day_light
	elif hours < night: ambient_light = day_light - (day_light - night_light) / (night - dusk)*(hours - dusk)
	else: ambient_light = night_light
	ambient_light = round(ambient_light)
	ambient_light = clamp(ambient_light, 0, 100)
	if last_ambient_light != ambient_light:
		last_ambient_light = ambient_light
		GameEngine.player.set_ambient_light(ambient_light)
