extends Button

var conversation

func _ready():
	var _err = GameEngine.connect("conversation_started", self, "conversation_started")
	visible = false

func conversation_started(conversation_obj, _name):
	conversation = conversation_obj
	conversation.connect("more_needed", self, "more_needed")
	visible = false

func more_needed():
	visible = true

func more_pressed():
	conversation.more_pressed()
	visible = false
