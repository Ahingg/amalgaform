class_name EntityDeadSystem 
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.HEALTH])
	for e in entities:
		var health := world.get_component_value(Comp.HEALTH, e)
		if health["current"] <= 0.0:
			world.attach_component(Comp.DEAD, e)
