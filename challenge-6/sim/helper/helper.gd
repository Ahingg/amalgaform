class_name Helper
extends RefCounted

static func overlap(pos_a: Dictionary, size_a: Dictionary, pos_b: Dictionary, size_b: Dictionary) -> bool:
	return pos_a["x"] < pos_b["x"] + size_b["w"] and pos_b["x"] < pos_a["x"] + size_a["w"] and pos_a["y"] < pos_b["y"] + size_b["h"] and pos_b["y"] < pos_a["y"] + size_a["h"]
