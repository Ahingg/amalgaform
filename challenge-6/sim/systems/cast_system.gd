class_name CastSystem
extends RefCounted

# Jalan PALING AWAL dan pake delta ASLI, bukan yang udah dikali time_scale.
# Kalo open_time ikut melambat, jadi lingkaran umpan balik dan jendela 0.6 detik
# molor jadi beberapa detik beneran.

static func process(world: World, delta: float) -> void:
	var round_ids := world.get_entities_with_comp([Comp.ROUND, Comp.TIME_SCALE])
	if round_ids.is_empty():
		return

	var time_scale: Scalar = world.get_component_value(Comp.TIME_SCALE, round_ids[0])

	# Direset sebelum loop, bukan didalemnya. Kalo gaada perapal sama sekali
	# (player mati pas lagi ngerapal), loopnya ga jalan dan dunianya bakal
	# lambat selamanya.
	time_scale.value = 1.0

	# CastQueue sengaja cuma punya player. Musuh yang bisa ngerapal nanti
	# nempelin CastRelease langsung, ga pake antrian.
	for e in world.get_entities_with_comp([Comp.CAST_QUEUE]):
		var queue: Dictionary = world.get_component_value(Comp.CAST_QUEUE, e)
		if not queue["open"]:
			continue
		queue["open_time"] = queue.get("open_time", 0.0) + delta
		time_scale.value = 1.0 - (1.0 - Tuning.SLOW_MIN) \
			* exp(-queue["open_time"] / Tuning.SLOW_TAU)
