class_name Vec2
extends Component

# Bentuk bersama untuk Position, Velocity, Facing, dan MoveIntent.
# Empat komponen berbeda, satu bentuk — sama seperti keluarga Countdown.

var x: float = 0.0
var y: float = 0.0


func _init(p_x: float = 0.0, p_y: float = 0.0) -> void:
	x = p_x
	y = p_y
