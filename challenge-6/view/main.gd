extends Node


# Called when the node enters the scene tree for the first time.
var world: World
func _ready() -> void:
	world = World.new()
	var e1 = world.add_entity()
	var e2 = world.add_entity()
	var e3 = world.add_entity()
	
	world.attach_component(Comp.FIRE, e1, Make.fire(10.0));
	world.attach_component(Comp.WATER, e1)
	world.attach_component(Comp.WIND, e1)
	
	world.attach_component(Comp.FIRE, e2, Make.fire(20.0))
	world.attach_component(Comp.WIND, e2)
	
	world.attach_component(Comp.WIND, e3)
	world.attach_component(Comp.WATER, e3)
	
	world.attach_component(Comp.DELAY, e1, Make.delay(2.0))
	world.attach_component(Comp.DELAY, e2, Make.delay(3.0))
	
	#var result: Dictionary =  world.get_component_value(Comp.FIRE, e1)
	#for key in result:
		#print(str(key) + " " + str(result[key]))
	#var result := world.get_entities_with_comp([Comp.WIND, Comp.FIRE, Comp.WATER])
	#for r in result:
		#print(r)
		
	#world.detach_component(Comp.WIND, e1);
	#print(world.entity_have_component(Comp.WIND, e1))


	# Lapisan tampilan. Ditambahkan dari kode biar scene-nya tetap sederhana.
	# renderer.gd cuma BACA world, gak pernah nulis apa pun ke sim/.
	add_child(WorldRenderer.new())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# panggil middle.process untuk process setiap system yang ada.
	SystemManager.process(world, delta)
