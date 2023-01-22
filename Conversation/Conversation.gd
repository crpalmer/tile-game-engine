extends Node2D
class_name Conversation

export var starter = "Hello"
export var attacked_text = "Die!"

var already_talked = false

func _ready():
	var _err = $Canvas/PlayerText.connect("text_entered", get_parent(), "player_said")
	
func start():
	if $Canvas.visible: return
	
	GameEngine.pause()
	
	$Canvas/SpeakerName.text = get_parent().display_name
	$Canvas/SpeakerText.text = starter
	reset_text_box()
	$Canvas.visible = true
	already_talked = true
	
func end(text = "", delay = 2.0):
	if not $Canvas.visible: return
	
	$Canvas/PlayerText.visible = false
	$Canvas/PlayerPrompt.visible = false
	if text.length() > 0:
		$Canvas/SpeakerText.text = text
		yield(get_tree().create_timer(delay), "timeout")
	$Canvas.visible = false
	
	GameEngine.resume()

func say(text:String):
	$Canvas/SpeakerText.text = text
	reset_text_box()

func say_in_parts(parts:Array):
	$Canvas/PlayerText.visible = false
	$Canvas/More.visible = true
	for i in parts.size():
		$Canvas/SpeakerText.text = parts[i]
		if (i < parts.size()-1): yield($Canvas/More, "pressed")
	reset_text_box()

func text_entered(player_text:String):
	player_said(player_text)
	
func player_said(text:String):
	player_said_default(tokenize(text))

func player_said_default(words:Array):
	if "hi" in words:
		say("Hello.")
	elif "hello" in words:
		say("Hi.")
	elif "thanks" in words:
		say("You're welcome.")
	elif "name" in words:
		say("My name is " + get_parent().display_name)
	elif "bye" in words:
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

func process(actor, with_player):
	if not with_player: already_talked = false
	
	if not with_player:
		end()
	elif actor.mood == Actor.Mood.FRIENDLY and not already_talked:
		start()
	elif actor.mood == Actor.Mood.HOSTILE:
		end(attacked_text, 0.75)

func reset_text_box():
	$Canvas/PlayerText.text = ""
	$Canvas/PlayerText.visible = true
	$Canvas/PlayerPrompt.visible = true
	$Canvas/More.visible = false
	$Canvas/PlayerText.grab_focus()
