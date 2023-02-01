extends Thing
class_name Door

export var is_locked = false
export var is_closed = true
export var key_group:String

func _ready():
	ensure_state()

func ensure_state():
	if has_node("Open"): $Open.visible = not is_closed
	if has_node("Lock"): $Lock.visible = is_locked
	if has_node("Closed"): $Closed.visible = is_closed
	if has_node("BlockerOpen"): $BlockerOpen.disabled = is_closed
	if has_node("BlockerClosed"): $BlockerClosed.disabled = not is_closed
	for o in get_children():
		if o is LightOccluder2D: o.visible = is_closed
	
func used_by(who):
	if who is Actor:
		if is_locked:
			if who.has_a_thing_in_group(key_group): is_locked = false
			else: GameEngine.message("The door appears to be locked")
		if not is_locked:
			is_closed = not is_closed
		ensure_state()
