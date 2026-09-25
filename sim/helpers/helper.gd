class_name Helper
extends RefCounted

# Geometri doang, ga tau apa apa soal api, musuh, atau spell.

static func overlap(pos_a: Vec2, size_a: Size, pos_b: Vec2, size_b: Size) -> bool:
	return pos_a.x < pos_b.x + size_b.w \
		and pos_b.x < pos_a.x + size_a.w \
		and pos_a.y < pos_b.y + size_b.h \
		and pos_b.y < pos_a.y + size_a.h

static func center(pos: Vec2, size: Size) -> Vec2:
	return Vec2.new(pos.x + (size.w / 2), pos.y + (size.h / 2))


static func cone_vertices(cone: Cone) -> PackedVector2Array:
	var origin := Vector2(cone.origin_x, cone.origin_y)
	var direction := Vector2(cone.direction_x, cone.direction_y).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var far := origin + direction * cone.reach
	var side := direction.orthogonal() * cone.reach * tan(deg_to_rad(cone.half_angle))
	return PackedVector2Array([origin, far + side, far - side])


# Separating-axis test between the cone triangle and an axis-aligned target.
# Checking only target centers misses enemies clipped by the visible edge.
static func cone_overlap(cone: Cone, pos: Vec2, size: Size) -> bool:
	var triangle := cone_vertices(cone)
	var rectangle := PackedVector2Array([
		Vector2(pos.x, pos.y), Vector2(pos.x + size.w, pos.y),
		Vector2(pos.x + size.w, pos.y + size.h), Vector2(pos.x, pos.y + size.h),
	])
	var axes := PackedVector2Array([Vector2.RIGHT, Vector2.DOWN])
	for i in 3:
		axes.append((triangle[(i + 1) % 3] - triangle[i]).orthogonal())
	for axis in axes:
		var t_min := INF
		var t_max := -INF
		var r_min := INF
		var r_max := -INF
		for point in triangle:
			var projection := point.dot(axis)
			t_min = minf(t_min, projection)
			t_max = maxf(t_max, projection)
		for point in rectangle:
			var projection := point.dot(axis)
			r_min = minf(r_min, projection)
			r_max = maxf(r_max, projection)
		if t_max <= r_min or r_max <= t_min:
			return false
	return true
	
