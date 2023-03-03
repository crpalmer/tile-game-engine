extends Node2D
class_name AttackChoice

func get_attack_choices():
	var choices = []
	for c in get_children():
		if c is Attack: choices.append(c)
	return choices

func may_use():
	for attack in get_attack_choices():
		if not attack.may_use(): return false
	return true
