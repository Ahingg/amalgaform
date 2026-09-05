class_name CastSystem
extends RefCounted


static func process(world: World, delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.CAST_QUEUE])
	var round_id := world.get_entities_with_comp([Comp.ROUND, Comp.TIME_SCALE])
	if round_id.is_empty():
		return
	
	var time_scale := world.get_component_value(Comp.TIME_SCALE, round_id[0])
	
	time_scale["value"] = 1.0
	for e in entities:
		var queue := world.get_component_value(Comp.CAST_QUEUE, e)
		if queue["open"] == true:
			queue["open_time"] = queue.get("open_time", 0.0) + delta
			var scale := 1.0 - (1.0 - Tuning.SLOW_MIN) * exp(-queue["open_time"] / Tuning.SLOW_TAU)
			time_scale["value"] = scale
			continue
			
