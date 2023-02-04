extends Resource
class_name GameConfiguration

export(String, DIR) var root = "res://GameEngine"
export(String, FILE) var player = "res://Player.tscn"
export(String, FILE) var entry_scene
export(String) var entry_point
export(String) var fade_animation
export(float) var pixels_per_foot = 16.0
export(float, 23) var game_start_time_in_hours = 0.0
export(Array, String, FILE) var currency
