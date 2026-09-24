class_name Countdown
extends Component

# Dipake bareng sama Delay, Lifetime, Invulnerable, Wet. Bentuknya emang sama
# persis. Yang bedain cuma NAMA komponennya waktu di attach, itu yang jadi kunci
# querynya.
# Bentuk boleh sama, makna engga. Position sama Velocity juga sama sama {x, y}.
#
# Cuma data, gaada advance() atau is_expired(). Itu kerjaan TimerSystem.

var elapsed: float = 0.0
var duration: float = 0.0

# component_name -> body, ditempel ke entity yang sama saat habis.
# Tetap Dictionary karena isinya heterogen.
var on_expire: Dictionary = {}


func _init(p_duration: float = 0.0, p_on_expire: Dictionary = {}) -> void:
	duration = p_duration
	on_expire = p_on_expire
