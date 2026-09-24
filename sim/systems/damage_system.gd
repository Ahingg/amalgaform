class_name DamageSystem
extends RefCounted



static func process(world: World, _delta: float) -> void:
	
	var entities := world.get_entities_with_comp([Comp.DAMAGED, Comp.HEALTH])
	var rounds := world.get_entities_with_comp([Comp.ROUND])


	for e in entities:
		if not world.entity_have_component(Comp.INVULNERABLE, e):
			var hp: Health = world.get_component_value(Comp.HEALTH, e)
			var dmg: Damaged = world.get_component_value(Comp.DAMAGED, e)
			hp.current -= dmg.damage
			world.attach_component(Comp.INVULNERABLE, e,
				Countdown.new(Tuning.INVULNERABLE_TIME))
			if not rounds.is_empty():
				world.attach_component(Comp.HIT_STOP, rounds[0], Countdown.new(Tuning.HIT_STOP_TIME))
		world.detach_component(Comp.DAMAGED, e)
