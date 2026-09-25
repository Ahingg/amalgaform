class_name RoomPathfinder
extends RefCounted

const STEPS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]


static func direction(from_pos: Vec2, target_pos: Vec2,
		obstacles: Array[Rect2], room: Size) -> Vector2:
	var start_point := Vector2(from_pos.x + 0.5, from_pos.y + 0.5)
	var target_point := Vector2(target_pos.x + 0.5, target_pos.y + 0.5)
	var direct := (target_point - start_point).normalized()
	var clear := true
	for obstacle in obstacles:
		if _segment_hits_rect(start_point, target_point, obstacle.grow(0.5)):
			clear = false
			break
	if clear:
		return direct

	var start := Vector2i(roundi(from_pos.x), roundi(from_pos.y))
	var goal := Vector2i(roundi(target_pos.x), roundi(target_pos.y))
	if start == goal:
		return direct
	var frontier: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var cursor := 0
	while cursor < frontier.size() and not previous.has(goal):
		var cell := frontier[cursor]
		cursor += 1
		for step in STEPS:
			var next: Vector2i = cell + step
			if next.x < 0 or next.y < 0 or next.x >= int(room.w) or next.y >= int(room.h):
				continue
			if previous.has(next) or _blocked(next, obstacles):
				continue
			previous[next] = cell
			frontier.append(next)
	if not previous.has(goal):
		return Vector2.ZERO
	var next_cell := goal
	while previous[next_cell] != start:
		next_cell = previous[next_cell]
	return (Vector2(next_cell) - Vector2(from_pos.x, from_pos.y)).normalized()


static func _blocked(cell: Vector2i, obstacles: Array[Rect2]) -> bool:
	var footprint := Rect2(Vector2(cell), Vector2.ONE)
	for obstacle in obstacles:
		if footprint.intersects(obstacle):
			return true
	return false


static func _segment_hits_rect(start: Vector2, finish: Vector2, rect: Rect2) -> bool:
	var delta := finish - start
	var entry := 0.0
	var exit := 1.0
	for axis in 2:
		var origin: float = start.x if axis == 0 else start.y
		var travel: float = delta.x if axis == 0 else delta.y
		var low: float = rect.position.x if axis == 0 else rect.position.y
		var high: float = rect.end.x if axis == 0 else rect.end.y
		if is_zero_approx(travel):
			if origin < low or origin > high:
				return false
			continue
		var first := (low - origin) / travel
		var last := (high - origin) / travel
		entry = maxf(entry, minf(first, last))
		exit = minf(exit, maxf(first, last))
		if entry > exit:
			return false
	return true
