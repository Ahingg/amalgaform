class_name TimeScaleSystem
extends RefCounted

static func process(world: World, delta: float) -> void:
	var rounds := world.get_entities_with_comp([Comp.ROUND, Comp.TIME_SCALE])
	if rounds.is_empty():
		return
	var r: int = rounds[0]
	var scale: Scalar = world.get_component_value(Comp.TIME_SCALE, r)

	var slowest := 1.0

	# dua case dihitung independent
	# hit stop
	if world.entity_have_component(Comp.HIT_STOP, r):
		var hs: Countdown = world.get_component_value(Comp.HIT_STOP, r)
		hs.elapsed += delta
		if hs.elapsed >= hs.duration:
			world.detach_component(Comp.HIT_STOP, r)
		else:
			slowest = minf(slowest, Tuning.HIT_STOP_SCALE)

	# cast queue
	for e in world.get_entities_with_comp([Comp.CAST_QUEUE]):
		var q: Dictionary = world.get_component_value(Comp.CAST_QUEUE, e)
		if q.get("open", false):
			slowest = minf(slowest, float(q.get("scale", 1.0)))
	scale.value = slowest
