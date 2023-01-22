extends Thing
class_name InventoryThing

export var n = 1
export var plural:String
export var singular:String

func _ready():
	if not singular or singular == "": singular = name
	if not plural or plural == "": plural = singular
	
func to_string():
	if n > 1: return String(n) + " " + plural
	else: return singular
