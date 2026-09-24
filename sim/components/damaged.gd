class_name Damaged
extends Component

# Komponen kejadian. Di attach sama system kontak, dimakan dan dicabut
# DamageSystem di frame yang sama.

var damage: float = 0.0


func _init(p_damage: float = 0.0) -> void:
	damage = p_damage
