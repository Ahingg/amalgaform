class_name BurstSystem
extends RefCounted

static func process(world: World, _delta: float) -> void: 
	var entities: = world.get_entities_with_comp([Comp.BURST, Comp.VELOCITY, Comp.SPEED, Comp.SIZE, Comp.POSITION])
	for e in entities:
		var puddle := world.add_entity()
		var size: Size = world.get_component_value(Comp.SIZE, e)
		var pos: Vec2 = world.get_component_value(Comp.POSITION, e)
		world.attach_component(Comp.POSITION, puddle, Vec2.new(pos.x - ((Tuning.PUDDLE_SIZE - size.w)/2), pos.y - ((Tuning.PUDDLE_SIZE - size.h)/2)))
		world.attach_component(Comp.SIZE, puddle, Size.new(Tuning.PUDDLE_SIZE, Tuning.PUDDLE_SIZE))
		world.attach_component(Comp.LIFETIME, puddle, Countdown.new(Tuning.PUDDLE_LIFETIME, {Comp.DEAD: {}}))
		var burst: Dictionary = world.get_component_value(Comp.BURST, e)
		world.attach_component(Comp.ON_HIT, puddle, Make.on_hit({}, burst["inflict"]))
		
		world.attach_component(Comp.DEAD, e)
		
