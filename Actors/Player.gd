extends Actor
class_name Player

signal player_stats_changed
signal player_died

var level = 1
var strength
var dexterity
var constitution

const NOT_RESTING = 0
const SHORT_RESTING = 1
const LONG_RESTING = 2

var attacks = []
var resting_until = 0
var resting_started_at = 0
var next_long_rest = 0
var resting_state = NOT_RESTING
var short_rest_spent = 0

var money = {}

var hit_dice = GameEngine.Dice(1, 10)
var xp:int = 0
var clss:Class
var animation:AnimatedSprite

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

func add_xp(new_xp:int):
	xp += new_xp
	while xp >= xp_table[level+1]:
		level = level + 1
		var new_hp = GameEngine.roll(clss.hit_dice, GameEngine.ability_modifier(constitution))
		hp += new_hp
		max_hp += new_hp
		GameEngine.message("You achieved level %d and gained %d hit points!" % [level, new_hp])
	emit_signal("player_stats_changed")

func get_persistent_data():
	var p = .get_persistent_data()
	var i = {}
	for c in get_inventory_containers():
		i.merge({
			c.name: c.get_persistent_data()
		})
	var m = {}
	for c in money.keys():
		m.merge( {
			c: {
				"n_units": money[c].n_units,
				"unit_value": money[c].unit_value
			}
		} )
	p.merge({
		"level": level,
		"strength": strength,
		"dexterity": dexterity,
		"constitution": constitution,
		"resting_state": resting_state,
		"resting_until": resting_until,
		"resting_started_at": resting_started_at,
		"next_long_rest": next_long_rest,
		"short_rest_spent": short_rest_spent,
		"inventory": i,
		"money": m
	})
	return p

func load_persistent_data(p):
	.load_persistent_data(p)
	level = p.level
	strength = p.strength
	dexterity = p.dexterity
	constitution = p.constitution
	resting_state = p.resting_state
	resting_until = p.resting_until
	resting_started_at = p.resting_started_at
	next_long_rest = p.next_long_rest
	short_rest_spent = p.short_rest_spent
	if resting_state != NOT_RESTING: Engine.time_scale = 600
	for c in get_inventory_containers():
		var i = p.inventory[c.name]
		if i: c.load_persistent_data(i)
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

func create_character(clss_path, populate_inventory = true, give_currency = true):
	var items = []
	clss = load(clss_path).instance()
	add_child(clss)
	strength = roll_ability_score()
	dexterity = roll_ability_score()
	constitution = roll_ability_score()
	print("Str: " + String(strength) + " Dex: " + String(dexterity) + " Con: " + String(constitution))
	for c in clss.get_children():
		if c.is_in_group("InventoryThings"):
			clss.remove_child(c)
			if populate_inventory: add_to_inventory(c)
			else: items.push_back(c)
		elif c is Currency:
			if give_currency: add_currency(c)
			else:
				items.push_back(c)
			clss.remove_child(c)
			c.queue_free()
	hp = clss.initial_hit_points() + GameEngine.ability_modifier(constitution)
	max_hp = hp
	on_inventory_changed()
	return items

func _ready():
	animation = get_node_or_null("AnimatedSprite")
	enter_current_scene()
	
func enter_current_scene():
	emit_signal("player_stats_changed")
	$Camera2D/AmbientLight.set_radius(vision_radius)

func stop_resting(regained_hp = 0):
	resting_state = NOT_RESTING
	GameEngine.fade_in()
	Engine.time_scale = 1
	var rest_time = int(GameEngine.time_in_minutes - resting_started_at)
	GameEngine.message("You rested for %d hour%s and %d minute%s" % [
		rest_time / 60,
		"s" if rest_time >= 60 and rest_time < 120 else "",
		rest_time % 60,
		"" if rest_time % 60 == 1 else "s"
	])
	if regained_hp > 0: GameEngine.message("You regained %d HPs" % regained_hp)

func take_damage(damage:int, from = null):
	if resting_state != NOT_RESTING: stop_resting()
	.take_damage(damage, from)
	emit_signal("player_stats_changed")

func give_hit_points(hp_given):
	hp += hp_given
	if hp > max_hp: hp = max_hp

func killed(who):
	add_xp(who.xp_value)

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
		if Input.is_key_pressed(KEY_CONTROL): long_rest()
		else: short_rest()
	
func default_physics_process(delta):
	var dir = Vector2(0, 0)
	if Input.is_action_pressed("left"): dir.x -= 1
	if Input.is_action_pressed("right"): dir.x += 1
	if Input.is_action_pressed("up"): dir.y -= 1
	if Input.is_action_pressed("down"): dir.y += 1
	
	if dir.length() > 0:
		if animation:
			animation.flip_h = dir.x < 0 or dir.y < 0
			animation.play("walk")
		var moved = dir.normalized()*travel_distance_in_pixels(delta)
		var _collision:KinematicCollision2D = move_and_collide(moved)
	elif animation:
		animation.stop()

