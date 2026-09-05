class_name Speed
extends Component

# `value` adalah kecepatan yang berlaku sekarang; `base` yang tidak pernah
# berubah. Efek seperti Wet memotong dari base, bukan dari value — kalau tidak,
# dua efek berurutan akan saling menumpuk dan kecepatan tidak pernah pulih.
var value: float = 0.0
var base: float = 0.0


func _init(num: float = 0.0) -> void:
	value = num
	base = num
