class_name CastSystem
extends RefCounted

static func process(world: World, delta: float) -> void:
	for e in world.get_entities_with_comp([Comp.CAST_QUEUE]):
		var queue: Dictionary = world.get_component_value(Comp.CAST_QUEUE, e)

		if not queue["open"]:
			queue["open_time"] = 0.0
			queue["scale"] = 1.0
			continue

		queue["open_time"] = queue.get("open_time", 0.0) + delta
		queue["scale"] = 1.0 - (1.0 - Tuning.SLOW_MIN) \
			* exp(-queue["open_time"] / Tuning.SLOW_TAU)
