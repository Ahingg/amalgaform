class_name SystemManager
extends RefCounted

static func process(world: World, delta: float) -> void:
	DelaySystem.process(world, delta)
	pass
	
	
