extends Actor
class_name Player

signal player_stats_changed
signal player_died
signal ability_improvement_needed
signal ability_improvement_needed_resume

enum Ability { STRENGTH, DEXTERITY, CONSTITUTION }

var level = 1
var abilities:Array[int]
const NOT_RESTING = 0
const SHORT_RESTING = 1
const LONG_RESTING = 2

var resting_until = 0
var resting_started_at = 0
var next_long_rest = 0
var resting_state = NOT_RESTING
var short_rest_spent = 0
var resting_hostile_ends_at = 0

var money = {}

var hit_dice = GameEngine.Dice(1, 10)
var xp:int = 0
var clss:Class
var animation:AnimatedSprite2D

var hp_per_level:Array[int] = []
var abilities_gained:Array[Ability] = []

const xp_table = {
	1: 0,
	2: 300,
	3: 900,
	4: 2700,
	5: 6500,
	6: 14000,
	7: 23000,
	8: 34000,
	9: 48000,
	10: 64000,
	11: 85000,
	12: 100000,
	13: 120000,
	14: 140000,
	15: 165000,
	16: 195000,
	17: 225000,
	18: 265000,
	19: 305000,
	20: 355000
}

func strength(): return abilities[Ability.STRENGTH]
func dexterity(): return abilities[Ability.DEXTERITY]
func constitution(): return abilities[Ability.CONSTITUTION]

func strength_modifier(): return clss.strength_modifier(strength(), level)
func dexterity_modifier(): return clss.dexterity_modifier(dexterity(), level)
func constitution_modifier(): return clss.constitution_modifier(constitution(), level)

func ability_to_string(ability:Ability) -> String:
	match ability:
		Ability.STRENGTH: return "strength"
		Ability.DEXTERITY: return "dexterity"
		Ability.CONSTITUTION: return "constitution"
	return ""

func on_player_stats_changed():
	if clss:
		attack_modifier = strength_modifier()
		attacks_per_round = clss.number_of_attacks(level)
	emit_signal("player_stats_changed")

func add_xp(new_xp:int, important = true):
	xp += new_xp
	GameEngine.message("You gained %d XP" % new_xp, important)
	while xp >= xp_table[level+1]:
		await conditionally_raise_an_ability()
		while level >= hp_per_level.size():
			hp_per_level.append(GameEngine.roll(clss.hit_dice(), constitution_modifier()))
		hp += hp_per_level[level]
		max_hp += hp_per_level[level]
		level += 1
		GameEngine.message("You achieved level %d and gained %d hit points!" % [level, hp_per_level[level-1]], true)
	on_player_stats_changed()

func conditionally_raise_an_ability():
	var ability_improvements = clss.ability_improvement_at_level(level+1)
	if clss.ability_improvement_at_level(level) < ability_improvements:
		if abilities_gained.size() < ability_improvements:
			await select_ability_gained()
		var old_cm = constitution_modifier()
		abilities[abilities_gained[ability_improvements-1]] += 1
		var new_cm = constitution_modifier()
		adjust_for_constitution_change(old_cm, new_cm)
		GameEngine.message("You gained one %s" % ability_to_string(abilities_gained[ability_improvements-1]))

func adjust_for_constitution_change(old_cm:int, new_cm:int) -> void:
	var delta = new_cm - old_cm
	for l in hp_per_level.size():
		hp_per_level[l] += delta
		hp += delta
		max_hp += delta
	hp = clamp(hp, 1, max_hp)

func select_ability_gained():
	emit_signal("ability_improvement_needed")
	await ability_improvement_needed_resume

func ability_improvement_selected(ability:Ability):
	abilities_gained.append(ability)
	#TODO do I need to retroactively improve the HP for a const gain??
	emit_signal("ability_improvement_needed_resume")

func lose_xp(new_xp:int, important = true):
	xp -= new_xp
	GameEngine.message("You lost %d XP" % new_xp, important)
	while xp < xp_table[level]:
		level -= 1
		hp -= hp_per_level[level]
		max_hp -= hp_per_level[level]
		if hp < 1: hp = 1
		if max_hp < 1: max_hp = 1
		GameEngine.message("You downgraded to level %d and lost %d hit points!" % [level, hp_per_level[level]], true)
		var ability_improvements = clss.ability_improvement_at_level(level+1)
		if clss.ability_improvement_at_level(level) < ability_improvements:
			var old_cm = constitution_modifier()
			abilities[abilities_gained[ability_improvements-1]] -= 1
			var new_cm = constitution_modifier()
			GameEngine.message("You lost one %s" % ability_to_string(abilities_gained[ability_improvements-1]))
			adjust_for_constitution_change(old_cm, new_cm)
	on_player_stats_changed()

func get_persistent_data():
	var p = super.get_persistent_data()
	var m = {}
	for c in money.keys():
		m.merge( {
			c: {
				"n_units": money[c].n_units,
				"unit_value": money[c].unit_value
			}
		} )
	p.merge({
		"clss": clss.scene_file_path,
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"hp_per_level": hp_per_level,
		"xp": xp,
		"abilities": abilities,
		"abilities_gained": abilities_gained,
		"resting_state": resting_state,
		"resting_until": resting_until,
		"resting_started_at": resting_started_at,
		"next_long_rest": next_long_rest,
		"short_rest_spent": short_rest_spent,
		"inventory": $Inventory.get_persistent_data(),
		"money": m
	})
	return p

