extends Node2D
class_name EnemyAI

var in_home: bool = true

func on_chasing() -> void:
	set_destination_location(DestinationLocations.CHASE_TARGET)

func on_scattered() -> void:
	set_destination_location(DestinationLocations.SCATTER_AREA)
	go_to_first_scatter_point()

func on_dead() -> void:
	set_destination_location(DestinationLocations.ENEMIES_HOME)

func on_frightened() -> void:
	set_destination_location(DestinationLocations.RANDOM_LOCATION)

enum States {
	CHASE,
	SCATTER,
	DEAD,
	FRIGHTENED
}


var current_state: States = States.SCATTER
var previous_state: States = current_state


signal state_set(value: EnemyAI.States, enemy: Ghost)

func set_state(state: States) -> void:
	if state == current_state and not first_initialization: return
	previous_state = current_state
	current_state = state
	
	match state:
		States.CHASE:
			self.on_chasing()
		States.SCATTER:
			self.on_scattered()
		States.DEAD:
			self.on_dead()
		States.FRIGHTENED:
			self.on_frightened()
		_:
			printerr("(!) Error in " + self.name + ": Unrecognized state!")
	
	self.state_set.emit(state, enemy)

# State waiting to be set which updates itself in the background while
# the current one is overrinding it
var background_state: States = self.current_state


@onready var chase_target: Player = get_tree().get_root().get_node("World/Player")
@onready var chase_target_position := Vector2.ZERO

func __update_chase_target_position() -> void:
	printerr("(!) ERROR in: " + self.name + ": __set_chase_target_position() must be implemented!")

func set_destination_position_to_chase_target_position() -> void:
	__update_chase_target_position()
	set_destination_position(chase_target_position)


#@export var scatter_points_node_name: String = ""
#@onready var scatter_points_node = get_tree().get_root().get_node("Level/AIWaypoints/" + scatter_points_node_name)
#@onready var scatter_point_target_position: Vector2 = Vector2(0.0, 0.0)

static var scatter_points : PackedVector2Array = [ Vector2(0,0), Vector2(0, 28), Vector2(36, 0), Vector2(36, 28) ]
var current_scatter_point_index: int = 0

func go_to_first_scatter_point() -> void:
	current_scatter_point_index = 0
	set_destination_position(scatter_points[current_scatter_point_index])

## Randomly picks one instead of keeping the same (like OG Pacman)
func go_to_next_scatter_point() -> void:
	set_destination_position(scatter_points[current_scatter_point_index])

	current_scatter_point_index += 1
	if current_scatter_point_index >= scatter_points.size():
		current_scatter_point_index = 0

@onready var shared_enemy_ai: SharedEnemyAI = get_tree().get_root().get_node("World/SharedEnemyAI")
@onready var enemies := shared_enemy_ai.enemies

func pick_random_destination_position() -> void:
	randomize()
	var random_index: int = randi() % shared_enemy_ai.walkable_tiles_list.size() - 1
#	set_destination_position(tile_map.map_to_local(shared_enemy_ai.walkable_tiles_list[random_index]))


@onready var enemy_home: Marker2D = get_tree().get_root().get_node("World/AIMarkers/EnemyHome")
@onready var enemy_home_position: Vector2 = enemy_home.global_position

@export var enemy: Ghost = null

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var tile_map = get_tree().get_root().get_node("World")

var destination_position: Vector2 = Vector2.ZERO

func set_destination_position(value: Vector2) -> void:
	destination_position = value
	nav_agent.set_target_position(destination_position)

enum DestinationLocations {
	CHASE_TARGET,
	SCATTER_AREA,
	ENEMIES_HOME,
	RANDOM_LOCATION
}


## Controls if the destination location is updated on each frame.
## Set to false when the position is set once and not changing later.
var can_update_destination_location: bool = true
var destination_location: DestinationLocations = DestinationLocations.SCATTER_AREA

func set_destination_location(new_destination: DestinationLocations) -> void:
	destination_location = new_destination
	can_update_destination_location = true

func update_destination_location() -> void:
	match destination_location:
		DestinationLocations.CHASE_TARGET:
			set_destination_position_to_chase_target_position()
		DestinationLocations.SCATTER_AREA:
			can_update_destination_location = false
			go_to_next_scatter_point()
		DestinationLocations.ENEMIES_HOME:
			can_update_destination_location = false
			set_destination_position(enemy_home_position)
		DestinationLocations.RANDOM_LOCATION:
			can_update_destination_location = false
			pick_random_destination_position()
		_:
			printerr("(!) ERROR in " + self.name + ": Unrecognized state!")


