class_name SystemManager
extends RefCounted

static func process(world: World, delta: float) -> void:
	CastSystem.process(world, delta)
	var sdelta := delta * RoundState.time_scale(world)
	TimerSystem.process(world, sdelta)
	MachineSystem.process(world, sdelta)
	ChaseSystem.process(world, sdelta)
	IntentSystem.process(world, sdelta)
	MoveSystem.process(world, sdelta)
	FireContactSystem.process(world, sdelta)
	DamageSystem.process(world, sdelta)
	DeadSystem.process(world, sdelta)
	
