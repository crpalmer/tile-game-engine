extends CharacterBody2D
class_name Missile

@export var speed_in_feet:float = 60
@export var max_distance_in_feet:float = 60
@export var display_name:String

@onready var sprite : Sprite2D = $Sprite2D
var speed:float
var max_distance:float

var shooter:Actor
var starting_position:Vector2
var attack:Attack

func _ready():
	speed = GameEngine.feet_to_pixels(speed_in_feet)
	max_distance = GameEngine.feet_to_pixels(max_distance_in_feet)
	set_physics_process(false)
	if display_name == "": display_name = name
	
func shoot(from:Actor, to:Actor, with_attack:Attack) -> void:
	global_position = from.global_position
	starting_position = from.global_position
	shooter = from
	attack = with_attack
	speed = GameEngine.feet_to_pixels(speed_in_feet)
	velocity = speed * global_position.direction_to(to.global_position)
	rotate(global_position.angle_to_point(to.global_position))
	add_collision_exception_with(shooter)
	GameEngine.current_scene.add_child(self)
	set_deferred("visible", true)
	call_deferred("set_physics_process", true)

func _physics_process(delta : float) -> void:
	var collision:KinematicCollision2D = move_and_collide(GameEngine.pixels_travelled(velocity, delta))
	var collider = collision.get_collider() if collision else null
	if not collider:
		if (global_position - starting_position).length() > max_distance:
			queue_free()
	elif collider is Actor:
		shooter.roll_attack(collider, attack)
		queue_free()
	elif GameEngine.is_self_or_child_of(collider, shooter):
		add_collision_exception_with(collider)
	else:
		queue_free()
