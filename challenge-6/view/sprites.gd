class_name Sprites
extends RefCounted

# ============================================================================
# Tempat semua tekstur dimuat dan dipilih.
#
# Dipisah dari renderer supaya renderer tetap kerjanya "gambar apa yang ada di
# World", bukan "tahu berkas mana milik siapa". Kalau nanti nama berkas berubah,
# yang perlu disentuh cuma file ini.
#
# Sprite karakter DIJANGKAR DI KAKI, bukan di tengah. Di game tampak atas, kotak
# tabrakan itu jejak kaki di lantai — gambarnya boleh lebih tinggi dan meluber
# ke atas. Kalau dijangkar di tengah, karakter akan kelihatan melayang.
# ============================================================================

const P := "res://assets/"

# Seberapa besar sisi gambar dibanding lebar kotak tabrakan. Karena figurnya
# tinggi-ramping di dalam kanvas persegi, angka ini perlu lebih dari 1 supaya
# lebar badannya kira-kira sepetak.
const PLAYER_SCALE := 2.3
const ENEMY_SCALE := 2.0
const RING_SCALE := 3.0

# Seberapa pipih cincin rapalan. Lingkarannya digambar penuh lalu diputar dulu,
# baru dipipihkan — kalau elipsnya dipanggang di gambar, cincinnya akan
# kelihatan jungkir balik di udara, bukan berputar rata di lantai.
const RING_SQUASH := 0.42

static var _cache := {}
static var _bounds := {}


# Kotak isi gambar di dalam kanvas, dinormalkan 0..1.
#
# Perlu karena figurnya jarang persis di tengah kanvas 1024x1024 — kalau
# gambarnya ditempel apa adanya, karakter akan melenceng dari kotak
# tabrakannya, dan panah arah jadi menunjuk ke sebelah badannya.
#
# Dihitung dari pikselnya sendiri, bukan ditulis tangan, supaya tetap benar
# kalau gambarnya diganti nanti.
static func content_rect(texture: Texture2D) -> Rect2:
	if texture == null:
		return Rect2(0, 0, 1, 1)
	var key := texture.resource_path
	if _bounds.has(key):
		return _bounds[key]

	var img := texture.get_image()
	var w := img.get_width()
	var h := img.get_height()
	var minx := w
	var miny := h
	var maxx := 0
	var maxy := 0
	# Dipindai tiap 4 piksel: cukup teliti untuk perataan, dan 16x lebih murah.
	for y in range(0, h, 4):
		for x in range(0, w, 4):
			if img.get_pixel(x, y).a > 0.05:
				minx = mini(minx, x); maxx = maxi(maxx, x)
				miny = mini(miny, y); maxy = maxi(maxy, y)
	var r := Rect2(0, 0, 1, 1)
	if maxx > minx:
		r = Rect2(float(minx) / w, float(miny) / h,
			float(maxx - minx) / w, float(maxy - miny) / h)
	_bounds[key] = r
	return r


static func tex(path: String) -> Texture2D:
	if not _cache.has(path):
		var full := P + path
		_cache[path] = load(full) if ResourceLoader.exists(full) else null
	return _cache[path]


# --- player -----------------------------------------------------------------

# Empat pose: diam, bergerak, dan dua-duanya versi merapal. Dipilih dari
# KEADAAN DI WORLD, bukan dari flag yang disimpan lapisan tampilan — jadi
# posenya tidak pernah bisa melenceng dari yang sebenarnya terjadi.
static func player_pose(moving: bool, casting: bool) -> Array:
	var base := ""
	if casting:
		base = "move_cast" if moving else "idle_cast"
	else:
		base = "move" if moving else "idle"
	return [tex("player/%s_fill.png" % base), tex("player/%s_outline.png" % base)]


# --- musuh ------------------------------------------------------------------

# Dua frame jalan, bergantian. Fasenya diturunkan dari id entity supaya musuh
# tidak melangkah serempak seperti barisan.
static func enemy_walk(id: int, t: float) -> Texture2D:
	var phase := fmod(t * 3.2 + float(id) * 0.7, 2.0)
	return tex("enemies/humanoid_walk%d.png" % (1 if phase < 1.0 else 2))


# --- rune -------------------------------------------------------------------

static func rune_stone(rune: String) -> Texture2D:
	return tex("runes/runes_%s_stone.png" % rune.to_lower())


static func rune_mark(rune: String) -> Texture2D:
	return tex("runes/runes_%s_mark.png" % rune.to_lower())


# --- lingkaran rapalan ------------------------------------------------------

static func cast_circle(rune: String) -> Texture2D:
	# Nama berkasnya "wind", bukan "ventus". Dipetakan di sini supaya sim
	# tidak perlu tahu apa-apa soal nama berkas.
	var file: String = {"ignis": "ignis", "aqua": "aqua", "ventus": "wind"}.get(rune.to_lower(), "ignis")
	return tex("misc/%s_circle.png" % file)
