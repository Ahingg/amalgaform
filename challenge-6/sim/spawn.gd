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
	world.attach_component(Comp.POSITION, e, Make.position(x, y))
	world.attach_component(Comp.SIZE, e, Make.size(w, h))
	world.attach_component(Comp.VELOCITY, e, Make.velocity(0.0, 0.0))
	world.attach_component(Comp.HEALTH, e, Make.health(hp))
	world.attach_component(Comp.MOVE_INTENT, e, Make.move_intent(0.0, 0.0))
	world.attach_component(Comp.SPEED, e, Make.speed(speed))
	#world.attach_component(Comp.CHASE, e)
	return e


static func machine(
	world: World,
	x: float, y: float,
	interval: float,
	recipe: Dictionary,
	w: float = 1.0, h: float = 1.0
) -> int:
	var m := world.add_entity()
	world.attach_component(Comp.MACHINE, m)
	world.attach_component(Comp.POSITION, m, Make.position(x, y))
	world.attach_component(Comp.SIZE, m, Make.size(w, h))
	world.attach_component(Comp.INTERVAL, m, Make.interval(interval))
	world.attach_component(Comp.DELAY, m, Make.delay(interval))
	world.attach_component(Comp.RECIPE, m, Make.recipe(recipe))
	return m

static func player(world: World,
	x: float, y: float,
	hp: int, 
	speed: float = Tuning.PLAYER_SPEED,
	w: float = 1.0, h: float = 1.0,
) -> int:
	var e := world.add_entity()
	world.attach_component(Comp.PLAYER, e)
	world.attach_component(Comp.POSITION, e, Make.position(x, y))
	world.attach_component(Comp.SIZE, e, Make.size(w, h))
	world.attach_component(Comp.HEALTH, e, Make.health(hp))
	world.attach_component(Comp.VELOCITY, e, Make.velocity(0.0, 0.0))
	world.attach_component(Comp.SPEED, e, Make.speed(speed))
	world.attach_component(Comp.CAST_QUEUE, e, Make.cast_queue())
	world.attach_component(Comp.FACING, e, Make.facing(0.0, 1.0))
	return e

static func round(world: World) -> int:
	var e := world.add_entity()
	world.attach_component(Comp.ROUND, e)
	world.attach_component(Comp.TIME_SCALE, e, Make.time_scale())
	return e 
