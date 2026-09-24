class_name MenuUI
extends Control

# ============================================================================
# LAYAR DI LUAR RONDE — judul dan jeda
#
# Dua-duanya di satu berkas karena mereka satu hal yang sama: lapisan yang
# muncul saat ronde TIDAK sedang berjalan. Keduanya membaca `mode` dari main,
# menggambar tirai di atas arena, dan menunggu satu tombol.
#
# Berkas ini tidak menyentuh World sama sekali. Menjeda permainan di sini cuma
# berarti mengubah satu nilai di main, dan main berhenti memanggil
# SystemManager. Tidak ada system yang tahu, tidak ada yang perlu dibereskan.
# ============================================================================

const KEY_MULAI := [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
const KEY_JEDA := [KEY_ESCAPE, KEY_P]

@onready var _backdrop: ColorRect = $Backdrop
@onready var _menu_content: Control = $MenuContent
@onready var _pause_content: Control = $PauseContent
@onready var _start_prompt: Label = $MenuContent/StartPrompt


func _ready() -> void:
	# A CanvasLayer keeps this screen-space UI independent of the world camera.
	z_index = 35


func _process(_delta: float) -> void:
	var main = _main()
	if main == null:
		return

	var on_menu: bool = main.is_menu()
	var paused: bool = main.mode == main.Mode.PAUSED
	visible = on_menu or paused
	_menu_content.visible = on_menu
	_pause_content.visible = paused
	_backdrop.color = Color(0.05, 0.045, 0.065, 0.93 if on_menu else 0.55)
	_start_prompt.modulate.a = 0.55 + 0.45 * sin(float(Time.get_ticks_msec()) / 1000.0 * 2.6)


func _main():
	var r := get_parent()
	return null if r == null else r.get_parent()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var main = _main()
	if main == null:
		return

	if main.is_menu():
		if event.keycode in KEY_MULAI:
			main.start()
			get_viewport().set_input_as_handled()
		return

	if not event.keycode in KEY_JEDA:
		return

	# ESC punya dua arti, dan aturannya satu: mundur dari apa pun yang sedang
	# kamu masuki. Kalau antrian rune sedang terbuka, ESC membatalkan rapalan —
	# itu sudah ditangani CastUI, jadi di sini dia harus dibiarkan lewat.
	# Kalau tidak sedang merapal, yang sedang dimasuki adalah permainannya.
	if event.keycode == KEY_ESCAPE and _sedang_merapal(main):
		return

	main.toggle_pause()
	get_viewport().set_input_as_handled()


func _sedang_merapal(main) -> bool:
	var world = main.get("world")
	if world == null:
		return false
	var q: Array[String] = [ViewConfig.CAST_QUEUE]
	for e in world.get_entities_with_comp(q):
		var antrian: Dictionary = world.get_component_value(ViewConfig.CAST_QUEUE, e)
		if antrian.get("open", false):
			return true
	return false
