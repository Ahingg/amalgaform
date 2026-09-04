class_name IntentSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.VELOCITY, Comp.MOVE_INTENT, Comp.SPEED, Comp.FACING])
	
	for e in entities:
		var casting := world.get_entities_with_comp([Comp.CAST_QUEUE])
		var can_move: bool = true
		if not casting.is_empty():
			var cast := world.get_component_value(Comp.CAST_QUEUE, e)
			can_move = not cast["open"]
		
		var intent := world.get_component_value(Comp.MOVE_INTENT, e)
		var speed := world.get_component_value(Comp.SPEED, e)
		
		var face_direction := world.get_component_value(Comp.FACING, e)
		face_direction["x"] = ceili(intent["x"])
		face_direction["y"] = ceili(intent["y"])
		
		
		var v := world.get_component_value(Comp.VELOCITY, e)
		if can_move:
			v["x"] = intent["x"] * speed["value"]
			v["y"] = intent["y"] * speed["value"] 
		else:
			v["x"] = 0.0
			v["y"] = 0.0
