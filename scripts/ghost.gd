extends CharacterBody2D
class_name Ghost

@export var base_speed: float = 5
var chase_speed : float = base_speed
var scatter_speed : float = base_speed
var dead_speed : float = base_speed * 2.0
var frightened_speed : float = base_speed / 2.0

var speed : float = base_speed

@export_group("Sound Files")
@export_file("*.ogg", "*.wav") var frightened_sound_file_path: String = ""
@export_file("*.ogg", "*.wav") var eaten_sound_file_path: String = ""
@export_file("*.ogg", "*.wav") var enemy_going_home_sound_file_path: String = ""
@export_group("")

@export var enemy_ai: EnemyAI = null

var initial_direction := Vector2(1.0, 0.0)
var direction := initial_direction
var next_direction := direction

var is_active  := false
var going_home := false

signal consumed()

func _ready() -> void:
	set_process(false)
	assert(enemy_ai != null and shared_enemy_ai != null)
	
	set_enabled(false)
	self._initialize_signals()
	self._initialize()

func _initialize_signals() -> void:
	self.enemy_ai.state_set.connect(on_enemy_ai_state_set)
	
	Events.player_died.connect(on_player_died)
	
	Events.game_paused.connect(on_game_paused)
	Events.game_over.connect(on_game_over)
	Events.game_resumed.connect(on_game_resumed)
	
	Events.level_started.connect(on_level_started)
	Events.level_won.connect(on_level_won)

@onready var sprite : AnimationTree = $AnimationTree
@onready var sprite_playback : AnimationNodeStateMachinePlayback = sprite.get("parameters/playback")
@onready var check_rotator = $BarrierCheckRotator

func _initialize() -> void:
	self.set_enabled(false)
	sprite.active = true
	speed = base_speed
	
	$AnimationTree/AnimationPlayer.speed_scale = speed / 4
	sprite.set("parameters/move/blend_position", self.direction)
	sprite_playback.travel("move")

@onready var shared_enemy_ai: SharedEnemyAI = get_tree().get_root().get_node("World/SharedEnemyAI")
@onready var enemies_timers = shared_enemy_ai.enemies_timers

func _process(_delta: float) -> void:
	if enemies_timers["Frightened"].get_time_left() > 0:
		if enemies_timers["Frightened"].get_time_left() <= 2.0:
			set_process(false)

## MOVEMENT ##
func _physics_process(_delta: float) -> void:
	self.velocity = Vector2.ZERO
	if !is_active:
		return
	
	if next_direction_check():
		direction = next_direction
	
	self.move(direction)
	Global.screen_wrap(self)
	
	if next_direction.x == -1.0:
		check_rotator.set_rotation_degrees(180.0)
	elif next_direction.x == 1.0:
		check_rotator.set_rotation_degrees(0.0)
	elif next_direction.y == -1.0:
		check_rotator.set_rotation_degrees(-90.0)
	elif next_direction.y == 1.0:
		check_rotator.set_rotation_degrees(90.0)

func move(dir: Vector2) -> void:
	self.velocity = dir * Global.tile_size * speed * Global.game_speed
	if not self.move_and_slide() and next_direction_check():
		sprite.set("parameters/move/blend_position", velocity)
		sprite_playback.travel("move")
	else:
#		print(str(enemy_ai.nav_agent.target_position))
		pass

func next_direction_check() -> bool:
	for raycast in check_rotator.get_children():
		if raycast.is_colliding():
			return false
	return true

func die() -> void:
	self.consumed.emit()

### GAME STATES ###
# Enemy specific states
func on_enemy_ai_state_set(state: EnemyAI.States, _enemy: Ghost) -> void:
	match state:
		EnemyAI.States.CHASE:
			on_chase()
		EnemyAI.States.SCATTER:
			on_scatter()
		EnemyAI.States.DEAD:
			consume()
		EnemyAI.States.FRIGHTENED:
			on_frightened()
		_:
			printerr("(!) ERROR: In: " + self.get_name() + ": Unhandled enemy ai state!")

func on_chase() -> void:
	set_process(false)
	speed = chase_speed
	going_home = false

func on_scatter() -> void:
	set_process(false)
	speed = scatter_speed
	going_home = false
	print("in ghost: scatter")

func consume() -> void:
	set_process(false)
	speed = dead_speed
	going_home = true

func on_frightened() -> void:
	set_process(true)
	speed = frightened_speed
	going_home = false
	
	

# Basic game states
func on_player_died() -> void:
	self.set_enabled(false)

func on_game_paused() -> void:
	self.set_enabled(false)

func on_game_over() -> void:
	self.set_enabled(false)

func on_game_restarted() -> void:
	self.set_enabled(true)
	
func on_game_resumed() -> void:
	self.set_enabled(true)

func on_level_won() -> void:
	self.set_enabled(false)

func on_level_started() -> void:
	self.set_enabled(true)
	self.velocity = self.direction

func set_enabled(value: bool = true) -> void:
	if value:
		is_active = true
		self.set_physics_process(true)
	else:
		is_active = false
		self.set_physics_process(false)
