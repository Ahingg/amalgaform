
class_name DeadSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.DEAD])
	for e in entities:
		world.remove_entity_by_id(e)
