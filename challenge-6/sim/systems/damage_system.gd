class_name DamageSystem
extends RefCounted


static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.DAMAGED, Comp.HEALTH])
	
	for e in entities:
		if not world.entity_have_component(Comp.INVULNERABLE, e):
			var hp := world.get_component_value(Comp.HEALTH, e)
			var dmg := world.get_component_value(Comp.DAMAGED, e)
			hp["current"] -= dmg["damage"]
			world.attach_component(Comp.INVULNERABLE, e, Make.invulnerable(0.5))
		world.detach_component(Comp.DAMAGED, e)
