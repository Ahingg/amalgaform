extends Node

# Bootstrap. Owns the World and hands it to the systems every physics tick.
# The World lives here — not inside SystemManager — because "start the round
# over" belongs to whoever owns the session, and because view/ needs to read
# the World to draw it.

var world: World

# Attempts belong to the session, not to the round — so this is the one piece of
# state that deliberately survives build_round(). Everything else is thrown away
# with the World.
var attempt: int = 1

func _ready() -> void:
	build_round()

	# View layer. Added from code to keep the scene file simple.
	# renderer.gd only READS world, it never writes into sim/.
	add_child(WorldRenderer.new())


func retry() -> void:
	attempt += 1
	build_round()


# Everything that describes one attempt at the room lives here. Retrying is
# literally this function again: throw the World away, build a new one. No
# cleanup, no reset pass — nothing in sim/ ever kept state outside the World.
func build_round() -> void:
	world = World.new()
	Spawn.round(world)
		
	Spawn.player(world, 2.0, 2.0, 200)
	Spawn.enemy(world, 0.5, 0.5, 100)


func _physics_process(delta: float) -> void:
	SystemManager.process(world, delta)
