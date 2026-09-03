class_name SystemManager
extends RefCounted

static func process(world: World, delta: float) -> void:
	TimerSystem.process(world, delta)
	MachineSystem.process(world, delta)
	ChaseSystem.process(world, delta)
	IntentSystem.process(world, delta)
	MoveSystem.process(world, delta)
	FireContactSystem.process(world, delta)
	BurnSystem.process(world, delta)
	DamageSystem.process(world, delta)
	DeadSystem.process(world, delta)
	
