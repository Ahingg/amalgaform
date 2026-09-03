class_name SystemManager
extends RefCounted

static func process(world: World, delta: float) -> void:
	DelaySystem.process(world, delta)
	MachineSystem.process(world, delta)
	MoveSystem.process(world, delta)
	FireContactSystem.process(world, delta)
	BurnSystem.process(world, delta)
	DamageSystem.process(world, delta)
	InvulnerabilitySystem.process(world, delta)
	LifetimeSystem.process(world, delta)
	DeadSystem.process(world, delta)
	
