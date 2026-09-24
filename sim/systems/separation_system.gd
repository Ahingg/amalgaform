class_name SeparationSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.ENEMY, Comp.POSITION, Comp.SIZE, Comp.VELOCITY])
	var len := entities.size()
	for i in range(len):
		for j in range(len):
			if i == j:
				continue
			var a := entities[i]
			var b := entities[j]
			var pos_a: Vec2 = world.get_component_value(Comp.POSITION, a)
			var pos_b: Vec2 = world.get_component_value(Comp.POSITION, b)
			var size_a: Size = world.get_component_value(Comp.SIZE, a)
			var size_b: Size = world.get_component_value(Comp.SIZE, b)
			if Helper.overlap(pos_a, size_a, pos_b, size_b):
				var dir: Vector2 = Vector2(pos_a.x - pos_b.x, pos_a.y - pos_b.y).normalized()
				
				var va: Vec2 = world.get_component_value(Comp.VELOCITY, a)
				va.x += (dir.x * Tuning.SEPARATE_SPEED) # speed pemecah
				va.y += (dir.y * Tuning.SEPARATE_SPEED)
