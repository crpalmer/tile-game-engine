extends SubScene

var n_monsters = 0

func get_persistent_data():
	return {
		"n_monsters": n_monsters
	}.merge(.get_persistent_data())

func load_persistent_data(p):
	.load_persistent_data(p)
	n_monsters = p.n_monsters

func should_return_from_scene():
	return n_monsters == 0

func _ready():
	for c in get_children():
		if c is Actor:
			c.connect("actor_died", self, "on_monster_died")
			n_monsters += 1

func on_monster_died(_name, _display_name):
	n_monsters -= 1
