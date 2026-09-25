class_name RoundState
extends RefCounted

# Dibungkus biar SystemManager ga ikut tau bentuk komponen keadaan ronde.
# Nanti kalo entity ronde nambah isi, yang berubah cuma file ini.

static func time_scale(world: World) -> float:
	var entities := world.get_entities_with_comp([Comp.ROUND, Comp.TIME_SCALE])
	if entities.is_empty():
		return 1.0                                   # tanpa entity ronde, waktu normal
	var scale: Scalar = world.get_component_value(Comp.TIME_SCALE, entities[0])
	return scale.value


static func room_size(world: World) -> Size:
	var entities := world.get_entities_with_comp([Comp.ROUND, Comp.ROOM_SIZE])
	if entities.is_empty():
		return Size.new(Tuning.ARENA_W, Tuning.ARENA_H)
	var size: Size = world.get_component_value(Comp.ROOM_SIZE, entities[0])
	return size
