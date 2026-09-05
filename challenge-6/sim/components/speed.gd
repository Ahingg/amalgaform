class_name Speed
extends Component

# value = kecepatan yang berlaku sekarang, base = yang gapernah berubah.
# Wet motong dari base, bukan dari value. Kalo motong dari value, dua efek
# berturut turut bakal numpuk dan kecepatannya gapernah balik.

var value: float = 0.0
var base: float = 0.0


func _init(num: float = 0.0) -> void:
	value = num
	base = num
