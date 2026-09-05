class_name ContactSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var sources := world.get_entities_with_comp([Comp.ON_HIT, Comp.POSITION, Comp.SIZE])
	var target := world.get_entities_with_comp([Comp.ENEMY, Comp.HEALTH, Comp.POSITION, Comp.SIZE])
	
	for s in sources:
		var pos_s := world.get_component_value(Comp.POSITION, s)
		var size_s := world.get_component_value(Comp.SIZE, s)
		var action := world.get_component_value(Comp.ON_HIT, s).duplicate(true)
		if not (action.has("self") and action.has("target")):
			continue

		
		for t in target:
			var pos_t := world.get_component_value(Comp.POSITION, t)
			var size_t := world.get_component_value(Comp.SIZE, t)
			if not Helper.overlap(pos_s, size_s, pos_t, size_t):
				continue
				
			for on_self in action["self"]:
				world.attach_component(on_self, s, action["self"][on_self])
			for on_target in action["target"]:
				world.attach_component(on_target, t, action["target"][on_target])
