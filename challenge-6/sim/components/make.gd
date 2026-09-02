
class_name Make
extends RefCounted

static func delay(duration: float) -> Dictionary:
	return {"elapsed": 0.0, "duration": duration}

static func fire(damage: float) -> Dictionary:
	return {"triggered": 0,"damage": damage}
	
	
static func position(x: float, y: float) -> Dictionary: 
	return {"x": x, "y": y}
	
static func velocity(speed_x: float, speed_y: float) -> Dictionary:
	return {"x": speed_x, "y": speed_y} 
