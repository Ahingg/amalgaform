class_name MeleeSystem
extends RefCounted

# Sama persis kayak ContactSystem, cuma kebalik: yang nyentuh entity ber-Melee,
# yang kena player.
#
# Querynya nanya KEMAMPUAN (Melee), bukan identitas (Enemy). Jadi musuh yang
# cuma nembak dari jauh tinggal ga dikasih Melee, system ini ga usah diubah.
#
# Kontak dinilai ulang tiap frame selama masih nyentuh. Aman disini soalnya
# DamageSystem nyaring lewat Invulnerable.

static func process(world: World, _delta: float) -> void:
	var sources := world.get_entities_with_comp([Comp.MELEE, Comp.POSITION, Comp.SIZE])
	var targets := world.get_entities_with_comp([Comp.PLAYER, Comp.HEALTH, Comp.POSITION, Comp.SIZE])
	if targets.is_empty():
		return

	for s in sources:
		var melee: Dictionary = world.get_component_value(Comp.MELEE, s)
		var action: Dictionary = melee.get(Comp.ON_HIT, {})
		if not (action.has("self") and action.has("target")):
			continue

		var pos_s: Vec2 = world.get_component_value(Comp.POSITION, s)
		var size_s: Size = world.get_component_value(Comp.SIZE, s)

		for t in targets:
			var pos_t: Vec2 = world.get_component_value(Comp.POSITION, t)
			var size_t: Size = world.get_component_value(Comp.SIZE, t)
			if not Helper.overlap(pos_s, size_s, pos_t, size_t):
				continue

			Inflict.apply(world, action, s, t, Helper.center(pos_s, size_s), Helper.center(pos_t, size_t))
