extends Node

# Runtime input bindings and user preferences. Defaults live here so the menu,
# gameplay scripts, and saved settings all use the same InputMap actions.

const SETTINGS_PATH := "user://settings.cfg"
var settings_path: String = SETTINGS_PATH

const KEYBIND_LABELS := {
	"move_up": "Move up",
	"move_down": "Move down",
	"move_left": "Move left",
	"move_right": "Move right",
	"dash": "Dash",
	"start": "Start game",
	"pause": "Pause / resume",
	"cast_modifier": "Cast modifier",
	"rune_fire": "Fire rune",
	"rune_water": "Water rune",
	"rune_wind": "Wind rune",
	"retry": "Retry round",
	"fullscreen": "Toggle fullscreen",
	"debug_badges": "Debug badges",
}

const DEFAULT_KEYS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"dash": [KEY_SPACE],
	"start": [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER],
	"pause": [KEY_ESCAPE, KEY_P],
	"cast_modifier": [KEY_SHIFT],
	"rune_fire": [KEY_J],
	"rune_water": [KEY_K],
	"rune_wind": [KEY_L],
	"retry": [KEY_R],
	"fullscreen": [KEY_F11],
	"debug_badges": [KEY_F1],
}

var _config := ConfigFile.new()
var _volumes := {"Master": 1.0, "Music": 1.0, "SFX": 1.0}


func _ready() -> void:
	_ensure_actions()
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_load()
	_apply_volumes()


func _ensure_actions() -> void:
	for action in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for code in DEFAULT_KEYS[action]:
				InputMap.action_add_event(action, _key_event(code))

	# Left mouse is the default spell-launch input. It is kept outside the
	# keyboard rebind list so the keybind panel can focus on keyboard controls.
	if not InputMap.has_action("launch_spell"):
		InputMap.add_action("launch_spell")
	if InputMap.action_get_events("launch_spell").is_empty():
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("launch_spell", click)


func _key_event(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _load() -> void:
	if _config.load(settings_path) != OK:
		return
	for action in KEYBIND_LABELS:
		if not _config.has_section_key("bindings", action):
			continue
		var saved = _config.get_value("bindings", action)
		if saved is Array:
			InputMap.action_erase_events(action)
			for data in saved:
				if data is Dictionary:
					InputMap.action_add_event(action, _event_from_data(data))
		elif saved is Dictionary:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, _event_from_data(saved))
	for bus in _volumes:
		_volumes[bus] = clampf(float(_config.get_value("audio", bus, 1.0)), 0.0, 1.0)


func _event_from_data(data: Dictionary) -> InputEvent:
	if data.get("type", "key") == "mouse":
		var mouse := InputEventMouseButton.new()
		mouse.button_index = int(data.get("button", MOUSE_BUTTON_LEFT))
		return mouse
	var key := InputEventKey.new()
	key.physical_keycode = int(data.get("physical", 0))
	key.keycode = int(data.get("key", key.physical_keycode))
	return key


func _data_from_event(event: InputEvent) -> Dictionary:
	if event is InputEventMouseButton:
		return {"type": "mouse", "button": event.button_index}
	var key := event as InputEventKey
	return {"type": "key", "physical": key.physical_keycode, "key": key.keycode}


func set_binding(action: String, event: InputEvent) -> void:
	var binding := event.duplicate()
	if binding is InputEventKey:
		binding.pressed = false
		binding.echo = false
	elif binding is InputEventMouseButton:
		binding.pressed = false
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, binding)
	_config.set_value("bindings", action, _data_from_event(binding))
	_config.save(settings_path)


func reset_bindings() -> void:
	for action in KEYBIND_LABELS:
		InputMap.action_erase_events(action)
		var serialized: Array[Dictionary] = []
		for code in DEFAULT_KEYS[action]:
			var event := _key_event(code)
			InputMap.action_add_event(action, event)
			serialized.append(_data_from_event(event))
		_config.set_value("bindings", action, serialized)
	_config.save(settings_path)


func binding_text(action: String) -> String:
	for event in InputMap.action_get_events(action):
		return event.as_text().trim_suffix(" (Physical)")
	return "Unbound"


func set_volume(bus: String, value: float) -> void:
	_volumes[bus] = clampf(value, 0.0, 1.0)
	_config.set_value("audio", bus, _volumes[bus])
	_config.save(settings_path)
	_apply_volume(bus)


func get_volume(bus: String) -> float:
	return float(_volumes.get(bus, 1.0))


func _apply_volumes() -> void:
	for bus in _volumes:
		_apply_volume(bus)


func _apply_volume(bus: String) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var value: float = _volumes[bus]
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))
