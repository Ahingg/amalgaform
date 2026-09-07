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
	_draw_wave(world)

	# Menang dan kalah dua-duanya dibaca dari keadaan dunia, bukan dari flag yang
	# disimpan di sini. Kalah = tidak ada entity ber-Player. Menang = entity
	# ronde punya Won. Tidak ada yang perlu diberi tahu, dan tidak ada yang perlu
	# dibersihkan waktu mulai lagi.
	var round_q: Array[String] = [ViewConfig.ROUND, ViewConfig.WON]
	if not world.get_entities_with_comp(round_q).is_empty():
		_draw_ended(world, "MENANG", Color(0.55, 0.92, 0.55))
		return

	var player_q: Array[String] = [ViewConfig.PLAYER]
	if world.get_entities_with_comp(player_q).is_empty():
		_draw_ended(world, "KALAH", Color(1.0, 0.42, 0.35))


func _draw_attempt(attempt: int) -> void:
	draw_string(_font, Vector2(48, 34), "Percobaan %d" % attempt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WorldRenderer.INK * Color(1,1,1,0.65))


# Nomor gelombang plus berapa musuh yang masih hidup. Tanpa ini pemain tidak
# punya cara tahu dia sudah sejauh apa, dan gelombang terakhir terasa sama saja
# dengan gelombang pertama.
func _draw_wave(world) -> void:
	var round_q: Array[String] = [ViewConfig.ROUND, ViewConfig.ROUND_WAVE]
	var rounds: Array[int] = world.get_entities_with_comp(round_q)
	if rounds.is_empty():
		return
	var wave = world.get_component_value(ViewConfig.ROUND_WAVE, rounds[0])

	var enemy_q: Array[String] = [ViewConfig.ENEMY]
	var alive: int = world.get_entities_with_comp(enemy_q).size()

	var shown: int = mini(int(wave.value), Tuning.WAVE_COUNT)
	var line := "Gelombang %d / %d   ·   musuh %d" % [shown, Tuning.WAVE_COUNT, alive]

	# Waktu lari ditampilkan bareng gelombang supaya efisiensi jadi angka, bukan
	# cuma perasaan. Digabung dengan penghitung percobaan, pemain bisa melihat
	# dirinya membaik: percobaan ke-12 tapi waktunya separuh percobaan ke-3.
	if world.entity_have_component(ViewConfig.RUN_TIME, rounds[0]):
		var rt = world.get_component_value(ViewConfig.RUN_TIME, rounds[0])
		line += "   ·   %.1fs" % rt.value

	draw_string(_font, Vector2(210, 34), line,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WorldRenderer.INK * Color(1,1,1,0.65))


func _draw_ended(world, text: String, color: Color) -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.09, 0.12, 0.86), true)

	var center := size * 0.5
	draw_string(_font, center + Vector2(-150, -20), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 72, color)

	var round_q: Array[String] = [ViewConfig.ROUND, ViewConfig.RUN_TIME]
	var rounds: Array[int] = world.get_entities_with_comp(round_q)
	if not rounds.is_empty():
		var rt = world.get_component_value(ViewConfig.RUN_TIME, rounds[0])
		draw_string(_font, center + Vector2(-150, 22), "Waktu %.1f detik" % rt.value,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, WorldRenderer.INK * Color(1,1,1,0.9))

	draw_string(_font, center + Vector2(-150, 56), "Tekan R untuk mengulang",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, WorldRenderer.INK * Color(1,1,1,0.7))
