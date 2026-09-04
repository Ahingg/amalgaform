extends Node

# Bootstrap. Owns the World and hands it to the systems every physics tick.
# The World lives here — not inside SystemManager — because "start the round
# over" belongs to whoever owns the session, and because view/ needs to read
# the World to draw it.

var world: World

func _ready() -> void:
	build_round()

	# View layer. Added from code to keep the scene file simple.
	# renderer.gd only READS world, it never writes into sim/.
	add_child(WorldRenderer.new())


# Everything that describes one attempt at the room lives here. Retry is going
# to be: throw the World away, call this again.
func build_round() -> void:
	world = World.new()
	Spawn.round(world)
		
	Spawn.player(world, 2.0, 2.0, 200)
	Spawn.enemy(world, 0.5, 0.5, 100)
#
	Spawn.machine(world, 3.0, 0.0, 2.0, {
		Comp.FIRE: Make.fire(5),
		Comp.POSITION: Make.position(3.0, 0.0)	,   # relative to the machine
		Comp.SIZE: Make.size(2.0, 1.0),
		Comp.LIFETIME: Make.lifetime(1.5),
	})


func _physics_process(delta: float) -> void:
	SystemManager.process(world, delta)
