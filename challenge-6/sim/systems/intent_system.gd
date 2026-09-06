class_name IntentSystem
extends RefCounted

# Ngubah KEMAUAN jadi kecepatan. Ga ngunci diri ke Player, apapun yang punya
# MoveIntent + Velocity + Speed bakal digerakin. Musuh ikut kelayanan gratis.
#
# Pake assignment (bukan +=) biar ini jadi titik nol tiap frame. Gaya luar kayak
# knockback numpuk DIATASNYA, di system yang jalan setelah ini.

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp(
		[Comp.VELOCITY, Comp.MOVE_INTENT, Comp.SPEED, Comp.FACING])

	for e in entities:
		var intent: Vec2 = world.get_component_value(Comp.MOVE_INTENT, e)
		var speed: Speed = world.get_component_value(Comp.SPEED, e)
		var face: Vec2 = world.get_component_value(Comp.FACING, e)
		var v: Vec2 = world.get_component_value(Comp.VELOCITY, e)

		# TODO: ceili(-0.7) = 0, jadi arah negatif ilang. Trus baris ini nimpa
		# Facing yang ditulis mouse tiap frame, jadi rebutan.
		face.x = intent.x
		face.y = intent.y

		v.x = intent.x * speed.value
		v.y = intent.y * speed.value
