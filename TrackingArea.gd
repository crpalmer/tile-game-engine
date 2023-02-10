extends Area2D
class_name TrackingArea

export var tracking_radius = 30

var in_area:Dictionary

func _ready():
	var _err
	_err = connect("area_entered", self, "area_entered")
	_err = connect("body_entered", self, "body_entered")

	_err = connect("area_exited", self, "area_exited")
	_err = connect("body_exited", self, "body_exited")

	update_tracking_radius()

func set_tracking_radius(radius:int):
	tracking_radius = radius
	update_tracking_radius()

func update_tracking_radius():
	$Circle.shape.set_radius(GameEngine.feet_to_pixels(tracking_radius))

func area_entered(who_entered):
	record_area(get_parent(), who_entered, true)

func area_exited(who_exited):
	record_area(get_parent(), who_exited, false)

func body_entered(who_entered):
	record_area(get_parent(), who_entered, true)

func body_exited(who_exited):
	record_area(get_parent(), who_exited, false)

func is_a_child_of_an_actor(node):
	node = node.get_parent()
	while node != null:
		if node is Actor: return true
		node = node.get_parent()
	return false

func is_trackable(tracker, trackee):
	if not trackee.is_in_group("Trackables"): return false
	if trackee == tracker: return false
	if is_a_child_of_an_actor(trackee): return false  # don't track anyone's inventory!
	return true

func record_area(tracker, trackee, is_entered):
	if is_trackable(tracker, trackee):
		var count = in_area[trackee] if in_area.has(trackee) else 0
		count += +1 if is_entered else -1
		if count <= 0: var _ignore = in_area.erase(trackee)
		else: in_area[trackee] = count
	#	print(name + " " + get_parent().name + " : " + String(in_area))
	#else:
	#	print("Not tracking %s / %s" % [get_parent().name, name])

# Inventory things shouldn't block our view, look through everything that
# doesn't exist on layer 1 (our physical world)
func ignorable(thing):
	return thing is CollisionObject2D and (thing.collision_layer & 1) == 0

func get_LOS_ignore(tracker, trackee):
	var ignore = [ tracker ]
	for c in tracker.get_children():
		if c.is_in_group("Trackables"): ignore.push_back(c)
	for tracked in in_area:
		if tracked != trackee and ignorable(tracked): ignore.push_back(tracked)
	return ignore

func is_self_or_child_of(node, target):
	while node != null:
		if node == target: return true
		node = node.get_parent()
	return false

func LOS(tracker, trackee):
	var ignore = get_LOS_ignore(tracker, trackee)
	var space_rid = get_world_2d().space
	var space_state = Physics2DServer.space_get_direct_state(space_rid)

	# See if we are on top of each other
	var colliding = space_state.intersect_point(tracker.position, 32, ignore)
	if colliding:
		for collision in colliding:
			if collision.collider == trackee: return true

	# Check a ray straight at the object
	var in_sight = space_state.intersect_ray(tracker.global_position, trackee.global_position, ignore)
	if in_sight and is_self_or_child_of(in_sight.collider, trackee): return true

	# If that doesn't work, try shooting rays at all its active collision shapes
	# For example a door has a position but open and closed have different collision shapes!
	for c in trackee.get_children():
		if (c is CollisionShape2D or c is CollisionPolygon2D) and not c.disabled:
			in_sight = space_state.intersect_ray(tracker.global_position, c.global_position, ignore)
			if in_sight and in_sight.collider == trackee: return true
	return false

func in_sight():
	var tracker = get_parent()
	var things = []
	for trackee in in_area:
		if LOS(tracker, trackee): things.push_back(trackee)
	return things

func is_in_sight(who):
	var tracker = get_parent()
	return in_area.has(who) and LOS(tracker, who)

func player_is_in_sight():
	return is_in_sight(GameEngine.player)

func n_hostiles():
	var n = 0
	for thing in in_area:
		if thing.has_method("is_hostile") and thing.is_hostile(): n += 1
	return n
