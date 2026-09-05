class_name Wet
extends Countdown

# Countdown dengan satu tambahan. Mewarisi di sini aman karena yang diwarisi
# cuma BENTUK data (elapsed/duration), bukan kelakuan — dan karena itu Wet
# otomatis ikut ditangani TimerSystem tanpa satu baris pun tambahan.

# Berapa banyak kecepatan yang dicabut. 0.5 = jalan setengah.
# Disimpan sebagai "yang dicabut", bukan "pengali", supaya dikali power hasilnya
# searah: power kecil -> perlambatan kecil.
var slow: float = 0.0


func _init(p_duration: float = 0.0, p_slow: float = 0.0) -> void:
	super(p_duration)
	slow = p_slow
