extends Node2D
class_name ActorConversation

@export var seconds_per_interation = 15

var things_for_sale = []
var services_for_sale = []

var in_conversation = false
var is_selling = false

@onready var actor = get_parent()
@onready var conversation = GameEngine.conversation

func _ready():
	pass

func get_persistent_data():
	return {}

func load_persistent_data(_p):
	pass

func start():
	if not conversation.is_active():
		conversation.start(actor.display_name, self)
		say_hello()

func say_hello(): say("Hello.")
func say_attacked(): say("Die!")
func say_bye(): say("Bye", false)

func say_and_end(text, delay = 2):
	await say(text, false)
	await conversation.end(delay)

func end(delay = 0.0):
	await conversation.end(delay)

func say(text, show_player_text_when_done = true):
	await conversation.say(actor.display_name, text, show_player_text_when_done).completed
	add_time()

func add_time():
	GameEngine.add_to_game_time(seconds_per_interation/60.0)

func player_said_internal(text, words):
	GameEngine.message("You> %s" % text)
	if text.begins_with("buy ") and process_sale(text.substr(4)):
		# Someone already knows what we're selling, them have it
		pass
	elif is_selling:
		handle_selling(text, words)
	elif services_for_sale.size() + things_for_sale.size() > 0 and is_sale_utterance(text, words):
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
		say("My name is " + actor.display_name)
	elif "bye" in words or text == "":
		say_bye()
		end(0.75)
	elif is_a_thing_for_sale(text):
		say("I sell %s, if you want to purchase it say \"buy %s\"." % [text, text])
	else:
		say("I don't understand")

func wants_to_initiate_conversation():
	return false

func _process(_delta):
	if GameEngine.is_paused(): return
	if actor.is_hostile(): return
	if in_conversation and not actor.player_is_close():
		end(0)
	elif not in_conversation and wants_to_initiate_conversation() and actor.player_is_close():
		start()

func is_sale_utterance(_text, words):
	return words.has("buy")

func is_a_thing_for_sale(text):
	for service in services_for_sale: if service.name == text: return true
	for thing in things_for_sale: if thing.display_name == text: return true
	return false

func sell_service(_sale):
	pass

func sell_thing(_thing):
	pass

func process_sale(text):
	for sale in services_for_sale:
		if sale.name == text:
			if GameEngine.player.try_to_pay(sale.cost):
				say(sell_service(sale) + "\nYou paid %s.  What else can I help you with?" % GameEngine.currency_value_to_string(sale.cost))
			else:
				say("You can't afford %s" % GameEngine.currency_value_to_string(sale.cost))
			is_selling = false
			return true
	for thing in things_for_sale:
		if thing.display_name == text:
			if GameEngine.player.try_to_pay(thing.value):
				var new_thing = thing.duplicate()
				new_thing.visible = true
				say(sell_thing(new_thing) + "\nYou paid %s.  What else can I help you with?" % GameEngine.currency_value_to_string(thing.value))
			else:
				say("You can't afford %s" % GameEngine.currency_value_to_string(thing.value))
			is_selling = false
			return true
	return false

func start_selling():
	is_selling = true
	var text = ""
	var divider = ""
	for sale in services_for_sale:
		text = text + "%s%s for %s" % [divider, sale.name, GameEngine.currency_value_to_string(sale.cost)]
		divider = " or "
	for thing in things_for_sale:
		text = text + "%s%s for %s" % [divider, thing.display_name, GameEngine.currency_value_to_string(thing.value)]
		divider = " or "
	say("I can offer: " + text)

func handle_selling(text, words):
	if text == "" or text == "" or words.has("nothing") or words.has("none"):
		say("What else can I help you with then?")
		is_selling = false
	elif is_sale_utterance(text, words):
		start_selling()
	elif not process_sale(text):
		say("What do you want to buy?")

func one_word_in(words, array):
	for word in array:
		if words.has(word): return true
	return false
