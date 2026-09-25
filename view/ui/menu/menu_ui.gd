class_name MenuUI
extends Control

const PAUSE_ACTION := "pause"

@onready var _menu_content: Control = $MenuContent
@onready var _pause_content: Control = $PauseContent
@onready var _settings_content: Control = $SettingsContent
@onready var _audio_controls: VBoxContainer = $SettingsContent/Center/Panel/Margins/Contents/AudioControls
@onready var _keybind_list: VBoxContainer = $SettingsContent/Center/Panel/Margins/Contents/KeybindScroll/KeybindList
@onready var _settings_hint: Label = $SettingsContent/Center/Panel/Margins/Contents/Hint
@onready var _menu_footer: Label = $MenuContent/Center/Contents/Footer

var _settings_open := false
var _pending_action := ""
var _binding_buttons: Dictionary = {}
var _volume_labels: Dictionary = {}


func _ready() -> void:
	_build_audio_controls()
	_build_keybind_controls()
	_refresh_control_hints()
	$MenuContent/Center/Contents/PlayButton.pressed.connect(_start_game)
	$MenuContent/Center/Contents/SettingsButton.pressed.connect(_open_settings)
	$MenuContent/Center/Contents/QuitButton.pressed.connect(_quit_game)
	$PauseContent/Center/Contents/ResumeButton.pressed.connect(_resume_game)
	$PauseContent/Center/Contents/SettingsButton.pressed.connect(_open_settings)
	$PauseContent/Center/Contents/MainMenuButton.pressed.connect(_return_to_menu)
	$PauseContent/Center/Contents/QuitButton.pressed.connect(_quit_game)
	$SettingsContent/Center/Panel/Margins/Contents/Buttons/ResetButton.pressed.connect(_reset_bindings)
	$SettingsContent/Center/Panel/Margins/Contents/Buttons/BackButton.pressed.connect(_close_settings)

	_style_buttons()
	_process(0.0)


func _process(_delta: float) -> void:
	var main = _main()
	if main == null:
		return
	var on_menu: bool = main.is_menu()
	var paused: bool = main.mode == main.Mode.PAUSED
	visible = on_menu or paused
	$Backdrop.color = Color(0.045, 0.04, 0.06, 1.0 if on_menu else 0.62)
	_menu_content.visible = on_menu and not _settings_open
	_pause_content.visible = paused and not _settings_open
	_settings_content.visible = _settings_open


func _main():
	var layer := get_parent()
	return null if layer == null else layer.get_parent()


func _input(event: InputEvent) -> void:
	if _pending_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			var cancelled := _pending_action
			_pending_action = ""
			_refresh_binding(cancelled)
			_close_settings()
			get_viewport().set_input_as_handled()
			return
		GameSettings.set_binding(_pending_action, event)
		_finish_binding()
		get_viewport().set_input_as_handled()
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var main = _main()
	if main == null:
		return

	if _settings_open:
		if event.is_action_pressed(PAUSE_ACTION):
			_close_settings()
			get_viewport().set_input_as_handled()
		return

	if main.is_menu() and event.is_action_pressed("start"):
		_start_game()
		get_viewport().set_input_as_handled()
	elif not main.is_menu() and event.is_action_pressed(PAUSE_ACTION):
		# Escape cancels a rune queue first; CastUI consumes that event. If it
		# reaches this screen, pause/resume is the next layer of meaning.
		main.toggle_pause()
		get_viewport().set_input_as_handled()


func _start_game() -> void:
	var main = _main()
	if main != null and main.is_menu():
		_settings_open = false
		main.start()


func _resume_game() -> void:
	var main = _main()
	if main != null and main.mode == main.Mode.PAUSED:
		main.toggle_pause()


func _return_to_menu() -> void:
	_settings_open = false
	var main = _main()
	if main != null:
		main.return_to_menu()


func _quit_game() -> void:
	get_tree().quit()


func _open_settings() -> void:
	_pending_action = ""
	_settings_open = true
	_settings_hint.text = "Choose a binding, then press a key. Press Esc here to go back."


func _close_settings() -> void:
	_pending_action = ""
	_settings_open = false


func _build_audio_controls() -> void:
	for entry in [["Master", "Master volume"], ["Music", "Music volume"], ["SFX", "Sound effects"]]:
		var bus: String = entry[0]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var label := Label.new()
		label.text = entry[1]
		label.custom_minimum_size.x = 150
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value = GameSettings.get_volume(bus)
		row.add_child(slider)
		var value_label := Label.new()
		value_label.custom_minimum_size.x = 48
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)
		_volume_labels[bus] = value_label
		_update_volume_label(bus, slider.value)
		slider.value_changed.connect(func(value: float):
			GameSettings.set_volume(bus, value)
			_update_volume_label(bus, value)
		)
		_audio_controls.add_child(row)


func _update_volume_label(bus: String, value: float) -> void:
	var label: Label = _volume_labels.get(bus)
	if label != null:
		label.text = "%d%%" % roundi(value * 100.0)


func _build_keybind_controls() -> void:
	for action in GameSettings.KEYBIND_LABELS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		var label := Label.new()
		label.text = GameSettings.KEYBIND_LABELS[action]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(190, 34)
		button.text = GameSettings.binding_text(action)
		button.pressed.connect(_begin_binding.bind(action))
		row.add_child(button)
		_binding_buttons[action] = button
		_keybind_list.add_child(row)


func _begin_binding(action: String) -> void:
	_pending_action = action
	_settings_hint.text = "Press a key for %s (Esc goes back)." % GameSettings.KEYBIND_LABELS[action]
	_binding_buttons[action].text = "Press a key..."


func _finish_binding() -> void:
	var changed_action := _pending_action
	_pending_action = ""
	_refresh_binding(changed_action)
	_refresh_control_hints()
	_settings_hint.text = "Binding saved. Select another control or go back."


func _refresh_binding(action: String) -> void:
	_binding_buttons[action].text = GameSettings.binding_text(action)


func _reset_bindings() -> void:
	_pending_action = ""
	GameSettings.reset_bindings()
	for action in _binding_buttons:
		_refresh_binding(action)
	_refresh_control_hints()
	_settings_hint.text = "Keyboard bindings restored to defaults."


func _refresh_control_hints() -> void:
	_menu_footer.text = "%s/%s/%s/%s move  ·  %s dash  ·  %s cast" % [
		GameSettings.binding_text("move_up"),
		GameSettings.binding_text("move_left"),
		GameSettings.binding_text("move_down"),
		GameSettings.binding_text("move_right"),
		GameSettings.binding_text("dash"),
		GameSettings.binding_text("cast_modifier"),
	]


func _style_buttons() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.07, 0.095, 0.98)
	panel_style.border_color = Color(0.28, 0.26, 0.33, 1.0)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	$SettingsContent/Center/Panel.add_theme_stylebox_override("panel", panel_style)
	for button in find_children("*", "Button", true, false):
		button.add_theme_font_size_override("font_size", 18)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.16, 0.15, 0.20, 1.0)
		normal.border_color = Color(0.38, 0.35, 0.45, 1.0)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(8)
		normal.content_margin_left = 16
		normal.content_margin_right = 16
		normal.content_margin_top = 10
		normal.content_margin_bottom = 10
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.25, 0.23, 0.31, 1.0)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
