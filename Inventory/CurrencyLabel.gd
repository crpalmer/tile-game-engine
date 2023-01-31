extends Label

export(String, FILE) var currency

func _ready():
	var _err = GameEngine.player.connect("player_stats_changed", self, "on_player_stats_changed")

func on_player_stats_changed():
	var amount = GameEngine.player.get_currency(currency)
	text = String(amount)
