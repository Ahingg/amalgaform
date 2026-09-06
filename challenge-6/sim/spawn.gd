class_name Spawn
extends RefCounted

# ============================================================================
# ARCHETYPES — shortcuts for entity shapes that get built often.
#
# These are NOT types. After a spawn function returns, nothing anywhere records
# that an entity is "an enemy": there is only an entity with some components,
# and no system ever asks what kind of thing it is. The function assembles and
# disappears.
#
# Three rules that keep it that way:
#   1. Assembly only. add_entity + attach_component, nothing else. The moment an
#      `if` decides behaviour in here, it has become a system in the wrong place.
#   2. Never the only way to build an entity. Attaching components by hand must
#      stay easy — these are shortcuts for common shapes, not an official list
#      of what is allowed to exist.
#   3. No derived factories. If enemy / fast_enemy / armored_enemy /
#      fast_armored_enemy ever appear, that is the inheritance explosion coming
#      back in through the factory door. Give the base shape here and stack the
#      extras on top at the call site:
#
#          var e := Spawn.enemy(world, 0, 3, 100)
#          world.attach_component(Comp.ARMOR, e, Make.armor(5))
# ============================================================================


static func enemy(
	world: World,
	x: float, y: float,
	hp: int,
	speed: float = Tuning.ENEMY_SPEED,
	w: float = 1.0, h: float = 1.0
) -> int:
	var e := world.add_entity()
	world.attach_component(Comp.ENEMY, e)
	world.attach_component(Comp.FACING, e, Vec2.new(1.0, 0))
	world.attach_component(Comp.MELEE, e, Make.melee(Make.on_hit({}, {Comp.DAMAGED: Damaged.new(Tuning.MELEE_DAMAGE)})))
	world.attach_component(Comp.POSITION, e, Vec2.new(x, y))
	world.attach_component(Comp.SIZE, e, Size.new(w, h))
	world.attach_component(Comp.VELOCITY, e, Vec2.new(0.0, 0.0))
	world.attach_component(Comp.HEALTH, e, Health.new(hp))
	world.attach_component(Comp.MOVE_INTENT, e, Vec2.new(0.0, 0.0))
	world.attach_component(Comp.SPEED, e, Speed.new(speed))
	world.attach_component(Comp.CHASE, e)
	return e

static func player(world: World,
	x: float, y: float,
	hp: int, 
	speed: float = Tuning.PLAYER_SPEED,
	w: float = 1.0, h: float = 1.0,
) -> int:
	var e := world.add_entity()
	world.attach_component(Comp.PLAYER, e)
	world.attach_component(Comp.BOUNDED, e)
	world.attach_component(Comp.POSITION, e, Vec2.new(x, y))
	world.attach_component(Comp.SIZE, e, Size.new(w, h))
	world.attach_component(Comp.HEALTH, e, Health.new(hp))
	world.attach_component(Comp.VELOCITY, e, Vec2.new(0.0, 0.0))
	world.attach_component(Comp.SPEED, e, Speed.new(speed))
	world.attach_component(Comp.CAST_QUEUE, e, Make.cast_queue())
	world.attach_component(Comp.FACING, e, Vec2.new(0.0, 1.0))
	return e
	

static func round(world: World) -> int:
	var e := world.add_entity()
	world.attach_component(Comp.ROUND, e)
	world.attach_component(Comp.ROUND_WAVE, e, Scalar.new(1))
	world.attach_component(Comp.RUN_TIME, e, Scalar.new(0.0))
	world.attach_component(Comp.TIME_SCALE, e, Scalar.new(1.0))
	return e 
