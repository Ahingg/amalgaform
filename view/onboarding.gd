class_name Onboarding
extends Node2D

# ============================================================================
# PENUNTUN RAPALAN PERTAMA
#
# Legenda kontrol di sudut sudah menjawab "apa tombolnya". Yang belum dijawab:
# orang yang baru pertama pegang ini harus melakukan EMPAT langkah berurutan
# sebelum satu spell keluar, dan dia melakukannya sambil dikejar. Membaca
# "SHIFT tahan → J/K/L → lepas → klik kiri" sebagai satu baris itu pekerjaan
# yang berbeda dari melakukannya.
#
# Jadi yang ditunjukkan cuma SATU langkah — langkah berikutnya — dan langkahnya
# dibaca dari World, bukan dari hitungan yang disimpan di sini. Konsekuensinya:
# pemain boleh salah urutan, boleh membatalkan, boleh mati di tengah jalan;
# penuntunnya tidak pernah bisa menunjuk ke langkah yang salah, karena dia tidak
# pernah menebak sedang di langkah mana.
#
# Satu-satunya hal yang disimpan: apakah rapalan pertama sudah pernah selesai.
# Itu milik SESI, bukan milik ronde — sama seperti penghitung percobaan — jadi
# dia tidak lahir ulang tiap kali mati, dan penuntunnya tidak muncul lagi di
# percobaan kedua.
# ============================================================================

const LANGKAH_SIAP := "Hold SHIFT to start casting"
const LANGKAH_RUNE := "Press  J  ·  K  ·  L  to stack runes"
const LANGKAH_LEPAS := "Release SHIFT to cast"
const LANGKAH_LEMPAR := "Aim with mouse, left click to throw"

var selesai: bool = false

var _font: Font
var _pernah_pegang := false


func _ready() -> void:
	_font = ThemeDB.fallback_font
	z_index = 20


func _process(_delta: float) -> void:
	queue_redraw()


func _renderer() -> WorldRenderer:
	return get_parent() as WorldRenderer


func _world():
	var r := _renderer()
	if r == null:
		return null
	var main := r.get_parent()
	return null if main == null else main.get("world")


func _player(world) -> int:
	var q: Array[String] = [ViewConfig.PLAYER]
	var ids: Array[int] = world.get_entities_with_comp(q)
	return -1 if ids.is_empty() else ids[0]


func _draw() -> void:
	if selesai:
		return
	var m = _main_node()
	if m != null and not m.is_playing():
		return
	var world = _world()
	var r := _renderer()
	if world == null or r == null:
		return
	var p := _player(world)
	if p == -1:
		return

	var memegang: bool = world.entity_have_component(ViewConfig.HELD_SPELL, p)
	# Bola yang tadi dipegang dan sekarang tidak ada berarti sudah dilempar.
	# Itu akhir rapalan pertama, dan penuntunnya berhenti selamanya.
	if _pernah_pegang and not memegang:
		selesai = true
		return
	if memegang:
		_pernah_pegang = true

	var teks := ""
	var sorot_slot := false
	if memegang:
		teks = LANGKAH_LEMPAR
	elif world.entity_have_component(ViewConfig.CASTING, p):
		teks = ""     # bar rapalan sudah bicara sendiri; dua pesan sekaligus malah bising
	else:
		var antrian := _antrian(world, p)
		var buka: bool = antrian.get("open", false)
		var runes: Array = antrian.get("runes", [])
		if not buka:
			teks = LANGKAH_SIAP
		elif runes.is_empty():
			teks = LANGKAH_RUNE
			sorot_slot = true
		else:
			teks = LANGKAH_LEPAS

	if sorot_slot:
		_sorot_slot(r)
	if teks != "":
		_pesan(r, teks)


func _antrian(world, p: int) -> Dictionary:
	if not world.entity_have_component(ViewConfig.CAST_QUEUE, p):
		return {}
	return world.get_component_value(ViewConfig.CAST_QUEUE, p)


# Satu baris, di atas arena, bukan di bawah bersama HUD lain. Alasannya: mata
# pemain baru ada di tokohnya, dan pesan yang ditaruh di antara HUD yang sudah
# ramai akan dibaca terakhir — kalau dibaca sama sekali.
func _pesan(r: WorldRenderer, teks: String) -> void:
	var lebar := _font.get_string_size(teks, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var x: float = r.hud_center_x() - lebar * 0.5
	var y: float = r.margin.y - 26.0

	# Denyut pelan supaya dia terbaca sebagai ajakan, bukan sebagai label.
	var t := float(Time.get_ticks_msec()) / 1000.0
	var a: float = 0.72 + 0.28 * sin(t * 3.0)

	var pad := 16.0
	draw_rect(Rect2(Vector2(x - pad, y - 24.0), Vector2(lebar + pad * 2.0, 34.0)),
		Color(0.06, 0.055, 0.075, 0.72), true)
	draw_string(_font, Vector2(x, y), teks, HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
		Color(1.0, 0.94, 0.72, a))


# Kotak yang berdenyut di sekeliling slot rune. Teks memberi tahu tombolnya;
# sorotan memberi tahu ke MANA hasilnya muncul — dan itu yang bikin tekanan
# pertama terasa nyambung, bukan seperti tombol yang tidak melakukan apa-apa.
func _sorot_slot(r: WorldRenderer) -> void:
	var total: float = Tuning.MAX_RUNES * CastUI.BOX + (Tuning.MAX_RUNES - 1) * CastUI.GAP
	var asal := Vector2(r.hud_center_x() - total * 0.5, r.hud_bottom() - 118.0)
	var t := float(Time.get_ticks_msec()) / 1000.0
	var d: float = 4.0 + 3.0 * sin(t * 5.0)
	draw_rect(Rect2(asal - Vector2(d, d), Vector2(total + d * 2.0, CastUI.BOX + d * 2.0)),
		Color(1.0, 0.9, 0.55, 0.55), false, 2.5)


func _main_node():
	var r := _renderer()
	return null if r == null else r.get_parent()
