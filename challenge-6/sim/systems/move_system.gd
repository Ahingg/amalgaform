class_name MoveSystem

extends RefCounted


static func process(world: World, delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.POSITION, Comp.VELOCITY])
	
	for e in entities:
		var pos: Dictionary = world.get_component_value(Comp.POSITION, e)
		var vel: Dictionary = world.get_component_value(Comp.VELOCITY, e)
		
		pos["x"] += vel["x"] * delta
		pos["y"] += vel["y"] * delta
			
	
