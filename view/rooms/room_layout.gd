class_name RoomLayout
extends Node2D

# Scene coordinates are authored at 52 pixels per room tile. The renderer
# scales the whole scene to its current responsive tile size.
const EDITOR_TILE_SIZE := 52.0

@export var room_size := Vector2i(20, 12)
@export var player_spawn := Vector2(3.0, 2.0)


func obstacle_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for child in $Obstacles.get_children():
		if child is ColorRect:
			result.append(Rect2(child.position / EDITOR_TILE_SIZE,
				child.size / EDITOR_TILE_SIZE))
	return result


func spawn_points() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for marker in $Spawns.get_children():
		if marker is Marker2D:
			result.append(marker.position / EDITOR_TILE_SIZE)
	return result


func exit_rect() -> Rect2:
	var exit_node := get_node_or_null("Exit") as ColorRect
	if exit_node == null:
		return Rect2()
	return Rect2(exit_node.position / EDITOR_TILE_SIZE,
		exit_node.size / EDITOR_TILE_SIZE)


func _process(_delta: float) -> void:
	var renderer := get_parent() as WorldRenderer
	if renderer == null:
		return
	var main := renderer.get_parent()
	if main == null:
		return
	visible = not main.is_menu()
	var exit_node := get_node_or_null("Exit") as ColorRect
	if exit_node == null:
		return
	var world = main.get("world")
	if world == null:
		exit_node.visible = false
		return
	var cleared: Array[String] = [ViewConfig.ROUND, ViewConfig.ROOM_CLEARED]
	exit_node.visible = not world.get_entities_with_comp(cleared).is_empty()
