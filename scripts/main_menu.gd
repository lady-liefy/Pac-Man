extends Control
class_name MainMenu

@onready var scene_to_load : PackedScene

@onready var characters_menu = $CharactersMenu
@onready var start_menu = $StartMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame

func _reset() -> void:
	start_menu.visible = false

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if not start_menu.visible:
			start_menu.visible = true
		else:
			get_tree().paused = false
			Global._reset()
			self._reset()
			scene_to_load = load("res://scenes/world.tscn")
			get_tree().change_scene_to_packed(scene_to_load)
