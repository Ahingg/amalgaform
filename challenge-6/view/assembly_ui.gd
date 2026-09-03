class_name AssemblyUI
extends Node2D

# ============================================================================
# INPUT / ASSEMBLY LAYER
#
# renderer.gd is strictly read-only. This file is NOT: placing a machine and
# editing its recipe are writes. That is fine, but it means input is its own
# layer, not part of the view — so it plays by one rule instead:
#
#   It only writes through sim's own front door: Spawn.* and the component
#   dictionaries World hands back. It never reaches into World's internals,
#   and it never contains game rules — no damage, no timing, no reactions.
#   Those belong to systems.
#
# What it does:
#   - click an empty tile      -> place a machine there
#   - click a machine          -> select it
#   - click a palette chip     -> toggle that component in the selected recipe
#   - right-click a machine    -> remove it and refund its slots
#
# NOTE (Xaviero's call, not mine): the slot budget lives in this file for now.
# It is game state, so it probably belongs inside World later — but that is a
# sim decision, so I left it here rather than inventing a component for it.
# ============================================================================

const COMP_MACHINE := "Machine"
const COMP_RECIPE := "Recipe"
const COMP_POSITION := "Position"

# Elements the player can drop into a recipe. Raw strings on purpose, same as
# the renderer: this file must never be the reason sim/ fails to parse.
const PALETTE := [
	{"label": "Fire", "comp": "Fire", "body": {"damage": 5.0}, "color": Color(0.95, 0.3, 0.2)},
	{"label": "Water", "comp": "Water", "body": {}, "color": Color(0.25, 0.6, 1.0)},
	{"label": "Wind", "comp": "Wind", "body": {}, "color": Color(0.4, 0.85, 0.75)},
]

# Every new machine starts with a delivery already in it, otherwise the spawned
# entity would have no position, no size and no lifetime, and MachineSystem
# would have nothing to place. Treat this as the "lingering area" delivery.
const DEFAULT_DELIVERY := {
	"Position": {"x": 1.0, "y": 0.0},
	"Size": {"w": 1.0, "h": 1.0},
	"Lifetime": {"elapsed": 0.0, "duration": 1.5},
}

const MACHINE_INTERVAL := 2.0
const SLOT_BUDGET := 8
const CHIP_SIZE := Vector2(96, 34)
const CHIP_GAP := 10.0

var selected: int = -1

var _font: Font
var _chip_rects: Array[Rect2] = []


func _ready() -> void:
	_font = ThemeDB.fallback_font
	z_index = 10


func _process(_delta: float) -> void:
	queue_redraw()


# --- access to the layers around this one -----------------------------------

func _renderer() -> WorldRenderer:
	return get_parent() as WorldRenderer


func _world():
	var r := _renderer()
	if r == null:
		return null
	var main := r.get_parent()
	if main == null:
		return null
	return main.get("world")


# --- slots -------------------------------------------------------------------

# Cost is derived from the world, never tracked in a counter. A counter would
# drift the moment anything else added or removed a machine; asking the world
# can never be out of date.
func _slots_used(world) -> int:
	var query: Array[String] = [COMP_MACHINE]
	var used := 0
	for m in world.get_entities_with_comp(query):
		used += 1  # the machine itself
		if world.entity_have_component(COMP_RECIPE, m):
			var recipe: Dictionary = world.get_component_value(COMP_RECIPE, m)
			for key in recipe:
				if _is_element(key):
					used += 1
	return used


func _is_element(comp_name: String) -> bool:
	for entry in PALETTE:
		if entry["comp"] == comp_name:
			return true
	return false


# --- input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	var world = _world()
	var r := _renderer()
	if world == null or r == null:
		return

	var at: Vector2 = event.position

	if event.button_index == MOUSE_BUTTON_LEFT:
		# Palette first: chips sit on top of the grid.
		for i in _chip_rects.size():
			if _chip_rects[i].has_point(at):
				_toggle_component(world, PALETTE[i])
				get_viewport().set_input_as_handled()
				return
		_click_grid(world, r, at)
		get_viewport().set_input_as_handled()

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		var tile := r.tile_at(at)
		var m := _machine_at(world, tile)
		if m != -1:
			world.remove_entity_by_id(m)
			if selected == m:
				selected = -1
		get_viewport().set_input_as_handled()


