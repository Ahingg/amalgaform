class_name Knocked
extends Countdown

var strength: float = 0.0
var x: float = 0.0
var y: float = 0.0


func _init(p_duration: float = 0.0, p_strength: float = 0.0) -> void:
	super(p_duration)
	strength = p_strength
