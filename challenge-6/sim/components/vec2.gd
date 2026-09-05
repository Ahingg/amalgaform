class_name Vec2
extends Component

# Buat Position, Velocity, Facing, dan MoveIntent.

var x: float = 0.0
var y: float = 0.0

func _init(p_x: float = 0.0, p_y: float = 0.0) -> void:
	x = p_x
	y = p_y
