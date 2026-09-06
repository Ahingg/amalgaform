class_name RuntimeSystem
extends RefCounted

static func process(world: World, delta: float) -> void:
	var timer := world.get_entities_with_comp([Comp.RUN_TIME])
	var player := world.get_entities_with_comp([Comp.PLAYER])
	var round := world.get_entities_with_comp([Comp.ROUND])
	if player.is_empty() or round.is_empty():
		return
	if world.entity_have_component(Comp.WON, round[0]): 
		return
	for e in timer:
		var t: Scalar = world.get_component_value(Comp.RUN_TIME, e)
		t.value += delta
