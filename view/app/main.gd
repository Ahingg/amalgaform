extends Node

const ROOM_SCENES := [
	preload("res://view/rooms/first_room.tscn"),
	preload("res://view/rooms/second_room.tscn"),
]

# Bootstrap. Owns the World and hands it to the systems every physics tick.
# The World lives here — not inside SystemManager — because "start the round
# over" belongs to whoever owns the session, and because view/ needs to read
# the World to draw it.

var world: World

# Attempts belong to the session, not to the round — so this is the one piece of
# state that deliberately survives build_round(). Everything else is thrown away
# with the World.
var attempt: int = 1
var dungeon_run: DungeonRun

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


# The title screen is a real pre-game state: no simulation exists until the
# player chooses to start. This keeps menu input and gameplay state separate.
func start() -> void:
	if mode != Mode.MENU:
		return
	attempt = 1
	dungeon_run = DungeonRun.new(ROOM_SCENES.size())
	build_round()
	mode = Mode.PLAYING


func toggle_pause() -> void:
	if mode == Mode.PLAYING:
		mode = Mode.PAUSED
	elif mode == Mode.PAUSED:
		mode = Mode.PLAYING

func retry() -> void:
	attempt += 1
	dungeon_run = DungeonRun.new(ROOM_SCENES.size())
	build_round()
	mode = Mode.PLAYING


func return_to_menu() -> void:
	world = null
	mode = Mode.MENU


# Everything that describes one attempt at the room lives here. Retrying is
# literally this function again: throw the World away, build a new one. No
# cleanup, no reset pass — nothing in sim/ ever kept state outside the World.
func build_round(player_health: float = 200.0) -> void:
	if dungeon_run == null:
		dungeon_run = DungeonRun.new(ROOM_SCENES.size())
	var gameplay_view := get_node("GameplayView") as WorldRenderer
	var previous := gameplay_view.get_node_or_null("RoomLayout")
	if previous != null:
		gameplay_view.remove_child(previous)
		previous.queue_free()
	var layout := ROOM_SCENES[dungeon_run.current_layout_index()].instantiate() as RoomLayout
	layout.name = "RoomLayout"
	gameplay_view.add_child(layout)
	gameplay_view.grid_width = layout.room_size.x
	gameplay_view.grid_height = layout.room_size.y
	world = World.new()
	Spawn.round(world, layout.room_size, layout.obstacle_rects(),
		layout.spawn_points(), layout.exit_rect(), dungeon_run.is_final_room())
	var player := Spawn.player(world, layout.player_spawn.x, layout.player_spawn.y, 200)
	var health: Health = world.get_component_value(Comp.HEALTH, player)
	health.current = clampf(player_health, 1.0, health.max)


func _physics_process(delta: float) -> void:
	if mode != Mode.PLAYING or world == null:
		return
	SystemManager.process(world, delta)
	var exited := world.get_entities_with_comp([Comp.ROUND, Comp.ROOM_EXITED])
	if exited.is_empty():
		return
	var carried_health := 200.0
	var players := world.get_entities_with_comp([Comp.PLAYER, Comp.HEALTH])
	if not players.is_empty():
		var health: Health = world.get_component_value(Comp.HEALTH, players[0])
		carried_health = health.current
	if dungeon_run.advance():
		build_round(carried_health)
