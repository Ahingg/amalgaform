class_name RoomExitSystem
extends RefCounted


static func process(world: World, _delta: float) -> void:
	var rounds := world.get_entities_with_comp([Comp.ROUND, Comp.ROOM_CLEARED, Comp.ROOM_EXIT])
	var players := world.get_entities_with_comp([Comp.PLAYER, Comp.POSITION, Comp.SIZE])
	if rounds.is_empty() or players.is_empty():
		return
	var exit_area: Rect2 = world.get_component_value(Comp.ROOM_EXIT, rounds[0])
	if exit_area.has_area() == false:
		return
	var exit_pos := Vec2.new(exit_area.position.x, exit_area.position.y)
	var exit_size := Size.new(exit_area.size.x, exit_area.size.y)
	for player in players:
		var position: Vec2 = world.get_component_value(Comp.POSITION, player)
		var size: Size = world.get_component_value(Comp.SIZE, player)
		if Helper.overlap(position, size, exit_pos, exit_size):
			world.attach_component(Comp.ROOM_EXITED, rounds[0])
			return
