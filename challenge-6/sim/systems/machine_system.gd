class_name MachineSystem
extends RefCounted


static func process(world: World, _delta: float) -> void: 
	var machines := world.get_entities_with_comp([Comp.MACHINE, Comp.RECIPE, Comp.POSITION, Comp.INTERVAL])
	for m in machines:
		if world.entity_have_component(Comp.DELAY, m):
			continue
		
		# create sebuah entity, lalu tempelin component componentnya
		var new_entity := world.add_entity()
		
		var recipe: Dictionary = world.get_component_value(Comp.RECIPE, m)
		for key in recipe:
			var dupe: Dictionary = recipe[key].duplicate()
			world.attach_component(key, new_entity, dupe)
			
		# calculate new position
		if world.entity_have_component(Comp.POSITION, new_entity):
			var pos: Dictionary = world.get_component_value(Comp.POSITION, m)
			var target_pos: Dictionary = world.get_component_value(Comp.POSITION, new_entity)
			target_pos["x"] += pos["x"]
			target_pos["y"] += pos["y"]
		
		var interval: Dictionary = world.get_component_value(Comp.INTERVAL, m)
		world.attach_component(Comp.DELAY, m, Countdown.new(interval["duration"]))
		
			
