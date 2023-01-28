extends Label

enum Stat { HP, AC, MAX_HP, LEVEL,  XP, TO_HIT_MODIFIER, STRENGTH, DEXTERITY, CONSTITUTION }

export(int, "Hit Points", "Armour Class", "Maximum Hit Points", "Level", "Experience Points", "To Hit Modifier", "Strength", "Dexterity", "Constitution") var stat

func _ready():
	var _err = GameEngine.connect("player_created", self, "player_created")

func player_created():
	var _err = GameEngine.player.connect("player_stats_changed", self, "update_my_stat")
	update_my_stat()

func update_my_stat():
	var value:int = get_stat(GameEngine.player)
	text = String(value)

func get_stat(p):
	match stat:
		Stat.HP: return p.hp
		Stat.AC: return p.ac
		Stat.MAX_HP: return p.max_hp
		Stat.LEVEL: return p.level
		Stat.XP: return p.xp
		Stat.TO_HIT_MODIFIER: return p.to_hit_modifier
		Stat.Strength: return p.strenght
		Stat.Dexterity: return p.dexterity
		Stat.Constitution: return p.constitution
