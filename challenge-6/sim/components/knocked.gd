class_name Knocked
extends Countdown

# Arah diisi oleh system kontak (dia yang tahu posisi sumber dan target),
# bukan oleh Grammar — Grammar cuma tahu seberapa kuat.
var strength: float = 0.0
var x: float = 0.0
var y: float = 0.0


func _init(p_duration: float = 0.0, p_strength: float = 0.0) -> void:
	super(p_duration)
	strength = p_strength