signal navigation_finished

func on_navigation_finished() -> void:
	match current_state:
		States.DEAD:
			can_update_destination_location = true
			self.set_state(background_state)
		States.FRIGHTENED:
			can_update_destination_location = true
			pick_random_destination_position()
		States.SCATTER:
			print("in enemy_ai: scatter")
			can_update_destination_location = false
			go_to_next_scatter_point()
#		# Useful for EnemyAICornichon only. AI just stops on player death anyways.
#		States.CHASE:
#			can_update_destination_location = true
#			set_destination_location(DestinationLocations.CHASE_TARGET)

var cycle_completed_before_permanent_chase_mode: bool = false
var cycle_count_before_permanent_chase_mode: int = 0
var cycle_count_limit_before_permanent_chase_mode: int = 4

func check_if_cycle_completed_before_permanent_chase() -> void:
	if cycle_count_before_permanent_chase_mode >= cycle_count_limit_before_permanent_chase_mode:
		cycle_completed_before_permanent_chase_mode = true


## State timer triggers ##

func on_scatter_timer_timeout() -> void:
	background_state = States.CHASE
	if current_state == States.DEAD or current_state == States.FRIGHTENED: return
	
	print("SCATTER DONE")
	
	if not cycle_completed_before_permanent_chase_mode:
		cycle_count_before_permanent_chase_mode += 1
		check_if_cycle_completed_before_permanent_chase()
	
	self.set_state(States.CHASE)

func on_chase_timer_timeout() -> void:
	background_state = States.SCATTER
	if current_state == States.DEAD or current_state == States.FRIGHTENED: return
	
	print("CHASE DONE")
	
	if not cycle_completed_before_permanent_chase_mode:
		cycle_count_before_permanent_chase_mode += 1
		check_if_cycle_completed_before_permanent_chase()
	else:
		return
		
	self.set_state(States.SCATTER)

func on_frightened_timer_timeout() -> void:
	if current_state == States.DEAD: return
	self.set_state(background_state)
	print("SCARED DONE in Enemy AI")

func on_player_died() -> void:
	self.set_enabled(false)
	cycle_count_before_permanent_chase_mode = 0
	cycle_completed_before_permanent_chase_mode = false

func on_game_over() -> void:
	self.set_enabled(false)
	cycle_count_before_permanent_chase_mode = 0
	cycle_completed_before_permanent_chase_mode = false

func on_enemy_died() -> void:
	self.set_state(States.DEAD)

func on_level_won() -> void:
	self.set_enabled(false)

func on_game_started() -> void:
	if not enable_ai_timer:
		self.set_enabled(true)

func on_player_energized() -> void:
	if self.in_home: return
	self.set_state(States.FRIGHTENED)

func _initialize_signals() -> void:
	self.navigation_finished.connect(on_navigation_finished)
	
	enemy.consumed.connect(on_enemy_died)
	
	Events.player_died.connect(on_player_died)
	Events.player_energized.connect(on_player_energized)
	Events.game_over.connect(on_game_over)
	Events.level_won.connect(on_level_won)
	
	Events.chase.connect(on_chase_timer_timeout)
	Events.scatter.connect(on_scatter_timer_timeout)
	Events.frightened.connect(on_frightened_timer_timeout)

var first_initialization: bool = true

#signal initialized
var is_initialized: bool = false

func _initialize():
	self.set_enabled(false)
	is_initialized = true
#	self.initialized.emit()

func _ready() -> void:
	assert(enemy != null)
	self.set_enabled(false)
	self._initialize_signals()
	self.call_deferred("_initialize")
	
#	tile_map = get_tree().get_root().get_node("World/Level/Background")
	print(str(tile_map))


func _physics_process(_delta: float) -> void:
	enemy.direction = to_local(nav_agent.get_next_path_position()).normalized()

@onready var pathfinding_timer: Timer = $PathfindingTimer
@onready var enable_ai_timer: EnableAITimer = get_node_or_null("EnableAITimer")

func set_enabled(value: bool = true) -> void:
	if value:
		self.set_physics_process(true)
		pathfinding_timer.start()
		enemy.set_enabled(true)
		self.in_home = false
	else:
		self.set_physics_process(false)
		pathfinding_timer.stop()
		enemy.set_enabled(false)


func _on_pathfinding_timer_timeout() -> void:
	if can_update_destination_location: update_destination_location()
	
	if nav_agent.is_navigation_finished():
		navigation_finished.emit()
		return
