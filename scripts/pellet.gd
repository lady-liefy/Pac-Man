extends Pickup
class_name Pellet

# Called when the node enters the scene tree for the first time.
func _ready():
	self.type = Type.PELLET
	sprite.texture.region = COORDS[0]
