extends Label

export var what:String

func _ready():
	var _err = GameEngine.connect("player_created", self, "player_created")

func player_created():
	var _err = GameEngine.player.connect("player_stats_changed", self, "update_my_stat")
	update_my_stat()

func update_my_stat():
	var stat:int = get_stat(GameEngine.player)
	text = String(stat)

func get_stat(p):
	match what:
		"hp": return p.hp
		"ac": return p.ac
		"hp-max", "max-hp": return p.max_hp
		"level": return p.level
		"xp": return p.xp
		"to-hit-modifier": return p.to_hit_modifier
		"str", "strength": return p.strenght
		"dex", "dexterity": return p.dexterity
		"con", "constitution": return p.constitution
