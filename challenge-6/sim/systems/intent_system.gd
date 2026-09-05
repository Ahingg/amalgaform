class_name IntentSystem
extends RefCounted

# Mengubah KEMAUAN jadi kecepatan. Tidak mengunci diri ke Player: apa pun yang
# punya MoveIntent + Velocity + Speed akan digerakkan, jadi musuh ikut terlayani
# tanpa satu baris pun tambahan.
#
# Assignment (bukan +=) supaya ini jadi titik nol tiap frame. Gaya luar seperti
# knockback menumpuk DI ATASNYA, di system yang jalan setelah ini.
static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp(
		[Comp.VELOCITY, Comp.MOVE_INTENT, Comp.SPEED, Comp.FACING])

	for e in entities:
		var intent: Vec2 = world.get_component_value(Comp.MOVE_INTENT, e)
		var speed: Speed = world.get_component_value(Comp.SPEED, e)
		var face: Vec2 = world.get_component_value(Comp.FACING, e)
		var v: Vec2 = world.get_component_value(Comp.VELOCITY, e)

		# CATATAN (belum diubah, ini logika milik Xaviero):
		# ceili(-0.7) = 0, jadi arah negatif hilang. Dan baris ini menimpa Facing
		# yang ditulis mouse tiap frame, jadi keduanya saling rebutan.
		face.x = ceili(intent.x)
		face.y = ceili(intent.y)

		v.x = intent.x * speed.value
		v.y = intent.y * speed.value
