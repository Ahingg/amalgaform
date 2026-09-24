class_name Make
extends RefCounted

# Sisanya disini cuma komponen yang bentuknya WADAH, isinya campur campur.
# Bentuk kayak gitu ga untung dijadiin class soalnya isinya emang ga tetap.
#
# Komponen yang bentuknya nilai udah pindah jadi class: Vec2, Size, Health,
# Speed, Countdown, Wet, Knocked, Damaged, Scalar.

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
	return {"runes": runes, "recipe": spell, "slow": runes.size() * Tuning.SPELL_HOLD_BASE_MODIFIER}
