extends Pickup
class_name Energizer

# Called when the node enters the scene tree for the first time.
func _ready():
	self.type = Type.ENERGIZER
	sprite.texture.region = COORDS[1]
