extends KinematicBody2D
class_name Actor

enum Mood { FRIENDLY = 0, NEUTRAL = 1, HOSTILE =2 }

export var display_name:String
export var ac = 10
export var hp = 1
export var max_hp = 1
export var to_hit_modifier = 0
export var speed = 30
export var xp_value = 1
export var close_radius = 6
export var vision_radius = 120
export var xp = 0
export var mood = Mood.FRIENDLY
export var next_action = 0

var player_position
var punch = load("res://GameEngine/Actors/Punch.tscn").instance()

func get_persistent_data():
	var p = {
		"hp": hp,
		"max_hp": max_hp,
		"mood": mood
	}
	if get_node_or_null("Conversation"): p.merge({ "conversation": $Conversation.get_persistent_data()})
	return p
	
func load_persistent_data(p):
	hp = p.hp
	max_hp = p.max_hp
	mood = p.mood
	if get_node_or_null("Conversation"): $Conversation.load_persistent_data(p.conversation)

func _ready():
	add_to_group("PersistentActors")
	add_to_group("Trackables")
	randomize()
	$VisionArea.visible = true
	$CloseArea.visible = true
	set_vision_range(vision_radius)
	set_close_range(close_radius)
	player_position = position
	if not display_name or display_name == "": display_name = name

func description():
	return display_name
	
func set_vision_range(radius:int):
	$VisionArea.set_tracking_radius(radius)
	vision_radius = radius
	
func set_close_range(radius:int):
	$CloseArea.set_tracking_radius(radius)
	close_radius = radius

func take_damage(damage:int, from:Actor = null):
	hp -= damage
	GameEngine.message(display_name + " takes " + String(damage) + " damage.")
	if hp <= 0:
		if from: from.killed(self)
		died()
	else:
		damage_popup(true, damage)

func attack(who:Actor, attack, damage_modifier = 0):
	who.mood = Mood.HOSTILE
	next_action = GameEngine.time_in_minutes + attack.use_time
	
	print(display_name + " attacks " + who.display_name + " with " + attack.display_name)
	if GameEngine.roll_test(GameEngine.D(20), who.ac - to_hit_modifier - attack.to_hit_modifier, 20):
		var damage_dice = attack.damage_dice
		damage_dice.plus += damage_modifier
		var damage = GameEngine.roll(damage_dice)
		who.take_damage(damage, self)
	else:
		who.damage_popup(false)

func died():
	GameEngine.message(display_name + " died!")
	for i in get_children():
		if i is InventoryThing: GameEngine.add_node_at(i, position)
		if i is Currency and i.n_units > 0: GameEngine.add_node_at(i, position)
		queue_free()
	
func killed(_who:Actor):
	pass

func has_a(_node): return false

func player_is_in_sight():
	var space_rid = get_world_2d().space
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	var in_sight = space_state.intersect_ray(position, GameEngine.player.position, [self])
	return in_sight and in_sight.collider == GameEngine.player

func player_is_visible():
	if $VisionArea.player_is_in_area:
		if player_is_in_sight():
			player_position = GameEngine.player.position
			return true
	return false

func default_process():
	if GameEngine.is_paused(): return
	if mood == Mood.HOSTILE and $CloseArea.player_is_in_area:
		process_attack()
	elif mood == Mood.NEUTRAL and player_is_visible():
		mood = Mood.HOSTILE

func select_attack():
	var has_attacks = false
	for attack in get_children():
		if attack is Attack:
			has_attacks = true
			if attack.may_use():
				attack.used_by(self)
				return attack
	if not has_attacks:
		punch.used_by(self)
		return punch
	return null

func process_attack():
	var attack = select_attack()
	if attack: attack(GameEngine.player, attack)

func default_physics_process(delta):
	if mood == Mood.HOSTILE and player_is_visible():
		var dir:Vector2 = player_position - position
		if dir.length() > 5:
			var move_vector = dir.normalized() * delta * GameEngine.feet_to_pixels(speed)
			var _collision = move_and_collide(move_vector)

func _process(_delta):
	if GameEngine.time_in_minutes < next_action: return
	if GameEngine.is_paused(): return
	default_process()

func _physics_process(delta):
	if GameEngine.time_in_minutes < next_action: return
	if GameEngine.is_paused(): return
	default_physics_process(delta)
	
func damage_popup(hit, damage = 0):
	$DamagePopup/Damage.text = String(damage)
	$DamagePopup/Damage.visible = hit
	$DamagePopup/Hit.visible = hit
	$DamagePopup/Miss.visible = not hit
	$DamagePopup.visible = true
	$DamagePopupTimer.start(0.5)
	pass

func _on_DamagePopupTimer_timeout():
	$DamagePopup.visible = false
