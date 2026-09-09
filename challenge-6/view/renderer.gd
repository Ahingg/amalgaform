class_name WorldRenderer
extends Node2D

# ============================================================================
# VIEW LAYER — READ ONLY
#
# This file never writes anything into World. It only asks and draws. If this
# file were deleted, the simulation would still run exactly the same — it would
# just be invisible.
#
# CONTRACT with sim/:
#   - component "Position" holds {"x": float, "y": float} in tile units
#   - component "Size" (optional) holds {"w": float, "h": float}, default 1x1
#
# Raw strings are used here on purpose instead of Comp.XXX, so that this file
# can never break sim/ parsing if a constant is missing or renamed.
# To make a new component show up as a badge, add it to ViewConfig.BADGE_ORDER.
# ============================================================================


# Dunia gelap, dan pemain satu-satunya yang terang.
#
# Nilai ditumpuk begini: latar di TENGAH, dua ekstrem dipakai untuk yang harus
# ketemu cepat. Pemain hampir putih, musuh hampir hitam — dua-duanya menonjol
# dari latar, dan pemain tidak pernah hilang di antara kerumunan musuh.
#
# Kalau latarnya terang, musuh hitam menang telak dan pemain putih justru
# tenggelam. Itu yang terjadi di versi kertas.
const BG := Color(0.075, 0.070, 0.095)       # di luar arena: paling gelap
const ARENA := Color(0.155, 0.150, 0.190)    # lantai arena
const ARENA_EDGE := Color(0.105, 0.100, 0.130)  # tepi arena, buat vignette
const LINE := Color(0.88, 0.86, 0.83)        # teks utama, bingkai
const DIM := Color(0.52, 0.50, 0.56)         # teks sekunder
const FILL := Color(0.98, 0.97, 0.95)        # isi badan pemain
const SHADOW := Color(0.045, 0.040, 0.060)   # musuh: hampir hitam

# Nama lama dipertahankan supaya berkas lain tidak perlu diubah semuanya.
const PAPER := BG
const INK := LINE

@export var grid_width: int = 20
@export var grid_height: int = 12
# Daftar komponen di bawah tiap entity: alat debug ECS paling berguna selama
# ngoding, tapi bikin layar berantakan dan tidak terbaca. Default mati, F1 untuk
# menyalakan.
@export var show_badges: bool = false

# Ruang yang disisakan untuk HUD di atas dan di bawah arena. HUD digambar
# MENUMPUK di atas latar, bukan di pita terpisah — pita bikin arenanya menyusut
# dan menyisakan pelataran kosong yang terbaca sebagai belum jadi.
const TOP_BAR := 46.0
const BOTTOM_BAR := 150.0
const SIDE_PAD := 28.0


# Dihitung ulang tiap gambar dari ukuran jendela, jadi arenanya selalu mengisi
# dan tidak pernah ketinggalan kalau jendelanya diubah.
var tile_size: float = 52.0
var margin: Vector2 = Vector2(24, 24)

var _font: Font


# --- efek yang butuh ingatan antar frame -------------------------------------
#
# Lapisan tampilan BOLEH punya ingatan; sim tidak. Yang disimpan di bawah ini
# semuanya cuma JEJAK — hasil membandingkan dunia frame ini dengan frame lalu.
# Tidak ada satu pun keadaan permainan yang tinggal di sini: kalau seluruh blok
# ini dihapus, simulasinya jalan persis sama, cuma jadi hambar.
#
# Semuanya diurus dengan delta ASLI, bukan delta terskala. Guncangan yang ikut
# melambat saat hit stop akan hilang justru di saat dia paling dibutuhkan.

const SHAKE_HIT := 6.0        # piksel, saat sesuatu kena keras
const SHAKE_DEATH := 10.0     # piksel, saat musuh lenyap
const SHAKE_DECAY := 40.0     # piksel per detik
const BURST_LIFE := 0.45
const LAUNCH_LIFE := 0.14     # lebih lama dari ini, kilatnya berhenti terbaca
							  # sebagai "lahir" dan mulai terbaca sebagai benda
const TRAIL_LIFE := 0.24
const HIT_FLASH := 0.12

const KIND_DEATH := 0
const KIND_LAUNCH := 1

var _shake: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _seen_enemies: Dictionary = {}   # id -> pusat terakhir, dalam petak
var _seen_spells: Dictionary = {}    # id -> true
var _bursts: Array = []
var _trail: Array = []
var _had_hit_stop: bool = false
var _last_world = null


func _fit_arena() -> void:
	var vp := get_viewport_rect().size
	var usable := Vector2(vp.x - SIDE_PAD * 2.0, vp.y - TOP_BAR - BOTTOM_BAR)
	tile_size = floorf(minf(usable.x / float(grid_width), usable.y / float(grid_height)))
	var w := tile_size * grid_width
	var h := tile_size * grid_height
	margin = Vector2((vp.x - w) * 0.5, TOP_BAR + (usable.y - h) * 0.5)


func _ready() -> void:
	_font = ThemeDB.fallback_font
	# Input layers live under the renderer so they can reuse the geometry
	# helpers above, and so main.gd does not need to know they exist.
	# AssemblyUI is parked: machine placement before the round no longer exists
	# after design revision 3. The file is kept for the casting panel.
	add_child(PlayerInput.new())
	add_child(CastUI.new())
	add_child(RoundUI.new())
	# Penuntun rapalan pertama. Menghilang sendiri begitu satu spell dilempar,
	# dan tidak pernah muncul lagi di percobaan berikutnya.
	add_child(Onboarding.new())
	# Layar judul dan jeda. Ditambahkan TERAKHIR supaya dia yang pertama
	# menerima input yang belum ditangani siapa pun.
	add_child(MenuUI.new())
	if DemoInput.enabled():
		add_child(DemoInput.new())


func _process(delta: float) -> void:
	# The simulation advances in Main's _physics_process. Here we only ask for
	# a repaint every rendered frame.
	_update_fx(delta)
	queue_redraw()


