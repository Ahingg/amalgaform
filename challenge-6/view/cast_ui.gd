class_name CastUI
extends Node2D

# Component names and palette come from ViewConfig; gameplay numbers from
# Tuning. Nothing tunable is defined in this file.


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
	elif ViewConfig.RUNE_KEYS.has(key):
		_queue_rune(world, player, ViewConfig.RUNE_KEYS[key])
		get_viewport().set_input_as_handled()


func _open(world, player: int) -> void:
	# Attached fresh rather than reusing an old one, so a queue can never carry
	# leftovers from the previous cast.
	world.attach_component(ViewConfig.CAST_QUEUE, player, {"runes": [], "open": true})


func _queue_rune(world, player: int, rune: String) -> void:
	var q := _queue(world, player)
	if q.is_empty() or not q.get("open", false):
		return
	var runes: Array = q["runes"]
	if runes.size() >= Tuning.MAX_RUNES:
		return
	# Appended, never de-duplicated: the same rune twice is a louder spell, and
	# order is part of the grammar.
	runes.append(rune)


func _release(world, player: int) -> void:
	var q := _queue(world, player)
	if q.is_empty() or not q.get("open", false):
		return
	q["open"] = false
	# The event carries its own payload, so whoever consumes it never has to go
	# hunting for context. That is what lets an enemy cast by attaching this
	# component directly, with no queue of its own and no branching in sim.
	# duplicate(): the queue is detached moments later, and the event must not
	# be holding a reference to something about to be thrown away.
	var runes: Array = q.get("runes", [])
	world.attach_component(ViewConfig.CAST_RELEASE, player,
		{"runes": runes.duplicate()})


func _cancel(world, player: int) -> void:
	# Emptied, not detached. Spawn.player gives every caster a permanent
	# CastQueue, and CastSystem resets time_scale from inside its loop over
	# casters — detaching here would remove the only entity that can put the
	# world back to normal speed, and time would stay slowed forever.
	var q := _queue(world, player)
	if q.is_empty():
		return
	q["open"] = false
	q["runes"] = []
	q["open_time"] = 0.0


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
	var query: Array[String] = [ViewConfig.PLAYER]
	var ids: Array[int] = world.get_entities_with_comp(query)
	return -1 if ids.is_empty() else ids[0]


func _queue(world, player: int) -> Dictionary:
	if not world.entity_have_component(ViewConfig.CAST_QUEUE, player):
		return {}
	return world.get_component_value(ViewConfig.CAST_QUEUE, player)


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

	for i in Tuning.MAX_RUNES:
		var at := origin + Vector2(i * (box.x + gap), 0)
		var rect := Rect2(at, box)

		if i >= runes.size():
			draw_rect(rect, Color(1, 1, 1, 0.05), true)
			draw_rect(rect, Color(1, 1, 1, 0.12), false, 1.0)
			continue

		var rune: String = runes[i]
		var col: Color = ViewConfig.color_of(rune)
		draw_rect(rect, Color(col.r, col.g, col.b, 0.8), true)
		draw_rect(rect, Color(1, 1, 1, 0.65), false, 1.5)
		draw_string(_font, at + Vector2(7, 32), rune.substr(0, 2).to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0, 0.8))

		# The first slot is marked because it is structurally different: it
		# decides the shape, the rest only decide the contents.
		if i == 0:
			draw_string(_font, at + Vector2(1, -6), "FORM",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.55))


func _draw_readout(at: Vector2, runes: Array) -> void:
	if runes.is_empty():
		draw_string(_font, at, "J api   ·   K air   ·   L angin   ·   ESC batal",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.4))
		return

	var form: String = ViewConfig.FORM_OF.get(runes[0], "?")
	var cast_time: float = Tuning.CAST_BASE + Tuning.CAST_PER_RUNE * runes.size()

	draw_string(_font, at, "%s   ·   lepas %.2fs" % [form, cast_time],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.92, 0.7, 0.9))


# Shows how much of the useful slow-motion window is left. Filled while time is
# still deeply slowed, draining as the world speeds back up — so hesitation is
# something the player can watch happening to them.
func _draw_window_bar(at: Vector2, open_time: float) -> void:
	var scale: float = 1.0 - (1.0 - Tuning.SLOW_MIN) * exp(-open_time / Tuning.SLOW_TAU)
	var left: float = clampf(1.0 - (scale - Tuning.SLOW_MIN) / (1.0 - Tuning.SLOW_MIN), 0.0, 1.0)
	var width := Tuning.MAX_RUNES * 52.0 + (Tuning.MAX_RUNES - 1) * 8.0

	draw_rect(Rect2(at, Vector2(width, 6)), Color(0, 0, 0, 0.5), true)
	var col := Color(0.6, 0.9, 1.0).lerp(Color(1.0, 0.35, 0.3), 1.0 - left)
	draw_rect(Rect2(at, Vector2(width * left, 6)), col, true)


func _draw_hint() -> void:
	draw_string(_font, Vector2(48, 596), "Tahan SPACE untuk merapal",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.3))
