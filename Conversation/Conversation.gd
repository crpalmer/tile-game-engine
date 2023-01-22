extends Node2D
class_name Conversation

export var initiate_conversation = false

var already_talked = false
var actor:Actor
var tracking_area:TrackingArea

func _ready():
	var _err = $Canvas/PlayerText.connect("text_entered", self, "text_entered")
	actor = get_parent()
	tracking_area = actor.get_node("CloseArea")

func name():
	return get_parent().display_name
	
func start():
	if $Canvas.visible: return
	
	GameEngine.pause()
	
	$Canvas/SpeakerName.text = name()
	$Canvas/SpeakerText.text = hello()
	reset_text_box()
	$Canvas.visible = true
	already_talked = true

func hello(): return "Hello."
func attacked(): return "Die!"

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
	player_said(player_text, tokenize(player_text))
	
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

func reset_text_box():
	$Canvas/PlayerText.text = ""
	$Canvas/PlayerText.visible = true
	$Canvas/PlayerPrompt.visible = true
	$Canvas/More.visible = false
	$Canvas/PlayerText.grab_focus()
