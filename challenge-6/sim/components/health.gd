class_name Health
extends Component

var current: float = 0.0
var max: float = 0.0


func _init(amount: float = 0.0) -> void:
	current = amount
	max = amount