func _update_fx(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - SHAKE_DECAY * delta)
		var a := randf() * TAU
		_shake_offset = Vector2(cos(a), sin(a)) * _shake
	else:
		_shake_offset = Vector2.ZERO

	for b in _bursts:
		b["t"] += delta
	_bursts = _bursts.filter(func(b): return b["t"] < BURST_LIFE)
	for s in _trail:
		s["t"] += delta
	_trail = _trail.filter(func(s): return s["t"] < TRAIL_LIFE)

	var world = _get_world()

	# Retry membuang World lama dan bikin yang baru. Tanpa penjagaan ini, SEMUA
	# id dari ronde lama terbaca "hilang" sekaligus dan layarnya meledak jadi
	# ledakan kematian massal.
	if world != _last_world:
		_last_world = world
		_seen_enemies.clear()
		_seen_spells.clear()
		_bursts.clear()
		_trail.clear()
		_had_hit_stop = false
		return
	if world == null:
		return

	_watch_hit_stop(world)
	_watch_deaths(world)
	_watch_launches(world)
	_watch_dash(world)


func _center_of(world, id: int) -> Vector2:
	var p: Vec2 = world.get_component_value(ViewConfig.POSITION, id)
	var s := Vector2.ONE
	if world.entity_have_component(ViewConfig.SIZE, id):
		var sz: Size = world.get_component_value(ViewConfig.SIZE, id)
		s = Vector2(sz.w, sz.h)
	return Vector2(p.x, p.y) + s * 0.5


# HitStop muncul di entity ronde persis saat sesuatu kena keras. Guncangan
# dipicu dari keadaan yang SAMA, bukan dari kejadian tersendiri — jadi dua-duanya
# tidak pernah bisa lepas sinkron, dan menyetel salah satunya di Tuning otomatis
# menyetel keduanya.
func _watch_hit_stop(world) -> void:
	var q: Array[String] = [ViewConfig.ROUND]
	var rounds: Array[int] = world.get_entities_with_comp(q)
	var now := false
	if not rounds.is_empty():
		now = world.entity_have_component(ViewConfig.HIT_STOP, rounds[0])
	if now and not _had_hit_stop:
		_shake = maxf(_shake, SHAKE_HIT)
	_had_hit_stop = now


# Kematian tidak punya komponen dan tidak perlu punya: musuh yang mati itu id
# yang ADA frame lalu dan TIDAK ADA sekarang. Posisi terakhirnya disimpan di
# sini karena setelah entity-nya lenyap, tidak ada lagi yang bisa ditanya.
func _watch_deaths(world) -> void:
	var q: Array[String] = [ViewConfig.ENEMY, ViewConfig.POSITION]
	var alive := {}
	for e in world.get_entities_with_comp(q):
		alive[e] = _center_of(world, e)
	for id in _seen_enemies:
		if alive.has(id):
			continue
		_bursts.append({"at": _seen_enemies[id], "t": 0.0,
			"kind": KIND_DEATH, "seed": float(id) * 1.7})
		_shake = maxf(_shake, SHAKE_DEATH)
	_seen_enemies = alive


func _watch_launches(world) -> void:
	var q: Array[String] = [ViewConfig.RUNES, ViewConfig.POSITION]
	var now := {}
	for e in world.get_entities_with_comp(q):
		now[e] = true
		if _seen_spells.has(e):
			continue
		var runes: Array = world.get_component_value(ViewConfig.RUNES, e)
		_bursts.append({"at": _center_of(world, e), "t": 0.0,
			"kind": KIND_LAUNCH, "seed": float(e) * 1.7,
			"color": _blend_runes(runes)})
	_seen_spells = now


func _watch_dash(world) -> void:
	var q: Array[String] = [ViewConfig.PLAYER, ViewConfig.DASH, ViewConfig.POSITION]
	for e in world.get_entities_with_comp(q):
		var p: Vec2 = world.get_component_value(ViewConfig.POSITION, e)
		var at := Vector2(p.x, p.y)
		# Disaring per jarak, bukan per frame: kalau tidak, dash 0.15 detik
		# meninggalkan sembilan siluet yang saling menumpuk jadi satu gumpalan.
		if not _trail.is_empty() and _trail[-1]["at"].distance_to(at) < 0.3:
			return
		_trail.append({"at": at, "t": 0.0})


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F1:
		show_badges = not show_badges
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F11:
		# Untuk presentasi: jendela kecil di proyektor tidak terbaca.
		var w := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if w == DisplayServer.WINDOW_MODE_FULLSCREEN
			else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	_fit_arena()
	_draw_grid()

	var world = _get_world()
	if world == null:
		_draw_message("Waiting for World.")
		return

	var query: Array[String] = [ViewConfig.POSITION]
	var ids: Array[int] = world.get_entities_with_comp(query)

	if ids.is_empty():
		_draw_message("No entity has a Position yet.")
		return

	# Urutan gambar itu kedalaman. Dua aturan:
	#   1. Efek yang menempel di LANTAI (genangan) selalu paling bawah — kalau
	#      tidak, dia bisa menutupi pemain dan menutupi apa yang harus dihindari.
	#   2. Sisanya diurutkan dari posisi y, jadi yang lebih dekat ke kamera
	#      (lebih bawah) menimpa yang lebih jauh. Itu yang bikin tampak atas
	#      terasa punya kedalaman tanpa satu pun perhitungan tambahan.
	var ground: Array[int] = []
	var actors: Array[int] = []
	for id in ids:
		if _is_ground_effect(world, id):
			ground.append(id)
		else:
			actors.append(id)

	actors.sort_custom(func(a, b):
		var pa: Vec2 = world.get_component_value(ViewConfig.POSITION, a)
		var pb: Vec2 = world.get_component_value(ViewConfig.POSITION, b)
		return pa.y < pb.y)

	for id in ground:
		_draw_entity(world, id)
	_draw_trail()
	for id in actors:
		_draw_entity(world, id)
	_draw_bursts()


# Bayangan dash: siluet garis pemain yang tertinggal, memudar kuadratik supaya
# yang paling belakang hilang cepat dan ekornya tidak terlihat menggantung.
func _draw_trail() -> void:
	if _trail.is_empty():
		return
	var pair: Array = Sprites.player_pose(true, false)
	var align := Sprites.content_rect(pair[1])
	var org := screen_of_tile(Vector2i.ZERO)
	for s in _trail:
		var f: float = 1.0 - float(s["t"]) / TRAIL_LIFE
		var at: Vector2 = s["at"]
		var rect := Rect2(org + at * tile_size, Vector2(tile_size, tile_size))
		_blit(pair[1], rect, Sprites.PLAYER_SCALE, false,
			Color(FILL.r, FILL.g, FILL.b, 0.28 * f * f), align)


