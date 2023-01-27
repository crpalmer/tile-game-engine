extends Class

func hit_dice(): return GameEngine.Dice(1, 10)
func initial_hit_points(): return 10
# func proficient_with(thing): return false
# special abilities, like second wind for figher

func ability_improvement_at_level(level):
	match(level):
		1-3: return 1
		4-5: return 2
		6-7: return 3
		8-11: return 4
		12-15: return 5
		16-18: return 6
		20-9999: return 7
		
func number_of_attacks(level):
	match(level):
		1-4: return 1
		5-10: return 2
		11-19:  return 3
		20-99999: return 4

func strength_modifier(strength):
	return .strength_modifier(strength) + profiency_modifier(strength)

func constitution_modifier(constitution):
	return .constitution_modifier(constitution) + profiency_modifier(constitution)
