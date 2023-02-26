extends Resource
class_name GameConfiguration

@export_dir var root = "res://GameEngine"
@export_file var player = "res://Player.tscn"
@export_file var damage_popup
@export var entry_scene:String
@export var entry_point: String
@export var fade_color: Color = Color.BLACK
@export var rest_time_accelerator: float = 600.0
@export var resting_alpha = 0.75 # (float, 1)
@export var pixels_per_foot: float = 16.0
@export var game_start_time_in_hours = 0.0 # (float, 23)
@export var currency:Array