func _draw_bursts() -> void:
	var org := screen_of_tile(Vector2i.ZERO)
	for b in _bursts:
		var at: Vector2 = org + (b["at"] as Vector2) * tile_size
		if int(b["kind"]) == KIND_LAUNCH:
			_draw_launch_flash(at, float(b["t"]), b.get("color", LINE))
		else:
			_draw_death_burst(at, float(b["t"]), float(b["seed"]))


# Kilat lepas: satu titik cahaya di tempat spell lahir. Gunanya menjawab
# "barusan keluar dari mana", yang di layar penuh musuh tidak selalu jelas.
func _draw_launch_flash(at: Vector2, age: float, c: Color) -> void:
	var g: float = age / LAUNCH_LIFE
	if g >= 1.0:
		return
	var fade: float = 1.0 - g
	draw_circle(at, tile_size * (0.30 + 0.45 * g), Color(c.r, c.g, c.b, 0.40 * fade))
	draw_arc(at, tile_size * (0.35 + 0.85 * g), 0.0, TAU, 20,
		Color(1, 1, 1, 0.55 * fade), 2.0)


# Ledakan mati. Warnanya TERANG, bukan warna musuhnya — musuh hampir hitam di
# atas latar gelap, jadi percikan sewarna musuh sama saja dengan tidak ada.
func _draw_death_burst(at: Vector2, age: float, seed: float) -> void:
	var f: float = age / BURST_LIFE
	var ease: float = 1.0 - pow(1.0 - f, 3.0)
	var a: float = pow(1.0 - f, 1.6)
	draw_arc(at, tile_size * (0.2 + 1.1 * ease), 0.0, TAU, 28,
		Color(LINE.r, LINE.g, LINE.b, 0.5 * a), 2.5)

	# Aset percikan yang sama seperti kilat kena, dipakai jauh lebih besar dan
	# lebih lama. Satu bahasa visual untuk "kena" dan "mati" — yang membedakan
	# cuma ukuran dan lamanya, dan itu memang perbedaan yang sebenarnya.
	var box := Rect2(at - Vector2(tile_size, tile_size) * 0.5,
		Vector2(tile_size, tile_size))
	var layers: Array = Sprites.impact_layers(f)
	if layers[0] != null:
		var grow: float = 2.6 + 1.8 * ease
		_blit(layers[0], box, grow, seed > 0.0 and fmod(seed, 2.0) < 1.0,
			Color(LINE.r, LINE.g, LINE.b, a), Rect2(), false)
		if layers[1] != null:
			_blit(layers[1], box, grow * 1.15, false,
				Color(1, 0.97, 0.92, 0.75 * a), Rect2(), false)
		return

	for i in 9:
		var ang: float = seed + float(i) * (TAU / 9.0)
		var dir := Vector2(cos(ang), sin(ang))
		var d: float = tile_size * (0.25 + 1.45 * ease)
		draw_line(at + dir * d * 0.7, at + dir * d,
			Color(LINE.r, LINE.g, LINE.b, 0.65 * a), 2.0)


func _is_ground_effect(world, id: int) -> bool:
	if not world.entity_have_component(ViewConfig.RUNES, id):
		return false
	# Spell tanpa Velocity berarti dia sudah diam di lantai.
	return not world.entity_have_component(ViewConfig.VELOCITY, id)


# --- geometry helpers, shared with the input layer -----------------------------
# The UI must not recompute tile maths on its own; if the grid moves, only this
# file should need to know.

# Dipakai lapisan UI supaya panel selalu duduk di bawah arena, berapa pun
# ukuran gridnya. Sebelumnya koordinatnya angka mati dari grid 12x8 yang lama,
# jadi panelnya menimpa lapangan begitu arena digedein.
# Titik-titik jangkar HUD. Semua dihitung dari jendela, bukan dari arena, jadi
# HUD tetap menempel di tepi layar berapa pun ukuran arenanya.
func hud_bottom() -> float:
	return get_viewport_rect().size.y


func hud_center_x() -> float:
	return get_viewport_rect().size.x * 0.5


func ui_origin() -> Vector2:
	return Vector2(margin.x, margin.y + grid_height * tile_size + 20.0)


func tile_at(screen_pos: Vector2) -> Vector2i:
	var local := screen_pos - margin
	return Vector2i(floori(local.x / tile_size), floori(local.y / tile_size))


# Fractional tile coordinates, unlike tile_at which rounds down. Aiming needs
# the real point under the cursor, not the tile it happens to sit in.
func world_at(screen_pos: Vector2) -> Vector2:
	return (screen_pos - margin) / tile_size


# Guncangan masuk di SINI saja. tile_at() dan world_at() sengaja tetap memakai
# margin mentah: itu pemetaan INPUT, dan bidikan yang ikut bergoyang bikin
# guncangan berubah dari rasa jadi cacat kontrol. ui_origin() juga tidak ikut,
# supaya HUD tetap diam saat lapangannya berguncang.
func screen_of_tile(tile: Vector2i) -> Vector2:
	return margin + _shake_offset + Vector2(tile) * tile_size


