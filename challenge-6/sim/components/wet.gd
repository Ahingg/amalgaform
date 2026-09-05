class_name Wet
extends Countdown

var slow: float = 0.0

func _init(p_duration: float = 0.0, p_slow: float = 0.0) -> void:
	super(p_duration)
	slow = p_slow
