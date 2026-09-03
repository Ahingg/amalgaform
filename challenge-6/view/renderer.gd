class_name WorldRenderer
extends Node2D

# ============================================================================
# VIEW LAYER — READ ONLY
#
# This file never writes anything into World. It only asks and draws. If this
# file were deleted, the simulation would still run exactly the same — it would
# just be invisible.
#
# CONTRACT with sim/:
#   - component "Position" holds {"x": float, "y": float} in tile units
#   - component "Size" (optional) holds {"w": float, "h": float}, default 1x1
#
# Raw strings are used here on purpose instead of Comp.XXX, so that this file
# can never break sim/ parsing if a constant is missing or renamed.
# To make a new component show up as a badge, add it to BADGE_ORDER.
# ============================================================================

const COMP_POSITION := "Position"
const COMP_SIZE := "Size"
const COMP_DELAY := "Delay"
const COMP_INVULNERABLE := "Invulnerable"
const COMP_HEALTH := "Health"

# Order matters: the first matching component wins the color.
const COMPONENT_COLORS := {
	"Player": Color(0.95, 0.9, 0.7),
	"Burn": Color(1.0, 0.45, 0.15),
	"Fire": Color(0.95, 0.3, 0.2),
	"Water": Color(0.25, 0.6, 1.0),
	"Wind": Color(0.4, 0.85, 0.75),
	"Damaged": Color(1.0, 0.85, 0.2),
	"Machine": Color(0.65, 0.55, 0.85),
	"Health": Color(0.55, 0.8, 0.4),
}

# Component names printed under each entity, so you can see what shape that
# entity currently has. This is the most useful ECS debugging tool here.
const BADGE_ORDER := [
	"Position", "Velocity", "Size", "Delay", "Fire", "Water", "Wind",
	"Burn", "Damaged", "Health", "Invulnerable",
	"Machine", "Recipe", "Lifetime", "Dead",
	"Player", "MoveIntent", "Chase", "CastQueue", "CastRelease",
]

@export var grid_width: int = 12
@export var grid_height: int = 8
@export var tile_size: float = 64.0
@export var margin: Vector2 = Vector2(48, 48)
@export var show_badges: bool = true

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	# Input layers live under the renderer so they can reuse the geometry
	# helpers above, and so main.gd does not need to know they exist.
	# AssemblyUI is parked: machine placement before the round no longer exists
	# after design revision 3. The file is kept for the casting panel.
	add_child(PlayerInput.new())
	add_child(CastUI.new())


func _process(_delta: float) -> void:
	# The simulation advances in Main's _physics_process. Here we only ask for
	# a repaint every rendered frame.
	queue_redraw()


func _draw() -> void:
	_draw_grid()

	var world = _get_world()
	if world == null:
		_draw_message("No World on Main yet. Renderer is waiting.")
		return

	var query: Array[String] = [COMP_POSITION]
	var ids: Array[int] = world.get_entities_with_comp(query)

	if ids.is_empty():
		_draw_message("No entity has the \"%s\" component yet." % COMP_POSITION)
		return

	for id in ids:
		_draw_entity(world, id)


# --- geometry helpers, shared with the input layer -----------------------------
# The UI must not recompute tile maths on its own; if the grid moves, only this
# file should need to know.

func tile_at(screen_pos: Vector2) -> Vector2i:
	var local := screen_pos - margin
	return Vector2i(floori(local.x / tile_size), floori(local.y / tile_size))


func screen_of_tile(tile: Vector2i) -> Vector2:
	return margin + Vector2(tile) * tile_size


