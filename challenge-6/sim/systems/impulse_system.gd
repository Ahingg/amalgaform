class_name ImpulseSystem
extends RefCounted

const IMPULSES := [Comp.KNOCKED, Comp.DASH]

static func process(world: World, _delta: float) -> void:
	for i in IMPULSES:
		var entities := world.get_entities_with_comp([i, Comp.VELOCITY])
		for e in entities:
			var impulse: Impulse = world.get_component_value(i, e)
			var v: Vec2 = world.get_component_value(Comp.VELOCITY, e)
			if is_zero_approx(impulse.duration):
				continue
			var t = impulse.elapsed/impulse.duration
			v.x += impulse.x * impulse.strength * pow(1.0-t, 2)
			v.y += impulse.y * impulse.strength * pow(1.0-t, 2)
			#v.x += impulse.x * impulse.strength * t / 3
			#v.y += impulse.y * impulse.strength * t / 3
		
	
	
