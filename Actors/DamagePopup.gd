extends Node2D

var vector

func start(hit, damage = 0):
	$Damage.text = String(damage)
	$Damage.visible = hit
	$Hit.visible = hit
	$Miss.visible = not hit
	$Timer.start(1)

func _ready():
	vector = Vector2(0, -16)
	var _err = $Timer.connect("timeout", self, "_on_timeout")

func _physics_process(delta):
	position += vector*delta

func _on_timeout():
	queue_free()