func inside_grid(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < grid_width and tile.y < grid_height


# --- world lookup ------------------------------------------------------------

# Fetched every frame on purpose instead of cached once in _ready.
# Reason: on retry, Main builds a NEW World. A cached reference would keep
# drawing the old, discarded world forever.
func _get_world():
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get("world")


# --- drawing -----------------------------------------------------------------

func _draw_grid() -> void:
	var w := grid_width * tile_size
	var h := grid_height * tile_size

	draw_rect(Rect2(margin, Vector2(w, h)), Color(0.11, 0.12, 0.15), true)

	var line_color := Color(1, 1, 1, 0.07)
	for i in range(grid_width + 1):
		var x := margin.x + i * tile_size
		draw_line(Vector2(x, margin.y), Vector2(x, margin.y + h), line_color, 1.0)
	for j in range(grid_height + 1):
		var y := margin.y + j * tile_size
		draw_line(Vector2(margin.x, y), Vector2(margin.x + w, y), line_color, 1.0)


func _draw_entity(world, id: int) -> void:
	var pos: Dictionary = world.get_component_value(COMP_POSITION, id)
	var px: float = float(pos.get("x", 0.0))
	var py: float = float(pos.get("y", 0.0))

	var w := 1.0
	var h := 1.0
	if world.entity_have_component(COMP_SIZE, id):
		var s: Dictionary = world.get_component_value(COMP_SIZE, id)
		w = float(s.get("w", 1.0))
		h = float(s.get("h", 1.0))

	var top_left := margin + Vector2(px, py) * tile_size
	var size := Vector2(w, h) * tile_size
	var rect := Rect2(top_left, size)

	var color := _color_for(world, id)

	# Tiles touched by this entity (binary occupancy: touching means inside).
	# Highlighted faintly so you can see when one entity straddles two tiles.
	_highlight_occupied_tiles(px, py, w, h, color)

	# While the i-frame window is open the entity blinks, so you can see exactly
	# when it can be hurt again. Blink is driven by the component's own elapsed
	# value, not by wall-clock time, so it stays in step with the simulation.
	var alpha := 0.85
	if world.entity_have_component(COMP_INVULNERABLE, id):
		var inv: Dictionary = world.get_component_value(COMP_INVULNERABLE, id)
		var t: float = float(inv.get("elapsed", 0.0))
		alpha = 0.85 if fmod(t, 0.16) < 0.08 else 0.2

	draw_rect(rect, Color(color.r, color.g, color.b, alpha), true)
	draw_rect(rect, Color(1, 1, 1, 0.5), false, 1.5)

	# Delay is drawn as a progress bar above the entity.
	if world.entity_have_component(COMP_DELAY, id):
		_draw_delay_bar(world, id, top_left, size.x)

	draw_string(_font, top_left + Vector2(5, 16), "#%d" % id,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 0, 0, 0.75))

	if world.entity_have_component(COMP_HEALTH, id):
		_draw_health_bar(world, id, top_left + Vector2(0, size.y + 3), size.x)

	if show_badges:
		var badges := _component_badges(world, id)
		if badges != "":
			draw_string(_font, top_left + Vector2(0, size.y + 22), badges,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.65))


func _draw_health_bar(world, id: int, at: Vector2, width_px: float) -> void:
	var hp: Dictionary = world.get_component_value(COMP_HEALTH, id)
	var max_hp: float = float(hp.get("max", 0.0))
	if max_hp <= 0.0:
		return
	var current: float = float(hp.get("current", 0.0))
	var ratio: float = clampf(current / max_hp, 0.0, 1.0)

	draw_rect(Rect2(at, Vector2(width_px, 5)), Color(0, 0, 0, 0.55), true)
	draw_rect(Rect2(at, Vector2(width_px * ratio, 5)), Color(0.4, 0.85, 0.35), true)
	draw_string(_font, at + Vector2(width_px + 5, 6), "%d/%d" % [int(current), int(max_hp)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.55))


func _highlight_occupied_tiles(px: float, py: float, w: float, h: float, color: Color) -> void:
	var x0 := floori(px)
	var y0 := floori(py)
	var x1 := ceili(px + w) - 1
	var y1 := ceili(py + h) - 1
	for tx in range(x0, x1 + 1):
		for ty in range(y0, y1 + 1):
			var p := margin + Vector2(tx, ty) * tile_size
			draw_rect(Rect2(p, Vector2(tile_size, tile_size)),
				Color(color.r, color.g, color.b, 0.13), true)


func _draw_delay_bar(world, id: int, top_left: Vector2, width_px: float) -> void:
	var d: Dictionary = world.get_component_value(COMP_DELAY, id)
	var duration: float = float(d.get("duration", 0.0))
	if duration <= 0.0:
		return
	var elapsed: float = float(d.get("elapsed", 0.0))
	var ratio: float = clampf(elapsed / duration, 0.0, 1.0)

	var bar_top := top_left + Vector2(0, -9)
	draw_rect(Rect2(bar_top, Vector2(width_px, 5)), Color(0, 0, 0, 0.55), true)
	draw_rect(Rect2(bar_top, Vector2(width_px * ratio, 5)), Color(0.95, 0.85, 0.3), true)


func _color_for(world, id: int) -> Color:
	for comp_name in COMPONENT_COLORS:
		if world.entity_have_component(comp_name, id):
			return COMPONENT_COLORS[comp_name]
	return Color(0.75, 0.75, 0.8)


func _component_badges(world, id: int) -> String:
	var owned: Array[String] = []
	for comp_name in BADGE_ORDER:
		if world.entity_have_component(comp_name, id):
			owned.append(comp_name)
	return " ".join(owned)


func _draw_message(text: String) -> void:
	draw_string(_font, margin + Vector2(8, -14), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.6))
