class_name TimeScaleSystem
extends RefCounted

# SATU-SATUNYA pemilik time_scale.
#
# Sebelumnya CastSystem dan HitStopSystem sama-sama menulisnya, dan yang jalan
# belakangan selalu ditimpa yang duluan di frame berikutnya — jadi hit stop
# ditulis lalu dibuang, tiap frame, tanpa pernah sampai ke sdelta.
#
# Polanya sama dengan SpeedModifierSystem: mulai dari 1.0, lalu tiap sumber
# perlambatan menariknya turun. Tidak pernah menyimpan hasilnya, selalu
# menghitung ulang — jadi "tidak ada yang memperlambat" tidak butuh penanganan
# khusus, loopnya cuma tidak menemukan apa-apa.
#
# WAJIB jalan PALING AWAL dan dengan delta ASLI. Apa pun yang mengendalikan
# waktu tidak boleh ikut diperlambat oleh waktu — kalau HitStop dihitung dengan
# waktu yang sudah lambat, dia membekukan dirinya sendiri 20x lebih lama.

static func process(world: World, delta: float) -> void:
	var rounds := world.get_entities_with_comp([Comp.ROUND, Comp.TIME_SCALE])
	if rounds.is_empty():
		return
	var r: int = rounds[0]
	var scale: Scalar = world.get_component_value(Comp.TIME_SCALE, r)

	var slowest := 1.0

	# --- sumber 1: hit stop. Sesaat, tajam, dipicu kejadian. Dihitung di sini
	# (bukan di TIMERS) justru karena TIMERS jalan dengan waktu yang sudah
	# diperlambat, dan hit stop tidak boleh memperlambat dirinya sendiri.
	if world.entity_have_component(Comp.HIT_STOP, r):
		var hs: Countdown = world.get_component_value(Comp.HIT_STOP, r)
		hs.elapsed += delta
		if hs.elapsed >= hs.duration:
			world.detach_component(Comp.HIT_STOP, r)
		else:
			slowest = minf(slowest, Tuning.HIT_STOP_SCALE)

	# --- sumber 2: antrian rapalan. Berkelanjutan, meluruh, selama ditahan.
	# Nilainya sudah dihitung CastSystem; di sini cuma dibaca.
	for e in world.get_entities_with_comp([Comp.CAST_QUEUE]):
		var q: Dictionary = world.get_component_value(Comp.CAST_QUEUE, e)
		if q.get("open", false):
			slowest = minf(slowest, float(q.get("scale", 1.0)))

	scale.value = slowest
