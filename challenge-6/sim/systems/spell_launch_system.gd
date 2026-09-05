class_name SpellLaunchSystem
extends RefCounted

# Babak dua: bola yang dipegang dilepas ke arah Facing.
#
# Position sama Speed di FORM itu cuma template, yang satu relatif ke pelempar,
# yang satu besaran tanpa arah. Cuma dua ini yang butuh konteks peluncuran,
# sisanya lewat apa adanya. Makanya dibenerin SEBELUM di attach, bukan
# dikoreksi setelahnya.

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp(
		[Comp.LAUNCH_SPELL, Comp.HELD_SPELL, Comp.POSITION, Comp.FACING])

	for e in entities:
		var facing: Vec2 = world.get_component_value(Comp.FACING, e)
		var caster: Vec2 = world.get_component_value(Comp.POSITION, e)
		var origin := Vec2.new(
			caster.x + facing.x * Tuning.SPAWN_OFFSET,
			caster.y + facing.y * Tuning.SPAWN_OFFSET)

		var held: Dictionary = world.get_component_value(Comp.HELD_SPELL, e)
		var recipe: Dictionary = held["recipe"]

		if recipe.has(Comp.POSITION):
			recipe[Comp.POSITION] = origin
		if recipe.has(Comp.SPEED):
			var s: Speed = recipe[Comp.SPEED]
			recipe[Comp.VELOCITY] = Vec2.new(facing.x * s.value, facing.y * s.value)

		var spell := world.add_entity()
		for comp in recipe:
			world.attach_component(comp, spell, Inflict._copy(recipe[comp]))

		world.detach_component(Comp.LAUNCH_SPELL, e)
		world.detach_component(Comp.HELD_SPELL, e)
