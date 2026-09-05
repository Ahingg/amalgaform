class_name CastSystem
extends RefCounted

# Dijalankan PALING AWAL dan dengan delta ASLI, bukan delta yang sudah dikali
# time_scale. Kalau open_time ikut melambat, terbentuk lingkaran umpan balik dan
# jendela 0,6 detik molor jadi beberapa detik nyata.
static func process(world: World, delta: float) -> void:
	var round_ids := world.get_entities_with_comp([Comp.ROUND, Comp.TIME_SCALE])
	if round_ids.is_empty():
		return

	var time_scale: Scalar = world.get_component_value(Comp.TIME_SCALE, round_ids[0])

	# Direset sebelum loop, bukan di dalamnya: kalau tidak ada perapal sama
	# sekali (player mati saat merapal), loop tidak jalan dan dunia akan
	# melambat selamanya.
	time_scale.value = 1.0

	# CastQueue sengaja hanya dipunyai player. Musuh yang bisa merapal nanti
	# menempelkan CastRelease langsung, tanpa antrian.
	for e in world.get_entities_with_comp([Comp.CAST_QUEUE]):
		var queue: Dictionary = world.get_component_value(Comp.CAST_QUEUE, e)
		if not queue["open"]:
			continue
		queue["open_time"] = queue.get("open_time", 0.0) + delta
		time_scale.value = 1.0 - (1.0 - Tuning.SLOW_MIN) \
			* exp(-queue["open_time"] / Tuning.SLOW_TAU)
