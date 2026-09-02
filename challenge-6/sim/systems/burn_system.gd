class_name BurnSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.BURN, Comp.HEALTH])
	
	for e in entities:
		var burn_stat := world.get_component_value(Comp.BURN, e)
		world.attach_component(Comp.DAMAGED, e, Make.damaged(burn_stat["damage"]))
		world.detach_component(Comp.BURN, e)
	
