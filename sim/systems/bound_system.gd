class_name BoundSystem
extends RefCounted

static func process(world: World, delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.BOUNDED, Comp.POSITION, Comp.SIZE])
	var room := RoundState.room_size(world)
	var obstacles := RoundState.room_obstacles(world)
	
	for e in entities:
		var pos: Vec2 = world.get_component_value(Comp.POSITION, e)
		var size: Size = world.get_component_value(Comp.SIZE, e)
		var previous := Vector2(pos.x, pos.y)
		if world.entity_have_component(Comp.VELOCITY, e):
			var velocity: Vec2 = world.get_component_value(Comp.VELOCITY, e)
			previous -= Vector2(velocity.x, velocity.y) * delta
		pos.x = max(0.0, min(room.w - size.w, pos.x))
		pos.y = max(0.0, min(room.h - size.h, pos.y))
		for obstacle in obstacles:
			var actor_rect := Rect2(pos.x, pos.y, size.w, size.h)
			if not actor_rect.intersects(obstacle):
				continue
			if previous.x + size.w <= obstacle.position.x:
				pos.x = obstacle.position.x - size.w
			elif previous.x >= obstacle.end.x:
				pos.x = obstacle.end.x
			elif previous.y + size.h <= obstacle.position.y:
				pos.y = obstacle.position.y - size.h
			elif previous.y >= obstacle.end.y:
				pos.y = obstacle.end.y
			else:
				var push_left := obstacle.position.x - (pos.x + size.w)
				var push_right := obstacle.end.x - pos.x
				var push_up := obstacle.position.y - (pos.y + size.h)
				var push_down := obstacle.end.y - pos.y
				var pushes := [push_left, push_right, push_up, push_down]
				var smallest: float = pushes[0]
				for push in pushes:
					if absf(push) < absf(smallest):
						smallest = push
				if smallest == push_left or smallest == push_right:
					pos.x += smallest
				else:
					pos.y += smallest
		pos.x = clampf(pos.x, 0.0, room.w - size.w)
		pos.y = clampf(pos.y, 0.0, room.h - size.h)
			
