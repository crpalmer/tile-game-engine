extends Actor
class_name ConversationalActor

export var seconds_per_interation = 15

var in_conversation = false

func get_persistent_data():
	return .get_persistent_data()
	
func load_persistent_data(p):
	.load_persistent_data(p)

func name():
	return display_name

func start():
	GameEngine.conversation.connect("player_said", self, "player_said")
	GameEngine.conversation.start(name())
	in_conversation = true
	say_hello()

func say_hello(): say("Hello.")
func say_attacked(): say("Die!")
func say_bye(): say("Bye.")

func end(delay = 2.0):
	GameEngine.conversation.disconnect("player_said", self, "player_said")
	GameEngine.conversation.end(delay)
	in_conversation = false

func say(text):
	GameEngine.conversation.say(text)
	add_time()

func say_in_parts(parts:Array):
	GameEngine.conversation.say_in_parts(parts)
	add_time()

func add_time():
	GameEngine.add_to_game_time(seconds_per_interation/60)

func player_said(text:String, words:Array):
	if "hi" in words:
		say("Hello.")
	elif "hello" in words:
		say("Hi.")
	elif "thanks" in words:
		say("You're welcome.")
	elif "name" in words:
		say("My name is " + name())
	elif "bye" in words or text == "":
		say_bye()
		end(0.75)
	else:
		say("I don't understand")

func wants_to_initiate_conversation():
	return false

func _process(_delta):
	if mood != Mood.FRIENDLY: return
	if in_conversation and not $CloseArea.player_is_in_sight():
		end(0)
	elif not in_conversation and wants_to_initiate_conversation() and $CloseArea.player_is_in_sight():
		start()
