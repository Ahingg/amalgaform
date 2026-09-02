class_name DelaySystem
extends RefCounted

static func process(world: World, delta: float) -> void:
	# query setiap entity yang punya compnent delay.
	var entities := world.get_entities_with_comp([Comp.DELAY])
	
	# key untuk setiap id
	for e in entities:
		var comp: Dictionary = world.get_component_value(Comp.DELAY, e)
		comp["elapsed"] += delta
		print(str(comp["elapsed"]) + " from e" + str(e))
		if comp["elapsed"] >= comp["duration"]:
			world.detach_component(Comp.DELAY, e)
 
