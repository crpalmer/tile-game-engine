extends CanvasLayer

func _ready():
	var _err = GameEngine.connect("conversation_started", self, "conversation_started")
	_err = GameEngine.connect("conversation_ended", self, "conversation_ended")
	visible = false
	
func conversation_started(_conversation, _name):
	visible = true

func conversation_ended():
	visible = false
