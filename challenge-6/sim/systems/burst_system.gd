class_name BurstSystem
extends RefCounted

static func process(world: World, _delta: float) -> void: 
	var entities: = world.get_entities_with_comp([Comp.BURST, Comp.VELOCITY, Comp.SPEED, Comp.SIZE, Comp.POSITION])
	for e in entities:
		#var puddle := world.add_entity()
		# karena ada burst, ubah dari yang awalnya ada kecepatan jadi diem karena pcah.
		world.detach_component(Comp.VELOCITY, e)
		world.detach_component(Comp.SPEED, e)
		var size: Size = world.get_component_value(Comp.SIZE, e)
		var pos: Vec2 = world.get_component_value(Comp.POSITION, e)
		pos.x -= ((Tuning.PUDDLE_SIZE - size.w)/2)
		pos.y -= ((Tuning.PUDDLE_SIZE - size.h)/2)
		# dikomen dulu, kalau mau balikin ke cuma puddle baru un comment lagi
		#world.attach_component(Comp.POSITION, puddle, Vec2.new(pos.x - ((Tuning.PUDDLE_SIZE - size.w)/2), pos.y - ((Tuning.PUDDLE_SIZE - size.h)/2)))
		size.w = Tuning.PUDDLE_SIZE
		size.h = Tuning.PUDDLE_SIZE
		#world.attach_component(Comp.SIZE, puddle, Size.new(Tuning.PUDDLE_SIZE, Tuning.PUDDLE_SIZE))
		world.attach_component(Comp.LIFETIME, e, Countdown.new(Tuning.PUDDLE_LIFETIME, {Comp.DEAD: {}}))
		#var burst: Dictionary = world.get_component_value(Comp.BURST, e)
		#world.attach_component(Comp.ON_HIT, puddle, Make.on_hit({}, burst["inflict"]))
