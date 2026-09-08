class_name TimerSystem
extends RefCounted

# HIT_STOP sengaja TIDAK di sini: TimerSystem jalan dengan waktu yang sudah
# diperlambat, dan hit stop harus dihitung dengan waktu asli. TimeScaleSystem
# yang mengurusnya.
const TIMERS := [Comp.DELAY, Comp.LIFETIME, Comp.INVULNERABLE, Comp.WET, Comp.KNOCKED, Comp.CASTING, Comp.DASH, Comp.DASH_COOLDOWN]

static func process(world: World, delta: float) -> void:
	for type in TIMERS: 
		var entities := world.get_entities_with_comp([type])
		# key untuk setiap id
		for e in entities:
			var comp: Countdown = world.get_component_value(type, e)
			comp.elapsed += delta
			if comp.elapsed < comp.duration:
				continue
			world.detach_component(type, e)
			if not comp.on_expire.is_empty():
				for key in comp.on_expire:
					var dupe: Dictionary = comp.on_expire[key].duplicate(true)
					world.attach_component(key, e, dupe)
