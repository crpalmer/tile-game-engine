extends Area2D
class_name TrackingArea

export var tracking_radius = 30

var in_area:Dictionary
var player_is_in_area = false

func _ready():
	var _err
	_err = connect("area_entered", self, "area_entered")
	_err = connect("body_entered", self, "area_entered")

	_err = connect("area_exited", self, "area_exited")
	_err = connect("body_exited", self, "area_exited")

	update_tracking_radius()

func set_tracking_radius(radius:int):
	tracking_radius = radius
	update_tracking_radius()

func update_tracking_radius():
	$Circle.shape.set_radius(GameEngine.feet_to_pixels(tracking_radius))
	
func who_is_in_area():
	var res = []
	for who in in_area.keys():
		if in_area[who] > 0: res.push_back(who)
	return res

func area_entered(who):
	record_area(who, +1)

func area_exited(who):
	record_area(who, -1)

func record_area(who, what):
	if who != get_parent() and (who is Actor or who is Thing):
		var count = in_area[who] if in_area.has(who) else 0
		count += what
		if count <= 0: var _ignore = in_area.erase(who)
		else: in_area[who] = count
		if who == GameEngine.player: player_is_in_area = (count > 0)
		#print(name + " " + get_parent().name + " : " + String(in_area))
