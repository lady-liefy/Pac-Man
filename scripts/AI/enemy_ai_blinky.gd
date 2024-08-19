extends EnemyAI
class_name EnemyAIBlinky


func __update_chase_target_position() -> void:
	chase_target_position = chase_target.global_position + (chase_target.direction * Global.tile_size * 4)
