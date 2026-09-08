class_name DamageSystem
extends RefCounted



static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.DAMAGED, Comp.HEALTH])

	for e in entities:
		if not world.entity_have_component(Comp.INVULNERABLE, e):
			var hp: Health = world.get_component_value(Comp.HEALTH, e)
			var dmg: Damaged = world.get_component_value(Comp.DAMAGED, e)
			hp.current -= dmg.damage
			world.attach_component(Comp.INVULNERABLE, e, TimeScale.new())
			# Ditempel ke entity RONDE, bukan ke yang terluka: perlambatan waktu
			# itu efek sedunia. Menempelkannya di musuh cuma kebetulan bisa
			# dicari, dan bikin dua musuh yang kena bersamaan saling menimpa.
			for r in world.get_entities_with_comp([Comp.ROUND]):
				world.attach_component(Comp.HIT_STOP, r,
					Countdown.new(Tuning.HIT_STOP_TIME))
		world.detach_component(Comp.DAMAGED, e)
