extends Node2D
class_name DamagePopup

var vector = Vector2.ZERO

func _ready():
	var _err = $Timer.connect("timeout",Callable(self,"_on_timeout"))
	visible = false

func setup(hit:bool, damage:int, delta:Vector2) -> void:
	$Damage.text = str(damage)
	$Damage.visible = hit
	$Hit.visible = hit
	$Miss.visible = not hit
	vector = delta

func run():
	visible = true
	$Timer.start(1)

func _physics_process(delta):
	position += vector*delta

func _on_timeout():
	queue_free()
