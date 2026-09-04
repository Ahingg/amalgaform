class_name RoundState
extends RefCounted


static func time_scale(world: World) -> float:
	
	var entities := world.get_entities_with_comp([Comp.ROUND, Comp.TIME_SCALE])
	if entities.is_empty():
		return 1.0
	
	return world.get_component_value(Comp.TIME_SCALE, entities[0])["value"]
