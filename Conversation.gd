extends CanvasLayer
class_name Conversation

signal more_pressed
signal player_said

var in_conversation = false
var player_is_in_area = false

func get_persistent_data(): return {}
func load_persistent_data(_p): pass

var speaker_name
var speaker_text
var player_text
var more

func _ready():
	GameEngine.conversation = self
	speaker_name = $SpeakerName
	speaker_text = $SpeakerText
	player_text = $PlayerText
	more = $More
	more.visible = false
	visible = false
	more.connect("pressed", self, "_on_More_pressed")
	player_text.connect("text_entered", self, "_on_PlayerText_text_entered")

func start(name):
	call_deferred("start_safe", name)
	in_conversation = true
	GameEngine.pause()

func start_safe(name):
	speaker_name.text = name
	visible = true
	player_text.visible = false

func end(delay):
	if delay > 0: yield(get_tree().create_timer(delay), "timeout")
	in_conversation = false
	GameEngine.resume()
	visible = false

func say(text):
	speaker_text.text = text
	player_text.text = ""
	player_text.visible = true
	player_text.grab_focus()
	
func say_in_parts(parts:Array):
	for i in parts.size():
		say(parts[i])
		more.visible = true
		if (i < parts.size()-1): yield(self, "more_pressed")
		more.visible = false
	player_text.visible = true

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

func _on_PlayerText_text_entered(new_text):
	player_text.visible = false
	emit_signal("player_said", new_text, tokenize(new_text))

func _on_More_pressed():
	emit_signal("more_pressed")
	more.visible = false
