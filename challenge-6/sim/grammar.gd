class_name Grammar 
extends RefCounted

static var FORM= {
	Comp.IGNIS : {
		Comp.POSITION: Make.position(0.0, 0.0), 
		Comp.SIZE: Make.size(Tuning.BULLET_SIZE, Tuning.BULLET_SIZE), 
		Comp.SPEED: Make.speed(Tuning.BULLET_SPEED),
		Comp.LIFETIME: Make.lifetime(Tuning.BULLET_LIFETIME),
		Comp.ON_HIT: Make.on_hit({Comp.DEAD: {}}, {})
	},
	Comp.AQUA : {
		Comp.POSITION: Make.position(0.0, 0.0), 
		Comp.SIZE: Make.size(Tuning.WATERBALL_SIZE, Tuning.WATERBALL_SIZE), 
		Comp.SPEED: Make.speed(Tuning.WATERBALL_SPEED),
		Comp.LIFETIME: Make.lifetime(Tuning.WATERBALL_LIFETIME),
		Comp.ON_HIT: Make.on_hit({}, {Comp.BURST: {}})
	}, 
	Comp.VENTUS : {
		Comp.POSITION: Make.position(0.0, 0.0), 
		Comp.SIZE: Make.size(Tuning.BURST_SIZE, Tuning.BURST_SIZE), 
		Comp.LIFETIME: Make.lifetime(Tuning.BURST_LIFETIME),
	}
}



static var PAYLOAD := {
	Comp.IGNIS: func(p: float) -> Dictionary:
			return Make.on_hit({}, {Comp.DAMAGED: Make.damaged(Tuning.FIRE_DAMAGE * p)}),
	Comp.AQUA : func(p: float) -> Dictionary:
			return Make.on_hit({}, {Comp.WET: Make.wet(Tuning.WET_DURATION, Tuning.WET_SLOW*p)}),
	Comp.VENTUS : func(p: float) -> Dictionary:
			return Make.on_hit({}, {Comp.KNOCKED: Make.knocked(Tuning.KNOCKBACK_DURATION, Tuning.KNOCKBACK_STRENGTH*p)}),
}

static func build(runes: Array) -> Dictionary:
	var rune_presence: Dictionary
	var unique: int = 0
	for r in runes:
		if not rune_presence.has(r):
			rune_presence[r] = 1
			unique += 1
			continue
		
		rune_presence[r] += 1
	
	var recipe: Dictionary = Grammar.FORM[runes[0]].duplicate(true)
	print(recipe)
	var on_self: Dictionary = recipe.get(Comp.ON_HIT, {}).get("self", {})
	var on_target: Dictionary = recipe.get(Comp.ON_HIT, {}).get("target", {})
	print("before")
	print(on_self)
	print(on_target)
	# gabungin on hit yang ada di actionnya for both on self, on target
	for r in rune_presence:
		var power: float = rune_presence[r] / pow(unique, Tuning.SPREAD)
		# setiap produced bakal punya on self sama on target juga, yang harus ditambahin ke on self dan on target diatas
		var produced: Dictionary = Grammar.PAYLOAD[r].call(power)
		print(produced)
		if not (produced.has("self") and produced.has("target")):
			continue
		
		for comp in produced["self"]:
			if on_self.has(comp):
				for k in produced["self"][comp]:
					on_self[comp][k] += produced["self"][comp][k]
			else:
				on_self[comp] = produced[comp]
		for comp in produced["target"]:
			if on_target.has(comp):
				for k in produced["target"][comp]:
					on_target[comp][k] += produced[comp][k]
			else:
				on_target[comp] = produced["target"][comp]
			
			
		print("after")
		print(on_self)
		print(on_target)
	recipe[Comp.ON_HIT] = Make.on_hit(on_self, on_target)
	#print(recipe)
	return recipe
