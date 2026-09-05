class_name MeleeSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var sources := world.get_entities_with_comp([Comp.MELEE, Comp.POSITION, Comp.SIZE])
	var target := world.get_entities_with_comp([Comp.PLAYER, Comp.HEALTH, Comp.POSITION, Comp.SIZE])
	if target.is_empty():
		return
		
	for s in sources:
		var pos_s: Dictionary = world.get_component_value(Comp.POSITION, s)
		var size_s: Dictionary = world.get_component_value(Comp.SIZE, s)
		
		# melee bakal dibuat punya on hit, sehingga bisa di embed efek tertentu
		var melee: Dictionary = world.get_component_value(Comp.MELEE, s)
		if not melee.has(Comp.ON_HIT):
			continue
		var action: Dictionary = melee.get(Comp.ON_HIT, {})
		if not (action.has("self") and action.has("target")):
			continue
		
		var t := target[0]
		var pos_t: Dictionary = world.get_component_value(Comp.POSITION, t)
		var size_t: Dictionary = world.get_component_value(Comp.SIZE, t)
		if not Helper.overlap(pos_s, size_s, pos_t, size_t):
			continue
			
		for on_self in action["self"]:
			world.attach_component(on_self, s, action["self"][on_self].duplicate(true))
		for on_target in action["target"]:
			world.attach_component(on_target, t, action["target"][on_target].duplicate(true))
