### world.gd
extends Node

@onready var player : Player = $Player
@onready var current_level : Node2D = $Level0

var player_prefab = preload("res://scenes/player.tscn")
var next_level_id := 0

func _ready() -> void:
	Global.current_level_id = next_level_id
	
	reset()
	_initialize_signals()

func _initialize_signals() -> void:
	Events.player_died.connect(on_player_died)
	Events.level_won.connect(on_level_won)

func clear_level() -> void:
	if current_level != null and is_instance_valid(current_level):
		current_level.queue_free()
	for pacman in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(pacman):
			pacman.queue_free()
	
func reset() -> void:
	clear_level()
	
	await get_tree().process_frame
	
	if not get_tree().get_nodes_in_group("player"):
		spawn_player()
	
	# Create the next level
	var next_level = Global.levels[next_level_id].instantiate()
	add_child(next_level)
	current_level = next_level

func on_player_died() -> void:
	player = null
	
	if ScoreManager.current_lives > 0:
		spawn_player()
	else:
		Events.emit_signal("game_over")
		next_level_id = 0
		Global.current_level_id = next_level_id
		reset()

func on_level_won() -> void:
	next_level_id += 1
	Global.current_level_id = next_level_id
	
	player.queue_free()
	player = null

	if next_level_id == Global.levels.size():
		next_level_id = 0
		ScoreManager.set_current_lives(Global.max_lives)
		reset()
	else :
		await Events.next_level
		reset()

func spawn_player() -> void:
	player = player_prefab.instantiate()
	call_deferred("add_child", player)
	
	if not player.is_in_group("player"):
		player.add_to_group("player")
	
	player.global_position = Global.initial_position