func inside_grid(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < grid_width and tile.y < grid_height


# --- world lookup ------------------------------------------------------------

# Fetched every frame on purpose instead of cached once in _ready.
# Reason: on retry, Main builds a NEW World. A cached reference would keep
# drawing the old, discarded world forever.
func _get_world():
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get("world")


# --- drawing -----------------------------------------------------------------

func _draw_grid() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), BG, true)

	var w := grid_width * tile_size
	var h := grid_height * tile_size
	var org := screen_of_tile(Vector2i.ZERO)
	var arena := Rect2(org, Vector2(w, h))

	draw_rect(arena, ARENA, true)
	_draw_floor(org)

	# Vignette: tepi arena diredupkan berlapis supaya mata tertarik ke tengah
	# dan batas lapangan terasa tanpa perlu dinding yang digambar.
	var layers := 7
	for i in layers:
		var f := float(i) / float(layers)
		var inset := f * tile_size * 1.6
		var a := 0.055 * (1.0 - f)
		draw_rect(Rect2(arena.position + Vector2(inset, inset),
			arena.size - Vector2(inset, inset) * 2.0),
			Color(ARENA_EDGE.r, ARENA_EDGE.g, ARENA_EDGE.b, a), false, tile_size * 0.34)

	var line_color := Color(LINE.r, LINE.g, LINE.b, 0.022)
	for i in range(grid_width + 1):
		var x := org.x + i * tile_size
		draw_line(Vector2(x, org.y), Vector2(x, org.y + h), line_color, 1.0)
	for j in range(grid_height + 1):
		var y := org.y + j * tile_size
		draw_line(Vector2(org.x, y), Vector2(org.x + w, y), line_color, 1.0)

	draw_rect(arena, Color(LINE.r, LINE.g, LINE.b, 0.22), false, 2.0)


# Lantai: warna dasar gelap, lalu dua lapis goresan putih transparan di atasnya.
#
# Versi sebelumnya memakai ubin lantai bergambar penuh, dan itu selalu terbaca
# sebagai petak berapa pun besar bloknya — karena setiap ubin punya batas, dan
# mata menemukan batas. Goresan transparan tidak punya batas: yang terlihat cuma
# guratannya, dan latar hitam di bawahnya menyambung tanpa putus.
#
# Dua lapis dengan SKALA BERBEDA, bukan dua lapis sejajar. Kalau skalanya sama,
# keduanya berulang di jarak yang sama dan polanya justru jadi lebih kentara,
# bukan lebih samar.
const FLOOR_TILE_A := 6      # berapa petak per ulangan, lapis lembut
const FLOOR_TILE_B := 9      # lapis tajam, sengaja tidak kelipatan A

func _draw_floor(org: Vector2) -> void:
	var w: float = grid_width * tile_size
	var h: float = grid_height * tile_size
	_floor_layer(org, Vector2(w, h), Sprites.floor_layer(0), FLOOR_TILE_A, 0.10)
	_floor_layer(org, Vector2(w, h), Sprites.floor_layer(1), FLOOR_TILE_B, 0.07)


func _floor_layer(org: Vector2, size: Vector2, tex: Texture2D,
		petak: int, alpha: float) -> void:
	if tex == null:
		return
	var sisi: float = tile_size * petak
	var kolom: int = int(ceil(size.x / sisi))
	var baris: int = int(ceil(size.y / sisi))
	var warna := Color(1, 1, 1, alpha)
	for by in baris:
		for bx in kolom:
			var at := org + Vector2(bx, by) * sisi
			# Bagian yang lewat tepi arena dipotong lewat REGION, bukan dibiarkan
			# meluber: arena punya bingkai, dan goresan yang keluar dari bingkai
			# langsung terbaca sebagai bocor.
			var lebar: float = minf(sisi, org.x + size.x - at.x)
			var tinggi: float = minf(sisi, org.y + size.y - at.y)
			var src := Rect2(Vector2.ZERO,
				Vector2(tex.get_width() * lebar / sisi, tex.get_height() * tinggi / sisi))
			draw_texture_rect_region(tex, Rect2(at, Vector2(lebar, tinggi)), src, warna)


func _draw_entity(world, id: int) -> void:
	var pos: Vec2 = world.get_component_value(ViewConfig.POSITION, id)
	var px: float = pos.x
	var py: float = pos.y

	var w := 1.0
	var h := 1.0
	if world.entity_have_component(ViewConfig.SIZE, id):
		var s: Size = world.get_component_value(ViewConfig.SIZE, id)
		w = s.w
		h = s.h

	var top_left := screen_of_tile(Vector2i.ZERO) + Vector2(px, py) * tile_size
	var size := Vector2(w, h) * tile_size
	var rect := Rect2(top_left, size)

	var color := _color_for(world, id)

	# Sorot petak yang tersentuh dulunya alat debug untuk keputusan posisi
	# pecahan. Sekarang cuma bikin kotak pucat yang membingungkan, jadi ikut
	# badge: mati kecuali F1.
	if show_badges:
		_highlight_occupied_tiles(px, py, w, h, color)

	# While the i-frame window is open the entity blinks, so you can see exactly
	# when it can be hurt again. Blink is driven by the component's own elapsed
	# value, not by wall-clock time, so it stays in step with the simulation.
	var alpha := 0.85
	if world.entity_have_component(ViewConfig.INVULNERABLE, id):
		var inv: Countdown = world.get_component_value(ViewConfig.INVULNERABLE, id)
		var t: float = inv.elapsed
		alpha = 0.85 if fmod(t, 0.16) < 0.08 else 0.2

	# Sprite digambar penuh; alpha 0.85 itu sisa dari zaman kotak dan bikin isi
	# putih pemain turun jadi abu-abu. Kedip i-frame tetap lewat.
	var sprite_alpha: float = 1.0 if alpha > 0.5 else alpha
	if not _draw_sprite(world, id, rect, sprite_alpha):
		draw_rect(rect, Color(color.r, color.g, color.b, alpha), true)
		draw_rect(rect, Color(INK.r, INK.g, INK.b, 0.55), false, 1.5)

	# Kotak tabrakan ikut badge: berguna untuk memeriksa perataan sprite, tapi
	# tidak ada urusannya dengan pemain.
	if show_badges:
		draw_rect(rect, Color(1, 0.2, 0.2, 0.9), false, 2.0)

	# Delay is drawn as a progress bar above the entity.
	if world.entity_have_component(ViewConfig.DELAY, id):
		_draw_delay_bar(world, id, top_left, size.x)

	# Panah arah cuma untuk player: di sana dia menunjukkan ke mana spell akan
	# pergi. Di musuh dia cuma coretan tambahan yang meramaikan layar.
	if world.entity_have_component(ViewConfig.FACING, id) \
			and world.entity_have_component(ViewConfig.PLAYER, id):
		_draw_aim(world, id, top_left + size * 0.5)

	if show_badges:
		draw_string(_font, top_left + Vector2(5, 16), "#%d" % id,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(INK.r, INK.g, INK.b, 0.8))

	# Bar HP musuh hanya muncul setelah dia terluka. Empat sampai delapan bar
	# penuh di layar itu kebisingan: tidak satu pun sedang memberi tahu apa-apa.
	# Bar pemain selalu tampak — itu nyawa sendiri, selalu relevan.
	if world.entity_have_component(ViewConfig.HEALTH, id):
		var hp0: Health = world.get_component_value(ViewConfig.HEALTH, id)
		var is_player0: bool = world.entity_have_component(ViewConfig.PLAYER, id)
		if is_player0 or hp0.current < hp0.max:
			_draw_health_bar(world, id, top_left + Vector2(0, size.y + 3), size.x)

	if show_badges:
		var badges := _component_badges(world, id)
		if badges != "":
			draw_string(_font, top_left + Vector2(0, size.y + 22), badges,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.65))


