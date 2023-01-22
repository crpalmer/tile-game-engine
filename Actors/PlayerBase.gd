extends Actor
class_name PlayerBase

var HUD
var inventory = []

func _ready():
	enter_current_scene()
	
func enter_current_scene():
	HUD = $Camera2D/HUD
	HUD.update_player_stats(self)
	$Camera2D/AmbientLight.set_radius(vision_radius)
	
func take_damage(damage:int, from):
	.take_damage(damage, from)
	HUD.update_player_stats(self)

func killed(who):
	xp += who.xp_value
	HUD.update_player_stats(self)
	
func process(_delta):
	if GameEngine.paused: return

	if Input.is_action_just_released("attack"): process_attack()
	if Input.is_action_just_released("use"): process_use()
	if Input.is_action_just_released("look"): process_look()
	if Input.is_action_just_released("talk"): process_talk()
	
func physics_process(delta):
	var dir = Vector2(0, 0)
	if Input.is_action_pressed("left"): dir.x -= 1
	if Input.is_action_pressed("right"): dir.x += 1
	if Input.is_action_pressed("up"): dir.y -= 1
	if Input.is_action_pressed("down"): dir.y += 1
	
	if dir.length() > 0:
		var moved = dir.normalized()*delta*GameEngine.feet_to_pixels(speed)
		var _collision:KinematicCollision2D = move_and_collide(moved)

func process_attack():
	var in_area:Array = $CloseArea.who_is_in_area()
	if in_area.size() > 0: attack(in_area[randi() % in_area.size()])

func process_use():
	for use_on in $CloseArea.who_is_in_area():
		if use_on is InventoryThing: add_to_inventory(use_on)
		elif use_on is Thing: use_on.used_by(self)

func process_look():
	var what = ""
	for thing in $CloseArea.who_is_in_area():
		if what.length() > 0: what = what + ", "
		what = what + thing.to_string()
	if what.length() == 0: what = "nothing"
	show_message("You see: " + what)

func process_talk():
	for thing in $CloseArea.who_is_in_area():
		var conversation = thing.get_node_or_null("Conversation")
		if conversation:
			conversation.start()
			return

func add_to_inventory(to_add):
	show_message("You picked up " + to_add.to_string())
	to_add.get_parent().remove_child(to_add)
	for i in inventory:
		if i == to_add:
			i.n = i.n + to_add.n
			return
	inventory.push_back(to_add)

func has_a(node):
	for i in inventory: if i == node: return true
	return false
	
func died():
	print_debug("Player died!")
	$Sprite.visible = false

func show_message(message):
	HUD.message(message)

func set_ambient_light(percent):
	$Camera2D/AmbientLight.set_brightness(percent)

func set_light_source(radius, brightness):
	$Camera2D/LightSource.set_radius(radius)
	$Camera2D/LightSource.set_brightness(brightness)
