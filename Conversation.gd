extends CanvasLayer

signal more_pressed

var actor_conversation

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

func is_active():
	return actor_conversation != null

func start(name, a_c):
	speaker_name.text = name
	actor_conversation = a_c
	visible = true
	player_text.visible = false
	GameEngine.pause()

func end(delay = 0):
	if delay > 0: yield(get_tree().create_timer(delay), "timeout")
	actor_conversation = null
	visible = false
	GameEngine.resume()

func say(who, text):
	call_deferred("said", who, text)

func say_bye(who, text, delay = 0):
	call_deferred("actor_said", who, text)
	end(delay)

func said(who, text):
	actor_said(who, text)
	show_player_text()

func actor_said(who, text):
	speaker_text.text = text
	if who: GameEngine.message("%s> %s" % [ who, text ])
	else: GameEngine.message(text)

func show_player_text():
	player_text.text = ""
	player_text.visible = true
	player_text.grab_focus()

func say_in_parts(who, parts:Array):
	var who_first_time = who
	for i in parts.size()-1:
		call_deferred("actor_said", who_first_time, parts[i])
		who_first_time = null
		more_timer.start(0.5)
		yield(self, "more_pressed")
	say(who_first_time, parts[parts.size()-1])

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

var filtered_words = [ "a", "of", "the", "is", "and", "or" ]

func player_entered(text):
	player_text.visible = false
	var tokenized = tokenize(text)
	var filtered = []
	for word in tokenized: if not filtered_words.has(word): filtered.append(word)
	var filtered_text = PoolStringArray(filtered).join(" ")
	actor_conversation.player_said_internal(filtered_text, filtered)

func _on_More_pressed():
	more.set_deferred("visible", false)
	emit_signal("more_pressed")

func _on_more_timer_timeout():
	more.set_deferred("visible", true)

func _unhandled_input(event):
	if more.visible and event.is_action_pressed("exit"):
		_on_More_pressed()
