class_name Grammar 
extends RefCounted

static var FORM= {
	Comp.IGNIS : {
		Comp.POSITION: Make.position(0.0, 0.0), 
		Comp.SIZE: Make.size(Tuning.BULLET_SIZE, Tuning.BULLET_SIZE), 
		Comp.VELOCITY: Make.velocity(0.0, 0.0),
		Comp.LIFETIME: Make.lifetime(Tuning.BULLET_LIFETIME),
		Comp.ON_HIT: Make.on_hit({Comp.DEAD: {}})
	},
	Comp.AQUA : {
		Comp.POSITION: Make.position(0.0, 0.0), 
		Comp.SIZE: Make.size(Tuning.WATERBALL_SIZE, Tuning.WATERBALL_SIZE), 
		Comp.VELOCITY: Make.velocity(0.0, 0.0),
		Comp.LIFETIME: Make.lifetime(Tuning.WATERBALL_LIFETIME),
		Comp.ON_HIT: Make.on_hit({Comp.BURST: {}})
	}, 
	Comp.VENTUS : {
		Comp.POSITION: Make.position(0.0, 0.0), 
		Comp.SIZE: Make.size(Tuning.BURST_SIZE, Tuning.BURST_SIZE), 
		Comp.LIFETIME: Make.lifetime(Tuning.BURST_LIFETIME),
	}
}

static var PAYLOAD := {
	Comp.IGNIS: { 
		Comp.DAMAGE: Make.damage(Tuning.FIRE_DAMAGE),
	},
	Comp.AQUA : {
		Comp.WET: Make.wet(Tuning.WET_DURATION, Tuning.WET_SPEED_MULT)
	},
	Comp.VENTUS : {
		Comp.KNOCKED: 
	}
}
