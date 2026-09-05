class_name Knocked
extends Countdown

# Arahnya diisi sama system kontak, dia yang tau posisi sumber sama target.
# Grammar cuma tau seberapa kuat.

var strength: float = 0.0
var x: float = 0.0
var y: float = 0.0


func _init(p_duration: float = 0.0, p_strength: float = 0.0) -> void:
	super(p_duration)
	strength = p_strength
