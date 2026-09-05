class_name SpellLaunchSystem
extends RefCounted

static func process(world: World, _delta: float) -> void:
	var entities := world.get_entities_with_comp([Comp.LAUNCH_SPELL, Comp.HELD_SPELL, Comp.POSITION, Comp.FACING])
	for e in entities:
		# cek origin dan velocity, karena masing masing itu memiliki sifat yang relatif.
		# sehingga kita perlu secara eksplisit ngecek apakah ada velocity yang 
		var facing: Dictionary = world.get_component_value(Comp.FACING, e)
		var origin: Dictionary = world.get_component_value(Comp.POSITION, e).duplicate(true)
		origin["x"] += facing["x"] * Tuning.SPAWN_OFFSET
		origin["y"] += facing["y"] * Tuning.SPAWN_OFFSET
		
		# entity yang bakal di release dari spell yang udah ada di tangan
		var to_be := world.add_entity()
		
		# untuk dapetin recipenya
		# ingat, recipenya held spell itu megang form dari grammar as key key
		# dan di akhir key key tersebut ada action untuk menentukan bakal ngapain aja, yang udah ditempelin dengan data data dari hasil perhitungan
		
		# Position yang diberikan dalam FORM itu cuma place holder, jangan lupa di ganti dengan origin
		# Kalau ada velocity, set dengan direction dan kecepatan wujud
		var held_spell: Dictionary = world.get_component_value(Comp.HELD_SPELL, e)
		var recipe: Dictionary = held_spell["recipe"].duplicate(true)
		
		if recipe.has(Comp.POSITION):
			#print(str(origin["x"]) + " " + str(origin["y"]))
			recipe[Comp.POSITION] = origin
			#print(str(recipe[Comp.POSITION]))
		if recipe.has(Comp.SPEED):
			var s: float = recipe[Comp.SPEED]["value"]
			recipe[Comp.VELOCITY] = Make.velocity(facing["x"]*s, facing["y"]*s)
			
		# world.attach dibawah karena kalau misalnya diatas, dia bakal set addressnya sama dengan yang recipe[comp]
		# sehingga nanti waktu recipe[Comp.POSITION] diubah ke origin, reference mereka jadi pecah.
		for comp in recipe: 
			world.attach_component(comp, to_be, recipe[comp])
		
			
		# detach
		world.detach_component(Comp.LAUNCH_SPELL, e)
		world.detach_component(Comp.HELD_SPELL, e)
	
