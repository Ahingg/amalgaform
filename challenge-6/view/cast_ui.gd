class_name CastUI
extends Node2D

# Component names and palette come from ViewConfig; gameplay numbers from
# Tuning. Nothing tunable is defined in this file.


const BOX := 76.0
const GAP := 12.0

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
	# HUD permainan tidak digambar di layar judul: di sana belum ada yang
	# dimainkan, dan panel rapalan kosong cuma jadi kebisingan di belakang menu.
	if _di_menu():
		return
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

	var r := get_parent() as WorldRenderer
	if r == null:
		return

	var q := _queue(world, player)
	var open: bool = not q.is_empty() and q.get("open", false)
	var runes: Array = q.get("runes", []) if open else []

	# Slotnya SELALU digambar, cuma redup saat menganggur. Dua alasan: area
	# bawah tidak jadi kosong melompong, dan pemain baru sudah melihat ada
	# empat slot sebelum dia pernah merapal sekali pun.
	if not open:
		_draw_slots_idle(r)
		_draw_hint(world, player)
		return

	# Antrian rune adalah elemen yang paling sering dilihat pemain, dan dia
	# dilihat DI BAWAH TEKANAN. Karena itu dia besar dan di tengah bawah —
	# tepat di jalur pandang antara arena dan tangan, bukan di sudut.
	var total := Tuning.MAX_RUNES * BOX + (Tuning.MAX_RUNES - 1) * GAP
	var origin := _slot_origin(r)

	if q.has("open_time"):
		_draw_window_bar(origin + Vector2(0, -18), total, float(q["open_time"]))

	_draw_runes(origin, runes)
	_draw_readout(Vector2(r.hud_center_x(), origin.y + BOX + 26.0), runes)


func _slot_origin(r: WorldRenderer) -> Vector2:
	var total := Tuning.MAX_RUNES * BOX + (Tuning.MAX_RUNES - 1) * GAP
	return Vector2(r.hud_center_x() - total * 0.5, r.hud_bottom() - 118.0)


func _draw_slots_idle(r: WorldRenderer) -> void:
	var origin := _slot_origin(r)
	var c := WorldRenderer.LINE
	for i in Tuning.MAX_RUNES:
		var rect := Rect2(origin + Vector2(i * (BOX + GAP), 0), Vector2(BOX, BOX))
		draw_rect(rect, Color(c.r, c.g, c.b, 0.025), true)
		draw_rect(rect, Color(c.r, c.g, c.b, 0.09), false, 1.5)
	# Huruf tombolnya ikut ditampilkan: kaitan tombol -> slot jadi terlihat
	# sebelum dipakai, bukan sesuatu yang harus dihafal dari daftar kontrol.
	var keys := ["J", "K", "L", ""]
	for i in keys.size():
		if keys[i] == "":
			continue
		var at := origin + Vector2(i * (BOX + GAP) + BOX * 0.5 - 5.0, BOX * 0.5 + 7.0)
		draw_string(_font, at, keys[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color(c.r, c.g, c.b, 0.16))


func _draw_runes(origin: Vector2, runes: Array) -> void:
	var box := Vector2(BOX, BOX)

	for i in Tuning.MAX_RUNES:
		var at := origin + Vector2(i * (BOX + GAP), 0)
		var rect := Rect2(at, box)

		if i >= runes.size():
			# Slot kosong: cuma bingkai tipis. Slot yang belum terisi tidak
			# boleh menarik perhatian sekuat yang sudah.
			draw_rect(rect, Color(WorldRenderer.LINE.r, WorldRenderer.LINE.g, WorldRenderer.LINE.b, 0.035), true)
			draw_rect(rect, Color(WorldRenderer.LINE.r, WorldRenderer.LINE.g, WorldRenderer.LINE.b, 0.14), false, 1.5)
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
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.6))


func _draw_readout(at: Vector2, runes: Array) -> void:
	if runes.is_empty():
		draw_string(_font, at, "J fire  ·  K water  ·  L wind  ·  WASD aim  ·  ESC cancel",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.6))
		return

	var form: String = ViewConfig.FORM_OF.get(runes[0], "?")
	var cast_time: float = Tuning.CAST_BASE + Tuning.CAST_PER_RUNE * runes.size()

	draw_string(_font, at, "%s   ·   release %.2fs" % [form, cast_time],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.85))


# Shows how much of the useful slow-motion window is left. Filled while time is
# still deeply slowed, draining as the world speeds back up — so hesitation is
# something the player can watch happening to them.
func _draw_window_bar(at: Vector2, width: float, open_time: float) -> void:
	var scale: float = 1.0 - (1.0 - Tuning.SLOW_MIN) * exp(-open_time / Tuning.SLOW_TAU)
	var left: float = clampf(1.0 - (scale - Tuning.SLOW_MIN) / (1.0 - Tuning.SLOW_MIN), 0.0, 1.0)

	draw_rect(Rect2(at, Vector2(width, 7)), Color(0, 0, 0, 0.45), true)
	var col := Color(0.55, 0.85, 1.0).lerp(Color(1.0, 0.32, 0.28), 1.0 - left)
	draw_rect(Rect2(at, Vector2(width * left, 7)), col, true)


