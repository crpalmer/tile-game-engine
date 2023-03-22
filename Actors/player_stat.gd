extends Label

enum Stat {
	HP, AC, MAX_HP,
	LEVEL,  XP,
	STRENGTH, DEXTERITY, CONSTITUTION,
	STRENGTH_MODIFIER, DEXTERITY_MODIFIER, CONSTITUTION_MODIFIER,
	ATTACKS_PER_ROUND,
	N_SHORT_RESTS, NEXT_LONG_REST_AT
}

var modifiers = [ Stat.STRENGTH_MODIFIER, Stat.DEXTERITY_MODIFIER, Stat.CONSTITUTION_MODIFIER]
var times = [ Stat.NEXT_LONG_REST_AT ]
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
	elif times.has(stat):
		if value < GameEngine.time_in_minutes:
			text = "now"
		else:
			text = GameEngine.time_of_day(value)
	else:
		text = str(value)

func get_stat(p:Player) -> int:
	match stat:
		Stat.HP: return p.hp
		Stat.AC: return p.ac
		Stat.MAX_HP: return p.max_hp
		Stat.LEVEL: return p.level
		Stat.XP: return p.xp
		Stat.ATTACKS_PER_ROUND: return p.attacks_per_round
		Stat.STRENGTH: return p.strength()
		Stat.DEXTERITY: return p.dexterity()
		Stat.CONSTITUTION: return p.constitution()
		Stat.STRENGTH_MODIFIER: return p.strength_modifier()
		Stat.DEXTERITY_MODIFIER: return p.dexterity_modifier()
		Stat.CONSTITUTION_MODIFIER: return p.constitution_modifier()
		Stat.N_SHORT_RESTS: return p.n_short_rests_remaining()
		Stat.NEXT_LONG_REST_AT: return ceil(p.next_long_rest_at())
	return 0
