class_name IntentSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.VELOCITY, Comp.MOVE_INTENT, Comp.SPEED, Comp.FACING])
	
	for e in entities:
		var intent := world.get_component_value(Comp.MOVE_INTENT, e)
		var speed := world.get_component_value(Comp.SPEED, e)
		
		var face_direction := world.get_component_value(Comp.FACING, e)
		face_direction["x"] = ceili(intent["x"])
		face_direction["y"] = ceili(intent["y"])
		
		
		var v := world.get_component_value(Comp.VELOCITY, e)
		v["x"] = intent["x"] * speed["value"]
		v["y"] = intent["y"] * speed["value"] 
