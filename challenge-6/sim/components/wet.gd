class_name Wet
extends Countdown

# Countdown + satu tambahan. Aman di extend soalnya yang diwarisin cuma bentuk
# datanya, bukan kelakuan. Efeknya Wet langsung ikut kehandle TimerSystem tanpa
# nambah apa apa.
#
# slow = berapa banyak kecepatan yang dicabut. 0.5 artinya jalan setengah.
# Disimpen sebagai "yang dicabut" biar waktu dikali power arahnya bener.

var slow: float = 0.0

func _init(p_duration: float = 0.0, p_slow: float = 0.0) -> void:
	super(p_duration)
	slow = p_slow
