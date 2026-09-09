class_name Sfx
extends Node

# ============================================================================
# LAPISAN SUARA — BACA SAJA, sama seperti renderer
#
# Berkas ini tidak pernah menulis apa pun ke World. Dia menonton, membandingkan
# dunia frame ini dengan frame lalu, dan membunyikan apa yang berubah. Kalau
# berkas ini dihapus, simulasinya jalan persis sama — cuma jadi bisu.
#
# Kenapa dia menonton sendiri dan tidak menumpang pemantau di renderer:
# kejadian yang PENTING buat telinga tidak sama dengan yang penting buat mata.
# Mata peduli rune ke berapa yang masuk hanya sebagai gambar; telinga peduli
# NOMOR SLOT-nya, karena nadanya naik tiap slot. Menyatukan keduanya berarti
# salah satu harus membawa data yang tidak dia pakai.
#
# Aturan yang dipegang:
#   - Tidak ada aturan main di sini. Kalau berkas ini perlu tahu berapa damage
#     sebuah spell, berarti ada yang salah tempat.
#   - Semua dipicu dari PERUBAHAN keadaan, bukan dari panggilan. Sim tidak
#     pernah bilang "bunyikan ini" — dia cuma berubah, dan sini yang menyadari.
# ============================================================================

const DIR := "res://assets/sfx/"

# Berapa suara boleh bunyi bersamaan. Delapan musuh yang mati berbarengan
# tidak boleh menghabiskan seluruh jatah dan membungkam bunyi rune berikutnya.
const SUARA := 14

const VOL_SFX := -5.0
# Musik duduk JAUH di bawah efek suara, dan ini bukan selera. Musik itu latar
# yang terus menerus; efek suara itu kabar. Begitu latarnya sekeras kabarnya,
# yang hilang bukan musiknya — yang hilang informasinya.
const VOL_MUSIK := -14.0

# Jeda minimum antar bunyi yang SAMA. Tanpa ini, tiga musuh yang kena dalam
# satu frame membunyikan berkas yang sama tiga kali dan hasilnya bukan tiga
# kali lebih keras — hasilnya satu bunyi yang pecah.
const JEDA_SAMA := 0.05

# Jarak antar geraman menganggur untuk SATU musuh, dan jarak minimum antar
# geraman siapa pun. Yang kedua yang menjaga kerumunan tetap terdengar seperti
# kerumunan, bukan seperti paduan suara.
const GROWL_MIN := 6.0
const GROWL_MAKS := 14.0
const GROWL_JEDA := 2.5

var _pemutar: Array[AudioStreamPlayer] = []
var _berikut := 0
var _musik: AudioStreamPlayer
var _bank := {}
var _terakhir := {}

var _rune_lalu := 0
var _antrian_lalu := false
var _musuh_lalu := {}
var _growl_next := {}
var _growl_gate := 0.0
var _spell_lalu := {}
var _luka_lalu := {}
var _selesai_lalu := ""
var _world_lalu = null
var _musik_sekarang := ""


func _ready() -> void:
	for i in SUARA:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pemutar.append(p)
	_musik = AudioStreamPlayer.new()
	_musik.bus = "Master"
	_musik.volume_db = VOL_MUSIK
	add_child(_musik)


func _muat(nama: String) -> AudioStream:
	if not _bank.has(nama):
		var path := DIR + nama + ".wav"
		_bank[nama] = load(path) if ResourceLoader.exists(path) else null
	return _bank[nama]


# Memilih satu dari beberapa varian bernomor: nama_1, nama_2, ...
# Variasi itu satu-satunya obat untuk bunyi yang terdengar puluhan kali.
func _varian(nama: String, jumlah: int) -> AudioStream:
	if jumlah <= 1:
		return _muat(nama)
	return _muat("%s_%d" % [nama, randi() % jumlah + 1])


