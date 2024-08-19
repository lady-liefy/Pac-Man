### global.gd
extends Node2D

@export var game_speed := 1.0 : set = _set_game_speed
@export var speed_factor := 0.3
@export var tile_size := 8

@onready var ghost_stats := {
	0 : Vector2(112, 116),
	1 : Vector2(112, 116), # NEED TO FIX POSITIONS
	2 : Vector2(112, 116),
	3 : Vector2(112, 116)
}
@onready var scatter_time := {
	1: [7, 7, 5, 5],
	2: [7, 7, 5, 0.016],
	5: [5, 5, 5, 0.016]
}
@onready var chase_time  := {
	1: [20, 20, 20, -1],
	2: [20, 20, 1033, -1],
	5: [20, 20, 1037, -1]
}

static var initial_position := Vector2(112, 212)
static var scene_paths = {
	"World": preload("res://scenes/world.tscn"),
	"Main_Menu": preload("res://scenes/main_menu.tscn")
}

var levels = {
	0 : preload("res://scenes/level.tscn") #,
#	1 : preload("res://scenes/level_1.tscn"),
#	2 : preload("res://scenes/level_2.tscn")
}
var current_level_id := 0
var max_lives   : int = 3

var game_real_size   := Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"),
								 ProjectSettings.get_setting("display/window/size/viewport_height"))
var game_window_size := DisplayServer.window_get_size()

func _ready() -> void:
	Events.game_won.connect(on_game_won)
	Events.game_over.connect(on_game_over)
	_set_game_speed(game_speed)

func _set_game_speed(speed : float) -> void:
	game_speed = speed

func _reset() -> void:
	ScoreManager.set_current_score(0)
	ScoreManager.set_current_lives(max_lives)

func _clear_level() -> void:
	current_level_id = 0
	ScoreManager.max_lane = 0

func on_game_over() -> void:
	get_tree().paused = true
	_set_game_speed(1)
	
	_clear_level()
	_reset()

func on_game_won() -> void:
	_set_game_speed(game_speed + speed_factor)
	_clear_level()

func screen_wrap(body : CharacterBody2D) -> void:
	if body.global_position.x < (0 - tile_size):
		body.global_position.x = game_real_size.x
	elif body.global_position.x > (game_real_size.x + tile_size):
		body.global_position.x = 0
