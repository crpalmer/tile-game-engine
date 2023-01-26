extends Actor
class_name PlayerBase

signal player_stats_changed

var level = 1
var strength
var dexterity
var constitution

const NOT_RESTING = 0
const SHORT_RESTING = 1
const LONG_RESTING = 2

var attacks = []
var resting_until = 0
var last_rest_finished = -30*60
var resting_state = NOT_RESTING
var short_rest_spent = 0

func get_persistent_data():
	var p = .get_persistent_data()
	var i = {}
	for c in get_inventory_containers():
		i.merge({
			c.name: c.get_persistent_data()
		})
	p.merge({
		"level": level,
		"strength": strength,
		"dexterity": dexterity,
		"constitution": constitution,
		"resting_state": resting_state,
		"resting_until": resting_until,
		"last_rest_finished": last_rest_finished,
		"short_rest_spent": short_rest_spent,
		"inventory": i
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
	last_rest_finished = p.last_rest_finished
	short_rest_spent = p.short_rest_spent
	if resting_state != NOT_RESTING: Engine.time_scale = 600
	for c in get_inventory_containers():
		var i = p.inventory[c.name]
		if i: c.load_persistent_data(i)
	on_inventory_changed()

func _ready():
	enter_current_scene()
	strength = GameEngine.roll(GameEngine.Dice(3, 6))
	dexterity = GameEngine.roll(GameEngine.Dice(3, 6))
	constitution = GameEngine.roll(GameEngine.Dice(3, 6))
	print("Str: " + String(strength) + " Dex: " + String(dexterity) + " Con: " + String(constitution))
	on_inventory_changed()
	
func enter_current_scene():
	emit_signal("player_stats_changed")
	$Camera2D/AmbientLight.set_radius(vision_radius)

func stop_resting():
	resting_state = NOT_RESTING
	last_rest_finished = GameEngine.time_in_minutes
	GameEngine.fade_in()
	Engine.time_scale = 1
	
func take_damage(damage:int, from = null):
	if resting_state != NOT_RESTING: stop_resting()
	.take_damage(damage, from)
	emit_signal("player_stats_changed")

func killed(who):
	xp += who.xp_value
	emit_signal("player_stats_changed")
	
func _process(_delta):
	if resting_state != NOT_RESTING:
		if resting_until > GameEngine.time_in_minutes: return
		if resting_state == LONG_RESTING:
			hp = max_hp
			short_rest_spent = 0
		else:
			hp += GameEngine.roll(GameEngine.Dice(1, 10, GameEngine.ability_modifier(constitution)))
		if hp > max_hp: hp = max_hp
		stop_resting()
		emit_signal("player_stats_changed")

	if GameEngine.is_paused(): return

	if Input.is_action_just_released("attack"): process_attack()
	if Input.is_action_just_released("use"): process_use()
	if Input.is_action_just_released("look"): process_look()
	if Input.is_action_just_released("talk"): process_talk()
	if Input.is_action_just_released("rest"): process_rest()
	
func _physics_process(delta):
	var dir = Vector2(0, 0)
	if Input.is_action_pressed("left"): dir.x -= 1
	if Input.is_action_pressed("right"): dir.x += 1
	if Input.is_action_pressed("up"): dir.y -= 1
	if Input.is_action_pressed("down"): dir.y += 1
	
	if dir.length() > 0:
		var moved = dir.normalized()*delta*GameEngine.feet_to_pixels(speed)
		var _collision:KinematicCollision2D = move_and_collide(moved)

func select_attack():
	for attack in attacks:
		if attack.may_use():
			attack.used_by(self)
			return attack
	return null
	
func select_attack_target():
	var hostiles = []
	var others = []
	for who in $CloseArea.who_is_in_area():
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
	attack(opponent, attack, GameEngine.ability_modifier(strength))

func process_use():
	for use_on in $CloseArea.who_is_in_area():
		if use_on is InventoryThing: add_to_inventory(use_on)
		elif use_on is Thing: use_on.used_by(self)

func process_look():
	var what = ""
	for thing in $CloseArea.who_is_in_area():
		var this_what = thing.looked_at()
		if this_what:
			if what.length() > 0: what = what + ", "
			what = what + thing.looked_at()
	if what.length() == 0: what = "nothing"
	GameEngine.message("You see: " + what)

func process_talk():
	for thing in $CloseArea.who_is_in_area():
		var conversation = thing.get_node_or_null("Conversation")
		if conversation:
			conversation.start()
			return

func get_inventory_containers():
	var containers = []
	for c in get_children():
		if c.is_in_group("InventoryContainers"): containers.push_back(c)
	return containers

func add_to_inventory(thing):
	for c in get_inventory_containers():
		if c.add_thing(thing):
			GameEngine.message("You picked up " + thing.to_string())
			return true
	GameEngine.message("You are carrying too much to pick up " + thing.to_string())
	return false
	
func has_a(thing):
	return $Inventory.has_a(thing)

func has_a_thing_in_group(group_name):
	return $Inventory.has_a_thing_in_group(group_name)

func died():
	print_debug("Player died!")
	$Sprite.visible = false

func set_ambient_light(percent):
	$Camera2D/AmbientLight.set_brightness(percent)

func set_light_source(radius, brightness):
	$Camera2D/LightSource.set_radius(radius)
	$Camera2D/LightSource.set_brightness(brightness)

func on_inventory_changed():
	ac = $Inventory.get_ac() + GameEngine.ability_modifier(dexterity)
	to_hit_modifier = $Inventory.get_to_hit_modifier() + GameEngine.ability_modifier(strength)
	attacks = []
	for thing in $Inventory.get_equipped_things():
		if thing.can_attack_with: attacks.push_back(thing)
	if attacks.size() == 0: attacks.push_back(punch)
	emit_signal("player_stats_changed")

func strength_test(needed): return GameEngine.roll_test(GameEngine.Dice(1, 20, GameEngine.ability_modifier(strength)), needed)
func dexterity_test(needed): return GameEngine.roll_test(GameEngine.Dice(1, 20, GameEngine.ability_modifier(dexterity)), needed)
func constitution_test(needed): return GameEngine.roll_test(GameEngine.Dice(1, 20, GameEngine.ability_modifier(constitution)), needed)

func process_rest():
	if last_rest_finished + 8*60 > GameEngine.time_in_minutes:
		if short_rest_spent < level:
			short_rest_spent += 1
			resting_state = SHORT_RESTING
			resting_until = GameEngine.time_in_minutes + 60
			GameEngine.message("You are taking a 1 hour rest")
		else:
			GameEngine.message("You aren't very tired, you can't rest right now")
			return
	else:
		resting_state = LONG_RESTING
		resting_until = GameEngine.time_in_minutes + 8*60
		GameEngine.message("Sleeping (hopefully for 8 hours)...")
	GameEngine.fade_out()
	Engine.time_scale = 600
