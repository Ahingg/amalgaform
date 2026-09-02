class_name WorldRenderer
extends Node2D

# ============================================================================
# LAPISAN TAMPILAN — CUMA BACA
#
# File ini tidak pernah menulis apa pun ke World. Dia cuma bertanya dan
# menggambar. Kalau suatu saat file ini dihapus, simulasi tetap jalan sama
# persis — cuma jadi tidak kelihatan.
#
# KONTRAK dengan sim/:
#   - komponen "Position" berisi {"x": float, "y": float} dalam satuan petak
#   - komponen "Size" (opsional) berisi {"w": float, "h": float}, default 1x1
#
# Sengaja pakai string mentah, bukan Comp.XXX, supaya file ini tidak pernah
# bikin sim/ gagal di-parse kalau nama konstantanya belum ada atau berubah.
# Kalau ada nama komponen baru yang mau kelihatan, tambahkan di BADGE_ORDER.
# ============================================================================

const KOMPONEN_POSISI := "Position"
const KOMPONEN_UKURAN := "Size"
const KOMPONEN_DELAY := "Delay"

# Urutan menentukan prioritas warna: yang paling atas menang.
const WARNA_KOMPONEN := {
	"Burn": Color(1.0, 0.45, 0.15),
	"Fire": Color(0.95, 0.3, 0.2),
	"Water": Color(0.25, 0.6, 1.0),
	"Wind": Color(0.4, 0.85, 0.75),
	"Damaged": Color(1.0, 0.85, 0.2),
	"Health": Color(0.55, 0.8, 0.4),
}

# Komponen yang namanya ditulis di bawah tiap entity, biar kelihatan
# entity itu lagi "berbentuk" apa. Ini alat debug ECS yang paling kepakai.
const BADGE_ORDER := [
	"Position", "Velocity", "Size", "Delay", "Fire", "Water", "Wind",
	"Burn", "Damaged", "Health",
]

@export var lebar_grid: int = 12
@export var tinggi_grid: int = 8
@export var ukuran_petak: float = 64.0
@export var margin: Vector2 = Vector2(48, 48)
@export var tampilkan_badge: bool = true

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func _process(_delta: float) -> void:
	# Simulasi berjalan di _physics_process milik Main. Di sini kita cuma minta
	# gambar ulang tiap frame layar.
	queue_redraw()


func _draw() -> void:
	_gambar_grid()

	var world = _ambil_world()
	if world == null:
		_gambar_pesan("World belum ada di Main. Renderer nunggu.")
		return

	var kunci: Array[String] = [KOMPONEN_POSISI]
	var ids: Array[int] = world.get_entities_with_comp(kunci)

	if ids.is_empty():
		_gambar_pesan("Belum ada entity yang punya komponen \"%s\"." % KOMPONEN_POSISI)
		return

	for id in ids:
		_gambar_entity(world, id)


# --- pengambilan world -------------------------------------------------------

# Sengaja diambil ulang tiap frame, bukan disimpan sekali di _ready.
# Alasannya: pas retry, Main bikin World BARU. Kalau referensinya di-cache,
# renderer bakal terus menggambar dunia lama yang sudah dibuang.
func _ambil_world():
	var induk := get_parent()
	if induk == null:
		return null
	return induk.get("world")


# --- menggambar --------------------------------------------------------------

func _gambar_grid() -> void:
	var w := lebar_grid * ukuran_petak
	var h := tinggi_grid * ukuran_petak

	draw_rect(Rect2(margin, Vector2(w, h)), Color(0.11, 0.12, 0.15), true)

	var warna_garis := Color(1, 1, 1, 0.07)
	for i in range(lebar_grid + 1):
		var x := margin.x + i * ukuran_petak
		draw_line(Vector2(x, margin.y), Vector2(x, margin.y + h), warna_garis, 1.0)
	for j in range(tinggi_grid + 1):
		var y := margin.y + j * ukuran_petak
		draw_line(Vector2(margin.x, y), Vector2(margin.x + w, y), warna_garis, 1.0)


