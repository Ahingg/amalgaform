class_name ChaseSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.CHASE, Comp.POSITION, Comp.MOVE_INTENT])
	var player := world.get_entities_with_comp([Comp.PLAYER, Comp.POSITION])

	for e in entities:
		var intent: Vec2 = world.get_component_value(Comp.MOVE_INTENT, e)

		# Tidak ada yang dikejar: berhenti, bukan melanjutkan arah terakhir.
		if player.is_empty():
			intent.x = 0.0
			intent.y = 0.0
			continue

		var pos: Vec2 = world.get_component_value(Comp.POSITION, e)
		var target_pos: Vec2 = world.get_component_value(Comp.POSITION, player[0])
		var dir := Vector2(target_pos.x - pos.x, target_pos.y - pos.y).normalized()

		intent.x = dir.x
		intent.y = dir.y
