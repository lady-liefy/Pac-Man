### gui.gd
extends Node2D

@export var high_score    : Label
@export var score_counter : Label
@export var lives_counter : Label

@export var color: Color = Color.WHITE

@onready var scene_to_load = Global.scene_paths["Main_Menu"]

signal level_finished

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self._initialize_signals()
	self._initialize()

func _initialize_signals() -> void:
	ScoreManager.current_score_changed.connect(set_current_score)
	ScoreManager.current_lives_changed.connect(set_current_lives)
	
	Events.game_over.connect(_on_game_over)
	Events.game_paused.connect(_on_game_paused)
	Events.game_resumed.connect(_on_game_resumed)
	Events.level_won.connect(on_level_won)

func _initialize() -> void:
	high_score.set("theme_override_colors/font_color", self.color)
	score_counter.set("theme_override_colors/font_color", self.color)
	set_current_score(ScoreManager.current_score)
	set_current_lives(ScoreManager.current_lives)

func _physics_process(_delta : float) -> void:	
	if Input.is_action_just_pressed("pause"):
		if not get_tree().is_paused():
			Events.emit_signal("game_paused")
		else:
			Events.emit_signal("game_resumed")

func set_current_score(value: int = -1) -> void:
	if value < 0:
		self.score_counter.text = str(ScoreManager.current_score)
	else:
		self.score_counter.text = str(value)

func set_current_lives(value: int = -1) -> void:
	pass
	#if value < 0:
		#self.lives_counter.text = str(ScoreManager.current_lives)
	#else:
		#self.lives_counter.text = str(value)

func on_level_won() -> void:
#	await get_tree().create_timer(0.6).timeout
	get_tree().set_pause(true)
	
	if Global.current_level_id != Global.levels.size():
		pass
	else:
		_on_game_over()
		Events.emit_signal("game_won")

func _on_game_over() -> void:
	pass

func _on_game_paused() -> void:
	get_tree().set_pause(true)

func _on_game_resumed() -> void:
	get_tree().set_pause(false)
