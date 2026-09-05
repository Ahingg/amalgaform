class_name Helper
extends RefCounted

# Geometri murni: tidak tahu apa-apa soal api, musuh, atau spell.
static func overlap(pos_a: Vec2, size_a: Size, pos_b: Vec2, size_b: Size) -> bool:
	return pos_a.x < pos_b.x + size_b.w \
		and pos_b.x < pos_a.x + size_a.w \
		and pos_a.y < pos_b.y + size_b.h \
		and pos_b.y < pos_a.y + size_a.h
