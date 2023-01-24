extends Label

export var what:String

func _ready():
	var _err = GameEngine.connect("conversation_started", self, "conversation_started")

func conversation_started(conversation, name):
	match what:
		"name": text = name
		"text": var _err = conversation.connect("actor_said", self, "update_text")

func update_text(new_text):
	text = new_text
