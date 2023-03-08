extends CharacterBody2D
class_name Actor

signal actor_died

enum Mood { FRIENDLY = 0, NEUTRAL = 1, HOSTILE =2 }

@export_category("Text")
@export var display_name:String : get = get_display_name
@export var long_description:String
@export var random_movement_path: String
@export_category("Stats")
@export var ac = 10
@export var hp = 1
@export var max_hp = 1
@export var attack_modifier = 0
@export var attacks_per_round = 1.0
@export var speed_feet_per_round = 30
@export var xp_value = 1
@export var close_radius = 3
@export var vision_radius = 60
@export var mood:Mood = Mood.FRIENDLY

@onready var navigation : NavigationAgent2D = $NavigationAgent2D
@onready var equipment = $Equipment

var next_action = 0
var next_move = 0
var random_movement
var conversation

var travel_distance_fudge_factor = 2
var attacks:Array[Attack]

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
	navigation.connect("velocity_computed", Callable(self, "velocity_computed"))
	navigation.max_speed = travel_distance_in_pixels(1)
	# Force the navigation layer if doing random movement
	random_movement = get_node(random_movement_path) if random_movement_path != "" else null
	if random_movement:
		navigation.navigation_layers = random_movement.navigation_layer
		random_movement.actor = self
	set_vision_range(vision_radius)
	set_close_range(close_radius)
	if display_name == "": display_name = name
	for c in get_children():
		if c is ActorConversation: conversation = c
	if random_movement: set_destination(random_movement.new_destination())

func get_display_name():
	return display_name

func set_mood(new_mood):
	mood = new_mood

func make_hostile(): set_mood(Mood.HOSTILE)
func make_neutral(): set_mood(Mood.NEUTRAL)
func make_friendly(): set_mood(Mood.FRIENDLY)

func is_hostile(): return mood == Mood.HOSTILE
func is_neutral(): return mood == Mood.NEUTRAL
func is_friendly(): return mood == Mood.FRIENDLY

func stop_navigating():
	set_destination(global_position)

func set_destination(pos):
	navigation.target_position = pos

func capitalized_display_name():
	if display_name != "": return capitalized(display_name)
	else: return capitalized(name)

func capitalized(s):
	return s.substr(0, 1).to_upper() + s.substr(1)
	
func description():
	return long_description
	
func set_vision_range(radius:int):
	$VisionArea.set_tracking_radius(radius)
	vision_radius = radius

func set_close_range(radius:int):
	$CloseArea.set_tracking_radius(radius)
	close_radius = radius

func take_damage(damage:int, from:Actor = null, cause = null, show_popup = true) -> void:
	var message
	if from: message = "%s hits %s for" % [from.capitalized_display_name(), get_display_name()]
	else: message = "%s takes"
	message += " %d damage" %  damage
	if cause: message += " with a %s" % (cause if cause is String else cause.display_name)
	GameEngine.message(message)
	hp -= damage
	if show_popup: damage_popup(true, damage, from)
	if hp <= 0:
		died()
		if from: from.killed(self)

func give_hit_points(hp_given):
	var old_hp = hp
	hp += hp_given
	if hp > max_hp: hp = max_hp
	GameEngine.message("%s gained %d HPs" % [ display_name, hp - old_hp])

func was_attacked_by(_attacker):
	if mood != Mood.HOSTILE and self != GameEngine.player:
		set_mood(Mood.HOSTILE)

func died():
	GameEngine.message("%s died!" % capitalized_display_name())
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

func can_see_actor_from(actor, pos):
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	return GameEngine.ray_from_point(space_state, pos, actor.global_position, 1) == actor

func can_see_player_from(pos):
	return can_see_actor_from(GameEngine.player, pos)

func is_a_good_place_to_place(pos):
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	var physics_parameters = PhysicsPointQueryParameters2D.new()
	physics_parameters.position = pos
	
	var colliding = space_state.intersect_point(physics_parameters)
	if  colliding != null and colliding.size() > 0:
		return false
	return can_see_player_from(pos)

