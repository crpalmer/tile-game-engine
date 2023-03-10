extends CanvasLayer

signal more_pressed
signal done_saying

var actor_conversation

func get_persistent_data(): return {}
func load_persistent_data(_p): pass

@onready var speaker_name = $SpeakerName
@onready var speaker_text = $SpeakerText
@onready var player_text = $PlayerText
@onready var more = $More
@onready var more_timer = $More/Timer

func _ready():
	GameEngine.conversation = self
	more.visible = false
	visible = false
	more.connect("pressed",Callable(self,"_on_More_pressed"))
	player_text.connect("text_submitted",Callable(self,"_on_PlayerText_text_entered"))
	more_timer.connect("timeout",Callable(self,"_on_more_timer_timeout"))

func is_active():
	return actor_conversation != null

func start(actor_name, a_c):
	speaker_name.text = actor_name
	actor_conversation = a_c
	visible = true
	player_text.visible = false
	GameEngine.pause()

func end(delay = 0):
	if delay > 0: await get_tree().create_timer(delay).timeout
	actor_conversation = null
	visible = false
	GameEngine.resume()

func say(who, text, show_player_text_when_done = true):
	if text is Array:
		await say_in_parts_async(who, text)
	else:
		await say_single_async(who, text)
	if show_player_text_when_done: show_player_text()

func actor_said(who, text, with_more):
	speaker_text.text = text
	if who: GameEngine.message("%s> %s" % [ who, text ])
	else: GameEngine.message(text)
	if with_more:
		more_timer.start(0.5)
		await self.more_pressed
	emit_signal("done_saying")

func show_player_text():
	player_text.text = ""
	player_text.visible = true
	player_text.grab_focus()

func say_single_async(who, text, with_more = false):
	call_deferred("actor_said", who, text, with_more)
	await self.done_saying

func say_in_parts_async(who, parts:Array):
	var who_first_time = who
	for i in parts.size()-1:
		await say_single_async(who_first_time, parts[i], true)
		who_first_time = null
	await say_single_async(who_first_time, parts[parts.size()-1])

var delimiters = [' ', '	', '\n', ',', '.', '?', '!', '&']

func tokenize(text:String):
	var words = []
	var start_at = 0
	var i = 0
	text = text.to_lower()
	while i <= text.length():
		if i == text.length() or text[i] in delimiters:
			if i > start_at:
				words.push_back(text.substr(start_at, i-start_at))
			start_at = i+1
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
	var filtered_text = " ".join(PackedStringArray(filtered))
	actor_conversation.player_said_internal(filtered_text, filtered)

func _on_More_pressed():
	more.set_deferred("visible", false)
	emit_signal("more_pressed")

func _on_more_timer_timeout():
	more.set_deferred("visible", true)

func _unhandled_input(event):
	if more.visible and event.is_action_pressed("exit"):
		_on_More_pressed()
