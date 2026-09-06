class_name DashSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var dasher := world.get_entities_with_comp([Comp.DASH_INTENT, Comp.MOVE_INTENT, Comp.FACING])
	
	for d in dasher:
		if world.entity_have_component(Comp.DASH_COOLDOWN, d): 
			continue
		
		var dir: Vec2 = world.get_component_value(Comp.MOVE_INTENT, d)
		if is_zero_approx(dir.x) and is_zero_approx(dir.y):
			dir = world.get_component_value(Comp.FACING, d)
		var dash := Impulse.new(Tuning.DASH_DURATION, Tuning.DASH_STRENGTH)
		dash.x = dir.x
		dash.y = dir.y
		world.attach_component(Comp.DASH, d, dash)
		world.attach_component(Comp.DASH_COOLDOWN, d, Countdown.new(Tuning.DASH_COOLDOWN))
		world.detach_component(Comp.DASH_INTENT, d)
