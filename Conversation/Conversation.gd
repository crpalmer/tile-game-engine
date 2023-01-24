extends Node2D
class_name Conversation

signal actor_said
signal more_needed
signal more_pressed
signal waiting_for_player

export var initiate_conversation = false

var already_talked = false
var actor:Actor
var tracking_area:TrackingArea
var in_conversation = false

func _ready():
	actor = get_parent()
	tracking_area = actor.get_node("CloseArea")

func name():
	return get_parent().display_name

func start():
	GameEngine.start_conversation(self, name())
	in_conversation = true
	say(hello())

func hello(): return "Hello."
func attacked(): return "Die!"

func end(text = "", delay = 2.0):
	if not in_conversation: return
	if text.length() > 0:
		say(text)
		yield(get_tree().create_timer(delay), "timeout")
	GameEngine.end_conversation()
	in_conversation = false

func say(text):
	emit_signal("actor_said", text)
	emit_signal("waiting_for_player")

func say_in_parts(parts:Array):
	for i in parts.size():
		emit_signal("actor_said", parts[i])
		emit_signal("more_needed")
		if (i < parts.size()-1): yield(self, "more_pressed")
	emit_signal("waiting_for_player")

func more_pressed():
	emit_signal("more_pressed")

func player_entered(text):
	player_said(text, tokenize(text))

func player_said(text:String, words:Array):
	if "hi" in words:
		say("Hello.")
	elif "hello" in words:
		say("Hi.")
	elif "thanks" in words:
		say("You're welcome.")
	elif "name" in words:
		say("My name is " + get_parent().display_name)
	elif "bye" in words or text == "":
		end("Bye.", 1)
	else:
		say("I don't understand")

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

func _process(_delta):
	if not tracking_area.player_is_in_area:
		already_talked = false
		end()
	elif actor.mood == Actor.Mood.FRIENDLY and initiate_conversation:
		initiate_conversation = false
		start()
	elif actor.mood == Actor.Mood.HOSTILE:
		end(attacked(), 0.75)
