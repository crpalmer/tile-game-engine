extends CanvasLayer
class_name Conversation

signal more_pressed
signal player_said

var in_conversation = false

func get_persistent_data(): return {}
func load_persistent_data(_p): pass

onready var speaker_name = $SpeakerName
onready var speaker_text = $SpeakerText
onready var player_text = $PlayerText
onready var more = $More
onready var more_timer = $More/Timer

func _ready():
	GameEngine.conversation = self
	more.visible = false
	visible = false
	more.connect("pressed", self, "_on_More_pressed")
	player_text.connect("text_entered", self, "_on_PlayerText_text_entered")
	more_timer.connect("timeout", self, "_on_more_timer_timeout")

func start(name):
	speaker_name.text = name
	visible = true
	player_text.visible = false
	in_conversation = true
	GameEngine.pause()

func end(delay = 0):
	if delay > 0: yield(get_tree().create_timer(delay), "timeout")
	in_conversation = false
	visible = false
	GameEngine.resume()

func say(text):
	call_deferred("said", text)

func say_bye(text, delay = 0):
	call_deferred("actor_said", text)
	end(delay)

func said(text):
	actor_said(text)
	show_player_text()

func actor_said(text):
	speaker_text.text = text
	GameEngine.message(text)

func show_player_text():
	player_text.text = ""
	player_text.visible = true
	player_text.grab_focus()

func say_in_parts(parts:Array):
	for i in parts.size()-1:
		call_deferred("actor_said", parts[i])
		more_timer.start(0.5)
		yield(self, "more_pressed")
		call_deferred("more_visible", false)
	say(parts[parts.size()-1])

var delimiters = [' ', '	', '\n', ',', '.', '?', '!', '&']

func tokenize(text:String):
	var words = []
	var start = 0
	var i = 0
	text = text.to_lower()
	while i <= text.length():
		if i == text.length() or text[i] in delimiters:
			if i > start:
				words.push_back(text.substr(start, i-start))
			start = i+1
		i += 1
	return words

func _on_PlayerText_text_entered(text):
	call_deferred("player_entered", text)

func player_entered(text):
	player_text.visible = false
	emit_signal("player_said", text, tokenize(text))

func _on_More_pressed():
	call_deferred("more_pressed")

func more_pressed():
	emit_signal("more_pressed")
	more.visible = false

func _on_more_timer_timeout():
	more.visible = true