func select_attack():
	for attack in attacks:
		if attack.may_use():
			attack.used_by(self)
			return attack
	return null
	
func select_attack_target():
	var hostiles = []
	var others = []
	for who in $CloseArea.in_sight():
		if who is Actor:
			if who.mood == Mood.HOSTILE: hostiles.push_back(who)
			else: others.push_back(who)
	if hostiles.size() > 0: return hostiles[randi() % hostiles.size()]
	if others.size() > 0: return others[randi() % others.size()]
	return null
	
func process_attack():
	var attack = select_attack()
	if attack == null: return
	var opponent = select_attack_target()
	if opponent == null: return
	attack(opponent, attack, clss.strength_modifier(strength))

func process_use():
	for use_on in $CloseArea.in_sight():
		if use_on is InventoryThing: add_to_inventory(use_on)
		elif use_on is Thing: use_on.used_by(self)

func add_currency(currency, amount = 0):
	if money.has(currency.filename):
		money[currency.filename].n_units += currency.n_units
	else:
		money[currency.filename] = {}
		money[currency.filename].n_units = currency.n_units if amount == 0 else amount
		money[currency.filename].unit_value = currency.unit_value
	emit_signal("player_stats_changed")

func get_currency_by_filename(filename):
	if money.has(filename): return money[filename].n_units
	else: return 0

func get_currency(currency):
	return get_currency_by_filename(currency.filename)

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
	var what = ""
	for thing in $CloseArea.in_sight():
		var this_what = thing.description() if thing.has_method("description") else null
		if this_what:
			if what.length() > 0: what = what + ", "
			what = what + this_what
	if what.length() == 0: what = "nothing"
	GameEngine.message("You see: " + what)

func process_talk():
	for thing in $CloseArea.in_sight():
		if thing.has_method("start"): thing.start()

func get_inventory_containers():
	var containers = []
	for c in get_children():
		if c.is_in_group("InventoryContainers"): containers.push_back(c)
	return containers

func add_to_inventory(thing):
	if $Inventory.add_thing(thing):
		GameEngine.message("You picked up " + thing.description())
		return true
	GameEngine.message("You are carrying too much to pick up " + thing.description())
	return false

func has_a_thing_in_group(group_name):
	return $Inventory.has_a_thing_in_group(group_name)

func died():
	print_debug("Player died!")
	GameEngine.pause()
	emit_signal("player_died")

func set_ambient_light(percent):
	$Camera2D/AmbientLight.set_brightness(percent)
	$Camera2D/LightSource.set_brightness(100-percent)

func on_inventory_changed():
	ac = $Inventory.get_ac() + clss.dexterity_modifier(dexterity)
	to_hit_modifier = $Inventory.get_to_hit_modifier() + clss.strength_modifier(strength)
	attacks = []
	for thing in $Inventory.get_equipped_things():
		if thing.can_attack_with: attacks.push_back(thing)
	if attacks.size() == 0: attacks.push_back(punch)
	emit_signal("player_stats_changed")

func strength_test(needed): return GameEngine.roll_test(needed, clss.strength_modifier(strength))
func dexterity_test(needed): return GameEngine.roll_test(needed, clss.dexterity_modifier(dexterity))
func constitution_test(needed): return GameEngine.roll_test(needed, clss.constitution_modifier(constitution))

func start_resting(state, minutes):
	resting_state = state
	resting_started_at = GameEngine.time_in_minutes
	resting_until = resting_started_at + minutes
	GameEngine.fade_out()
	Engine.time_scale = 1000

func short_rest():
	if resting_state == NOT_RESTING:
		start_resting(SHORT_RESTING, 60)

func long_rest():
	if resting_state == NOT_RESTING and GameEngine.time_in_minutes >= next_long_rest:
		start_resting(LONG_RESTING, 8*60)
	else:
		GameEngine.message("You can't sleep until at least " + GameEngine.time_of_day(next_long_rest))

func process_resting():
	if GameEngine.time_in_minutes < resting_until: return

	var old_hp = hp

	match resting_state:
		LONG_RESTING:
			hp = max_hp
			short_rest_spent = 0
			next_long_rest = GameEngine.time_in_minutes + 8*60
			emit_signal("player_stats_changed")
		SHORT_RESTING:
			if short_rest_spent < level:
				give_hit_points(GameEngine.roll(clss.hit_dice(), clss.constitution_modifier(constitution)))
				short_rest_spent += 1
				emit_signal("player_stats_changed")

	stop_resting(hp - old_hp)	
