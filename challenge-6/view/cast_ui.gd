class_name CastUI
extends Node2D

# ============================================================================
# CASTING — input + panel
#
# Same deal as the old AssemblyUI: this writes into World, so it is an input
# layer, not part of the read-only view. The rule it plays by: it records only
# WHAT THE PLAYER DID, and holds no game rules.
#
# It does not know what a rune means. It does not know what Fire + Wind makes.
# It does not advance time. All of that is sim's.
#
# CONTRACT with sim/:
#   writes on the entity tagged "Player":
#     CastQueue = {"runes": ["Fire", "Water"], "open": true}
#     CastRelease                      (marker, no data, one frame)
#
#   reads, if sim chooses to provide it:
#     CastQueue["open_time"]  — seconds the queue has been open, in sim time.
#                               Only used to draw the closing-window bar. The
#                               panel stays correct without it.
#
# sim/ still owns CastSystem: accumulating open_time, computing time_scale, and
# translating runes into a spell on release. Those are game rules.
#
# Controls: hold SPACE to open, J/K/L to queue fire/water/wind, release to cast,
# ESC to cancel without casting.
# ============================================================================

const COMP_PLAYER := "Player"
const COMP_CAST_QUEUE := "CastQueue"
const COMP_CAST_RELEASE := "CastRelease"

const MAX_RUNES := 4

# Mirrors the numbers in DESIGN.md so the panel can preview the cost of the
# queue being built. sim/ owns the real values; this is a readout, not a rule.
const CAST_BASE := 0.25
const CAST_PER_RUNE := 0.25

# Curve constants, likewise only for drawing the window bar.
const SLOW_MIN := 0.12
const SLOW_TAU := 0.6

# J/K/L, not 1/2/3: the left hand never leaves WASD, so the runes have to sit
# under the right hand.
const RUNE_KEYS := {
	KEY_J: "Fire",
	KEY_K: "Water",
	KEY_L: "Wind",
}

const RUNE_COLORS := {
	"Fire": Color(0.95, 0.3, 0.2),
	"Water": Color(0.25, 0.6, 1.0),
	"Wind": Color(0.4, 0.85, 0.75),
}

# The first rune decides the shape of the spell. Naming it on screen the moment
# it is queued is feedback on what the player is holding — not a recipe list.
# The player still has to find out what each shape is good for.
const FORM_OF := {
	"Fire": "PELURU",
	"Water": "GENANGAN",
	"Wind": "KERUCUT",
}

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	z_index = 20


func _process(_delta: float) -> void:
	queue_redraw()


# --- input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo:
		return

	var world = _get_world()
	if world == null:
		return
	var player := _player(world)
	if player == -1:
		return

	var key: int = event.keycode

	if key == KEY_SPACE:
		if event.pressed:
			_open(world, player)
		else:
			_release(world, player)
		get_viewport().set_input_as_handled()
		return

	if not event.pressed:
		return

	if key == KEY_ESCAPE:
		_cancel(world, player)
		get_viewport().set_input_as_handled()
	elif RUNE_KEYS.has(key):
		_queue_rune(world, player, RUNE_KEYS[key])
		get_viewport().set_input_as_handled()


func _open(world, player: int) -> void:
	# Attached fresh rather than reusing an old one, so a queue can never carry
	# leftovers from the previous cast.
	world.attach_component(COMP_CAST_QUEUE, player, {"runes": [], "open": true})


func _queue_rune(world, player: int, rune: String) -> void:
	var q := _queue(world, player)
	if q.is_empty() or not q.get("open", false):
		return
	var runes: Array = q["runes"]
	if runes.size() >= MAX_RUNES:
		return
	# Appended, never de-duplicated: the same rune twice is a louder spell, and
	# order is part of the grammar.
	runes.append(rune)


func _release(world, player: int) -> void:
	var q := _queue(world, player)
	if q.is_empty() or not q.get("open", false):
		return
	q["open"] = false
	# An event component, exactly like Damaged: sim consumes it and detaches it
	# in the same frame. This layer never decides what the runes mean.
	world.attach_component(COMP_CAST_RELEASE, player, {})