func default_process():
	if is_hostile(): process_attack()

func get_attacks():
	attacks = []
	for attack in get_children():
		if attack is Attack: attacks.append(attack)
	if attacks.size() == 0: add_punch()

func add_punch():
	var punch = load("%s/Combat/punch.tscn" % GameEngine.config.root).instantiate()
	add_child(punch)
	attacks.append(punch)

func i_would_attack(target : Actor, _pass_number) -> bool:
	return target == GameEngine.player

func select_attack_target(attack : Attack) -> Actor:
	for pass_number in range(2):
		var targets = []
		for target in $VisionArea.actors_in_area():
			if i_would_attack(target, pass_number) and attack.may_attack(self, target) and $VisionArea.is_in_sight(target):
				targets.push_back(target)
		if targets.size() > 0: return targets[randi() % targets.size()]
	return null

func try_to_attack(attack:Attack) -> bool:
	var target = select_attack_target(attack)
	if not target: return false
	next_action = GameEngine.time_in_minutes + attack.use_time/attacks_per_round
	if self != GameEngine.player:
		# Hack: let the player move so the UI doesn't suck
		#       don't let the monster move so they keep their ranged attack ability
		next_move = GameEngine.time_in_minutes + attack.minutes_between_uses
	attack.attack(self, target)
	return true

func process_attack() -> void:
	if attacks.size() == 0: get_attacks()
	for attack in attacks:
		if try_to_attack(attack): return

func default_physics_process(delta):
	if not is_friendly() and player_is_in_sight():
		set_destination(GameEngine.player.global_position)
		if is_neutral() and not conversation: make_hostile()

	if random_movement and navigation.is_navigation_finished():
		set_destination(random_movement.new_destination())

	var next_location = navigation.get_next_path_position()
	if not navigation.is_navigation_finished():
		var v = global_position.direction_to(next_location) * travel_distance_in_pixels(delta)
		if navigation.avoidance_enabled:
			navigation.set_velocity(v)
		else:
			velocity_computed(v)

func velocity_computed(v):
	var collision:KinematicCollision2D = move_and_collide(v)
	var collider = collision.get_collider() if collision else null
	if collider and collider != GameEngine.player and not collider is Missile:
		var _err = move_and_collide(collision.get_remainder().bounce(collision.get_normal()))

func travel_distance_in_pixels(delta_elapsed_time):
	var minutes = GameEngine.real_time_to_game_time(delta_elapsed_time)
	var pixels_per_minute = GameEngine.feet_to_pixels(speed_feet_per_round)*6  # 10 rounds per minute
	return pixels_per_minute * minutes / travel_distance_fudge_factor

func _process(_delta):
	if next_action == null or GameEngine.time_in_minutes < next_action: return
	if GameEngine.is_paused(): return
	default_process()

func _physics_process(delta):
	if next_move == null: return
	if GameEngine.time_in_minutes < next_move or GameEngine.is_paused():
		#var _next_location = navigation.get_next_path_position()
		return
	default_physics_process(delta)

func create_damage_popup(hit:bool, damage:int, from:Actor) -> DamagePopup:
	var delta = Vector2(0, -24)
	if from and global_position.x >= from.global_position.x - 24 and global_position.x <= from.global_position.x + 24:
		if global_position.y > from.global_position.y:
			delta = -delta
	var filename = GameEngine.config.damage_popup if GameEngine.config.damage_popup else "%s/Actors/damage_popup.tscn" % GameEngine.config.root
	var popup:DamagePopup = GameEngine.instantiate(GameEngine.current_scene, filename, null, global_position + delta)
	popup.setup(hit, damage, delta)
	return popup

func damage_popup(hit:bool, damage:int, from:Actor) -> void:
	create_damage_popup(hit, damage, from).run()

func get_equipment_in_group(group:String) -> Array[InventoryThing]:
	var in_group:Array[InventoryThing] = []
	for thing in equipment.get_children():
		if thing.is_in_group(group):
			in_group.append(thing)
	return in_group
