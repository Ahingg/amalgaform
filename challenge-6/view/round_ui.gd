class_name RoundUI
extends Node2D

# ============================================================================
# ROUND STATE — lose overlay, retry, attempt counter
#
# Death is not a state anybody stores: it is simply the absence of an entity
# tagged Player. Nothing in sim/ has to be told the round is over, and nothing
# has to be reset when it starts again — main.build_round() throws the World
# away and builds a new one. That is only possible because no simulation state
# ever lived outside World.
#
# The attempt counter is the exception, and deliberately so: attempts belong to
# the SESSION, not to the round, so it lives on main and survives the rebuild.
#
# Framing matters here. The counter is shown as effort, not as failure — the
# game never says "you died 12 times", it says this is attempt 12. Retrying is
# the intended way to play, so the UI should not flinch at it.
# ============================================================================

const RETRY_KEY := KEY_R

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	z_index = 30


func _process(_delta: float) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode != RETRY_KEY:
		return
	var main = _main()
	if main == null:
		return
	main.retry()
	get_viewport().set_input_as_handled()


func _main():
	var renderer := get_parent()
	return null if renderer == null else renderer.get_parent()


func _draw() -> void:
	var main = _main()
	if main == null:
		return
	var world = main.get("world")
	if world == null:
		return

	var attempt: int = main.get("attempt")
	_draw_attempt(attempt)

	var query: Array[String] = ["Player"]
	if not world.get_entities_with_comp(query).is_empty():
		return

	_draw_lost()


func _draw_attempt(attempt: int) -> void:
	draw_string(_font, Vector2(48, 30), "Percobaan %d" % attempt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.45))


func _draw_lost() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.08, 0.72), true)

	var center := size * 0.5
	draw_string(_font, center + Vector2(-70, -10), "KALAH",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color(0.95, 0.35, 0.3))
	draw_string(_font, center + Vector2(-70, 26), "Tekan R untuk mengulang",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))
