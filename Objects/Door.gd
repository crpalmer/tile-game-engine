extends Thing
class_name Door

@export var is_locked = false
@export var is_closed = true
@export var key_group:String
@export var occluders_flipped = false

@onready var open = get_node_or_null("Open")
@onready var closed = get_node_or_null("Closed")
@onready var lock = get_node_or_null("Lock")
@onready var blocker_open = get_node_or_null("BlockerOpen")
@onready var blocker_closed = get_node_or_null("BlockerClosed")

func get_persistent_data():
	var p = super.get_persistent_data()
	p.merge({
		"is_locked": is_locked,
		"is_closed": is_closed
	})
	return p

func load_persistent_data(p):
	super.load_persistent_data(p)
	is_locked = p.is_locked
	is_closed = p.is_closed
	ensure_state()

func _ready():
	super()
	ensure_state()

func set_visibility(node, value, condition):
	if node and value == condition: node.visible = value

func set_disabled(node, value, condition):
	if node and value == condition: node.disabled = value

func ensure_state():
	ensure_state_if(true)
	ensure_state_if(false)

func ensure_state_if(this_visible):
	set_visibility(open, not is_closed, this_visible)
	set_visibility(closed, is_closed, this_visible)
	set_visibility(lock, is_locked, this_visible)
	set_disabled(blocker_open, is_closed, not this_visible)
	set_disabled(blocker_closed, not is_closed, not this_visible)
	
func used_by(who):
	if who is Actor:
		if is_locked:
			if who.has_a_thing_in_group(key_group): is_locked = false
			else: GameEngine.message("The %s appears to be locked." % display_name)
		if not is_locked:
			is_closed = not is_closed
		call_deferred("ensure_state")
