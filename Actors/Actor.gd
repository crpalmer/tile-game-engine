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

func _ready():
	randomize()
	$VisionArea.visible = true
	$CloseArea.visible = true
	set_vision_range(vision_radius)
	set_close_range(close_radius)
	player_position = position
	if not display_name or display_name == "": display_name = name

func looked_at():
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

func attack(who:Actor, attack):
	who.mood = Mood.HOSTILE
	next_action = GameEngine.time + attack.use_time
	
	print(display_name + " attacks " + who.display_name + " with " + attack.display_name)
	if GameEngine.roll_test(GameEngine.D(20), who.ac - to_hit_modifier - attack.to_hit_modifier, 20):
		var damage = GameEngine.roll(attack.damage_dice)
		who.take_damage(damage, self)
	else:
		who.damage_popup(false)

func died():
	GameEngine.message(display_name + " died!")
	for i in get_children():
		if i is InventoryThing: GameEngine.add_node_at(i, position)
		queue_free()
	
func killed(_who:Actor):
	pass

func has_a(_node): return false

func player_is_visible():
	if $VisionArea.player_is_in_area:
		var space_rid = get_world_2d().space
		var space_state = Physics2DServer.space_get_direct_state(space_rid)
		var in_sight = space_state.intersect_ray(position, GameEngine.player.position, [self])
		if in_sight.collider == GameEngine.player:
			player_position = GameEngine.player.position
			return true
	return false

func default_process(_delta):
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
			var collision = move_and_collide(move_vector)
			if collision and collision.collider != GameEngine.player:
				var _collision = move_and_collide(collision.remainder.length() * collision.normal)

func process(delta):
	default_process(delta)

func physics_process(delta):
	default_physics_process(delta)

func _process(delta):
	if GameEngine.time < next_action: return
	if GameEngine.is_paused(): return
	process(delta)

func _physics_process(delta):
	if GameEngine.time < next_action: return
	if GameEngine.is_paused(): return
	physics_process(delta)
	
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

func to_string():
	return display_name
