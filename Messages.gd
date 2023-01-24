extends Label
class_name Messages

export var max_messages = 3
var messages = []

func _ready():
	var _err = GameEngine.connect("message", self, "message")
	update_messages()

func message(msg):
	messages.push_back(msg)
	while messages.size() > max_messages: messages.pop_front()
	update_messages()

func update_messages():
	text = PoolStringArray(messages).join("\n")
