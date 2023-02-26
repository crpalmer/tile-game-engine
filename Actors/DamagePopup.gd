extends Node2D

var vector = Vector2.ZERO

func start(hit, damage, delta):
	vector = delta
	$Damage.text = str(damage)
	$Damage.visible = hit
	$Hit.visible = hit
	$Miss.visible = not hit
	$Timer.start(1)

func _ready():
	var _err = $Timer.connect("timeout",Callable(self,"_on_timeout"))

func _physics_process(delta):
	position += vector*delta

func _on_timeout():
	queue_free()