func _draw_aim(world, id: int, center: Vector2) -> void:
	var f: Vec2 = world.get_component_value(ViewConfig.FACING, id)
	var dir := Vector2(f.x, f.y)
	if dir == Vector2.ZERO:
		return
	dir = dir.normalized()

	var near := center + dir * tile_size * 0.55
	var far := center + dir * tile_size * 1.35
	draw_line(near, far, Color(INK.r, INK.g, INK.b, 0.55), 3.0)
	# A small head, so the direction reads at a glance instead of being a stick.
	var side := dir.orthogonal() * tile_size * 0.16
	draw_line(far, far - dir * tile_size * 0.22 + side, Color(INK.r, INK.g, INK.b, 0.55), 3.0)
	draw_line(far, far - dir * tile_size * 0.22 - side, Color(INK.r, INK.g, INK.b, 0.55), 3.0)


# Menggambar sprite kalau entity ini punya. Balikan false artinya tidak ada
# sprite yang cocok, dan pemanggil menggambar kotak seperti dulu — jadi entity
# yang belum punya gambar tetap kelihatan, bukan menghilang.
func _draw_sprite(world, id: int, rect: Rect2, alpha: float) -> bool:
	var is_player: bool = world.entity_have_component(ViewConfig.PLAYER, id)
	var is_enemy: bool = world.entity_have_component(ViewConfig.ENEMY, id)
	var t: float = float(Time.get_ticks_msec()) / 1000.0

	if not (is_player or is_enemy):
		return _draw_spell(world, id, rect, t)

	if is_player:
		var moving := false
		if world.entity_have_component(ViewConfig.MOVE_INTENT, id):
			var mi: Vec2 = world.get_component_value(ViewConfig.MOVE_INTENT, id)
			moving = absf(mi.x) > 0.01 or absf(mi.y) > 0.01
		var casting: bool = world.entity_have_component(ViewConfig.CASTING, id)
		if not casting and world.entity_have_component(ViewConfig.CAST_QUEUE, id):
			var q: Dictionary = world.get_component_value(ViewConfig.CAST_QUEUE, id)
			casting = q.get("open", false)

		# Lingkaran rapalan digambar DULU supaya dia ada di lantai, di bawah kaki.
		if casting:
			_draw_cast_circles(world, id, rect, t)

		var pair: Array = Sprites.player_pose(moving, casting)
		var flip := _facing_flip(world, id, Sprites.PLAYER_FACES_LEFT)
		# Garis jadi acuan untuk keduanya, supaya isi tidak lepas dari garisnya.
		var align := Sprites.content_rect(pair[1])
		# Isi putih, GARIS tetap gelap. Kalau garisnya ikut terang, coretan tinta
		# di dalam badan hilang dan figurnya jadi satu gumpalan pucat.
		_blit(pair[0], rect, Sprites.PLAYER_SCALE, flip, Color(FILL.r, FILL.g, FILL.b, alpha), align)
		_blit(pair[1], rect, Sprites.PLAYER_SCALE, flip, Color(SHADOW.r, SHADOW.g, SHADOW.b, alpha), align)
		return true

	# Musuh hampir hitam, dan tanpa tepi terang dia lumer jadi satu massa dengan
	# lantai gelap begitu berkerumun.
	#
	# Tepinya TIDAK bisa dibuat dari spritenya sendiri. Modulate itu perkalian
	# dan seni musuh ini 97% hitam pekat, jadi menggambarnya berkali-kali dengan
	# warna terang tetap menghasilkan hitam — versi lama berkas ini melakukan
	# persis itu selama berhari-hari dan tidak menghasilkan apa pun.
	#
	# Yang dipakai sekarang: gambar siluet putih (dibuat tools/make_silhouette.py)
	# digambar SEDIKIT LEBIH BESAR di belakang badannya. Yang menyembul di
	# pinggirnya itu garis tepinya.
	var etex := Sprites.enemy_walk(id, t)
	var eflip := _facing_flip(world, id, Sprites.ENEMY_FACES_LEFT)
	var sil := Sprites.enemy_silhouette(id, t)
	if sil != null:
		# Digeser ke delapan arah pada skala YANG SAMA, bukan digambar sekali
		# lebih besar. Memperbesar akan menumbuhkan gambar dari titik jangkarnya
		# — dan jangkar di sini ada di KAKI, jadi garisnya jadi tebal di kepala
		# dan hilang sama sekali di kaki.
		var d: float = maxf(1.5, tile_size * 0.045)
		for off in [Vector2(-d, 0), Vector2(d, 0), Vector2(0, -d), Vector2(0, d),
				Vector2(-d, -d) * 0.7, Vector2(d, -d) * 0.7,
				Vector2(-d, d) * 0.7, Vector2(d, d) * 0.7]:
			_blit(sil, Rect2(rect.position + off, rect.size), Sprites.ENEMY_SCALE,
				eflip, Color(LINE.r, LINE.g, LINE.b, alpha * 0.42))

	# Kilat kena digambar SEBELUM badannya, jadi cahayanya ada di belakang dan
	# siluet musuhnya tetap terbaca. Kalau ditumpuk di atas, yang terjadi cuma
	# gumpalan putih yang menutupi musuhnya sendiri.
	if world.entity_have_component(ViewConfig.INVULNERABLE, id):
		var inv: Countdown = world.get_component_value(ViewConfig.INVULNERABLE, id)
		if inv.elapsed < HIT_FLASH:
			_draw_hit_flash(etex, rect, eflip, inv.elapsed / HIT_FLASH)

	# Digambar dengan warna aslinya, TIDAK diwarnai. Modulate itu perkalian,
	# jadi mewarnai dengan warna gelap ikut menghapus goresan putih di wajahnya
	# — dan justru putih itu yang bikin musuhnya terlihat hidup.
	_blit(etex, rect, Sprites.ENEMY_SCALE, eflip, Color(1, 1, 1, alpha))

	if world.entity_have_component(ViewConfig.WET, id):
		_draw_wet(id, rect, t, alpha)
	return true


