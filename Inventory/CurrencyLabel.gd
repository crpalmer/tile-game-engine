extends Label

@export var currency:String # (String, FILE)

func _ready():
	var _err = GameEngine.player.connect("player_stats_changed",Callable(self,"on_player_stats_changed"))

func on_player_stats_changed():
	var amount:int = GameEngine.player.get_currency_by_filename(currency)
	text = "%d" % amount
