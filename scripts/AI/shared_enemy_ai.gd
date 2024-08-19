extends Node
class_name SharedEnemyAI

@onready var tile_map : TileMapLayer = get_tree().get_root().get_node("World/Level/Background")

var walkable_tiles_list: PackedVector2Array = []

func build_walkable_tiles_list() -> void:
	for tile in tile_map.get_used_cells():
		var cell_tile_data: TileData = tile_map.get_cell_tile_data(tile)
		if cell_tile_data and cell_tile_data.get_custom_data("walkable"):
			walkable_tiles_list.append(tile)

@onready var scatter_timer: Timer = $ScatterTimer
@onready var chase_timer: Timer = $ChaseTimer
@onready var frightened_timer: Timer = $FrightenedTimer
@onready var enemies_timers = { "Scatter" : scatter_timer, "Chase" : chase_timer, "Frightened" : frightened_timer}

@onready var player : Player = get_tree().get_root().get_node("World/Player")

var enemies : Array[Ghost] = []
var enemy_ai_list: Array[EnemyAI] = []

#var frightened_enemy_ais_count: int = 0
#var enemies_eaten_combo_count: int = 0

#var enemy_base_score_value: int = 200
#var enemy_score_value: int = enemy_base_score_value

#@export var numbers_displayer_scene: PackedScene = null

func on_enemy_state_set(state: EnemyAI.States, enemy: Ghost) -> void:
	match state:
		EnemyAI.States.DEAD:
			pass
#			frightened_enemy_ais_count -= 1
#			enemies_eaten_combo_count += 1
#			if frightened_enemy_ais_count >= 0:
#				if enemies_eaten_combo_count > 1:
#					enemy_score_value *= 2
#				Global.increase_score(enemy_score_value)
				
#				var numbers_displayer_instance: NumbersDisplayer = numbers_displayer_scene.instantiate()
#				numbers_displayer_instance.color = Color(0.102, 0, 0.945, 1.0)
#				numbers_displayer_instance.set_text(str(enemy_score_value))
#				numbers_displayer_instance.set_global_position(enemy.get_global_position())
#				get_tree().get_root().add_child(numbers_displayer_instance)
				
#				total_enemies_eaten_count += 1
				
#				if total_enemies_eaten_count >= enemies_to_eat_for_combo_bonus_cap:
#					Global.increase_score(combo_bonus_score_value)
		EnemyAI.States.FRIGHTENED:
			pass
#			frightened_enemy_ais_count += 1


## This value should stay the same across all EnemyAIs so it's set in this manager scene. 
## Frightened and Dead should not be assigned here as it's not handled cases to
## start with.
@export var initial_ais_state: EnemyAI.States = EnemyAI.States.SCATTER

func on_level_started() -> void:
	print ("made it!")
	var timer_started: bool = false
	for enemy_ai: EnemyAI in enemy_ai_list:
		print ("MADE IT DEEPER")
		# AI must absolutely be initialized before proceeding
		if not enemy_ai.is_initialized:
			print("waiting")
			await enemy_ai.initialized
			print("wait over")
		
		print ("DEEPEST")
		enemy_ai.state_set.connect(on_enemy_state_set)
		enemy_ai.set_state(initial_ais_state)
	
		match initial_ais_state:
			enemy_ai.States.CHASE:
				enemy_ai.background_state = enemy_ai.States.CHASE
				if not timer_started:
					timer_started = true
					chase_timer.start()
			enemy_ai.States.SCATTER:
				enemy_ai.background_state = enemy_ai.States.SCATTER
				if not timer_started:
					timer_started = true
					scatter_timer.start()
					print("scatter timer START")
			_:
				printerr(("(!) ERROR: In: " + self.get_name() + ": Uhandled state on game started!"))
				
		enemy_ai.first_initialization = false


#@onready var pellets: Pellets = get_tree().get_root().get_node("Level/Pickables/Pellets")
#@onready var enemies_to_eat_for_combo_bonus_cap = pellets.initial_power_pellets_count * enemies.initial_enemies_count
#var total_enemies_eaten_count: int = 0
#var combo_bonus_score_value: int = 12000

func _ready() -> void:
#	assert(numbers_displayer_scene != null)
	
	for ghost in get_tree().get_nodes_in_group("ghost"):
		enemies.append(ghost)
	
	for ghost: Ghost in enemies:
		enemy_ai_list.append(ghost.enemy_ai)
	
	for enemy_ai in enemy_ai_list:
		self.build_walkable_tiles_list()
		enemy_ai.state_set.connect(on_enemy_state_set)

func _initialize_signals() -> void:
	Events.player_respawned.connect(on_player_respawned)
	Events.level_started.connect(on_level_started)

func on_player_respawned() -> void:
	player = null
	
	if not get_tree().get_nodes_in_group("player"):
		await get_tree().process_frame
	
	player = get_tree().get_root().get_node("World/Player")

func _on_frightened_timer_timeout():
#	player.is_energized = false
	Events.emit_signal("frightened")

func _on_chase_timer_timeout() -> void:
	print("in shared_enemy_ai: chase timeout")
	Events.emit_signal("scatter")

func _on_scatter_timer_timeout() -> void:
	Events.emit_signal("chase")