# Kilat kena: penanda "barusan kena" yang paling murah. Sengaja TIDAK dibuat
# dengan mewarnai spritenya putih — modulate mengalikan, dan seni musuhnya
# hampir hitam, jadi dikali apa pun tetap hitam. Yang dipakai: cahaya di
# belakang badan, plus siluet yang melebar sesaat.
func _draw_hit_flash(etex: Texture2D, rect: Rect2, flip: bool, ratio: float) -> void:
	var k: float = 1.0 - ratio
	var center := rect.position + rect.size * 0.5
	draw_circle(center, rect.size.x * (0.45 + 0.4 * ratio), Color(1, 1, 1, 0.28 * k))
	var spread: float = 2.0 + 5.0 * k
	for off in [Vector2(-spread, 0), Vector2(spread, 0),
			Vector2(0, -spread), Vector2(0, spread)]:
		_blit(etex, Rect2(rect.position + off, rect.size), Sprites.ENEMY_SCALE, flip,
			Color(1, 1, 1, 0.45 * k))

	# Percikan gambar tangan, empat frame. Frame dipilih dari UMUR luka, bukan
	# dari jam dinding — dua musuh yang kena di waktu berbeda tidak boleh
	# melangkah serempak.
	var layers: Array = Sprites.impact_layers(ratio)
	if layers[0] == null:
		return
	var grow: float = 1.0 + 0.45 * ratio
	_blit(layers[0], rect, 1.9 * grow, flip, Color(1, 1, 1, k), Rect2(), false)
	if layers[1] != null:
		_blit(layers[1], rect, 2.2 * grow, flip,
			Color(1, 0.96, 0.88, 0.8 * k), Rect2(), false)


# Basah tidak bisa ditunjukkan di badan musuhnya, alasan yang sama seperti di
# atas. Jadi ditunjukkan di LANTAI (genangan kecil di kaki) dan di tetesan yang
# jatuh — dua tanda yang dua-duanya berada di luar siluet gelapnya.
func _draw_wet(id: int, rect: Rect2, t: float, alpha: float) -> void:
	var wet := ViewConfig.color_of(ViewConfig.AQUA)
	var feet := Vector2(rect.position.x + rect.size.x * 0.5,
		rect.position.y + rect.size.y - 2.0)
	for i in 2:
		var rw: float = rect.size.x * (0.30 + 0.15 * i)
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, rw,
			Color(wet.r, wet.g, wet.b, (0.28 - 0.11 * i) * alpha))
		draw_set_transform_matrix(Transform2D.IDENTITY)

	# Dua keadaan tetesan, bergantian, sambil MELUNCUR turun. Pergantian gambar
	# saja terbaca sebagai kedipan; yang bikin dia terbaca sebagai air jatuh itu
	# perpindahannya. Fasenya diturunkan dari id, jadi musuh yang basah bareng
	# tidak menetes serempak.
	var phase: float = float(id) * 0.61
	var drop := Sprites.wet_drops(t, phase)
	if drop == null:
		return
	var slide: float = fmod(t * 1.5 + phase, 1.0)
	var box := Rect2(rect.position + Vector2(0, rect.size.y * slide * 0.55), rect.size)
	_blit(drop, box, 1.5, false,
		Color(wet.r, wet.g, wet.b, 0.7 * (1.0 - slide) * alpha), Rect2(), false)


# Spell digambar dari daftar rune yang membentuknya. runes[0] menentukan wujud
# (jadi sprite mana yang dipakai); sisanya mewarnai LAPIS PER LAPIS.
#
# Dulu semua lapisan dicat satu warna campuran, dan itu salah: merah dicampur
# biru menghasilkan merah muda — bukan api, bukan air, dan tidak ada di dalam
# permainan. Ditumpuk per lapisan, mata membaca dua bahan yang saling menindih,
# yang memang persis yang terjadi di aturannya.
func _draw_spell(world, id: int, rect: Rect2, t: float) -> bool:
	if not world.entity_have_component(ViewConfig.RUNES, id):
		return false
	var runes: Array = world.get_component_value(ViewConfig.RUNES, id)
	if runes.is_empty():
		return false

	var form: String = String(runes[0]).to_lower()

	if form == "aqua":
		# Bola air yang belum pecah masih punya Velocity; genangan sudah diam.
		if not world.entity_have_component(ViewConfig.VELOCITY, id):
			_draw_puddle(rect, t, runes)
			return true
		_draw_orb(rect, t, runes)
		return true

	if form == "ventus":
		var ratio := 0.0
		if world.entity_have_component(ViewConfig.LIFETIME, id):
			var lt: Countdown = world.get_component_value(ViewConfig.LIFETIME, id)
			if lt.duration > 0.0:
				ratio = clampf(lt.elapsed / lt.duration, 0.0, 1.0)
		var wc := _blend_runes(runes)
		_blit(Sprites.burst_frame(ratio), rect, Sprites.BURST_SCALE, false,
			Color(wc.r, wc.g, wc.b, 1.0 - ratio * 0.5), Rect2(), false)
		return true

	_draw_orb(rect, t, runes)
	return true


# Warna untuk lapisan ke-i. Diambil dari SUSUNAN rune, bukan dari rata-rata:
# lapisan 0 pakai rune kedua, lapisan 1 pakai rune ketiga, dan berputar balik
# kalau runenya lebih sedikit. Jadi "api api" tetap merah seluruhnya, sementara
# "api air" punya satu lapis merah dan satu lapis biru yang bergolak bergantian.
func _layer_color(runes: Array, i: int) -> Color:
	return ViewConfig.color_of(String(runes[(i + 1) % runes.size()]))


