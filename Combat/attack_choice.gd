extends Attack

var selected_attack:Attack = null
var time_to_switch_in_mins = 0.2

func attack(from:Actor, to:Actor) -> bool:
	return selected_attack.attack(from, to)

func set_time_scale(value:float) -> void:
	selected_attack.set_time_scale(value)

func used_by(who:Actor) -> bool:
	return selected_attack.used_by(who)

func capitalized_display_name() -> String:
	return selected_attack.capitalized_display_name()

func may_attack(from:Actor, to:Actor):
	if selected_attack and not selected_attack.may_use(): return false
	var new_attack:Attack = null
	for a in get_children():
		if a is Attack and a.may_attack(from, to):
			if new_attack == null: new_attack = a
			if a == selected_attack:
				return true
	if selected_attack and new_attack:
		next_use_at = GameEngine.time_in_minutes + time_to_switch_in_mins
	selected_attack = new_attack
	return false