# Dash siap atau tidak. Tanpa penunjuk ini pemain menekan SPACE dan tidak tahu
# kenapa tidak terjadi apa-apa — dan sekarang niatnya memang ditolak, bukan
# ditunda, jadi tidak ada umpan balik lain yang menjelaskannya.
func _draw_dash(world, player: int) -> void:
	var r := get_parent() as WorldRenderer
	if r == null:
		return
	var at := Vector2(28.0, r.hud_bottom() - 34.0)
	var w := 110.0

	if world.entity_have_component(ViewConfig.DASH_COOLDOWN, player):
		var cd = world.get_component_value(ViewConfig.DASH_COOLDOWN, player)
		var ratio: float = 0.0
		if cd.duration > 0.0:
			ratio = clampf(cd.elapsed / cd.duration, 0.0, 1.0)
		draw_rect(Rect2(at, Vector2(w, 6)), Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.3), true)
		draw_rect(Rect2(at, Vector2(w * ratio, 6)), Color(0.5, 0.55, 0.7), true)
		draw_string(_font, at + Vector2(w + 8, 7), "dash",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(WorldRenderer.DIM.r, WorldRenderer.DIM.g, WorldRenderer.DIM.b, 0.8))
		return

	draw_rect(Rect2(at, Vector2(w, 6)), Color(0.6, 0.85, 1.0, 0.9), true)
	draw_string(_font, at + Vector2(w + 8, 7), "dash ready  ·  SPACE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.65))


# Jeda antara melepas SHIFT dan bola muncul. Digambar supaya ongkos rapalan
# panjang jadi sesuatu yang KELIHATAN, bukan cuma terasa lambat.
func _draw_casting(world, player: int) -> void:
	var c = world.get_component_value(ViewConfig.CASTING, player)
	if c.duration <= 0.0:
		return
	var ratio: float = clampf(c.elapsed / c.duration, 0.0, 1.0)
	var r := get_parent() as WorldRenderer
	if r == null:
		return
	var w := Tuning.MAX_RUNES * BOX + (Tuning.MAX_RUNES - 1) * GAP
	var at := Vector2(r.hud_center_x() - w * 0.5, r.hud_bottom() - 136.0)

	draw_rect(Rect2(at, Vector2(w, 8)), Color(WorldRenderer.INK.r, WorldRenderer.INK.g, WorldRenderer.INK.b, 0.3), true)
	draw_rect(Rect2(at, Vector2(w * ratio, 8)), Color(0.75, 0.6, 1.0), true)
	draw_string(_font, at + Vector2(w + 8, 9), "casting %.2fs" % c.duration,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(WorldRenderer.DIM.r, WorldRenderer.DIM.g, WorldRenderer.DIM.b, 0.9))


func _draw_hint(world, player: int) -> void:
	var text := "Hold SHIFT to cast"
	if world.entity_have_component(ViewConfig.CASTING, player):
		text = "Casting..."
	elif world.entity_have_component(ViewConfig.HELD_SPELL, player):
		text = "Spell ready  ·  aim with mouse  ·  left click to throw"
	var rr := get_parent() as WorldRenderer
	if rr != null:
		var tw := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		# Sejajar dengan tempat bacaan wujud muncul saat merapal, jadi baris ini
		# tidak pernah pindah-pindah dan tidak menabrak slot.
		draw_string(_font, Vector2(rr.hud_center_x() - tw * 0.5, rr.hud_bottom() - 16.0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17,
			Color(WorldRenderer.LINE.r, WorldRenderer.LINE.g, WorldRenderer.LINE.b, 0.8))
	_draw_legend()


# Legenda kontrol. Ini jawaban termurah untuk masukan "terlalu kompleks": yang
# rumit bukan sistemnya, tapi lima langkah input yang tidak pernah dijelaskan
# ke siapa pun. Ditulis permanen, bukan tutorial bertahap, karena pemain yang
# lupa di tengah pertarungan tidak akan membuka menu bantuan.
func _draw_legend() -> void:
	var r := get_parent() as WorldRenderer
	if r == null:
		return
	# Petunjuk kontrol di sudut kanan bawah dan sangat redup: perlu ada untuk
	# yang baru main, tapi tidak boleh ikut berebut perhatian tiap ronde.
	var c := WorldRenderer.DIM
	var dim := Color(c.r, c.g, c.b, 0.75)
	var lines := [
		"WASD move      SPACE dash      R retry",
		"Hold SHIFT → J/K/L → release → left click",
	]
	var right: float = r.get_viewport_rect().size.x - 28.0
	var bottom: float = r.hud_bottom() - 46.0
	for i in lines.size():
		var w := _font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(_font, Vector2(right - w, bottom + i * 20.0), lines[i],
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

	var t: float = float(Time.get_ticks_msec()) / 1000.0

	# Melayang di atas bahu, bukan menempel di depan badan. Bola yang menempel
	# terbaca sebagai bagian dari sprite; yang melayang terbaca sebagai sesuatu
	# yang sedang DITAHAN — dan itu memang keadaannya.
	# Naik SETINGGI sprite, bukan setinggi kotak tabrakan: kotaknya cuma sepetak,
	# sedangkan gambar penyihirnya 2.3 petak, jadi lift sepetak mendarat tepat di
	# wajahnya. Simpangan mendatarnya ikut arah hadap, tapi komponen tegaknya
	# tidak — kalau ikut, membidik ke atas akan menenggelamkan bola di kepala.
	var orb := here + Vector2(dir.x * renderer.tile_size * 0.8,
		-renderer.tile_size * 1.9 + sin(t * 2.6) * 4.0)

	# Garis bidik berangkat dari BOLA, bukan dari badan: yang akan terbang itu
	# bolanya.
	draw_line(orb + dir * renderer.tile_size * 0.4,
		orb + dir * renderer.tile_size * 4.2,
		Color(1, 0.95, 0.7, 0.22), 2.0)

	var col := _rune_blend(runes)
	var side: float = renderer.tile_size * 1.35
	var box := Rect2(orb - Vector2(side, side) * 0.5, Vector2(side, side))

	var frame := Sprites.held_frame(t)
	if frame == null:
		draw_circle(orb, 13.0, Color(col.r, col.g, col.b, 0.85))
		draw_arc(orb, 15.0, 0.0, TAU, 24, Color(1, 1, 1, 0.6), 2.0)
		return

	# Cahaya palsu: gambar yang sama diulang lebih besar dengan alpha rendah.
	# Jauh lebih murah daripada shader glow, dan di ukuran segini hasilnya sama.
	for i in 2:
		var s: float = side * (1.18 + 0.2 * i)
		draw_texture_rect(frame, Rect2(orb - Vector2(s, s) * 0.5, Vector2(s, s)),
			false, Color(col.r, col.g, col.b, 0.09))

	var support := Sprites.held_support()
	if support != null:
		var sw: float = side * 1.3
		draw_texture_rect(support, Rect2(orb - Vector2(sw, sw) * 0.5, Vector2(sw, sw)),
			false, Color(col.r, col.g, col.b, 0.45))

	# Cangkang dan inti diwarnai TERPISAH, alasan yang sama seperti bola api:
	# api dicampur air jadi merah muda, yang bukan api dan bukan air. Cangkang
	# ikut rune terakhir, inti ikut rune pertama — jadi bola api-air punya inti
	# merah di dalam cangkang biru, dan isinya terbaca sebagai dua bahan.
	var shell := _rune_at(runes, -1)
	var core_col := _rune_at(runes, 0)
	draw_texture_rect(frame, box, false, Color(shell.r, shell.g, shell.b, 0.95))

	var core := Sprites.held_core()
	if core != null:
		# Inti dicerahkan mendekati putih: pusat yang lebih terang dari tepinya
		# itu satu-satunya cara membaca "panas" tanpa shader.
		draw_texture_rect(core, box, false, Color(
			minf(core_col.r * 1.7, 1.0), minf(core_col.g * 1.7, 1.0),
			minf(core_col.b * 1.7, 1.0), 1.0))


# Rune ke-i dari antrian; -1 berarti yang terakhir. Kalau antriannya kosong,
# warna netral.
func _rune_at(runes: Array, i: int) -> Color:
	if runes.is_empty():
		return Color(1, 0.95, 0.75)
	var n := runes.size()
	return ViewConfig.color_of(String(runes[(i + n) % n]))


# Rata-rata warna semua rune di antrian. Dipakai bola di tangan supaya warnanya
# menunjukkan ISI rapalan, bukan cuma rune pertama yang menentukan wujud.
func _rune_blend(runes: Array) -> Color:
	if runes.is_empty():
		return Color(1, 0.95, 0.75)
	var r := 0.0
	var g := 0.0
	var b := 0.0
	for rune in runes:
		var c: Color = ViewConfig.color_of(String(rune))
		r += c.r
		g += c.g
		b += c.b
	var n := float(runes.size())
	return Color(r / n, g / n, b / n)


func _di_menu() -> bool:
	var r := get_parent()
	if r == null:
		return false
	var main = r.get_parent()
	return main != null and main.has_method("is_menu") and main.is_menu()
