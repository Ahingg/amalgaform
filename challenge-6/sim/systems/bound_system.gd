class_name BoundSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.BOUNDED, Comp.POSITION, Comp.SIZE])
	
	for e in entities:
		var pos: Vec2 = world.get_component_value(Comp.POSITION, e)
		var size: Size = world.get_component_value(Comp.SIZE, e)
		pos.x = max(0.0, min(Tuning.ARENA_W - size.w, pos.x))
		pos.y = max(0.0, min(Tuning.ARENA_H - size.h, pos.y))
			
