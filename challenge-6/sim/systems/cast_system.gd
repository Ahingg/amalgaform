class_name CastSystem
extends RefCounted

# Kerjaannya cuma satu: menjaga antrian rapalan.
#
# Dia TIDAK menyentuh time_scale lagi. Dulu iya, dan itu yang bikin hit stop
# tidak pernah jalan — dua system merasa memiliki time_scale, dan yang satu
# menimpa yang lain tiap frame.
#
# Yang dia simpan sekarang cuma "seberapa lambat SEHARUSNYA dunia karena
# antrian ini". Yang memutuskan kecepatan dunia sebenarnya cuma
# TimeScaleSystem.
#
# Pakai delta ASLI. Kalau open_time ikut melambat, terbentuk lingkaran umpan
# balik dan jendela 0,9 detik molor jadi beberapa detik nyata.
static func process(world: World, delta: float) -> void:
	for e in world.get_entities_with_comp([Comp.CAST_QUEUE]):
		var queue: Dictionary = world.get_component_value(Comp.CAST_QUEUE, e)

		if not queue["open"]:
			queue["open_time"] = 0.0
			queue["scale"] = 1.0
			continue

		queue["open_time"] = queue.get("open_time", 0.0) + delta
		queue["scale"] = 1.0 - (1.0 - Tuning.SLOW_MIN) \
			* exp(-queue["open_time"] / Tuning.SLOW_TAU)
