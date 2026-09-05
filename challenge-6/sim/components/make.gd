
class_name Make
extends RefCounted


	
# bentuknya adalah component_name: {body}
static func recipe(body: Dictionary) -> Dictionary:
	return body


static func lifetime(duration: float) -> Dictionary:
	return {"elapsed": 0.0, "duration": duration, "on_expire": {Comp.DEAD: {}}}
		

static func interval(duration: float) -> Dictionary:
	return {"duration": duration}

static func fire(damage: float) -> Dictionary:
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
	return {"runes": []}

static func time_scale() -> Dictionary:
	return {"value": 1.0}
	
static func on_hit(on_self: Dictionary, on_target: Dictionary) -> Dictionary:
	return {"self": on_self, "target": on_target}
	
static func damage(amount: float) -> Dictionary:
	return {"amount": amount}

static func wet(duration: float, slow: float) -> Dictionary:
	return {"duration": duration, "slow": slow}

static func knocked(duration: float, strength: float) -> Dictionary:
	return {"duration": duration, "strength": strength}
	
static func held_spell(spell: Dictionary, runes: Array) -> Dictionary:
	return {"runes": runes, "recipe": spell}
	
static func melee(on_hit: Dictionary) -> Dictionary:
	return {Comp.ON_HIT: on_hit}
