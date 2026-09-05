class_name RoundState
extends RefCounted

# Dibungkus supaya SystemManager tidak ikut tahu bentuk komponen keadaan ronde.
# Kalau nanti entity ronde bertambah isi (nomor gelombang, penghitung), yang
# perlu berubah cuma file ini.
static func time_scale(world: World) -> float:
	var entities := world.get_entities_with_comp([Comp.ROUND, Comp.TIME_SCALE])
	if entities.is_empty():
		return 1.0                                   # tanpa entity ronde, waktu normal
	var scale: Scalar = world.get_component_value(Comp.TIME_SCALE, entities[0])
	return scale.value
