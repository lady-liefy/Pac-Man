extends Timer
class_name EnableAITimer

@export var enemy_ai: EnemyAI = self.get_parent()

func on_level_started() -> void:
	self.start()

func on_player_died() -> void:
	self.stop()

func on_game_over() -> void:
	self.stop()

func _ready() -> void:
	assert(enemy_ai != null)
	Events.level_started.connect(on_level_started)
	Events.game_over.connect(on_game_over)
	Events.player_died.connect(on_player_died)

func _on_timeout() -> void:
	enemy_ai.set_enabled(true)
