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
export(String) var random_movement_path

onready var navigation : NavigationAgent2D = $Navigation
var random_movement
var conversation

var travel_distance_fudge_factor = 2
var punch = load("%s/Actors/Punch.tscn" % GameEngine.config.root).instance()

func get_persistent_data():
	var c = conversation.get_persistent_data() if conversation else null
	var rm = random_movement.get_persistent_data() if random_movement else null
	var p = {
		"hp": hp,
		"max_hp": max_hp,
		"mood": mood,
		"conversation": c,
		"random_movement": rm
	}
	return p
	
func load_persistent_data(p):
	hp = p.hp
	max_hp = p.max_hp
	mood = p.mood
	if conversation: conversation.load_persistent_data(p.conversation)
	if random_movement: random_movement.load_persistent_data(p.random_movement)

func _ready():
	add_to_group("PersistentNodes")
	add_to_group("Trackables")
	add_to_group("Ephemeral")
	# We don't have the logic for avoidance_enabled in here
	navigation.avoidance_enabled = false
	navigation.max_speed = travel_distance_in_pixels(1)
	# Force the navigation layer if doing random movement
	random_movement = get_node(random_movement_path) if random_movement_path != "" else null
	if random_movement:
		navigation.navigation_layers = random_movement.navigation_layer
		random_movement.actor = self
	$VisionArea.visible = true
	$CloseArea.visible = true
	set_vision_range(vision_radius)
	set_close_range(close_radius)
	if not display_name or display_name == "": display_name = name
	for c in get_children():
		if c is ActorConversation: conversation = c
	if random_movement: set_destination(random_movement.new_destination())
	else: stop_navigating()

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
	damage_popup(true, damage, from)
	if hp <= 0:
		died()
		if from: from.killed(self)

func give_hit_points(hp_given):
	hp += hp_given
	if hp > max_hp: hp = max_hp
	GameEngine.message("%s gained %d HPs" % [ display_name, hp_given ])

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
		who.damage_popup(false, 0, who)

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
	if random_movement and not random_movement.may_see_player():
		return false
	return $CloseArea.player_is_in_sight()

func player_is_in_sight():
	if random_movement and not random_movement.may_see_player():
		return false
	return $VisionArea.player_is_in_sight()

func is_in_sight(who):
	return $VisionArea.is_in_sight(who)

func start_conversation():
	if conversation: conversation.start()

func can_see_actor_from(actor, position):
	var space_rid = get_world_2d().space
	var space_state = Physics2DServer.space_get_direct_state(space_rid)

	# See if we are on top of each other
	var colliding = space_state.intersect_point(position, 32, [], 1)
	if colliding:
		for collision in colliding:
			if collision.collider == actor: return true

	# Check a ray straight at the object colliding only on layer 1
	var in_sight = space_state.intersect_ray(position, actor.global_position, [], 1)
	return in_sight and in_sight.collider == actor

func can_see_player_from(position):
	return can_see_actor_from(GameEngine.player, position)

func is_a_good_place_to_place(position):
	var space_rid = get_world_2d().space
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	var colliding = space_state.intersect_point(position, 32, [], 1)
	if  colliding != null and colliding.size() > 0:
		return false
	return can_see_player_from(position)

func place_near_internal(who, exclude):
	assert(not is_physics_processing())
	for distance in range(2, 5):
		var x_dir = range(-distance, distance*2+1, 2)
		x_dir.append(0)
		var y_dir = x_dir.duplicate()
		x_dir.shuffle()
		y_dir.shuffle()
		for x in x_dir:
			for y in y_dir:
				if x != 0 or y != 0:
					var place = who.global_position + Vector2(x, y) * GameEngine.feet_to_pixels(1)
					if not exclude.has(place) and is_a_good_place_to_place(place):
						set_position(place)
						return

func place_near(who, exclude = []):
	var physics_process = is_physics_processing()
	if physics_process:
		set_physics_process(false)
		yield(get_tree(), "idle_frame")
	place_near_internal(who, exclude)
	if physics_process:
		yield(get_tree(), "idle_frame")
		set_physics_process(true)

func place_near_player(exclude = []):
	place_near(GameEngine.player, exclude)

func default_process():
	if mood == Mood.HOSTILE and player_is_close():
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
	if not is_friendly() and player_is_in_sight():
		set_destination(GameEngine.player.global_position)
		if is_neutral() and not conversation: make_hostile()

	if random_movement and navigation.is_navigation_finished():
		set_destination(random_movement.new_destination())

	var next_location = navigation.get_next_location()
	if not navigation.is_navigation_finished():
		var velocity = (next_location - global_position).normalized() * travel_distance_in_pixels(delta)
		var collision:KinematicCollision2D = move_and_collide(velocity)
		if collision and collision.collider != GameEngine.player:
			var _err = move_and_collide(collision.remainder.bounce(collision.normal.rotated(randi()%30 - 15)))

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
	
func damage_popup(hit, damage, who):
	var delta = Vector2(0, -24)
	if who and who.global_position.x >= who.global_position.x - 24 and who.global_position.x <= who.global_position.x + 24:
		if global_position.y > who.global_position.y:
			delta = -delta
	var popup = GameEngine.instantiate(GameEngine.current_scene, "%s/Actors/DamagePopup.tscn" % GameEngine.config.root, null, global_position + delta)
	popup.start(hit, damage, delta)
