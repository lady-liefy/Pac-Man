extends Node
class_name PickupManager

enum Scores { PELLET = 10, ENERGIZER = 50, GHOST = 200, FRUIT = 100 }

var pellet_scn = preload("res://scenes/pellet.tscn")
var energizer_scn = preload("res://scenes/energizer.tscn")

var pickup_types : Array[String] = []
var coords  : PackedVector2Array = []
var check := 0

func _ready() -> void:
	self._initialize()
	self._setup_pickups()

func _initialize() -> void:
	for pickup in get_children():
		if pickup is Pickup:
			coords.append(pickup.position)
			
			if pickup is Pellet:
				pickup_types.append("Pellet")
			elif pickup is Energizer:
				pickup_types.append("Energizer")
	_clear_pickups()

func _clear_pickups() -> void:
	get_tree().call_group("pickup", "queue_free")
	check = 0

func _setup_pickups() -> void:
	var i : int = 0
	
	for pos in coords:
		var pickup : Pickup
		match pickup_types[i]:
			"Pellet":
				pickup = pellet_scn.instantiate() as Pellet
				pickup.add_to_group("pellet")
			"Energizer":
				pickup = energizer_scn.instantiate() as Energizer
				pickup.add_to_group("energizer")
		
		i += 1
		call_deferred("add_child", pickup)
		
		if not pickup.is_in_group("pickup"):
			pickup.add_to_group("pickup")
		
		pickup.position = pos
		var _d = pickup.connect("consumed", Callable(self, "on_pickup_consumed"))

func on_pickup_consumed(pickup : Pickup) -> void:
	var score_to_add := 0
	match pickup.type:
		0:
			score_to_add = Scores.PELLET
		1:
			score_to_add = Scores.ENERGIZER
		2:
			score_to_add = Scores.FRUIT
	ScoreManager.add_to_score(score_to_add)
	check += 1
	if check_level_won():
		Events.emit_signal("level_won")

func check_level_won() -> bool:
	if (check + 1) == coords.size():
		return true
	return false
