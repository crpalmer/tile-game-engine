extends CanvasLayer
class_name Messages

const MAX_MESSAGES = 3.0
var messages = []

func _ready():
	$Text.text = ""
	visible = true
	pass

func message(msg):
	messages.push_back(msg)
	while messages.size() > MAX_MESSAGES: messages.pop_front()
	update_messages()

func update_messages():
	$Text.text = PoolStringArray(messages).join("\n")
	#visible = messages.size() > 0
	#$Timer.start(3)

func _on_Timer_timeout():
	messages.pop_front()
	update_messages()
	
