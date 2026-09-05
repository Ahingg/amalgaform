class_name SystemManager
extends RefCounted

static func process(world: World, delta: float) -> void:
	CastSystem.process(world, delta)
	var sdelta := delta * RoundState.time_scale(world)
	TimerSystem.process(world, sdelta)
	#MachineSystem.process(world, sdelta) # untuk sekarang ga kepake, cuma perlu cara kerja doang
	CastReleaseSystem.process(world, sdelta)
	SpellLaunchSystem.process(world, delta)
	ChaseSystem.process(world, sdelta)
	IntentSystem.process(world, sdelta)
	MoveSystem.process(world, sdelta)
	ContactSystem.process(world, sdelta)
	DamageSystem.process(world, sdelta)
	DeadSystem.process(world, sdelta)
	
