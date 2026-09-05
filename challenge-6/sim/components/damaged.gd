class_name Damaged
extends Component

# Komponen KEJADIAN: ditempel oleh system kontak, dikonsumsi dan dicabut
# DamageSystem di frame yang sama.
var damage: float = 0.0


func _init(p_damage: float = 0.0) -> void:
	damage = p_damage