func _gambar_entity(world, id: int) -> void:
	var pos: Dictionary = world.get_component_value(KOMPONEN_POSISI, id)
	var px: float = float(pos.get("x", 0.0))
	var py: float = float(pos.get("y", 0.0))

	var lebar := 1.0
	var tinggi := 1.0
	if world.entity_have_component(KOMPONEN_UKURAN, id):
		var uk: Dictionary = world.get_component_value(KOMPONEN_UKURAN, id)
		lebar = float(uk.get("w", 1.0))
		tinggi = float(uk.get("h", 1.0))

	var kiri_atas := margin + Vector2(px, py) * ukuran_petak
	var ukuran := Vector2(lebar, tinggi) * ukuran_petak
	var kotak := Rect2(kiri_atas, ukuran)

	var warna := _warna_untuk(world, id)

	# Petak-petak yang tersentuh entity ini (okupansi biner: nyentuh = masuk).
	# Ditandai tipis supaya kelihatan kalau satu entity lagi berdiri di dua petak.
	_tandai_petak_tersentuh(px, py, lebar, tinggi, warna)

	draw_rect(kotak, Color(warna.r, warna.g, warna.b, 0.85), true)
	draw_rect(kotak, Color(1, 1, 1, 0.5), false, 1.5)

	# Delay digambar sebagai bar progres di atas entity.
	if world.entity_have_component(KOMPONEN_DELAY, id):
		_gambar_bar_delay(world, id, kiri_atas, ukuran.x)

	draw_string(_font, kiri_atas + Vector2(5, 16), "#%d" % id,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 0, 0, 0.75))

	if tampilkan_badge:
		var badge := _daftar_komponen(world, id)
		if badge != "":
			draw_string(_font, kiri_atas + Vector2(0, ukuran.y + 13), badge,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.65))


func _tandai_petak_tersentuh(px: float, py: float, w: float, h: float, warna: Color) -> void:
	var x0 := floori(px)
	var y0 := floori(py)
	var x1 := ceili(px + w) - 1
	var y1 := ceili(py + h) - 1
	for tx in range(x0, x1 + 1):
		for ty in range(y0, y1 + 1):
			var p := margin + Vector2(tx, ty) * ukuran_petak
			draw_rect(Rect2(p, Vector2(ukuran_petak, ukuran_petak)),
				Color(warna.r, warna.g, warna.b, 0.13), true)


func _gambar_bar_delay(world, id: int, kiri_atas: Vector2, lebar_px: float) -> void:
	var d: Dictionary = world.get_component_value(KOMPONEN_DELAY, id)
	var durasi: float = float(d.get("duration", 0.0))
	if durasi <= 0.0:
		return
	var lewat: float = float(d.get("elapsed", 0.0))
	var rasio: float = clampf(lewat / durasi, 0.0, 1.0)

	var atas := kiri_atas + Vector2(0, -9)
	draw_rect(Rect2(atas, Vector2(lebar_px, 5)), Color(0, 0, 0, 0.55), true)
	draw_rect(Rect2(atas, Vector2(lebar_px * rasio, 5)), Color(0.95, 0.85, 0.3), true)


func _warna_untuk(world, id: int) -> Color:
	for nama in WARNA_KOMPONEN:
		if world.entity_have_component(nama, id):
			return WARNA_KOMPONEN[nama]
	return Color(0.75, 0.75, 0.8)


func _daftar_komponen(world, id: int) -> String:
	var punya: Array[String] = []
	for nama in BADGE_ORDER:
		if world.entity_have_component(nama, id):
			punya.append(nama)
	return " ".join(punya)


func _gambar_pesan(teks: String) -> void:
	draw_string(_font, margin + Vector2(8, -14), teks,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.6))