func _bunyi(aliran: AudioStream, nada: float = 1.0, keras: float = 0.0) -> void:
	if aliran == null:
		return
	var t := float(Time.get_ticks_msec()) / 1000.0
	var kunci := aliran.resource_path
	if t - float(_terakhir.get(kunci, -99.0)) < JEDA_SAMA:
		return
	_terakhir[kunci] = t

	# Round-robin: pemutar paling lama dipakai yang direbut duluan. Suara yang
	# terpotong itu suara paling tua, dan itu memang yang paling tidak penting.
	for i in SUARA:
		var p := _pemutar[(_berikut + i) % SUARA]
		if p.playing:
			continue
		_berikut = (_berikut + i + 1) % SUARA
		p.stream = aliran
		p.pitch_scale = nada
		p.volume_db = VOL_SFX + keras
		p.play()
		return
	var p2 := _pemutar[_berikut]
	_berikut = (_berikut + 1) % SUARA
	p2.stream = aliran
	p2.pitch_scale = nada
	p2.volume_db = VOL_SFX + keras
	p2.play()


# Musik mengikuti keadaan SESI, bukan keadaan ronde: tema di layar judul,
# musik permainan saat main. Judul lagunya diturunkan dari keadaan itu tiap
# frame, jadi tidak ada satu pun tempat yang harus ingat menghentikan yang lama
# sebelum memulai yang baru.
func _tonton_musik() -> void:
	var main = get_parent()
	if main == null or not main.has_method("is_menu"):
		return
	var mau := "theme_menu" if main.is_menu() else "music_game"
	if _musik_sekarang == mau and _musik.playing:
		return
	if _musik_sekarang == mau:
		return
	var m := _muat_musik(mau)
	if m == null:
		return
	_musik_sekarang = mau
	_musik.stream = m
	_musik.play()


func _muat_musik(nama: String) -> AudioStream:
	for ext in [".mp3", ".wav"]:
		var path: String = DIR + nama + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _world():
	var induk := get_parent()
	return null if induk == null else induk.get("world")


func _process(_delta: float) -> void:
	var world = _world()

	# Retry membuang World lama. Tanpa penjagaan ini, semua id ronde lama
	# terbaca "hilang" sekaligus dan terdengar delapan musuh mati serentak.
	if world != _world_lalu:
		_world_lalu = world
		_musuh_lalu.clear()
		_growl_next.clear()
		_spell_lalu.clear()
		_luka_lalu.clear()
		_rune_lalu = 0
		_antrian_lalu = false
		_selesai_lalu = ""
		return
	if world == null:
		return

	_tonton_musik()
	_tonton_antrian(world)
	_tonton_spell(world)
	_tonton_luka(world)
	_tonton_musuh(world)
	_tonton_ronde(world)


# Rune masuk antrian. Nadanya naik per SLOT, bukan per jenis rune — jadi
# telinga menghitung sudah berapa rune yang ditumpuk tanpa melihat panel.
func _tonton_antrian(world) -> void:
	var q: Array[String] = [ViewConfig.CAST_QUEUE]
	var pemain: Array[int] = world.get_entities_with_comp(q)
	if pemain.is_empty():
		_rune_lalu = 0
		_antrian_lalu = false
		return
	var antrian: Dictionary = world.get_component_value(ViewConfig.CAST_QUEUE, pemain[0])
	var buka: bool = antrian.get("open", false)
	var runes: Array = antrian.get("runes", [])

	if buka and not _antrian_lalu:
		_bunyi(_muat("cast_riser"), 1.0, -3.0)
	if not buka:
		_rune_lalu = 0
	elif runes.size() > _rune_lalu:
		_bunyi(_varian("rune", 4) if runes.size() > 4 else _muat("rune_%d" % runes.size()))
	if buka:
		_rune_lalu = runes.size()
	_antrian_lalu = buka


# Spell lahir. Bunyinya mengikuti WUJUD — rune pertama — sama seperti gambarnya.
func _tonton_spell(world) -> void:
	var q: Array[String] = [ViewConfig.RUNES, ViewConfig.POSITION]
	var sekarang := {}
	for e in world.get_entities_with_comp(q):
		sekarang[e] = true
		if _spell_lalu.has(e):
			continue
		var runes: Array = world.get_component_value(ViewConfig.RUNES, e)
		if runes.is_empty():
			continue
		match String(runes[0]).to_lower():
			"ignis":
				_bunyi(_muat("spell_fire"))
			"aqua":
				_bunyi(_muat("spell_water"))
			_:
				_bunyi(_muat("cast_whoosh_1"))
	_spell_lalu = sekarang


