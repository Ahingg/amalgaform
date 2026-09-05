class_name Inflict
extends RefCounted

# Satu-satunya tempat isi OnHit dibongkar dan ditempel. Dipakai bersama oleh
# ContactSystem dan MeleeSystem — keduanya cuma berbeda di SIAPA yang menyentuh
# siapa, bukan di apa yang terjadi setelahnya.
#
# clone() wajib: satu ledakan bisa mengenai beberapa target dalam satu frame,
# dan tanpa salinan mereka akan berbagi satu komponen — timer Wet-nya akan
# jalan berkali lipat, diam-diam.
static func apply(world: World, action: Dictionary, source: int, target: int,
		pos_s: Vec2, pos_t: Vec2) -> void:
	for comp in action["self"]:
		world.attach_component(comp, source, _copy(action["self"][comp]))

	for comp in action["target"]:
		var body: Variant = _copy(action["target"][comp])
		# Arah dorongan hanya diketahui di sini: Grammar cuma tahu seberapa
		# kuat, system kontak yang tahu dari mana ke mana.
		if body is Knocked:
			var dir := Vector2(pos_t.x - pos_s.x, pos_t.y - pos_s.y).normalized()
			body.x = dir.x
			body.y = dir.y
		world.attach_component(comp, target, body)


static func _copy(body: Variant) -> Variant:
	if body is Component:
		return body.clone()
	if body is Dictionary:
		return body.duplicate(true)
	return body
