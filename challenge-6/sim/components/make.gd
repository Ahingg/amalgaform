
class_name Make
extends RefCounted

static func delay(duration: float) -> Dictionary:
	return {"elapsed": 0.0, "duration": duration}

static func fire(damage: float) -> Dictionary:
	return {"triggered": 0,"damage": damage}