func load_persistent_data(p):
	super.load_persistent_data(p)
	clss = load(p.clss).instantiate()
	level = p.level
	hp = p.hp
	max_hp = p.max_hp
	hp_per_level = p.hp_per_level
	xp = p.xp
	abilities = p.abilities
	abilities_gained = p.abilities_gained
	resting_state = p.resting_state
	resting_until = p.resting_until
	resting_started_at = p.resting_started_at
	next_long_rest = p.next_long_rest
	short_rest_spent = p.short_rest_spent
	$Inventory.load_persistent_data(p.inventory)
	for c in p.money.keys():
		var m = p.money[c]
		money[c] = {}
		money[c].n_units = m.n_units
		money[c].unit_value = m.unit_value
	on_inventory_changed()

func roll_ability_score():
	var dice = []
	for _i in range(4): dice.push_back(GameEngine.roll(GameEngine.D(6)))
	dice.sort()
	print(dice)
	return dice[1] + dice[2] + dice[3] + 1   # +1 is the human bonus

func roll_ability_scores():
	while true:
		abilities = []
		for _ability in Ability:
			abilities.append(roll_ability_score())
		if abilities.reduce(func (accum, ability): return accum + ability, 0) > 12*Ability.size():
			return

func create_initial_items():
	var items = []
	for c in clss.get_children():
		if c.is_in_group("InventoryThings"):
			clss.remove_child(c)
			items.push_back(c)
		elif c is Currency:
			add_currency(c)
			clss.remove_child(c)
			c.queue_free()
	on_inventory_changed()
	return items

func create_character(clss_in):
	clss = clss_in.duplicate()
	add_child(clss)
	roll_ability_scores()
	hp = clss.initial_hit_points() + constitution_modifier()
	max_hp = hp
	hp_per_level = [ hp ]
	return create_initial_items()

func _ready():
	super()
	animation = get_node_or_null("AnimatedSprite2D")
	enter_current_scene()
	
func enter_current_scene():
	on_player_stats_changed()
	$Camera2D/AmbientLight.set_radius(vision_radius)

func stop_resting():
	resting_state = NOT_RESTING
	GameEngine.fade_from_resting()
	var rest_time:int = int(GameEngine.time_in_minutes - resting_started_at)
	GameEngine.message("You rested for %d hour%s and %d minute%s" % [
		floor(rest_time / 60.0),
		"s" if rest_time >= 60 and rest_time < 120 else "",
		rest_time % 60,
		"" if rest_time % 60 == 1 else "s"
	])

func was_attacked_by(_attacker):
	if resting_state != NOT_RESTING: stop_resting()

func take_damage(damage:int, from:Actor = null, cause = null, show_popup = true) -> void:
	if resting_state != NOT_RESTING: stop_resting()
	super(damage, from, cause, show_popup)
	on_player_stats_changed()

func give_hit_points(hp_given):
	super.give_hit_points(hp_given)
	on_player_stats_changed()

func killed(who):
	add_xp(who.xp_value, false)

func default_process():
	if resting_state != NOT_RESTING:
		process_resting()
		return

	if Input.is_action_just_released("attack"): process_attack()
	if Input.is_action_just_released("use"): process_use()
	if Input.is_action_just_released("look"): process_look()
	if Input.is_action_just_released("talk"): process_talk()
	if Input.is_action_just_released("show_inventory"): $Inventory.open()
	if Input.is_action_just_released("rest"):
		if Input.is_key_pressed(KEY_CTRL): long_rest()
		else: short_rest()
	
func default_physics_process(delta):
	if resting_state != NOT_RESTING:
		if resting_hostile_ends_at > 0 and GameEngine.time_in_minutes >= resting_hostile_ends_at:
			GameEngine.message("You wake up from a bad nightmare about being attacked.")
			stop_resting()
		else:
			GameEngine.player_rested_for(delta)
			if $VisionArea.n_hostiles() > 0 and resting_hostile_ends_at == 0:
				resting_hostile_ends_at = GameEngine.time_in_minutes + 1
		return

	var dir = Vector2(0, 0)
	if Input.is_action_pressed("left"): dir.x -= 1
	if Input.is_action_pressed("right"): dir.x += 1
	if Input.is_action_pressed("up"): dir.y -= 1
	if Input.is_action_pressed("down"): dir.y += 1
	
	if dir.length() > 0:
		if animation:
			animation.flip_h = dir.x < 0 or dir.y < 0
			animation.play("walk")
		if $VisionArea.n_hostiles() == 0:
			GameEngine.player_traveled_for(delta)
		var v = dir.normalized()*travel_distance_in_pixels(delta)
		if navigation.avoidance_enabled:
			navigation.set_velocity(v)
		else:
			var _collision:KinematicCollision2D = move_and_collide(v)
	elif animation:
		animation.stop()

