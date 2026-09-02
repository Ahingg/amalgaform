class_name FireContactSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var fires := world.get_entities_with_comp([Comp.FIRE, Comp.SIZE, Comp.POSITION])
	var targets := world.get_entities_with_comp([Comp.HEALTH, Comp.SIZE, Comp.POSITION])
	
	for target in targets:
		var target_pos := world.get_component_value(Comp.POSITION, target)
		var target_size := world.get_component_value(Comp.SIZE, target) 
		
		for fire in fires:
			var fire_pos := world.get_component_value(Comp.POSITION, fire)
			var fire_size := world.get_component_value(Comp.SIZE, fire) 
			var fire_comp := world.get_component_value(Comp.FIRE, fire)
			
			if Helper.overlap(target_pos, target_size, fire_pos, fire_size):
				world.attach_component(Comp.BURN, target, Make.burn(fire_comp["damage"]))
	
