class_name MeleeSystem
extends RefCounted

# Bentuknya sama persis dengan ContactSystem, cuma arahnya kebalik: yang
# menyentuh adalah entity ber-Melee, yang kena adalah player.
#
# Query-nya menanyakan KEMAMPUAN (Melee), bukan identitas (Enemy) — jadi musuh
# yang cuma menembak dari jauh tinggal tidak diberi Melee, tanpa system ini
# diubah.
#
# Kontak dinilai ulang tiap frame selama masih bersentuhan. Itu aman di sini
# karena DamageSystem menyaring lewat Invulnerable.
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

			Inflict.apply(world, action, s, t, pos_s, pos_t)
