class_name PlayerInput
extends Node

# ============================================================================
# INPUT LAYER — keyboard to intent
#
# This writes into World, so it is not part of the read-only view. It plays by
# the input-layer rule instead: it may write, but only plain intent, and it
# holds no game rules. How fast the wizard actually moves, whether casting
# slows him down, whether wind overrides him — all of that is sim's business.
#
# CONTRACT with sim/:
#   - the wizard entity carries a "Player" tag component (no data)
#   - this layer writes "MoveIntent" = {"x": float, "y": float}, a normalised
#     direction in -1..1. It is a REQUEST, not a movement.
#
# sim/ still needs a system that turns MoveIntent into Velocity. That system is
# where speed, casting penalties and knockback get reconciled — and it is a
# design decision, so it is not written here.
# ============================================================================

# Component names come from ViewConfig.


func _physics_process(_delta: float) -> void:
	var world = _get_world()
	if world == null:
		return

	var query: Array[String] = [ViewConfig.PLAYER]
	var players: Array[int] = world.get_entities_with_comp(query)
	if players.is_empty():
		return

	var dir := _read_direction()

	for id in players:
		# Written every tick, including when it is zero. Only writing on
		# keypress would leave the last direction stuck in the component after
		# the key is released, and the wizard would drift forever. "No input"
		# is a statement that has to be made out loud.
		if world.entity_have_component(ViewConfig.MOVE_INTENT, id):
			var intent: Dictionary = world.get_component_value(ViewConfig.MOVE_INTENT, id)
			intent["x"] = dir.x
			intent["y"] = dir.y
		else:
			world.attach_component(ViewConfig.MOVE_INTENT, id, {"x": dir.x, "y": dir.y})


func _read_direction() -> Vector2:
	var dir := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0

	# Without this, holding two keys gives length 1.41 and diagonal movement is
	# 41% faster than straight movement. Players find that within a minute and
	# then run diagonally forever.
	return dir.normalized()


func _get_world():
	# Walked up from the renderer, and re-read every tick rather than cached:
	# on retry Main builds a NEW World, and a cached reference would keep
	# writing into the discarded one.
	var renderer := get_parent()
	if renderer == null:
		return null
	var main := renderer.get_parent()
	if main == null:
		return null
	return main.get("world")
