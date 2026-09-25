extends SceneTree

# Small end-to-end regression for the menu, room geometry, and dungeon flow.
# Run with: godot --headless --path . --script res://tools/test_gameplay.gd


func _initialize() -> void:
	call_deferred("_run")


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _clear_wave(world: World) -> void:
	for enemy in world.get_entities_with_comp([Comp.ENEMY]):
		world.remove_entity_by_id(enemy)
	var rounds := world.get_entities_with_comp([Comp.ROUND])
	world.detach_component(Comp.DELAY, rounds[0])
	WaveSystem.process(world, 0.0)


func _run() -> void:
	var scene: PackedScene = load("res://view/main.tscn")
	var main := scene.instantiate()
	root.add_child(main)
	var menu := main.get_node("MenuLayer/MenuUI")
	if not _require(main.get("world") == null, "The menu should not create a simulation"):
		return
	menu.get_node("MenuContent/Center/Contents/SettingsButton").emit_signal("pressed")
	if not _require(menu.get("_settings_open"), "Settings should open from the menu"):
		return
	menu.get_node("SettingsContent/Center/Panel/Margins/Contents/Buttons/BackButton").emit_signal("pressed")
	if not _require(not menu.get("_settings_open"), "Settings should close"):
		return
	var settings := root.get_node_or_null("GameSettings")
	if not _require(settings != null, "Game settings should be loaded"):
		return
	if not _require(settings.call("binding_text", "dash") != "Unbound",
			"Gameplay key bindings should be available"):
		return
	var original_events := InputMap.action_get_events("dash").duplicate()
	var original_volume: float = settings.call("get_volume", "SFX")
	var original_path: String = settings.get("settings_path")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/test-logs"))
	var test_path := "res://build/test-logs/settings-test.cfg"
	settings.set("settings_path", test_path)
	var test_key := InputEventKey.new()
	test_key.physical_keycode = KEY_Q
	settings.call("set_binding", "dash", test_key)
	settings.call("set_volume", "SFX", 0.35)
	var saved := ConfigFile.new()
	if not _require(saved.load(test_path) == OK and saved.has_section_key("bindings", "dash")
			and is_equal_approx(float(saved.get_value("audio", "SFX", 0.0)), 0.35),
			"Settings should persist the new key and volume"):
		return
	if not _require(settings.call("binding_text", "dash").contains("Q"),
			"The displayed binding should update after rebinding"):
		return
	InputMap.action_erase_events("dash")
	for event in original_events:
		InputMap.action_add_event("dash", event)
	settings.call("set_volume", "SFX", original_volume)
	settings.set("settings_path", original_path)
	menu.get_node("MenuContent/Center/Contents/PlayButton").emit_signal("pressed")
	if not _require(main.call("is_playing"), "Start should begin gameplay"):
		return
	main.call("toggle_pause")
	if not _require(not main.call("is_playing"), "Pause should stop gameplay"):
		return
	menu.get_node("PauseContent/Center/Contents/ResumeButton").emit_signal("pressed")
	var world: World = main.get("world")
	var room := RoundState.room_size(world)
	if not _require(room.w == 20.0 and room.h == 12.0,
			"The first room should use its scene dimensions"):
		return
	if not _require(RoundState.room_obstacles(world).size() == 2,
			"The first room should have two scene-authored obstacles"):
		return
	var players := world.get_entities_with_comp([Comp.PLAYER, Comp.POSITION, Comp.SIZE])
	var player := players[0]
	var position: Vec2 = world.get_component_value(Comp.POSITION, player)
	position.x = 8.5
	position.y = 3.5
	BoundSystem.process(world, 0.0)
	var pillar := RoundState.room_obstacles(world)[0]
	if not _require(not Rect2(position.x, position.y, 1.0, 1.0).intersects(pillar),
			"The pillar should block the player"):
		return
	var detour := RoomPathfinder.direction(Vec2.new(7.0, 4.0),
		Vec2.new(11.0, 4.0), RoundState.room_obstacles(world), room)
	if not _require(absf(detour.y) > 0.1,
			"Enemies should route around the pillar"):
		return
	var navigation_world := World.new()
	Spawn.round(navigation_world, Vector2i(20, 12),
		RoundState.room_obstacles(world), [], Rect2(), true)
	Spawn.player(navigation_world, 11.0, 4.0, 200)
	var navigating_enemy := Spawn.enemy(navigation_world, 7.0, 4.0, 100)
	var navigation_started := Time.get_ticks_msec()
	for frame in 600:
		ChaseSystem.process(navigation_world, 0.016)
		IntentSystem.process(navigation_world, 0.016)
		MoveSystem.process(navigation_world, 0.016)
		BoundSystem.process(navigation_world, 0.016)
	print("Navigation regression 600 ticks: %d ms" % (Time.get_ticks_msec() - navigation_started))
	var enemy_after: Vec2 = navigation_world.get_component_value(Comp.POSITION, navigating_enemy)
	if not _require(Vector2(enemy_after.x, enemy_after.y).distance_to(Vector2(11.0, 4.0)) < 1.5,
			"An enemy should reach the player by walking around a pillar"):
		return
	var health: Health = world.get_component_value(Comp.HEALTH, player)
	health.current = 143.0
	WaveSystem.process(world, 0.0)
	var spawned := world.get_entities_with_comp([Comp.ENEMY, Comp.POSITION])
	if not _require(spawned.size() == 3, "The first wave should spawn three enemies"):
		return
	var authored_spawns := RoundState.room_spawns(world)
	for enemy in spawned:
		var enemy_pos: Vec2 = world.get_component_value(Comp.POSITION, enemy)
		if not _require(authored_spawns.has(Vector2(enemy_pos.x, enemy_pos.y)),
				"Waves should use spawn markers from the room scene"):
			return
	for i in Tuning.WAVE_COUNT:
		_clear_wave(world)
	var rounds := world.get_entities_with_comp([Comp.ROUND])
	if not _require(world.entity_have_component(Comp.ROOM_CLEARED, rounds[0]),
			"The first room should open its exit after four waves"):
		return
	if not _require(not world.entity_have_component(Comp.WON, rounds[0]),
			"Victory should wait for the final room"):
		return
	RoomExitSystem.process(world, 0.0)
	if not _require(not world.entity_have_component(Comp.ROOM_EXITED, rounds[0]),
			"The exit should require the player to enter it"):
		return
	position.x = 19.0
	position.y = 5.5
	RoomExitSystem.process(world, 0.0)
	if not _require(world.entity_have_component(Comp.ROOM_EXITED, rounds[0]),
			"The open exit should recognize the player"):
		return
	main.call("_physics_process", 0.0)
	world = main.get("world")
	room = RoundState.room_size(world)
	if not _require(room.w == 16.0 and room.h == 10.0,
			"The exit should load the second room scene"):
		return
	players = world.get_entities_with_comp([Comp.PLAYER, Comp.HEALTH])
	health = world.get_component_value(Comp.HEALTH, players[0])
	if not _require(is_equal_approx(health.current, 143.0),
			"Health should carry into the next room"):
		return
	WaveSystem.process(world, 0.0)
	for i in Tuning.WAVE_COUNT:
		_clear_wave(world)
	rounds = world.get_entities_with_comp([Comp.ROUND])
	if not _require(world.entity_have_component(Comp.WON, rounds[0]),
			"The final room should award victory"):
		return
	print("Gameplay regression passed: menu, settings, rooms, obstacles, exits, victory.")
	main.queue_free()
	quit()