func _click_grid(world, r: WorldRenderer, at: Vector2) -> void:
	var tile := r.tile_at(at)
	if not r.inside_grid(tile):
		selected = -1
		return

	var existing := _machine_at(world, tile)
	if existing != -1:
		selected = existing
		return

	if _slots_used(world) + 1 > SLOT_BUDGET:
		return

	selected = Spawn.machine(
		world, float(tile.x), float(tile.y),
		MACHINE_INTERVAL,
		DEFAULT_DELIVERY.duplicate(true)
	)


func _machine_at(world, tile: Vector2i) -> int:
	var query: Array[String] = [COMP_MACHINE, COMP_POSITION]
	for m in world.get_entities_with_comp(query):
		var p: Dictionary = world.get_component_value(COMP_POSITION, m)
		if floori(float(p["x"])) == tile.x and floori(float(p["y"])) == tile.y:
			return m
	return -1


func _toggle_component(world, entry: Dictionary) -> void:
	if selected == -1 or not world.entity_have_component(COMP_RECIPE, selected):
		return

	var recipe: Dictionary = world.get_component_value(COMP_RECIPE, selected)
	var comp_name: String = entry["comp"]

	if recipe.has(comp_name):
		recipe.erase(comp_name)
		return

	if _slots_used(world) + 1 > SLOT_BUDGET:
		return

	# duplicate(): the palette entry is a template shared by every machine.
	# Handing the same dictionary out twice would make two machines share one
	# body, and a change to either would change both.
	recipe[comp_name] = (entry["body"] as Dictionary).duplicate(true)


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	var world = _world()
	var r := _renderer()
	if world == null or r == null:
		return

	if selected != -1 and world.entity_have_component(COMP_POSITION, selected):
		var p: Dictionary = world.get_component_value(COMP_POSITION, selected)
		var top_left := r.screen_of_tile(Vector2i(floori(float(p["x"])), floori(float(p["y"]))))
		draw_rect(Rect2(top_left - Vector2(3, 3), Vector2(r.tile_size + 6, r.tile_size + 6)),
			Color(1.0, 0.9, 0.4), false, 2.5)

	_draw_palette(world, r)


func _draw_palette(world, r: WorldRenderer) -> void:
	var used := _slots_used(world)
	var base := Vector2(r.margin.x, r.margin.y + r.grid_height * r.tile_size + 28)

	draw_string(_font, base + Vector2(0, -8),
		"Slot: %d / %d" % [used, SLOT_BUDGET],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color(1, 0.9, 0.5) if used < SLOT_BUDGET else Color(1, 0.5, 0.45))

	var recipe := {}
	if selected != -1 and world.entity_have_component(COMP_RECIPE, selected):
		recipe = world.get_component_value(COMP_RECIPE, selected)

	_chip_rects.clear()
	for i in PALETTE.size():
		var entry: Dictionary = PALETTE[i]
		var pos := base + Vector2(i * (CHIP_SIZE.x + CHIP_GAP), 6)
		var rect := Rect2(pos, CHIP_SIZE)
		_chip_rects.append(rect)

		var active: bool = recipe.has(entry["comp"])
		var col: Color = entry["color"]
		var enabled := selected != -1

		draw_rect(rect, Color(col.r, col.g, col.b, 0.75 if active else 0.18), true)
		draw_rect(rect, Color(1, 1, 1, 0.5 if enabled else 0.15), false, 1.5)
		draw_string(_font, pos + Vector2(12, 23), entry["label"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(1, 1, 1, 0.95 if enabled else 0.3))

	var hint := "Klik petak kosong: taruh mesin  ·  Klik mesin: pilih  ·  Klik kanan: hapus"
	if selected == -1:
		hint = "Belum ada mesin terpilih. Klik petak buat naruh, atau klik mesin yang ada."
	draw_string(_font, base + Vector2(0, CHIP_SIZE.y + 26), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.45))
