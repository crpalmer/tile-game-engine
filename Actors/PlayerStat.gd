extends Label

enum Stat {
	HP, AC, MAX_HP,
	LEVEL,  XP,
	STRENGTH, DEXTERITY, CONSTITUTION,
	STRENGTH_MODIFIER, DEXTERITY_MODIFIER, CONSTITUTION_MODIFIER,
	TO_HIT_MODIFIER
}

var modifiers = [ Stat.STRENGTH_MODIFIER, Stat.DEXTERITY_MODIFIER, Stat.CONSTITUTION_MODIFIER]
@export var stat:Stat

func _ready():
	var _err = GameEngine.connect("player_created",Callable(self,"player_created"))

func player_created():
	var _err = GameEngine.player.connect("player_stats_changed",Callable(self,"update_my_stat"))

func modifier_sign(value):
	if value > 0: return "+"
	return ""

func update_my_stat():
	var value:int = get_stat(GameEngine.player)
	if modifiers.has(stat):
		text = "%s%d" % [ modifier_sign(value), value ]
	else:
		text = str(value)

func get_stat(p):
	match stat:
		Stat.HP: return p.hp
		Stat.AC: return p.ac
		Stat.MAX_HP: return p.max_hp
		Stat.LEVEL: return p.level
		Stat.XP: return p.xp
		Stat.TO_HIT_MODIFIER: return p.to_hit_modifier
		Stat.STRENGTH: return p.strength
		Stat.DEXTERITY: return p.dexterity
		Stat.CONSTITUTION: return p.constitution
		Stat.STRENGTH_MODIFIER: return p.clss.strength_modifier(p.strength, p.level)
		Stat.DEXTERITY_MODIFIER: return p.clss.dexterity_modifier(p.dexterity, p.level)
		Stat.CONSTITUTION_MODIFIER: return p.clss.constitution_modifier(p.constitution, p.level)