func i_would_attack(target, pass_number):
	if target.is_hostile(): return true
	if pass_number > 0: return true
	return false

func process_use():
	for use_on in $CloseArea.in_sight():
		if not use_on.visible: pass
		elif use_on is Currency:
			add_currency(use_on)
			use_on.queue_free()
		elif use_on is InventoryThing: add_to_inventory(use_on)
		elif use_on is Thing:
			if use_on.used_by(self):
				queue_free()

func add_currency(currency, amount = 0):
	var n_units = currency.n_units if amount == 0 else amount
	var f = currency.scene_file_path
	if money.has(f):
		money[f].n_units += n_units
	else:
		money[f] = {}
		money[f].n_units = n_units
		money[f].unit_value = currency.unit_value
	GameEngine.message("You picked up %d %s" % [ n_units, currency.abbreviation ])
	on_player_stats_changed()

func get_currency_by_filename(filename):
	if money.has(filename): return money[filename].n_units
	else: return 0

func get_currency(currency):
	return get_currency_by_filename(currency.scene_file_path)

func try_to_pay(units:float):
	var total = 0.0
	for c in GameEngine.currency_ascending: total += get_currency(c) * c.unit_value
	if total < units: return false
	total -= units
	money = {}
	for c in GameEngine.currency_descending:
		var amount = floor(total / c.unit_value)
		add_currency(c, amount)
		total -= amount * c.unit_value
	return true

func process_look():
	var any_descriptions = false
	var what = ""
	for thing in $CloseArea.in_sight():
		var long = thing.description() if thing.has_method("description") else ""
		if long != "":
			GameEngine.message("%s: %s" % [ thing.capitalized_display_name(), long ])
			any_descriptions = true
		else:
			if what.length() > 0: what = what + ", "
			what += thing.display_name
		if thing.has_method("looked_at"): thing.looked_at()
	if what == "" and not any_descriptions: what = "nothing"
	if what != "": GameEngine.message("You %ssee: %s" % [ "also " if any_descriptions else "", what])

func process_talk():
	for thing in $CloseArea.in_sight():
		if thing.has_method("start_conversation"): thing.start_conversation()

func add_to_inventory(thing:InventoryThing, silent = false, auto_equip = false):
	if $Inventory.add_thing(thing, auto_equip):
		if not silent: GameEngine.message("You picked up " + thing.display_name)
		return true
	GameEngine.message("You are carrying too much to pick up " + thing.display_name)
	return false

func has_a(thing_display_name):
	return $Inventory.has_a(thing_display_name)

func has_a_thing_in_group(group_name):
	return $Inventory.has_a_thing_in_group(group_name)

func died():
	GameEngine.message("You died!", true)
	print_debug("Player died!")
	GameEngine.pause()
	emit_signal("player_died")

func set_ambient_light(percent):
	$Camera2D/AmbientLight.set_brightness(percent)
	$Camera2D/LightSource.set_brightness(100-percent)

func get_attacks():
	attacks = []
	for thing in $Inventory.get_equipped_things():
		for attack in thing.get_children():
			if attack is Attack: attacks.push_back(attack)
	if attacks.size() == 0:
		super.add_punch()

func on_inventory_changed():
	ac = $Inventory.get_ac() + dexterity_modifier()
	get_attacks()
	on_player_stats_changed()

func strength_test(needed): return GameEngine.roll_test(needed, strength_modifier())
func dexterity_test(needed): return GameEngine.roll_test(needed, dexterity_modifier())
func constitution_test(needed): return GameEngine.roll_test(needed, constitution_modifier())

func start_resting(state, minutes):
	resting_state = state
	resting_started_at = GameEngine.time_in_minutes
	resting_until = resting_started_at + minutes
	resting_hostile_ends_at = 0
	GameEngine.fade_to_resting()

func short_rest():
	if resting_state == NOT_RESTING:
		if $VisionArea.n_hostiles() > 0:
			GameEngine.message("You may not rest in a hostile area.")
		else:
			start_resting(SHORT_RESTING, 60)

func long_rest():
	if resting_state == NOT_RESTING:
		if GameEngine.time_in_minutes < next_long_rest:
			GameEngine.message("You can't sleep until at least " + GameEngine.time_of_day(next_long_rest))
		elif $VisionArea.n_hostiles() > 0:
			GameEngine.message("You may not rest in a hostile area.")
		else:
			start_resting(LONG_RESTING, 8*60)

func process_resting():
	if GameEngine.time_in_minutes < resting_until: return

	var to_give = 0
	resting_hostile_ends_at = 0
	match resting_state:
		LONG_RESTING:
			to_give = max_hp
			short_rest_spent = 0
			next_long_rest = GameEngine.time_in_minutes + 8*60
		SHORT_RESTING:
			if short_rest_spent < level and hp < max_hp:
				to_give = GameEngine.roll(clss.hit_dice(), constitution_modifier())
				short_rest_spent += 1

	stop_resting()
	give_hit_points(to_give)

func n_short_rests_remaining() -> int:
	return level - short_rest_spent

func next_long_rest_at() -> float:
	return next_long_rest
