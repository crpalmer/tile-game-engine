extends SubScene

var n_monsters = 0

func get_persistent_data():
	var p = super.get_persistent_data()
	p.merge({
		"n_monsters": n_monsters
	})
	return p

func load_persistent_data(p):
	super.load_persistent_data(p)
	n_monsters = p.n_monsters

func should_return_from_scene():
	return n_monsters == 0

func _ready():
	super._ready()
	for c in get_children():
		if c is Actor:
			c.connect("actor_died",Callable(self,"on_monster_died"))
			n_monsters += 1

func on_monster_died(_name, _display_name):
	n_monsters -= 1
