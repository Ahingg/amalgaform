class_name KnockedSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.KNOCKED, Comp.VELOCITY])
	for e in entities:
		var knocked: Knocked = world.get_component_value(Comp.KNOCKED, e)
		var v: Vec2 = world.get_component_value(Comp.VELOCITY, e)
		var t = knocked.elapsed/knocked.duration
		v.x += knocked.x * knocked.strength * pow(1.0-t, 2)
		v.y += knocked.y * knocked.strength * pow(1.0-t, 2)
		
	
	
