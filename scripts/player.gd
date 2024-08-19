### player.gd
extends CharacterBody2D
class_name Player

@export var speed : float = 100.0
@export var energize_time : float = 4.0

@onready var sprite : AnimationTree = $AnimationTree
@onready var sprite_playback : AnimationNodeStateMachinePlayback = sprite.get("parameters/playback")
@onready var check_rotator = $BarrierCheckRotator

@onready var chomp_audio = $Audio/ChompAudio
@onready var death_audio = $Audio/DeathAudio

var input_direction   := Vector2.ZERO
var initial_direction := Vector2(1.0, 0.0)
var direction := initial_direction
var next_direction := direction

var is_energized := false
var is_eating    := false
var active       := false

func _ready() -> void:
	assert(Global.initial_position != null)
	
	self._initialize_signals()
	$AnimationTree/AnimationPlayer.speed_scale = speed / 2
	sprite_playback.travel("idle")

func _initialize_signals() -> void:
	Events.game_paused.connect(_on_game_paused)
	Events.game_resumed.connect(_on_game_resumed)
	Events.level_started.connect(on_level_started)
	Events.level_won.connect(on_level_won)

# ---------------------- PROCESSES -----------------------------------------------
func _physics_process(_delta : float) -> void:
	# Reset and confirm any input
	self.input_direction = Vector2.ZERO
	self.velocity = Vector2.ZERO
	
	if !active:
		return
	
	_process_inputs()
	Global.screen_wrap(self)
	
	if next_direction_check():
		direction = next_direction
	
	if input_direction != Vector2.ZERO:
		next_direction = input_direction
		
		if next_direction.x == -1.0:
			check_rotator.set_rotation_degrees(180.0)
		elif next_direction.x == 1.0:
			check_rotator.set_rotation_degrees(0.0)
		elif next_direction.y == -1.0:
			check_rotator.set_rotation_degrees(-90.0)
		elif next_direction.y == 1.0:
			check_rotator.set_rotation_degrees(90.0)
	
	self.move(direction)

func _process_inputs() -> void:
	input_direction.x = Input.get_axis("move_left", "move_right")
	if input_direction.x != 0:
		return
	input_direction.y = Input.get_axis("move_up", "move_down")

func move(dir: Vector2) -> void:
	self.velocity = dir * speed * Global.game_speed
	if self.move_and_slide() and not next_direction_check():
		sprite_playback.travel("idle")
		chomp_audio.stop()
	else:
		sprite.set("parameters/move/blend_position", velocity)
		sprite_playback.travel("move")

func next_direction_check() -> bool:
	for raycast in check_rotator.get_children():
		if raycast.is_colliding():
			return false
	return true

func die() -> void:
	active = false
	
	sprite_playback.travel("die")
	death_audio.play()
	
#	await sprite.animation_finished
	await death_audio.finished
	Events.emit_signal("player_died")
	self.call_deferred("queue_free")

func eat(food : Node2D) -> void:
	if not food.has_method("consume"):
		is_eating = false
		chomp_audio.stop()
		return
	
	if food.is_consumed:
		is_eating = false
		chomp_audio.stop()
		return
	
	is_eating = true
	if food.is_in_group("pellet"):
#		await get_tree().process_frame      # hopefully this pauses player 1/60th of a second
		food.consume()
	elif food.is_in_group("energizer"):
		self.energize()
#		await get_tree().process_frame
#		await get_tree().process_frame 
#		await get_tree().process_frame 
		food.consume()
	elif food.is_in_group("fruit"):
#		await get_tree().process_frame
		food.consume()
	
	# Movement audio start
	if is_eating and not chomp_audio.playing:
		chomp_audio.play()

func energize() -> void:
	self.is_energized = true
	Events.emit_signal("player_energized")

func _on_death_collider_body_entered(body: Node2D) -> void:
	if not body is Ghost:
		print("not a ghost...")
		return
		
	if not self.is_energized:
		self.die()
	else:
		print("OMNOM")
		body.die()

func _on_pickup_collider_body_entered(consumable : Area2D ) -> void:
	if not consumable is Pickup:
		return
	eat(consumable)

func set_enabled(value: bool) -> void:
	if value:
		active = true
		self.set_process_unhandled_input(true)
		self.set_physics_process(true)
	else:
		active = false
		self.set_process_unhandled_input(false)
		self.set_physics_process(false)

func _on_game_paused() -> void:
	self.set_enabled(false)

func _on_game_resumed() -> void:
	self.set_enabled(true)

func on_level_started() -> void:
	self.set_enabled(true)

func on_level_won() -> void:
	self.set_enabled(false)
	$AnimationTree/AnimationPlayer.speed_scale = speed
	sprite_playback.travel("idle")
