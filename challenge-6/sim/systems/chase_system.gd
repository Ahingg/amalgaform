class_name ChaseSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.CHASE, Comp.POSITION, Comp.MOVE_INTENT])
	var player := world.get_entities_with_comp([Comp.PLAYER, Comp.POSITION])
	if player.is_empty():
		return
		
	var target_pos := world.get_component_value(Comp.POSITION, player[0])
	
	for e in entities:
		var pos := world.get_component_value(Comp.POSITION, e)
		var v2d: Vector2 = Vector2(target_pos["x"]-pos["x"], target_pos["y"]-pos["y"]).normalized()
		
		var intent := world.get_component_value(Comp.MOVE_INTENT, e)
		intent["x"] = v2d.x
		intent["y"] = v2d.y
		
		
