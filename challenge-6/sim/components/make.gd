
class_name Make
extends RefCounted

	
# bentuknya adalah component_name: {body}
static func recipe(body: Dictionary) -> Dictionary:
	return body

static func delay(duration: float) -> Dictionary:
	return {"elapsed": 0.0, "duration": duration}

static func lifetime(duration: float) -> Dictionary:
	return {"elapsed": 0.0, "duration": duration, "on_expire": {Comp.DEAD: {}}}
		
static func invulnerable(duration: float) -> Dictionary:
	return {"elapsed": 0.0, "duration": duration}

static func interval(duration: float) -> Dictionary:
	return {"duration": duration}

static func fire(damage: float) -> Dictionary:
	return {"damage": damage}
	
static func burn(damage: float) -> Dictionary:
	return {"damage": damage}
	
static func damaged(damage: float) -> Dictionary:
	return {"damage": damage}
	
static func position(x: float, y: float) -> Dictionary: 
	return {"x": x, "y": y}
	
static func velocity(speed_x: float, speed_y: float) -> Dictionary:
	return {"x": speed_x, "y": speed_y}
	
static func speed(num: float) -> Dictionary:
	return {"value": num}
	
static func size(width: float, height: float) -> Dictionary:
	return {"w": width, "h": height} 

static func health(amount: int) -> Dictionary:
	return {"current": amount, "max": amount};
	
static func move_intent(x: float, y: float) -> Dictionary:
	return {"x": x, "y": y}
	
static func facing(x: float, y: float) -> Dictionary:
	return {"x": x, "y": y}
	
static func cast_queue() -> Dictionary:
	return {"runes": [], "open": false, "open_time": 0.0}
	
static func cast_release() -> Dictionary: 
	return {}

static func time_scale() -> Dictionary:
	return {"value": 1.0}
