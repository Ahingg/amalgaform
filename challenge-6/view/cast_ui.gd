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
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_launch()
		return

	if not (event is InputEventKey) or event.echo:
		return

	var world = _get_world()
	if world == null:
		return
	var player := _player(world)
	if player == -1:
		return

	var key: int = event.keycode

	if key == KEY_SHIFT:
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
	# One orb at a time. Holding one blocks chanting the next, which is what
	# turns "I have a spell ready" into a decision — spend it now, or keep it
	# for a better moment — instead of a stockpile.
	if world.entity_have_component(ViewConfig.HELD_SPELL, player):
		return
	# Juga ditolak selagi rapalan sebelumnya masih terbentuk. Tanpa ini, chant
	# kedua menimpa Casting yang pertama dan spell pertamanya hilang diam-diam.
	if world.entity_have_component(ViewConfig.CASTING, player):
		return
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


# Phase two. The orb waits, so there is no timer racing the hand that has to
# travel from JKL to the mouse — that trip is exactly what made aiming and
# chanting at the same time feel awful.
func _launch() -> void:
	var world = _get_world()
	if world == null:
		return
	var player := _player(world)
	if player == -1:
		return
	if not world.entity_have_component(ViewConfig.HELD_SPELL, player):
		return
	# A bare event. Direction is read from Facing by sim, so this layer never
	# decides where a spell goes — only that the player asked for it to go.
	world.attach_component(ViewConfig.LAUNCH_SPELL, player, {})


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

func _renderer_origin() -> Vector2:
	var r := get_parent() as WorldRenderer
	return Vector2(48, 512) if r == null else r.ui_origin()


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

	_draw_dash(world, player)

	if world.entity_have_component(ViewConfig.CASTING, player):
		_draw_casting(world, player)

	if world.entity_have_component(ViewConfig.HELD_SPELL, player):
		_draw_held(world, player)

	var q := _queue(world, player)
	if q.is_empty() or not q.get("open", false):
		_draw_hint(world, player)
		return

	var runes: Array = q.get("runes", [])
	var origin := _renderer_origin() + Vector2(0, 46)

	if q.has("open_time"):
		_draw_window_bar(origin + Vector2(0, -26), float(q["open_time"]))

	_draw_runes(origin, runes)
	_draw_readout(origin + Vector2(0, 62), runes)


func _draw_runes(origin: Vector2, runes: Array) -> void:
	var box := Vector2(58, 58)
	var gap := 8.0

	for i in Tuning.MAX_RUNES:
		var at := origin + Vector2(i * (box.x + gap), 0)
		var rect := Rect2(at, box)

		if i >= runes.size():
			draw_rect(rect, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.05), true)
			draw_rect(rect, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.18), false, 1.0)
			continue

		var rune: String = runes[i]
		var col: Color = ViewConfig.color_of(rune)
		var stone := Sprites.rune_stone(rune)
		var mark := Sprites.rune_mark(rune)

		if stone != null and mark != null:
			# Batu bertinta, tanda berwarna. Tandanya digambar putih di berkasnya
			# lalu diwarnai di sini, jadi warnanya bisa disetel dan dibuat menyala
			# tanpa gambarnya digambar ulang.
			draw_texture_rect(stone, rect, false,
				Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.92))
			# Rune terakhir yang masuk berdenyut sebentar, jadi pemain tahu
			# ketikannya kebaca tanpa perlu menghitung kotak.
			var glow := 1.0
			if i == runes.size() - 1:
				glow = 1.0 + 0.35 * absf(sin(float(Time.get_ticks_msec()) / 140.0))
			draw_texture_rect(mark, rect, false,
				Color(col.r * glow, col.g * glow, col.b * glow, 1.0))
		else:
			draw_rect(rect, Color(col.r, col.g, col.b, 0.8), true)
			draw_rect(rect, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.6), false, 1.5)
			draw_string(_font, at + Vector2(7, 32), rune.substr(0, 2).to_upper(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.12, 0.11, 0.14))

		# The first slot is marked because it is structurally different: it
		# decides the shape, the rest only decide the contents.
		if i == 0:
			draw_string(_font, at + Vector2(1, -6), "FORM",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.6))


func _draw_readout(at: Vector2, runes: Array) -> void:
	if runes.is_empty():
		draw_string(_font, at, "J api  ·  K air  ·  L angin  ·  WASD arah  ·  ESC batal",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.6))
		return

	var form: String = ViewConfig.FORM_OF.get(runes[0], "?")
	var cast_time: float = Tuning.CAST_BASE + Tuning.CAST_PER_RUNE * runes.size()

	draw_string(_font, at, "%s   ·   lepas %.2fs" % [form, cast_time],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.85))


# Shows how much of the useful slow-motion window is left. Filled while time is
# still deeply slowed, draining as the world speeds back up — so hesitation is
# something the player can watch happening to them.
func _draw_window_bar(at: Vector2, open_time: float) -> void:
	var scale: float = 1.0 - (1.0 - Tuning.SLOW_MIN) * exp(-open_time / Tuning.SLOW_TAU)
	var left: float = clampf(1.0 - (scale - Tuning.SLOW_MIN) / (1.0 - Tuning.SLOW_MIN), 0.0, 1.0)
	var width := Tuning.MAX_RUNES * 52.0 + (Tuning.MAX_RUNES - 1) * 8.0

	draw_rect(Rect2(at, Vector2(width, 6)), Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.3), true)
	var col := Color(0.6, 0.9, 1.0).lerp(Color(1.0, 0.35, 0.3), 1.0 - left)
	draw_rect(Rect2(at, Vector2(width * left, 6)), col, true)


