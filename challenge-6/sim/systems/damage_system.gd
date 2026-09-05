class_name DamageSystem
extends RefCounted


static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.DAMAGED, Comp.HEALTH])
	
	for e in entities:
		if not world.entity_have_component(Comp.INVULNERABLE, e):
			var hp := world.get_component_value(Comp.HEALTH, e)
			var dmg := world.get_component_value(Comp.DAMAGED, e)
			hp["current"] = max(hp["current"] - dmg["damage"], 0.0)
			world.attach_component(Comp.INVULNERABLE, e, Make.invulnerable(Tuning.INVULNERABLE_TIME))
		world.detach_component(Comp.DAMAGED, e)
