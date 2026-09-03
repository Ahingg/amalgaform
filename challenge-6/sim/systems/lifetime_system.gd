class_name LifetimeSystem
extends RefCounted

static func process(world: World, delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.LIFETIME])
	
	# key untuk setiap id
	for e in entities:
		var comp: Dictionary = world.get_component_value(Comp.LIFETIME, e)
		comp["elapsed"] += delta
		if comp["elapsed"] >= comp["duration"]:
			world.attach_component(Comp.DEAD, e)
			#world.detach_component(Comp.LIFETME, e)
