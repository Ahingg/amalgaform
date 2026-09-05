class_name WetSystem
extends RefCounted


static func process(world: World, delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.WET, Comp.SPEED])
	
	for e in entities:
		var wet_factor: Wet = world.get_component_value(Comp.WET, e)
		if(wet_factor.triggered):
			continue
		wet_factor.triggered = true
		var speed: Speed = world.get_component_value(Comp.SPEED, e)
		speed.value * wet_factor.slow
		
		
