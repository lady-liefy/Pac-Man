extends Node
class_name GhostSpawner

#var ghost_prefabs := [ preload("res://scenes/ghost.tscn"), preload("res://scenes/ghost.tscn"), preload("res://scenes/ghost.tscn"), preload("res://scenes/ghost.tscn") ]
var ghosts : Array[Ghost] = []

func _ready() -> void:
	Events.player_respawned.connect(on_player_respawned)
	setup_ghosts()

func setup_ghosts() -> void:
	for ghost in get_tree().get_nodes_in_group("ghost"):
		if ghost is Ghost:
			ghosts.append(ghost)

func spawn_ghosts() -> void:
	var num := 0
	for ghost in ghosts:
		ghost.set_enabled(true)
		ghost.position = Global.ghost_stats[num]
		ghost.direction = ghost.initial_direction
		ghost.sprite.set("parameters/move/blend_position", ghost.direction)
		num += 1

func on_player_respawned() -> void:
	spawn_ghosts()
