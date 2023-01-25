extends RichTextLabel
class_name Messages

export var max_messages = 30
export var stale_time = 3
export var new_message_color = Color(255, 255, 255)
export var stale_message_color = Color(255, 255, 255)
var messages = []

class Message:
	var posted_at
	var text

func CreateMessage(t):
	var m = Message.new()
	m.text = t
	m.posted_at = GameEngine.time
	return m

func _ready():
	var _err = GameEngine.connect("message", self, "message")
	update_messages()

func message(msg):
	messages.push_back(CreateMessage(msg))
	while messages.size() > max_messages: messages.pop_front()
	update_messages()

func update_messages():
	clear()
	var is_first = true
	for m in messages:
		if is_first: is_first = false
		else:
			var is_new = GameEngine.time < m.posted_at + stale_time
			if is_new: $RedrawTimer.start(1)
			add_text("\n")
			push_color(new_message_color if is_new else stale_message_color)
			add_text(m.text)

func _on_RedrawTimer_timeout():
	update_messages()
