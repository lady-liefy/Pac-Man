@tool
extends Area2D
class_name Pickup

@export var type : Type :
	set(value):
		type = value

enum Type { PELLET = 0, ENERGIZER = 1, FRUIT = 2 }

static var COORDS : Array[Rect2] = [
	Rect2(8, 8, 8, 8),
	Rect2(8, 24, 8, 8), 
	Rect2(488, 48, 16, 16)
]

@onready var sprite := $Sprite2D
@onready var is_consumed := false

signal consumed(pickup : Pickup)

func consume() -> void:
	if is_consumed:
		return
	
	is_consumed = true
	self.hide()
	consumed.emit(self)