# Warna alas: bara bawaan gambarnya untuk api, dan warna runenya sendiri untuk
# wujud lain. Alas TIDAK pernah ikut dicampur — dia yang bikin bentuknya masih
# terbaca sebagai bola api sekalipun isinya campuran.
func _base_color(runes: Array) -> Color:
	var form: String = String(runes[0]).to_lower()
	if form == "ignis":
		return Color(1, 1, 1)
	return ViewConfig.color_of(String(runes[0]))


# bg -> dua lapis berdenyut -> fg. Cuma dua lapis tengah yang diwarnai rune.
func _draw_orb(rect: Rect2, t: float, runes: Array) -> void:
	var layers: Array = Sprites.fireball_layers(t)
	var base := _base_color(runes)

	# Cahaya palsu. Renderer proyek ini gl_compatibility, dan glow sungguhan di
	# sana perlu WorldEnvironment plus HDR 2D yang tidak didukung — jadi
	# cahayanya dibuat dengan menggambar ulang gambar yang sama lebih besar
	# dengan alpha rendah. Di ukuran segini hasilnya tidak bisa dibedakan, dan
	# tidak mengubah apa pun di pengaturan proyek.
	var halo := _blend_runes(runes)
	for i in 2:
		_blit(layers[0], rect, Sprites.SPELL_SCALE * (1.2 + 0.25 * i), false,
			Color(halo.r, halo.g, halo.b, 0.13 - 0.05 * i))

	_blit(layers[0], rect, Sprites.SPELL_SCALE, false, Color(base.r, base.g, base.b, 1.0))
	for i in 2:
		var c := _layer_color(runes, i)
		# Sedikit dicerahkan: lapisan tengah itu inti nyala, dan inti yang lebih
		# redup dari tepinya akan terbaca sebagai lubang, bukan sebagai panas.
		_blit(layers[1 + i], rect, Sprites.SPELL_SCALE, false,
			Color(minf(c.r * 1.25, 1.0), minf(c.g * 1.25, 1.0), minf(c.b * 1.25, 1.0), 0.95))
	_blit(layers[3], rect, Sprites.SPELL_SCALE, false, Color(base.r, base.g, base.b, 1.0))


# Genangan. Alas biru tetap; riak dan sorotan mengikuti rune berikutnya.
#
# Kalau ada Ventus di dalamnya, ada satu cincin putih tambahan PALING BAWAH yang
# berdenyut keluar-masuk. Denyutnya bukan hiasan: dorongan angin itu satu-satunya
# efek genangan yang bisa memindahkan musuh, dan pemain butuh tahu genangan ini
# mendorong sebelum dia berdiri di sebelahnya.
func _draw_puddle(rect: Rect2, t: float, runes: Array) -> void:
	var layers: Array = Sprites.puddle_layers(t)
	var has_wind := false
	for r in runes:
		if String(r).to_lower() == "ventus":
			has_wind = true
			break

	if has_wind:
		var pulse: float = 0.5 + 0.5 * sin(t * 5.0)
		_blit(layers[1], rect, Sprites.PUDDLE_SCALE * (1.05 + 0.22 * pulse), false,
			Color(1, 1, 1, 0.30 - 0.16 * pulse), Rect2(), false)

	# Lebih transparan daripada tokoh: genangan itu keadaan lantai, dan kalau
	# sepekat karakter, mata berhenti bisa memisahkan mana yang harus dihindari.
	var base := _base_color(runes)
	_blit(layers[0], rect, Sprites.PUDDLE_SCALE, false,
		Color(base.r, base.g, base.b, 0.55), Rect2(), false)
	for i in 2:
		var c := _layer_color(runes, i)
		_blit(layers[1 + i], rect, Sprites.PUDDLE_SCALE, false,
			Color(c.r, c.g, c.b, 0.5), Rect2(), false)


# Rata-rata warna semua rune. Masih dipakai untuk hembusan angin — ledakannya
# cuma satu gambar tanpa lapisan, jadi di sana tidak ada yang bisa dipisah.
func _blend_runes(runes: Array) -> Color:
	var r := 0.0
	var g := 0.0
	var b := 0.0
	for rune in runes:
		var c: Color = ViewConfig.color_of(String(rune))
		r += c.r; g += c.g; b += c.b
	var n := float(runes.size())
	return Color(r / n, g / n, b / n)


# Cermin kiri-kanan mengikuti arah hadap. Cuma dicerminkan, tidak diputar —
# figurnya digambar menghadap kamera, jadi memutarnya akan terlihat rebah.
func _facing_flip(world, id: int, faces_left: bool) -> bool:
	if not world.entity_have_component(ViewConfig.FACING, id):
		return false
	var f: Vec2 = world.get_component_value(ViewConfig.FACING, id)
	var wants_left: bool = f.x < 0.0
	# Dicerminkan hanya kalau arah yang diinginkan berbeda dari arah asli
	# gambarnya. Tanpa ini, gambar yang aslinya menghadap kiri akan selalu
	# terbalik dari arah jalannya.
	return wants_left != faces_left


