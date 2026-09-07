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
const BG := Color(0.16, 0.15, 0.19)          # latar, nilai tengah-gelap
const ARENA := Color(0.21, 0.20, 0.25)       # lantai arena, sedikit lebih terang
const LINE := Color(0.86, 0.84, 0.80)        # teks, garis tepi, bingkai
const FILL := Color(0.97, 0.96, 0.93)        # isi badan pemain
const SHADOW := Color(0.06, 0.05, 0.08)      # musuh: hampir hitam

# Nama lama dipertahankan supaya berkas lain tidak perlu diubah semuanya.
const PAPER := BG
const INK := LINE

@export var grid_width: int = 20
@export var grid_height: int = 12
@export var tile_size: float = 52.0
@export var margin: Vector2 = Vector2(24, 24)
# Daftar komponen di bawah tiap entity: alat debug ECS paling berguna selama
# ngoding, tapi bikin layar berantakan dan tidak terbaca. Default mati, F1 untuk
# menyalakan.
@export var show_badges: bool = false

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	# Input layers live under the renderer so they can reuse the geometry
	# helpers above, and so main.gd does not need to know they exist.
	# AssemblyUI is parked: machine placement before the round no longer exists
	# after design revision 3. The file is kept for the casting panel.
	add_child(PlayerInput.new())
	add_child(CastUI.new())
	add_child(RoundUI.new())


func _process(_delta: float) -> void:
	# The simulation advances in Main's _physics_process. Here we only ask for
	# a repaint every rendered frame.
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_F1:
		show_badges = not show_badges
		get_viewport().set_input_as_handled()


func _draw() -> void:
	_draw_grid()

	var world = _get_world()
	if world == null:
		_draw_message("Menunggu World.")
		return

	var query: Array[String] = [ViewConfig.POSITION]
	var ids: Array[int] = world.get_entities_with_comp(query)

	if ids.is_empty():
		_draw_message("Belum ada entity yang punya Position.")
		return

	for id in ids:
		_draw_entity(world, id)


# --- geometry helpers, shared with the input layer -----------------------------
# The UI must not recompute tile maths on its own; if the grid moves, only this
# file should need to know.

# Dipakai lapisan UI supaya panel selalu duduk di bawah arena, berapa pun
# ukuran gridnya. Sebelumnya koordinatnya angka mati dari grid 12x8 yang lama,
# jadi panelnya menimpa lapangan begitu arena digedein.
func ui_origin() -> Vector2:
	return Vector2(margin.x, margin.y + grid_height * tile_size + 20.0)


func tile_at(screen_pos: Vector2) -> Vector2i:
	var local := screen_pos - margin
	return Vector2i(floori(local.x / tile_size), floori(local.y / tile_size))


# Fractional tile coordinates, unlike tile_at which rounds down. Aiming needs
# the real point under the cursor, not the tile it happens to sit in.
func world_at(screen_pos: Vector2) -> Vector2:
	return (screen_pos - margin) / tile_size


func screen_of_tile(tile: Vector2i) -> Vector2:
	return margin + Vector2(tile) * tile_size


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
	# Seluruh jendela adalah halaman, bukan cuma arenanya. Tanpa ini ada pita
	# abu-abu di bawah arena tempat panel duduk, dan itu terbaca sebagai belum
	# jadi, bukan sebagai pilihan.
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), BG, true)

	var w := grid_width * tile_size
	var h := grid_height * tile_size

	# Arena sedikit lebih gelap dari halaman, plus garis tepi tinta — supaya
	# batas lapangan jelas tanpa perlu dinding yang digambar.
	draw_rect(Rect2(margin, Vector2(w, h)), ARENA, true)

	var line_color := Color(INK.r, INK.g, INK.b, 0.10)
	for i in range(grid_width + 1):
		var x := margin.x + i * tile_size
		draw_line(Vector2(x, margin.y), Vector2(x, margin.y + h), line_color, 1.0)
	for j in range(grid_height + 1):
		var y := margin.y + j * tile_size
		draw_line(Vector2(margin.x, y), Vector2(margin.x + w, y), line_color, 1.0)

	draw_rect(Rect2(margin, Vector2(w, h)), Color(INK.r, INK.g, INK.b, 0.35), false, 2.0)


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

	var top_left := margin + Vector2(px, py) * tile_size
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

	if world.entity_have_component(ViewConfig.HEALTH, id):
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
		var flip := _facing_flip(world, id)
		# Garis jadi acuan untuk keduanya, supaya isi tidak lepas dari garisnya.
		var align := Sprites.content_rect(pair[1])
		# Isi putih, GARIS tetap gelap. Kalau garisnya ikut terang, coretan tinta
		# di dalam badan hilang dan figurnya jadi satu gumpalan pucat.
		_blit(pair[0], rect, Sprites.PLAYER_SCALE, flip, Color(FILL.r, FILL.g, FILL.b, alpha), align)
		_blit(pair[1], rect, Sprites.PLAYER_SCALE, flip, Color(SHADOW.r, SHADOW.g, SHADOW.b, alpha), align)
		return true

	# Musuh hampir hitam, tapi diberi tepi terang tipis: siluet hitam pekat di
	# latar gelap gampang lumer jadi satu massa saat berkerumun.
	var etex := Sprites.enemy_walk(id, t)
	var eflip := _facing_flip(world, id)
	var rim := Color(LINE.r, LINE.g, LINE.b, alpha * 0.30)
	for off in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		_blit(etex, Rect2(rect.position + off, rect.size), Sprites.ENEMY_SCALE, eflip, rim)
	_blit(etex, rect, Sprites.ENEMY_SCALE, eflip, Color(SHADOW.r, SHADOW.g, SHADOW.b, alpha))
	return true


