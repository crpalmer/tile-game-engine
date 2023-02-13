extends KinematicBody2D
class_name Actor

signal actor_died

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

onready var navigation : NavigationAgent2D = $Navigation
var random_movement
var conversation

var travel_distance_fudge_factor = 2
var punch = load("%s/Actors/Punch.tscn" % GameEngine.config.root).instance()

var place_near_actor = null

func get_persistent_data():
	var p = {
		"hp": hp,
		"max_hp": max_hp,
		"mood": mood
	}
	return p
	
func load_persistent_data(p):
	yield(self, "ready")
	hp = p.hp
	max_hp = p.max_hp
	mood = p.mood

func _ready():
	add_to_group("PersistentNodes")
	add_to_group("Trackables")
	# We don't have the logic for avoidance_enabled in here
	navigation.avoidance_enabled = false
	randomize()
	$VisionArea.visible = true
	$CloseArea.visible = true
	set_vision_range(vision_radius)
	set_close_range(close_radius)
	var _err = navigation.connect("velocity_computed", self, "_on_Navigation_velocity_computed")
	navigation.max_speed = travel_distance_in_pixels(1)
	if not display_name or display_name == "": display_name = name
	for c in get_children():
		if c is ActorRandomMovement: random_movement = c
		if c is ActorConversation: conversation = c
	if random_movement: set_destination(random_movement.new_destination())
	else: stop_navigating()

func was_spawned():
	remove_from_group("PersistentNodes")
	add_to_group("PersistentSpawned")

func set_mood(new_mood):
	mood = new_mood

func make_hostile(): set_mood(Mood.HOSTILE)
func make_neutral(): set_mood(Mood.NEUTRAL)
func make_friendly(): set_mood(Mood.FRIENDLY)

func is_hostile(): return mood == Mood.HOSTILE
func is_neutral(): return mood == Mood.NEUTRAL
func is_friendly(): return mood == Mood.FRIENDLY

func set_position(pos):
	global_position = pos
	stop_navigating()

func stop_navigating():
	navigation.set_target_location(global_position)

func set_destination(pos):
	#GameEngine.message("%s to (%f, %f)" % [ display_name, pos.x, pos.y ])
	if random_movement: pos = random_movement.clamp_to_area(pos)
	var old = navigation.get_target_location()
	if (old - pos).length() > GameEngine.feet_to_pixels(1):
		navigation.set_target_location(pos)
		print_debug(display_name, ": ", pos, " path ", navigation.get_nav_path())

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
	queue_free()
	emit_signal("actor_died", name, display_name)

func killed(_who:Actor):
	pass

func player_is_close():
	return $CloseArea.player_is_in_sight()

func player_is_in_sight():
	return $VisionArea.player_is_in_sight()

func is_in_sight(who):
	return $VisionArea.is_in_sight(who)

func start_conversation():
	if conversation: conversation.start()

func place_near(who):
	place_near_actor = who

func can_see_actor_from(actor, position):
	var space_rid = get_world_2d().space
	var space_state = Physics2DServer.space_get_direct_state(space_rid)

	# See if we are on top of each other
	var colliding = space_state.intersect_point(position, 32)
	if colliding:
		for collision in colliding:
			if collision.collider == actor: return true

	# Check a ray straight at the object
	var in_sight = space_state.intersect_ray(position, actor.global_position)
	return in_sight and in_sight.collider == actor

func can_see_player_from(position):
	return can_see_actor_from(GameEngine.player, position)

func physics_place_near():
	var who = place_near_actor
	place_near_actor = null

	var x_dir = [0, 1, -1]
	var y_dir = [0, 1, -1]
	x_dir.shuffle()
	y_dir.shuffle()
	for distance in [ 5, 3, 1]:
		for x in x_dir:
			for y in y_dir:
				if x != 0 or y != 0:
					var place = who.global_position + Vector2(x, y)*GameEngine.feet_to_pixels(distance)
					if can_see_player_from(place):
						GameEngine.message("Placed %s at (%f, %f)" % [ display_name, place.x, place.y ])
						set_position(place)
						return true
					else:
						GameEngine.message("Failed %s at (%f, %f)" % [ display_name, place.x, place.y ])

func place_near_player():
	place_near(GameEngine.player)

func default_process():
	if mood == Mood.HOSTILE and $CloseArea.player_is_in_sight():
		process_attack()

func select_attack():
	var has_attacks = false
	for attack in get_children():
		if attack is Attack:
			has_attacks = true
			if attack.may_use():
				attack.used_by(self)
				return attack
	if not has_attacks and punch.may_use():
		punch.used_by(self)
		return punch
	return null

func process_attack():
	var attack = select_attack()
	if attack: attack(GameEngine.player, attack)

func default_physics_process(delta):
	if place_near_actor != null:
		physics_place_near()

	if not is_friendly() and $VisionArea.player_is_in_sight():
		set_destination(GameEngine.player.global_position)
		if is_neutral() and not conversation: make_hostile()

	if random_movement and navigation.is_navigation_finished():
		set_destination(random_movement.new_destination())

	var next_location = navigation.get_next_location()
	if not navigation.is_navigation_finished():
		var velocity = (next_location - global_position).normalized() * travel_distance_in_pixels(1)
		var _err = move_and_slide(velocity)

func _on_Navigation_velocity_computed(safe_velocity):
	var _collision = move_and_slide(safe_velocity)

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
