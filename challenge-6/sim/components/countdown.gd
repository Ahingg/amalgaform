class_name Countdown
extends RefCounted

# Dipakai bersama oleh Delay, Lifetime, dan Invulnerable — bentuknya memang
# identik. Yang membedakan cuma nama komponennya saat ditempel, dan apa yang
# terjadi saat habis (on_expire).
#
# CATATAN GARIS OOP:
# Class ini cuma menyimpan data. Tidak ada advance(), tidak ada is_expired().
# Menambah advance() akan memindahkan kelakuan ke dalam komponen — dan itu
# persis hal yang dihindari sejak hari pertama. Komponen = data, system =
# kelakuan. Yang berubah dari migrasi ini cuma BENTUK datanya (field bertipe,
# bukan key string), bukan pembagian tugasnya.

var elapsed: float = 0.0
var duration: float

# component_name -> body, ditempel ke entity yang sama saat timer habis.
# Tetap Dictionary karena isinya heterogen: kumpulan komponen apa pun.
var on_expire: Dictionary


func _init(p_duration: float, p_on_expire: Dictionary = {}) -> void:
	duration = p_duration
	on_expire = p_on_expire