# Sprite dijangkar di KAKI (tengah-bawah kotak tabrakan), bukan di tengah.
# Perataannya memakai kotak ISI gambar, bukan kanvasnya — figur yang digambar
# agak ke pinggir kanvas tetap berdiri pas di atas kotak tabrakannya.
# `align` memaksa perataan memakai kotak isi milik tekstur LAIN. Dipakai untuk
# pasangan isi+garis: keduanya punya kotak isi sendiri yang beda beberapa
# piksel, dan kalau masing-masing diratakan sendiri, isinya melenceng dari
# garisnya. Satu acuan untuk keduanya.
# foot=true menjangkarkan gambar di KAKI kotak tabrakan, karena di game tampak
# atas kotak itu jejak kaki di lantai dan gambarnya boleh meluber ke atas.
# foot=false menjangkarkan di TENGAH — dipakai efek lantai (genangan, hembusan),
# yang bukan berdiri di atas kotaknya melainkan MENGISI kotaknya. Genangan yang
# dijangkar di kaki akan terlihat mengambang di atas kepala pemain.
func _blit(texture: Texture2D, box: Rect2, scale: float, flip: bool, tint: Color,
		align: Rect2 = Rect2(), foot: bool = true) -> void:
	if texture == null:
		return
	var c := align if align.size.x > 0.0 else Sprites.content_rect(texture)
	var side: float = box.size.x * scale
	var cx: float = c.position.x + c.size.x * 0.5
	var cy: float = c.position.y + (c.size.y if foot else c.size.y * 0.5)
	var anchor_y: float = box.position.y + box.size.y * (1.0 if foot else 0.5)

	var at := Vector2(box.position.x + box.size.x * 0.5 - side * cx,
		anchor_y - side * cy)
	var dst := Rect2(at, Vector2(side, side))

	if not flip:
		draw_texture_rect(texture, dst, false, tint)
		return

	# draw_texture_rect TIDAK mendukung lebar negatif untuk mencerminkan — dia
	# mengabaikan tandanya dan tetap menggambar ke kanan, jadi sprite yang
	# menghadap kiri melenceng persis selebar dirinya sendiri.
	#
	# Dicerminkan lewat matriks, di sumbu tegak yang lewat tengah kotak
	# tabrakan, supaya posisinya tidak ikut bergeser.
	var axis: float = box.position.x + box.size.x * 0.5
	draw_set_transform_matrix(Transform2D(Vector2(-1, 0), Vector2(0, 1), Vector2(axis * 2.0, 0)))
	draw_texture_rect(texture, dst, false, tint)
	draw_set_transform_matrix(Transform2D.IDENTITY)


# Satu cincin per rune yang sedang diantrikan, tiap lapis berputar dengan
# kecepatan berbeda. Warnanya mengikuti rune-nya — jadi lingkaran ini
# menunjukkan apa yang sedang disusun tanpa pemain perlu melirik panel.
func _draw_cast_circles(world, id: int, box: Rect2, t: float) -> void:
	if not world.entity_have_component(ViewConfig.CAST_QUEUE, id):
		return
	var q: Dictionary = world.get_component_value(ViewConfig.CAST_QUEUE, id)
	var runes: Array = q.get("runes", [])
	if runes.is_empty():
		return

	var center := Vector2(box.position.x + box.size.x * 0.5,
		box.position.y + box.size.y * 0.9)
	var side: float = box.size.x * Sprites.RING_SCALE

	for i in runes.size():
		var texture := Sprites.cast_circle(runes[i])
		if texture == null:
			continue
		var col: Color = ViewConfig.color_of(runes[i])
		var spin: float = t * (0.6 + 0.35 * i) * (1.0 if i % 2 == 0 else -1.0)
		var s: float = side * (1.0 - 0.16 * i)

		# draw_set_transform menyusun basisnya sebagai rotasi * skala, artinya
		# gambarnya dipipihkan DULU baru diputar — dan cincinnya jadi terlihat
		# jungkir balik di udara. Yang benar kebalikannya: putar dulu di bidang
		# lantai, baru proyeksikan jadi elips. Matriksnya disusun tangan.
		var k: float = Sprites.RING_SQUASH
		var basis_x := Vector2(cos(spin), k * sin(spin))
		var basis_y := Vector2(-sin(spin), k * cos(spin))
		draw_set_transform_matrix(Transform2D(basis_x, basis_y, center))
		draw_texture_rect(texture, Rect2(Vector2(-s, -s) * 0.5, Vector2(s, s)),
			false, Color(col.r, col.g, col.b, 0.8))
		draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_health_bar(world, id: int, at: Vector2, width_px: float) -> void:
	var hp: Health = world.get_component_value(ViewConfig.HEALTH, id)
	if hp.max <= 0.0:
		return
	var current: float = hp.current
	var ratio: float = clampf(current / hp.max, 0.0, 1.0)

	draw_rect(Rect2(at, Vector2(width_px, 5)), Color(INK.r, INK.g, INK.b, 0.35), true)
	draw_rect(Rect2(at, Vector2(width_px * ratio, 5)), Color(0.55, 0.72, 0.50), true)
	draw_string(_font, at + Vector2(width_px + 5, 6), "%d/%d" % [int(current), int(hp.max)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(LINE.r, LINE.g, LINE.b, 0.7))


func _highlight_occupied_tiles(px: float, py: float, w: float, h: float, color: Color) -> void:
	var x0 := floori(px)
	var y0 := floori(py)
	var x1 := ceili(px + w) - 1
	var y1 := ceili(py + h) - 1
	for tx in range(x0, x1 + 1):
		for ty in range(y0, y1 + 1):
			var p := margin + Vector2(tx, ty) * tile_size
			draw_rect(Rect2(p, Vector2(tile_size, tile_size)),
				Color(color.r, color.g, color.b, 0.13), true)


func _draw_delay_bar(world, id: int, top_left: Vector2, width_px: float) -> void:
	var d: Countdown = world.get_component_value(ViewConfig.DELAY, id)
	if d.duration <= 0.0:
		return
	var ratio: float = clampf(d.elapsed / d.duration, 0.0, 1.0)

	var bar_top := top_left + Vector2(0, -9)
	draw_rect(Rect2(bar_top, Vector2(width_px, 5)), Color(INK.r, INK.g, INK.b, 0.35), true)
	draw_rect(Rect2(bar_top, Vector2(width_px * ratio, 5)), Color(0.95, 0.85, 0.3), true)


func _color_for(world, id: int) -> Color:
	for comp_name in ViewConfig.COLORS:
		if world.entity_have_component(comp_name, id):
			return ViewConfig.COLORS[comp_name]
	return ViewConfig.NEUTRAL


func _component_badges(world, id: int) -> String:
	var owned: Array[String] = []
	for comp_name in ViewConfig.BADGE_ORDER:
		if world.entity_have_component(comp_name, id):
			owned.append(comp_name)
	return " ".join(owned)


func _draw_message(text: String) -> void:
	draw_string(_font, margin + Vector2(8, -14), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(INK.r, INK.g, INK.b, 0.6))
