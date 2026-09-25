extends SceneTree

# Alat periksa, bukan bagian permainan. Bangun dunia kecil dengan pemain di
# posisi yang KITA tentukan, lempar satu Ventus ke delapan arah, lalu periksa
# pusat dan hit area cone terhadap arah hadap pemain.
#
#   godot --headless --script res://tools/probe_launch.gd
#
# Yang benar: cone mengarah ke facing, mengenai target di depan, dan tidak
# mengenai target pada jarak sama di belakang.

func _initialize() -> void:
	var dirs := [
		Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
		Vector2(0.707, 0.707), Vector2(-0.707, 0.707),
		Vector2(0.707, -0.707), Vector2(-0.707, -0.707),
	]
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

		var spells := world.get_entities_with_comp([Comp.CONE, Comp.RUNES])
		if spells.size() != 1:
			push_error("Expected one wind cone for facing %s" % d)
			quit(1)
			return
		var cone: Cone = world.get_component_value(Comp.CONE, spells[0])
		var vertices := Helper.cone_vertices(cone)
		var center_of_far_edge := (vertices[1] + vertices[2]) * 0.5
		var player_center := Vector2(pc.x, pc.y)
		var direction: Vector2 = d.normalized()
		if (center_of_far_edge - player_center).dot(direction) < cone.reach - 0.01:
			push_error("Wind cone points away from facing %s" % d)
			quit(1)
			return
		var front := player_center + direction * 2.0 - Vector2(0.1, 0.1)
		var back := player_center - direction * 2.0 - Vector2(0.1, 0.1)
		if not Helper.cone_overlap(cone, Vec2.new(front.x, front.y), Size.new(0.2, 0.2)) \
				or Helper.cone_overlap(cone, Vec2.new(back.x, back.y), Size.new(0.2, 0.2)):
			push_error("Wind cone hit area disagrees with facing %s" % d)
			quit(1)
			return
	print("Wind cone faces and hits correctly in all eight directions.")
	quit()
