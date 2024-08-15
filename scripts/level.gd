### level.gd
extends Node
class_name Level

func _ready() -> void:
	self._initialize_signals()
	self._initialize()

func _initialize_signals() -> void:
	Events.level_begun.connect(on_level_begun)

func _initialize() -> void:
	$Ready.visible = true
	$StartAudio.play()

func on_level_begun() -> void:
	$Ready.visible = false

func _on_start_audio_finished() -> void:
	Events.emit_signal("level_begun")