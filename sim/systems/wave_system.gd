class_name WaveSystem
extends RefCounted

const WAVES := [
	{ "count": 3, "hp": 100},
	{ "count": 4, "hp": 120},
	{ "count": 5, "hp": 140},
	{ "count": 6, "hp": 160},
]

static func process(world: World, _delta: float) -> void:
	var round := world.get_entities_with_comp([Comp.ROUND, Comp.ROUND_WAVE])
	var enemies := world.get_entities_with_comp([Comp.ENEMY])
	for r in round:
		var wave: Scalar = world.get_component_value(Comp.ROUND_WAVE, r)
		if world.entity_have_component(Comp.DELAY, r) or not enemies.is_empty():
			continue
		if world.entity_have_component(Comp.WON, r): 
			continue
		if wave.value >= Tuning.WAVE_COUNT:
			world.attach_component(Comp.WON, r)
			continue
		var data: Dictionary = WAVES[wave.value]
		var room := RoundState.room_size(world)
		var points := _spawn_points(room, data["count"])
		for i in data["count"]:
			Spawn.enemy(world, points[i].x, points[i].y, data["hp"])
		wave.value += 1
		world.attach_component(Comp.DELAY, r, Countdown.new(Tuning.WAVE_GAP))


static func _spawn_points(room: Size, count: int) -> Array[Vector2]:
	var right := maxf(0.0, room.w - 1.0)
	var bottom := maxf(0.0, room.h - 1.0)
	var mid_x := right * 0.5
	var mid_y := bottom * 0.5
	var positions: Array[Vector2] = [
		Vector2(0.0, 0.0), Vector2(right, 0.0),
		Vector2(right, bottom), Vector2(0.0, bottom),
		Vector2(mid_x, 0.0), Vector2(right, mid_y),
		Vector2(mid_x, bottom), Vector2(0.0, mid_y),
	]
	var result: Array[Vector2] = []
	for i in count:
		result.append(positions[i % positions.size()])
	return result
		
