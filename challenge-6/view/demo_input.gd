class_name DemoInput
extends Node

# ============================================================================
# Sumber input palsu untuk pengujian. Menulis komponen yang sama persis dengan
# yang ditulis PlayerInput dan CastUI, jadi sim tidak bisa membedakan mana yang
# dari manusia dan mana yang dari sini — kalau bisa membedakan, berarti ada
# aturan main yang bocor ke lapisan input.
#
# Cuma aktif kalau dijalankan dengan --demo, jadi tidak pernah menyentuh
# permainan sungguhan:
#     godot --path . -- --demo
#
# Gunanya: memeriksa pose bergerak, merapal, dan spell yang terbang tanpa perlu
# ada yang menekan tombol. Perataan sprite saat bergerak cuma bisa dilihat
# kalau karakternya benar-benar bergerak.
# ============================================================================

const RUNE_KEYS := ["Ignis", "Aqua", "Ventus"]

var _t := 0.0
var _phase := 0
var _next := 0.6


static func enabled() -> bool:
	return OS.get_cmdline_user_args().has("--demo") or OS.get_cmdline_args().has("--demo")


func _get_world():
	var renderer := get_parent()
	if renderer == null:
		return null
	var main := renderer.get_parent()
	return null if main == null else main.get("world")


func _physics_process(delta: float) -> void:
	var world = _get_world()
	if world == null:
		return
	var query: Array[String] = ["Player"]
	var players: Array[int] = world.get_entities_with_comp(query)
	if players.is_empty():
		return
	var p: int = players[0]

	_t += delta

	# Bergerak melingkar terus-menerus supaya pose bergerak dan pencerminan
	# kiri-kanan keduanya kena.
	var dir := Vector2(cos(_t * 0.9), sin(_t * 0.9))
	if world.entity_have_component("MoveIntent", p):
		var mi = world.get_component_value("MoveIntent", p)
		mi.x = dir.x
		mi.y = dir.y
	if world.entity_have_component("Facing", p):
		var f = world.get_component_value("Facing", p)
		f.x = dir.x
		f.y = dir.y

	if _t < _next:
		return
	_advance(world, p)


# Satu siklus rapalan penuh: buka antrian, masukkan dua rune, lepas, tembak.
func _advance(world, p: int) -> void:
	match _phase:
		0:
			world.attach_component("CastQueue", p, {"runes": [], "open": true, "open_time": 0.0})
			_next = _t + 0.35
		1, 2:
			var q: Dictionary = world.get_component_value("CastQueue", p)
			q["runes"].append(RUNE_KEYS[(int(_t) + _phase) % 3])
			_next = _t + 0.3
		3:
			var q2: Dictionary = world.get_component_value("CastQueue", p)
			q2["open"] = false
			world.attach_component("CastRelease", p, {"runes": q2["runes"].duplicate()})
			_next = _t + 2.2
		4:
			if world.entity_have_component("HeldSpell", p):
				world.attach_component("LaunchSpell", p, {})
			_next = _t + 1.1
	_phase = (_phase + 1) % 5
