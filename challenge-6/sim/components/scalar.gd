class_name Scalar
extends Component

# Bentuk bersama untuk komponen yang isinya cuma satu angka: TimeScale,
# Interval, dan sejenisnya.
var value: float = 0.0


func _init(p_value: float = 0.0) -> void:
	value = p_value
