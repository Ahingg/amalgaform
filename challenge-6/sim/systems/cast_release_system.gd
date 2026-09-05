class_name CastReleaseSystem
extends RefCounted


static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.CAST_RELEASE])
	for e in entities:
		var body: Dictionary = world.get_component_value(Comp.CAST_RELEASE, e)
		if not body.has("runes") or body["runes"].is_empty():
			continue
			
		var recipe := Grammar.build(body["runes"])
		world.attach_component(Comp.HELD_SPELL, e, Make.held_spell(recipe, body["runes"].duplicate(true)))
		world.detach_component(Comp.CAST_RELEASE, e)
