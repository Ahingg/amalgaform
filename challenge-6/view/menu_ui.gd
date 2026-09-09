class_name MenuUI
extends Node2D

# ============================================================================
# LAYAR DI LUAR RONDE — judul dan jeda
#
# Dua-duanya di satu berkas karena mereka satu hal yang sama: lapisan yang
# muncul saat ronde TIDAK sedang berjalan. Keduanya membaca `mode` dari main,
# menggambar tirai di atas arena, dan menunggu satu tombol.
#
# Berkas ini tidak menyentuh World sama sekali. Menjeda permainan di sini cuma
# berarti mengubah satu nilai di main, dan main berhenti memanggil
# SystemManager. Tidak ada system yang tahu, tidak ada yang perlu dibereskan.
# ============================================================================

const KEY_MULAI := [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
const KEY_JEDA := [KEY_ESCAPE, KEY_P]

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	# Paling atas. HUD permainan disembunyikan sendiri saat menu terbuka, jadi
	# tidak ada yang perlu ditimpa — tapi tirai jeda memang harus menutupi HUD.
	z_index = 35


func _process(_delta: float) -> void:
	queue_redraw()


func _main():
	var r := get_parent()
	return null if r == null else r.get_parent()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var main = _main()
	if main == null:
		return

	if main.is_menu():
		if event.keycode in KEY_MULAI:
			main.start()
			get_viewport().set_input_as_handled()
		return

	if not event.keycode in KEY_JEDA:
		return

	# ESC punya dua arti, dan aturannya satu: mundur dari apa pun yang sedang
	# kamu masuki. Kalau antrian rune sedang terbuka, ESC membatalkan rapalan —
	# itu sudah ditangani CastUI, jadi di sini dia harus dibiarkan lewat.
	# Kalau tidak sedang merapal, yang sedang dimasuki adalah permainannya.
	if event.keycode == KEY_ESCAPE and _sedang_merapal(main):
		return

	main.toggle_pause()
	get_viewport().set_input_as_handled()


func _sedang_merapal(main) -> bool:
	var world = main.get("world")
	if world == null:
		return false
	var q: Array[String] = [ViewConfig.CAST_QUEUE]
	for e in world.get_entities_with_comp(q):
		var antrian: Dictionary = world.get_component_value(ViewConfig.CAST_QUEUE, e)
		if antrian.get("open", false):
			return true
	return false


func _draw() -> void:
	var main = _main()
	var r := get_parent() as WorldRenderer
	if main == null or r == null:
		return
	if main.is_menu():
		_draw_menu(r)
	elif main.mode == main.Mode.PAUSED:
		_draw_pause(r)


# Tirai, bukan latar penuh. Arenanya tetap terlihat samar di belakangnya, jadi
# pemain tahu ada permainan di balik layar ini sebelum dia menekan apa pun.
func _tirai(r: WorldRenderer, gelap: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, r.get_viewport_rect().size),
		Color(0.05, 0.045, 0.065, gelap), true)


func _tengah(r: WorldRenderer, teks: String, y: float, ukuran: int, warna: Color) -> void:
	var w := _font.get_string_size(teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
	draw_string(_font, Vector2(r.hud_center_x() - w * 0.5, y), teks,
		HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, warna)


func _draw_menu(r: WorldRenderer) -> void:
	var size := r.get_viewport_rect().size
	_tirai(r, 0.93)
	var cy: float = size.y * 0.34

	_tengah(r, "AMALGAFORM", cy, 76, Color(0.97, 0.95, 0.92))
	_tengah(r, "the first rune decides the shape  ·  the whole queue decides what is inside",
		cy + 40.0, 17, Color(WorldRenderer.DIM.r, WorldRenderer.DIM.g, WorldRenderer.DIM.b, 1.0))

	var t := float(Time.get_ticks_msec()) / 1000.0
	var a: float = 0.55 + 0.45 * sin(t * 2.6)
	_tengah(r, "press SPACE to begin", cy + 130.0, 24, Color(1.0, 0.94, 0.72, a))

	var baris := [
		"WASD move        SPACE dash        ESC pause        R retry",
		"hold SHIFT  →  J / K / L  →  release  →  left click",
	]
	for i in baris.size():
		_tengah(r, baris[i], size.y * 0.78 + i * 26.0, 16,
			Color(WorldRenderer.DIM.r, WorldRenderer.DIM.g, WorldRenderer.DIM.b, 0.95))


func _draw_pause(r: WorldRenderer) -> void:
	var size := r.get_viewport_rect().size
	# Lebih tipis daripada menu: permainan masih berlangsung di balik ini, dan
	# pemain sering menjeda justru untuk MELIHAT keadaan lapangan.
	_tirai(r, 0.55)
	# Ditaruh di atas, bukan di tengah: tengah layar itu tempat pertarungan
	# terjadi, dan pemain menjeda justru untuk MELIHAT keadaan di sana.
	_tengah(r, "PAUSED", size.y * 0.26, 56, Color(0.97, 0.95, 0.92))
	_tengah(r, "ESC to resume  ·  R to restart", size.y * 0.26 + 40.0, 18,
		Color(WorldRenderer.DIM.r, WorldRenderer.DIM.g, WorldRenderer.DIM.b, 1.0))
