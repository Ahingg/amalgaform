extends SceneTree

# Alat periksa, bukan bagian permainan. Bangun dunia kecil dengan pemain di
# posisi yang KITA tentukan, lempar satu Ventus ke delapan arah, lalu cetak
# ke mana pusat ledakannya mendarat relatif ke pusat pemain.
#
#   godot --headless --script res://tools/probe_launch.gd
#
# Yang benar: kolom "relatif" harus SEARAH dengan kolom "facing", dan
# panjangnya sama untuk kedelapan arah.

func _initialize() -> void:
	var dirs := [
		Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
		Vector2(0.707, 0.707), Vector2(-0.707, 0.707),
		Vector2(0.707, -0.707), Vector2(-0.707, -0.707),
	]
	print("facing            pojok spell        pusat spell        relatif ke pusat pemain")
	for d in dirs:
		var world := World.new()
		var p := Spawn.player(world, 5.0, 5.0, 200)
		var f: Vec2 = world.get_component_value(Comp.FACING, p)
		f.x = d.x
		f.y = d.y

		var recipe: Dictionary = Grammar.build([Comp.VENTUS])
		world.attach_component(Comp.HELD_SPELL, p, Make.held_spell(recipe, [Comp.VENTUS]))
		world.attach_component(Comp.LAUNCH_SPELL, p, {})
		SpellLaunchSystem.process(world, 0.016)

		var caster: Vec2 = world.get_component_value(Comp.POSITION, p)
		var csize: Size = world.get_component_value(Comp.SIZE, p)
		var pc: Vec2 = Helper.center(caster, csize)

		for e in world.get_entities_with_comp([Comp.POSITION, Comp.SIZE, Comp.RUNES]):
			var sp: Vec2 = world.get_component_value(Comp.POSITION, e)
			var ss: Size = world.get_component_value(Comp.SIZE, e)
			var sc: Vec2 = Helper.center(sp, ss)
			print("(%5.2f,%5.2f)   (%6.2f,%6.2f)   (%6.2f,%6.2f)   (%6.2f,%6.2f)" % [
				d.x, d.y, sp.x, sp.y, sc.x, sc.y, sc.x - pc.x, sc.y - pc.y])
	quit()
