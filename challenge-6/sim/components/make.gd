class_name Make
extends RefCounted

# Yang tersisa di sini hanya komponen berbentuk WADAH: isinya heterogen —
# kumpulan komponen lain, array rune, atau pasangan self/target. Bentuk seperti
# itu tidak untung dijadikan class bertipe, karena isinya memang tidak tetap.
#
# Komponen berbentuk NILAI sudah pindah jadi class: Vec2, Size, Health, Speed,
# Countdown, Wet, Knocked, Damaged, Scalar. Konstruktornya sendiri yang jadi
# skema, dan salah ketik nama field ketahuan editor.

static func recipe(body: Dictionary) -> Dictionary:
	return body

static func on_hit(on_self: Dictionary, on_target: Dictionary) -> Dictionary:
	return {"self": on_self, "target": on_target}

static func melee(on_hit_body: Dictionary) -> Dictionary:
	return {Comp.ON_HIT: on_hit_body}

static func cast_queue() -> Dictionary:
	return {"runes": [], "open": false, "open_time": 0.0}

static func cast_release() -> Dictionary:
	return {"runes": []}

static func held_spell(spell: Dictionary, runes: Array) -> Dictionary:
	return {"runes": runes, "recipe": spell}
