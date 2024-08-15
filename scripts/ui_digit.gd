@tool
extends TextureRect
class_name Digit

@export_range(-1, 9, 1) var number : int = -1 :
	set(num):
		number = num
		
		if COORDS == []:
			return
		
		if number < 0:
			self.coords = COORDS[0]
		else:
			self.coords = COORDS[number + 1]
		
		self.texture.region = Rect2(coords.x, coords.y, SIZE.x, SIZE.y)
	get:
		return number

static var SIZE  := Vector2(8, 8)
static var COORDS : Array[Vector2] = []

var coords := Vector2.ZERO

func _ready() -> void:
	coords_setup()

func coords_setup() -> void:
	COORDS.clear()
	
	var y := 16
	var x := 0
	while x <= 74:
		COORDS.append(Vector2(x, y))
		x = x + 8
		
	COORDS.push_front(Vector2(120, 16))

func update_number(num : int) -> void:
	number = num
