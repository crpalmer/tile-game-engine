extends Label

export(String, FILE) var currency
var last_amount = 0

func _process(delta):
	var amount = GameEngine.player.get_currency(currency)
	if amount != last_amount:
		text = String(amount)
		last_amount = amount
