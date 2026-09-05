class_name Countdown
extends Component

# Dipakai bersama oleh Delay, Lifetime, Invulnerable, dan Wet — bentuknya memang
# identik. Yang membedakan cuma NAMA komponennya saat ditempel (itulah kunci
# query-nya) dan apa yang terjadi saat habis.
#
# Bentuk boleh dibagi, makna tidak. Position dan Velocity juga sama-sama {x, y}
# dan tetap dua komponen berbeda.
#
# Hanya data: tidak ada advance() atau is_expired(). Itu tugas TimerSystem.

var elapsed: float = 0.0
var duration: float = 0.0

# component_name -> body, ditempel ke entity yang sama saat habis.
# Tetap Dictionary karena isinya heterogen.
var on_expire: Dictionary = {}


func _init(p_duration: float = 0.0, p_on_expire: Dictionary = {}) -> void:
	duration = p_duration
	on_expire = p_on_expire
