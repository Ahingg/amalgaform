class_name Cone
extends Component

# A directional spell's hit area, in room tile coordinates.
var origin_x: float = 0.0
var origin_y: float = 0.0
var direction_x: float = 1.0
var direction_y: float = 0.0
var reach: float = 4.0
var half_angle: float = 35.0


func _init(p_reach: float = 4.0, p_half_angle: float = 35.0) -> void:
	reach = p_reach
	half_angle = p_half_angle
