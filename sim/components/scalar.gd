class_name Scalar
extends Component

# Bentuk bareng buat komponen yang isinya cuma satu angka: TimeScale, Interval.

var value: float = 0.0


func _init(p_value: float = 0.0) -> void:
	value = p_value
