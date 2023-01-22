extends CanvasLayer
class_name HUD

func message(msg: String):
	$Messages.message(msg)

func update_player_stats(player):
	$Stats/HPRect/HP.text = String(player.hp)
	$Stats/HPMaxRect/HPMax.text = String(player.max_hp)
	$Stats/ACRect/AC.text = String(player.ac)
	$Stats/XPRect/XP.text = String(player.xp)