func _cancel(world, player: int) -> void:
	if world.entity_have_component(COMP_CAST_QUEUE, player):
		world.detach_component(COMP_CAST_QUEUE, player)


# --- lookups -----------------------------------------------------------------

func _get_world():
	var renderer := get_parent()
	if renderer == null:
		return null
	var main := renderer.get_parent()
	if main == null:
		return null
	return main.get("world")


func _player(world) -> int:
	var query: Array[String] = [COMP_PLAYER]
	var ids: Array[int] = world.get_entities_with_comp(query)
	return -1 if ids.is_empty() else ids[0]


func _queue(world, player: int) -> Dictionary:
	if not world.entity_have_component(COMP_CAST_QUEUE, player):
		return {}
	return world.get_component_value(COMP_CAST_QUEUE, player)


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	var world = _get_world()
	if world == null:
		return
	var player := _player(world)
	if player == -1:
		return

	var q := _queue(world, player)
	if q.is_empty() or not q.get("open", false):
		_draw_hint()
		return

	var runes: Array = q.get("runes", [])
	var origin := Vector2(48, 560)

	if q.has("open_time"):
		_draw_window_bar(origin + Vector2(0, -26), float(q["open_time"]))

	_draw_runes(origin, runes)
	_draw_readout(origin + Vector2(0, 62), runes)


func _draw_runes(origin: Vector2, runes: Array) -> void:
	var box := Vector2(52, 52)
	var gap := 8.0

	for i in MAX_RUNES:
		var at := origin + Vector2(i * (box.x + gap), 0)
		var rect := Rect2(at, box)

		if i >= runes.size():
			draw_rect(rect, Color(1, 1, 1, 0.05), true)
			draw_rect(rect, Color(1, 1, 1, 0.12), false, 1.0)
			continue

		var rune: String = runes[i]
		var col: Color = RUNE_COLORS.get(rune, Color.WHITE)
		draw_rect(rect, Color(col.r, col.g, col.b, 0.8), true)
		draw_rect(rect, Color(1, 1, 1, 0.65), false, 1.5)
		draw_string(_font, at + Vector2(7, 32), rune.substr(0, 2).to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0, 0.8))

		# The first slot is marked because it is structurally different: it
		# decides the shape, the rest only decide the contents.
		if i == 0:
			draw_string(_font, at + Vector2(1, -6), "WUJUD",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.55))


func _draw_readout(at: Vector2, runes: Array) -> void:
	if runes.is_empty():
		draw_string(_font, at, "J api   ·   K air   ·   L angin   ·   ESC batal",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.4))
		return

	var form: String = FORM_OF.get(runes[0], "?")
	var cast_time: float = CAST_BASE + CAST_PER_RUNE * runes.size()

	draw_string(_font, at, "%s   ·   lepas %.2fs" % [form, cast_time],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.92, 0.7, 0.9))


# Shows how much of the useful slow-motion window is left. Filled while time is
# still deeply slowed, draining as the world speeds back up — so hesitation is
# something the player can watch happening to them.
func _draw_window_bar(at: Vector2, open_time: float) -> void:
	var scale: float = 1.0 - (1.0 - SLOW_MIN) * exp(-open_time / SLOW_TAU)
	var left: float = clampf(1.0 - (scale - SLOW_MIN) / (1.0 - SLOW_MIN), 0.0, 1.0)
	var width := 4.0 * 52.0 + 3.0 * 8.0

	draw_rect(Rect2(at, Vector2(width, 6)), Color(0, 0, 0, 0.5), true)
	var col := Color(0.6, 0.9, 1.0).lerp(Color(1.0, 0.35, 0.3), 1.0 - left)
	draw_rect(Rect2(at, Vector2(width * left, 6)), col, true)


func _draw_hint() -> void:
	draw_string(_font, Vector2(48, 596), "Tahan SPACE untuk merapal",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.3))
