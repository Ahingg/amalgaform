class_name TimerSystem
extends RefCounted

const TIMERS := [Comp.DELAY, Comp.LIFETIME, Comp.INVULNERABLE]

static func process(world: World, delta: float) -> void:
	for type in TIMERS: 
		var entities := world.get_entities_with_comp([type])
		# key untuk setiap id
		for e in entities:
			var comp: Dictionary = world.get_component_value(type, e)
			comp["elapsed"] += delta
			if comp["elapsed"] < comp["duration"]:
				continue
			world.detach_component(type, e)
			if comp.has("on_expire"):
				for key in comp["on_expire"]:
					var dupe: Dictionary = comp["on_expire"][key].duplicate(true)
					world.attach_component(key, e, dupe)
					
