extends CharacterBody2D
class_name Ghost

@export var speed: float = 100.0

@onready var sprite : AnimationTree = $AnimationTree
@onready var sprite_playback : AnimationNodeStateMachinePlayback = sprite.get("parameters/playback")

var input_direction   := Vector2.ZERO
var initial_direction := Vector2(-1.0, 0.0)
var direction := initial_direction
var next_direction := direction

var initial_position := self.position

var is_teleporting := false
var is_scared := false
var is_active := false

signal consumed(pickup : Pickup)

func _ready() -> void:
#	set_velocity(velocity * Global.tile_size * Global.game_speed * self.speed)
	self._initialize_signals()
	$AnimationTree/AnimationPlayer.speed_scale = speed / 2
	sprite.set("parameters/move/blend_position", next_direction)
	sprite_playback.travel("move")
	self.set_enabled(true)

func _initialize_signals() -> void:
	Events.game_paused.connect(on_game_paused)
	Events.game_over.connect(on_game_over)
	Events.game_resumed.connect(on_game_resumed)

func _physics_process(_delta: float) -> void:
	if not is_active:
		return
	
	find_player()
	move_and_slide()

func find_player() -> void:
	if is_scared:
		return
	
	print("hunting you!")

func consume() -> void:
	consumed.emit(self)
	self.die()

func enter_scared_mode() -> void:
	is_scared = true

func exit_scared_mode() -> void:
	is_scared = false

func die() -> void:
	self.queue_free()

func on_game_paused() -> void:
	self.set_enabled(false)

func on_game_over() -> void:
	self.set_enabled(false)

func on_game_restarted() -> void:
	self.set_enabled(true)
	
func on_game_resumed() -> void:
	self.set_enabled(true)

func set_enabled(value: bool = true) -> void:
	if value:
		is_active = true
		self.set_physics_process(true)
	else:
		is_active = false
		self.set_physics_process(false)
