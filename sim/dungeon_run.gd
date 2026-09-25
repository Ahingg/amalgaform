class_name DungeonRun
extends RefCounted

# Session progress survives the World being rebuilt for each room.
var room_index: int = 0
var room_count: int = 1
var room_order: Array[int] = []


func _init(p_room_count: int = 1) -> void:
	room_count = maxi(1, p_room_count)
	room_order.assign(range(room_count))
	room_order.shuffle()


func current_layout_index() -> int:
	return room_order[room_index]


func is_final_room() -> bool:
	return room_index >= room_count - 1


func advance() -> bool:
	if is_final_room():
		return false
	room_index += 1
	return true
