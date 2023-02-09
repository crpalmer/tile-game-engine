extends KinematicBody2D
class_name Actor

signal actor_removed

enum Mood { FRIENDLY = 0, NEUTRAL = 1, HOSTILE =2 }

export var display_name:String
export var long_description:String
export var ac = 10
export var hp = 1
export var max_hp = 1
export var to_hit_modifier = 0
export var speed_feet_per_round = 30
export var xp_value = 1
export var close_radius = 3
export var vision_radius = 60
export var mood = Mood.FRIENDLY setget set_mood
export var next_action = 0

onready var navigation = $Navigation
var random_movement

var travel_distance_fudge_factor = 2
var punch = load("%s/Actors/Punch.tscn" % GameEngine.config.root).instance()

func get_persistent_data():
	var p = {
		"hp": hp,
		"max_hp": max_hp,
		"mood": mood
	}
	if get_node_or_null("Conversation"): p.merge({ "conversation": $Conversation.get_persistent_data()})
	return p
	
func load_persistent_data(p):
	yield(self, "ready")
	hp = p.hp
	max_hp = p.max_hp
	if mood == Mood.HOSTILE: GameEngine.n_hostile -= 1
	mood = p.mood
	if mood == Mood.HOSTILE: GameEngine.n_hostile += 1
	if get_node_or_null("Conversation"): $Conversation.load_persistent_data(p.conversation)

func _ready():
	add_to_group("PersistentActors")
	add_to_group("Trackables")
	randomize()
	$VisionArea.visible = true
	$CloseArea.visible = true
	set_vision_range(vision_radius)
	set_close_range(close_radius)
	navigation.connect("velocity_computed", self, "_on_Navigation_velocity_computed")
	navigation.max_speed = travel_distance_in_pixels(1)
	if not display_name or display_name == "": display_name = name
	if mood == Mood.HOSTILE: GameEngine.n_hostile += 1
	for c in get_children():
		if c is ActorRandomMovement: random_movement = c
	if random_movement: set_destination(random_movement.new_destination())

func set_mood(new_mood):
	if mood == new_mood: return
	if mood == Mood.HOSTILE: GameEngine.n_hostile -= 1
	mood = new_mood
	if mood == Mood.HOSTILE: GameEngine.n_hostile += 1

func is_hostile(): return mood == Mood.HOSTILE
func is_neutral(): return mood == Mood.NEUTRAL
func is_friendly(): return mood == Mood.FRIENDLY

func set_destination(pos):
	#GameEngine.message("%s to (%f, %f)" % [ display_name, pos.x, pos.y ])
	if random_movement: pos = random_movement.clamp_to_area(pos)
	navigation.set_target_location(pos)

func capitalized_display_name():
	return display_name[0].to_upper() + display_name.substr(1) if display_name else "<unknown>"

func description():
	return long_description
	
func set_vision_range(radius:int):
	$VisionArea.set_tracking_radius(radius)
	vision_radius = radius

func set_close_range(radius:int):
	$CloseArea.set_tracking_radius(radius)
	close_radius = radius

func take_damage(damage:int, from:Actor = null, cause = null):
	hp -= damage
	var message = "%s takes %d damage" % [ capitalized_display_name(), damage ]
	if from and from != GameEngine.player: message += " from a %s" % from.display_name
	if cause: message += " by a %s" % cause.display_name
	GameEngine.message(message)
	if hp <= 0:
		died()
		if from: from.killed(self)
	else:
		damage_popup(true, damage)

func was_attacked_by(_attacker):
	if mood != Mood.HOSTILE and self != GameEngine.player:
		set_mood(Mood.HOSTILE)

func attack(who:Actor, attack, damage_modifier = 0):
	who.was_attacked_by(self)
	next_action = GameEngine.time_in_minutes + attack.use_time
	
	if GameEngine.roll_test(who.ac, to_hit_modifier + attack.to_hit_modifier, true):
		var damage_dice = attack.damage_dice.duplicate()
		damage_dice.plus += damage_modifier
		var damage = GameEngine.roll(damage_dice)
		who.take_damage(damage, self, attack)
	else:
		GameEngine.message("%s misses %s with a %s" % [ capitalized_display_name(), who.display_name, attack.display_name ])
		who.damage_popup(false)

func died():
	GameEngine.message("%s  died!" % capitalized_display_name())
	for i in get_children():
		if i is InventoryThing: GameEngine.add_node_at(i, global_position)
		if i is Currency and i.n_units > 0: GameEngine.add_node_at(i, global_position)
	remove()

func remove():
	queue_free()
	if mood == Mood.HOSTILE: GameEngine.n_hostile -= 1
	emit_signal("actor_removed", name, display_name)

func killed(_who:Actor):
	pass

func player_is_in_sight():
	return $VisionArea.player_is_in_sight()

func is_in_sight(who):
	return $VisionArea.is_in_sight(who)

func i_see_the_player():
	set_destination(GameEngine.player.global_position)

func default_process():
	if mood == Mood.HOSTILE and $CloseArea.player_is_in_sight():
		i_see_the_player()
		process_attack()
	elif mood != Mood.FRIENDLY and $VisionArea.player_is_in_sight():
		i_see_the_player()
		set_mood(Mood.HOSTILE)

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

func default_physics_process(_delta):
	if (mood == Mood.HOSTILE or random_movement) and not navigation.is_navigation_finished():
		var next_location = navigation.get_next_location()
		var velocity = (next_location - global_position).normalized()
		if $Navigation.avoidance_enabled:
			velocity *= travel_distance_in_pixels(_delta)
			navigation.set_velocity(velocity)
		else:
			velocity *= travel_distance_in_pixels(1)
			var _err = move_and_slide(velocity)
	elif random_movement:
		set_destination(random_movement.new_destination())

func _on_Navigation_velocity_computed(safe_velocity):
	var _collision = move_and_collide(safe_velocity)

func travel_distance_in_pixels(delta_elapsed_time):
	var minutes = GameEngine.real_time_to_game_time(delta_elapsed_time)
	var pixels_per_minute = GameEngine.feet_to_pixels(speed_feet_per_round)*6  # 10 rounds per minute
	return pixels_per_minute * minutes / travel_distance_fudge_factor

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
