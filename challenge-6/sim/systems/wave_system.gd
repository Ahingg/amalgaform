class_name WaveSystem
extends RefCounted

const WAVES := [
	{ "count": 3, "hp": 100, "at": [[0,0], [20, 0], [20, 12]]},
	{ "count": 4, "hp": 120, "at": [[0,0], [20, 0], [20, 12], [0, 12]]},
	{ "count": 5, "hp": 140, "at": [[0,0], [20, 0], [20, 12], [19, 11], [19, 0]]},
	{ "count": 6, "hp": 160, "at": [[0,0], [20, 0], [20, 12], [19, 11], [19, 0], [1, 1], [19, 0], [1, 11]]},
]

static func process(world: World, _delta: float) -> void:
	var round := world.get_entities_with_comp([Comp.ROUND, Comp.ROUND_WAVE])
	var enemies := world.get_entities_with_comp([Comp.ENEMY])
	for r in round:
		var wave: Scalar = world.get_component_value(Comp.ROUND_WAVE, r)
		if world.entity_have_component(Comp.DELAY, r) or not enemies.is_empty():
			continue
		if wave.value > Tuning.WAVE_COUNT and not world.entity_have_component(Comp.WON, r):
			world.attach_component(Comp.WON, r)
			continue
		var data: Dictionary = WAVES[wave.value-1]
		for i in data["count"]:
			Spawn.enemy(world, data["at"][i][0], data["at"][i][1], data["hp"])
		wave.value += 1	
		world.attach_component(Comp.DELAY, r, Countdown.new(Tuning.WAVE_GAP))
		
