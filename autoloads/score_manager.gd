### score_manager.gd
extends Node

@onready var current_score : int = 0
@onready var current_lives : int = Global.max_lives

var one_up := 10000
var two_up := 20000

signal current_score_changed(new_score: int)
signal current_lives_changed(new_lives: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_initialize_signals()

func _initialize_signals() -> void:
	Events.game_over.connect(self.on_game_over)
	
	Events.player_died.connect(self.on_player_died)
	Events.level_won.connect(self.on_level_won)

func on_player_died() -> void:
	if current_lives >= 0:
		self.subtract_life()
	else:
		self.set_current_lives(0)

func on_level_won() -> void:
	self.set_current_score(current_score)

func on_game_over() -> void:
	self.set_current_lives(0)

func on_game_restarted() -> void:
	self.set_current_lives(Global.max_lives)

func add_to_score(value: int) -> void:
	self.current_score += value
	
	if new_life_check:
		set_current_lives(current_lives + 1)
	
	self.emit_signal("current_score_changed", current_score)

func set_current_score(value: int) -> void:
	self.current_score = value
	
	if new_life_check:
		set_current_lives(current_lives + 1)
	
	self.emit_signal("current_score_changed", current_score)

func set_current_lives(value: int) -> void:
	self.current_lives = value
	self.emit_signal("current_lives_changed", current_lives)

func subtract_life() -> void:
	self.current_lives -= 1
	self.emit_signal("current_lives_changed", current_lives)

func new_life_check() -> bool:
	if current_score == one_up:
		return true
	return false
