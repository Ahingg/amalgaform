class_name MachineSystem
extends RefCounted

# Mesin melahirkan entity dari resep, lalu memasang ulang Delay dari Interval.
# Sengaja bodoh: tidak pernah tahu isi resepnya apa, jadi jenis efek baru tidak
# pernah menyentuh file ini.
static func process(world: World, _delta: float) -> void:
	var machines := world.get_entities_with_comp(
		[Comp.MACHINE, Comp.RECIPE, Comp.POSITION, Comp.INTERVAL])

	for m in machines:
		if world.entity_have_component(Comp.DELAY, m):
			continue                                  # masih menghitung mundur

		var recipe: Dictionary = world.get_component_value(Comp.RECIPE, m)
		var machine_pos: Vec2 = world.get_component_value(Comp.POSITION, m)

		var born := world.add_entity()
		for comp in recipe:
			world.attach_component(comp, born, Inflict._copy(recipe[comp]))

		# Position di dalam resep bersifat relatif terhadap mesin.
		if world.entity_have_component(Comp.POSITION, born):
			var pos: Vec2 = world.get_component_value(Comp.POSITION, born)
			pos.x += machine_pos.x
			pos.y += machine_pos.y

		var interval: Scalar = world.get_component_value(Comp.INTERVAL, m)
		world.attach_component(Comp.DELAY, m, Countdown.new(interval.value))
