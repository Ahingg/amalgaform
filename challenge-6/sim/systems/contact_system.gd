class_name ContactSystem
extends RefCounted

# Spell menyentuh musuh. Isi OnHit dibongkar jadi dua: yang ditempel ke DIRI
# SENDIRI (mati, pecah) dan yang ditempel ke TARGET (luka, basah, terdorong).
# System ini tidak pernah tahu efeknya apa — dia cuma menyalurkan.
static func process(world: World, _delta: float) -> void:
	var sources := world.get_entities_with_comp([Comp.ON_HIT, Comp.POSITION, Comp.SIZE])
	var targets := world.get_entities_with_comp([Comp.ENEMY, Comp.HEALTH, Comp.POSITION, Comp.SIZE])

	for s in sources:
		var pos_s: Vec2 = world.get_component_value(Comp.POSITION, s)
		var size_s: Size = world.get_component_value(Comp.SIZE, s)
		var action: Dictionary = world.get_component_value(Comp.ON_HIT, s)
		if not (action.has("self") and action.has("target")):
			continue

		for t in targets:
			var pos_t: Vec2 = world.get_component_value(Comp.POSITION, t)
			var size_t: Size = world.get_component_value(Comp.SIZE, t)
			if not Helper.overlap(pos_s, size_s, pos_t, size_t):
				continue

			Inflict.apply(world, action, s, t, pos_s, pos_t)
