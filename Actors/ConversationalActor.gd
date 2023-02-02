extends Actor
class_name ConversationalActor

export var seconds_per_interation = 15

var for_sale = []

var in_conversation = false
var is_selling = false

func get_persistent_data():
	return .get_persistent_data()

func load_persistent_data(p):
	.load_persistent_data(p)

func name():
	return display_name

func start():
	GameEngine.conversation.connect("player_said", self, "player_said_wrapper")
	GameEngine.conversation.start(name())
	in_conversation = true
	say_hello()

func say_hello(): say("Hello.")
func say_attacked(): say("Die!")

func say_bye(text = "Bye", delay = 0):
	GameEngine.conversation.say_bye(text, delay)

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

func player_said_wrapper(text, words):
	if process_sale(text):
		# Someone already knows what we're selling, them have it
		pass
	elif is_selling:
		handle_selling_other_than_sale(text, words)
	elif for_sale.size() > 0 and is_sale_utterance(text, words):
		start_selling()
	else:
		player_said(text, words)

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

func is_sale_utterance(_text, words):
	return words.has("buy")

func sell(sale):
	pass

func process_sale(text):
	for sale in for_sale:
		if sale.name == text:
			if GameEngine.player.try_to_pay(sale.cost):
				say(sell(sale) + "\nYou paid %s.  What else can I help you with?" % GameEngine.currency_value_to_string(sale.cost))
			else:
				say("You can't afford %s" % GameEngine.currency_value_to_string(sale.cost))
			is_selling = false
			return true
	return false

func start_selling():
	is_selling = true
	var text = ""
	var divider = ""
	for sale in for_sale:
		text = text + "%s%s for %s" % [divider, sale.name, GameEngine.currency_value_to_string(sale.cost)]
		divider = " or "
	say("I can offer: " + text)

func handle_selling_other_than_sale(text, words):
	if text == "" or text == "" or words.has("nothing") or words.has("none"):
		say("What else can I help you with then?")
		is_selling = false
	elif is_sale_utterance(text, words):
		start_selling()
