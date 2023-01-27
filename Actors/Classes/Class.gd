extends Node
class_name Class

func profiency_modifier(level): return floor(level/4) + 1
func hit_dice(): return GameEngine.D(6)
func initial_hit_points(): return 6
# func proficient_with(thing): return false
# special abilities, like second wind for figher
func ability_improvement_at_level(level): return 0
func number_of_attacks(level): return 1

func strength_modifier(strength): return GameEngine.ability_modifier(strength)
func dexterity_modifier(dex): return GameEngine.ability_modifier(dex)
func constitution_modifier(con): return GameEngine.ability_modifier(con)
