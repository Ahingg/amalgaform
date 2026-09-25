class_name RoomFactory
extends RefCounted


static func build_world(
	room_size: Vector2i,
	obstacles: Array[Rect2],
	spawns: Array[Vector2],
	exit_area: Rect2,
	final_room: bool,
	player_spawn: Vector2,
	player_health: float = Tuning.PLAYER_HEALTH
) -> World:
	var world := World.new()
	Spawn.round(world, room_size, obstacles, spawns, exit_area, final_room)
	var player := Spawn.player(world, player_spawn.x, player_spawn.y,
		Tuning.PLAYER_HEALTH)
	var health: Health = world.get_component_value(Comp.HEALTH, player)
	health.current = clampf(player_health, 1.0, health.max)
	return world
