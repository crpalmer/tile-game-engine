extends Node2D
class_name MissileShot

@export var speed_in_feet:float = 120
@export var final_delta:float = 5

var starting_position:Vector2
var final_position:Vector2
var shooter:Actor
var popup:DamagePopup
var velocity:Vector2

func _ready():
	set_process(false)
	set_physics_process(false)

func shoot(from:Actor, to:Actor, damage_popup:DamagePopup) -> void:
	global_position = from.global_position
	starting_position = from.global_position
	final_position = to.global_position
	popup = damage_popup
	velocity = GameEngine.feet_to_pixels(speed_in_feet) * global_position.direction_to(to.global_position)
	rotate(global_position.angle_to_point(to.global_position))
	set_deferred("visible", true)
	call_deferred("set_physics_process", true)

func _physics_process(delta : float) -> void:
	var old_d = global_position.distance_squared_to(final_position)
	global_position += velocity*delta
	var new_d = global_position.distance_squared_to(final_position)
	if global_position.distance_to(final_position) < final_delta or new_d > old_d:
		popup.run()
		queue_free()