# Spell digambar dari daftar rune yang membentuknya. runes[0] menentukan wujud
# (jadi sprite mana yang dipakai); seluruh daftar menentukan warnanya, jadi
# warna spell menunjukkan ISInya, bukan cuma bentuknya.
func _draw_spell(world, id: int, rect: Rect2, t: float) -> bool:
	if not world.entity_have_component(ViewConfig.RUNES, id):
		return false
	var runes: Array = world.get_component_value(ViewConfig.RUNES, id)
	if runes.is_empty():
		return false

	var tint := _blend_runes(runes)
	var form: String = String(runes[0]).to_lower()

	if form == "aqua":
		# Bola air yang belum pecah masih punya Velocity; genangan sudah diam.
		var is_puddle: bool = not world.entity_have_component(ViewConfig.VELOCITY, id)
		if is_puddle:
			for layer in Sprites.puddle_layers(t):
				_blit(layer, rect, Sprites.PUDDLE_SCALE, false, tint)
			return true
		for layer in Sprites.fireball_layers(t):
			_blit(layer, rect, Sprites.SPELL_SCALE, false, tint)
		return true

	if form == "ventus":
		var ratio := 0.0
		if world.entity_have_component(ViewConfig.LIFETIME, id):
			var lt: Countdown = world.get_component_value(ViewConfig.LIFETIME, id)
			if lt.duration > 0.0:
				ratio = clampf(lt.elapsed / lt.duration, 0.0, 1.0)
		_blit(Sprites.burst_frame(ratio), rect, Sprites.BURST_SCALE, false,
			Color(tint.r, tint.g, tint.b, 1.0 - ratio * 0.5))
		return true

	for layer in Sprites.fireball_layers(t):
		_blit(layer, rect, Sprites.SPELL_SCALE, false, tint)
	return true


# Rata-rata warna semua rune di dalamnya. Rune kembar menariknya lebih kuat ke
# warnanya sendiri, jadi "api api" lebih merah daripada "api air".
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
func _facing_flip(world, id: int) -> bool:
	if not world.entity_have_component(ViewConfig.FACING, id):
		return false
	var f: Vec2 = world.get_component_value(ViewConfig.FACING, id)
	return f.x < 0.0


# Sprite dijangkar di KAKI (tengah-bawah kotak tabrakan), bukan di tengah.
# Perataannya memakai kotak ISI gambar, bukan kanvasnya — figur yang digambar
# agak ke pinggir kanvas tetap berdiri pas di atas kotak tabrakannya.
# `align` memaksa perataan memakai kotak isi milik tekstur LAIN. Dipakai untuk
# pasangan isi+garis: keduanya punya kotak isi sendiri yang beda beberapa
# piksel, dan kalau masing-masing diratakan sendiri, isinya melenceng dari
# garisnya. Satu acuan untuk keduanya.
func _blit(texture: Texture2D, box: Rect2, scale: float, flip: bool, tint: Color,
		align: Rect2 = Rect2()) -> void:
	if texture == null:
		return
	var c := align if align.size.x > 0.0 else Sprites.content_rect(texture)
	var side: float = box.size.x * scale
	var cx: float = c.position.x + c.size.x * 0.5
	var cy: float = c.position.y + c.size.y

	# Saat dicerminkan, isi gambar ikut pindah ke seberang kanvas. Kalau
	# jangkarnya tidak ikut dicerminkan, karakternya melompat ke samping tiap
	# kali berbalik arah.
	var anchor_x: float = (1.0 - cx) if flip else cx
	var at := Vector2(box.position.x + box.size.x * 0.5 - side * anchor_x,
		box.position.y + box.size.y - side * cy)

	var dst := Rect2(at, Vector2(side, side))
	if flip:
		dst.position.x += dst.size.x
		dst.size.x = -dst.size.x
	draw_texture_rect(texture, dst, false, tint)


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
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(INK.r, INK.g, INK.b, 0.6))


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
