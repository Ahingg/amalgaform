extends Node

# Bootstrap. Owns the World and hands it to the systems every physics tick.
# The World lives here — not inside SystemManager — because "start the round
# over" belongs to whoever owns the session, and because view/ needs to read
# the World to draw it.

var world: World

# Attempts belong to the session, not to the round — so this is the one piece of
# state that deliberately survives build_round(). Everything else is thrown away
# with the World.
var attempt: int = 1

# Keadaan SESI, bukan keadaan ronde. Sama alasannya dengan `attempt`: menu dan
# jeda hidup di luar satu percobaan, jadi mereka tidak boleh ikut dibuang waktu
# World-nya dibuang.
#
# Yang bikin jeda jadi murah di sini: kalau tidak sedang MAIN, SystemManager
# cukup tidak dipanggil. Tidak ada satu pun system yang perlu tahu ada jeda,
# tidak ada bendera yang perlu dibaca siapa pun, dan tidak ada yang perlu
# dibereskan saat lanjut. Itu cuma mungkin karena tidak ada satu pun keadaan
# simulasi yang tinggal di luar World.
enum Mode { MENU, PLAYING, PAUSED }
var mode: int = Mode.MENU


func is_playing() -> bool:
	return mode == Mode.PLAYING


func is_menu() -> bool:
	return mode == Mode.MENU


# Ronde sudah dibangun sejak awal walaupun menunya masih terbuka, supaya
# arenanya terlihat di belakang menu — dan supaya "mulai" tidak perlu menunggu
# apa pun dibangun.
func start() -> void:
	mode = Mode.PLAYING


func toggle_pause() -> void:
	if mode == Mode.PLAYING:
		mode = Mode.PAUSED
	elif mode == Mode.PAUSED:
		mode = Mode.PLAYING

func _ready() -> void:
	build_round()

	# The renderer and sound observer are explicit children in main.tscn.
	# renderer.gd only READS world; it never writes into sim/.


func retry() -> void:
	attempt += 1
	build_round()
	mode = Mode.PLAYING


# Everything that describes one attempt at the room lives here. Retrying is
# literally this function again: throw the World away, build a new one. No
# cleanup, no reset pass — nothing in sim/ ever kept state outside the World.
func build_round() -> void:
	world = World.new()
	Spawn.round(world)
		
	Spawn.player(world, 3.0, 2.0, 200)
	#Spawn.enemy(world, 0.5, 0.5, 100)
	#Spawn.enemy(world, 10.0, 1.0, 100)
	#Spawn.enemy(world, 6.0, 6.0, 100)


func _physics_process(delta: float) -> void:
	if mode != Mode.PLAYING:
		return
	SystemManager.process(world, delta)
