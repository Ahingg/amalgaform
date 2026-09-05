
extends RefCounted
class_name SpeedModifierSystem

const SPEED_MODIFIERS := [Comp.WET]

static func process(world: World, _delta: float) -> void:

	var entities := world.get_entities_with_comp([Comp.SPEED])
	for e in entities:
		var speed: Speed = world.get_component_value(Comp.SPEED, e)
		var v := speed.base
		
		for name in SPEED_MODIFIERS:
			if world.entity_have_component(name, e):
				v *= (1.0 - world.get_component_value(name, e).slow)
				
		speed.value = v
		
		
			
	
