extends LineEdit

var conversation

func _ready():
	var _err = GameEngine.connect("conversation_started", self, "conversation_started")

func conversation_started(conversation_obj, _name):
	conversation = conversation_obj
	var _err = conversation.connect("waiting_for_player", self, "waiting_for_player")
	
func text_entered(text):
	conversation.player_entered(text)

func waiting_for_player():
	text = ""
	grab_focus()
