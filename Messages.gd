extends RichTextLabel
class_name Messages

@export var max_messages = 30
@export var stale_time = 3
@export var new_message_color = Color(255, 255, 255)
@export var stale_message_color = Color(255, 255, 255)
@export var important_message_color = Color(255, 255, 255)
var messages = []

@onready var audio = $AudioStreamPlayer2D

class Message:
	var posted_at
	var text
	var beep

func CreateMessage(t, beep):
	var m = Message.new()
	m.text = t
	m.posted_at = GameEngine.time_in_minutes
	m.beep = beep
	return m

func _ready():
	var _err = GameEngine.connect("show_message",Callable(self,"message"))
	_err = GameEngine.connect("new_game",Callable(self,"new_game"))
	update_messages()

func message(msg, beep = false):
	if beep: audio.play()
	messages.push_back(CreateMessage(msg, beep))
	while messages.size() > max_messages: messages.pop_front()
	update_messages()

func update_messages():
	clear()
	for m in messages:
		add_text("\n")
		var is_new = GameEngine.time_in_minutes < m.posted_at + GameEngine.real_time_to_game_time(stale_time)
		if is_new:
			$RedrawTimer.start(1)
			push_color(new_message_color)
		elif m.beep:
			push_color(important_message_color)
		else:
			push_color(stale_message_color)
		add_text(m.text)

func _on_RedrawTimer_timeout():
	update_messages()

func new_game():
	messages = []