# Luka. Invulnerable menempel persis saat damage mendarat, jadi kemunculannya
# adalah kejadian "kena" — keadaan yang sama yang dipakai kilat kena dan hit
# stop, jadi ketiganya tidak pernah bisa lepas sinkron.
func _tonton_luka(world) -> void:
	var q: Array[String] = [ViewConfig.INVULNERABLE]
	var sekarang := {}
	for e in world.get_entities_with_comp(q):
		sekarang[e] = true
		if _luka_lalu.has(e):
			continue
		if world.entity_have_component(ViewConfig.PLAYER, e):
			_bunyi(_muat("player_hurt_1"), randf_range(0.95, 1.05), 2.0)
		else:
			_bunyi(_varian("impact", 21), randf_range(0.9, 1.1))
			_bunyi(_muat("enemy_hurt_1"), randf_range(0.92, 1.08), 0.0)
	_luka_lalu = sekarang


# Musuh datang dan musuh hilang. Keduanya diturunkan dari daftar id, bukan dari
# komponen: kematian memang tidak punya komponen, dan tidak perlu punya.
func _tonton_musuh(world) -> void:
	var q: Array[String] = [ViewConfig.ENEMY]
	var t := float(Time.get_ticks_msec()) / 1000.0
	var sekarang := {}
	for e in world.get_entities_with_comp(q):
		sekarang[e] = true

	for id in sekarang:
		if not _musuh_lalu.has(id):
			_bunyi(_varian("enemy_growl", 4), randf_range(0.88, 1.12), -2.0)
			_growl_next[id] = t + randf_range(GROWL_MIN, GROWL_MAKS)
			continue
		# Geraman berkala. Sekali saat muncul saja terlalu mudah terlewat —
		# musuh berjalan diam selama sepuluh detik lalu tiba-tiba memukul.
		if t < float(_growl_next.get(id, 0.0)) or t < _growl_gate:
			continue
		_bunyi(_varian("enemy_growl", 4), randf_range(0.85, 1.15), -5.0)
		_growl_next[id] = t + randf_range(GROWL_MIN, GROWL_MAKS)
		# Gerbang global: tanpa ini, delapan musuh yang jadwalnya kebetulan
		# berdekatan akan menggeram bersahutan tanpa henti dan berhenti terbaca
		# sebagai makhluk — jadi kebisingan.
		_growl_gate = t + GROWL_JEDA

	for id in _musuh_lalu:
		if not sekarang.has(id):
			_bunyi(_muat("enemy_death_1"), randf_range(0.94, 1.06))
			_growl_next.erase(id)
	_musuh_lalu = sekarang


# Menang dan kalah dibaca dari keadaan yang sama persis dengan yang dipakai
# RoundUI untuk menggambar layarnya, jadi bunyi dan gambar tidak bisa berbeda
# pendapat soal ronde sudah selesai atau belum.
func _tonton_ronde(world) -> void:
	var menang_q: Array[String] = [ViewConfig.ROUND, ViewConfig.WON]
	var pemain_q: Array[String] = [ViewConfig.PLAYER]
	var keadaan := ""
	if not world.get_entities_with_comp(menang_q).is_empty():
		keadaan = "menang"
	elif world.get_entities_with_comp(pemain_q).is_empty():
		keadaan = "kalah"

	if keadaan != "" and keadaan != _selesai_lalu:
		_bunyi(_muat("round_win" if keadaan == "menang" else "round_lose"), 1.0, 2.0)
		# Musik dihentikan saat ronde selesai: sting penutup harus punya
		# ruangnya sendiri, dan musik yang terus jalan di balik layar kalah
		# membuat kekalahannya terasa belum berhenti.
		_musik.stop()
	_selesai_lalu = keadaan
