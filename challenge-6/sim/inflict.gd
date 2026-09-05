class_name Inflict
extends RefCounted

# Org yang punya inflict itu kerjaannya bakal handle onhit dan bongkar onhitnya 
#
# wajib pake clone biar referenceenya ga sama
static func apply(world: World, action: Dictionary, source: int, target: int,
		pos_s: Vec2, pos_t: Vec2) -> void:
	for comp in action["self"]:
		world.attach_component(comp, source, _copy(action["self"][comp]))
	
	action["self"] = {}
	for comp in action["target"]:
		if world.entity_have_component(comp, target):
			continue
		var body: Variant = _copy(action["target"][comp])
		# arah dorongan kalo knocked
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
