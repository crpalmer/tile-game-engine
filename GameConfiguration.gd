extends Resource
class_name GameConfiguration

export(String, DIR) var root = "res://GameEngine"
export(String, FILE) var player = "res://Player.tscn"
export(String, FILE) var entry_scene
export(String) var entry_point
export(Color) var fade_color = Color.black
export(float) var rest_time_accelerator = 600.0
export(float, 1) var resting_alpha = 0.75
export(float) var pixels_per_foot = 16.0
export(float, 23) var game_start_time_in_hours = 0.0
export(Array, String, FILE) var currency
