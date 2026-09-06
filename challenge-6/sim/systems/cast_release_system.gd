class_name CastReleaseSystem
extends RefCounted


static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.CAST_RELEASE])
	for e in entities:
		var body: Dictionary = world.get_component_value(Comp.CAST_RELEASE, e)
		if not body.has("runes") or body["runes"].is_empty():
			continue
			
		var recipe := Grammar.build(body["runes"])
		var cast_time: float = Tuning.CAST_BASE + Tuning.CAST_PER_RUNE * body["runes"].size()
		world.attach_component(Comp.CASTING, e, Countdown.new(cast_time, { Comp.HELD_SPELL: Make.held_spell(recipe, body["runes"].duplicate(true))}))
		world.detach_component(Comp.CAST_RELEASE, e)