# Dash siap atau tidak. Tanpa penunjuk ini pemain menekan SPACE dan tidak tahu
# kenapa tidak terjadi apa-apa — dan sekarang niatnya memang ditolak, bukan
# ditunda, jadi tidak ada umpan balik lain yang menjelaskannya.
func _draw_dash(world, player: int) -> void:
	var at := _renderer_origin() + Vector2(0, 4)
	var w := 96.0

	if world.entity_have_component(ViewConfig.DASH_COOLDOWN, player):
		var cd = world.get_component_value(ViewConfig.DASH_COOLDOWN, player)
		var ratio: float = 0.0
		if cd.duration > 0.0:
			ratio = clampf(cd.elapsed / cd.duration, 0.0, 1.0)
		draw_rect(Rect2(at, Vector2(w, 6)), Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.3), true)
		draw_rect(Rect2(at, Vector2(w * ratio, 6)), Color(0.5, 0.55, 0.7), true)
		draw_string(_font, at + Vector2(w + 8, 7), "dash",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.35))
		return

	draw_rect(Rect2(at, Vector2(w, 6)), Color(0.6, 0.85, 1.0, 0.9), true)
	draw_string(_font, at + Vector2(w + 8, 7), "dash siap  ·  SPACE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.65))


# Jeda antara melepas SHIFT dan bola muncul. Digambar supaya ongkos rapalan
# panjang jadi sesuatu yang KELIHATAN, bukan cuma terasa lambat.
func _draw_casting(world, player: int) -> void:
	var c = world.get_component_value(ViewConfig.CASTING, player)
	if c.duration <= 0.0:
		return
	var ratio: float = clampf(c.elapsed / c.duration, 0.0, 1.0)
	var at := _renderer_origin() + Vector2(0, 26)
	var w := Tuning.MAX_RUNES * 52.0 + (Tuning.MAX_RUNES - 1) * 8.0

	draw_rect(Rect2(at, Vector2(w, 8)), Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.3), true)
	draw_rect(Rect2(at, Vector2(w * ratio, 8)), Color(0.75, 0.6, 1.0), true)
	draw_string(_font, at + Vector2(w + 8, 9), "merapal %.2fs" % c.duration,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.55))


func _draw_hint(world, player: int) -> void:
	var text := "Tahan SHIFT untuk merapal"
	if world.entity_have_component(ViewConfig.CASTING, player):
		text = "Merapal..."
	elif world.entity_have_component(ViewConfig.HELD_SPELL, player):
		text = "Bola siap  ·  arahkan mouse  ·  klik kiri untuk melepas"
	draw_string(_font, _renderer_origin() + Vector2(0, 46), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.75))
	_draw_legend()


# Legenda kontrol. Ini jawaban termurah untuk masukan "terlalu kompleks": yang
# rumit bukan sistemnya, tapi lima langkah input yang tidak pernah dijelaskan
# ke siapa pun. Ditulis permanen, bukan tutorial bertahap, karena pemain yang
# lupa di tengah pertarungan tidak akan membuka menu bantuan.
func _draw_legend() -> void:
	var at := _renderer_origin() + Vector2(0, 84)
	var ink := WorldRenderer.INK
	var dim := Color(ink.r, ink.g, ink.b, 0.42)
	var lines := [
		"WASD  bergerak          SPACE  dash",
		"SHIFT (tahan)  buka rapalan     J / K / L  antrikan rune",
		"lepas SHIFT  bentuk bola        klik kiri  lepaskan ke arah kursor",
		"R  ulangi ronde",
	]
	for i in lines.size():
		draw_string(_font, at + Vector2(0, i * 21), lines[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, dim)


# The orb, and a line to where it will go. Without the line the player has no
# idea what "aimed" means, and 360 degrees of freedom is worse than 8 was.
func _draw_held(world, player: int) -> void:
	var renderer := get_parent() as WorldRenderer
	if renderer == null:
		return
	if not world.entity_have_component(ViewConfig.POSITION, player):
		return

	var pos: Vec2 = world.get_component_value(ViewConfig.POSITION, player)
	var here := renderer.screen_of_tile(Vector2i.ZERO) \
		+ Vector2(pos.x, pos.y) * renderer.tile_size \
		+ Vector2(renderer.tile_size, renderer.tile_size) * 0.5

	var held: Dictionary = world.get_component_value(ViewConfig.HELD_SPELL, player)
	var runes: Array = held.get("runes", [])

	var dir := Vector2.RIGHT
	if world.entity_have_component(ViewConfig.FACING, player):
		var f: Vec2 = world.get_component_value(ViewConfig.FACING, player)
		var v := Vector2(f.x, f.y)
		if v != Vector2.ZERO:
			dir = v.normalized()

	draw_line(here + dir * renderer.tile_size * 0.7,
		here + dir * renderer.tile_size * 4.0,
		Color(1, 0.95, 0.7, 0.25), 2.0)

	var orb := here + dir * renderer.tile_size * 0.8
	var col := Color(1, 0.95, 0.75)
	if not runes.is_empty():
		col = ViewConfig.color_of(runes[0])
	draw_circle(orb, 13.0, Color(col.r, col.g, col.b, 0.85))
	draw_arc(orb, 15.0, 0.0, TAU, 24, Color(1, 1, 1, 0.6), 2.0)
	draw_string(_font, orb + Vector2(-6, 5), str(runes.size()),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.93, 0.88))
