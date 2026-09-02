extends Node


# Called when the node enters the scene tree for the first time.
var world: World
func _ready() -> void:
	world = World.new()
	var e1 = world.add_entity()
	var e2 = world.add_entity()
	var e3 = world.add_entity()
	
	#world.attach_component(Comp.DELAY, e1, Make.delay(2.0))
	world.attach_component(Comp.POSITION, e1, Make.position(0.5, 0.5))
	world.attach_component(Comp.VELOCITY, e1, Make.velocity(1.0, 0))
	world.attach_component(Comp.SIZE, e1, Make.size(1.0, 1.0))
	world.attach_component(Comp.HEALTH, e1, Make.health(100))
	
	world.attach_component(Comp.POSITION, e2, Make.position(5.0, 0))
	world.attach_component(Comp.SIZE, e2, Make.size(2, 1))
	world.attach_component(Comp.FIRE, e2, Make.fire(10.0))
	
	world.attach_component(Comp.WIND, e3)
	world.attach_component(Comp.WATER, e3)
	
	
	#var result: Dictionary =  world.get_component_value(Comp.FIRE, e1)
	#for key in result:
		#print(str(key) + " " + str(result[key]))
	#var result := world.get_entities_with_comp([Comp.WIND, Comp.FIRE, Comp.WATER])
	#for r in result:
		#print(r)
		
	#world.detach_component(Comp.WIND, e1);
	#print(world.entity_have_component(Comp.WIND, e1))


	# View layer. Added from code to keep the scene file simple.
	# renderer.gd only READS world, it never writes into sim/.
	add_child(WorldRenderer.new())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# panggil middle.process untuk process setiap system yang ada.
	SystemManager.process(world, delta)
