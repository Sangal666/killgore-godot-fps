extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	set_meta("killgore_start_level", 13)
	set_meta("killgore_level_select", true)
	change_scene_to_file("res://Main.tscn")
	for frame in 12: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	var player = main.player
	var runtime = main.level_manager.horror_runtime
	player.set_process_input(false)
	player.set_physics_process(false)
	player.set_developer_mode(false)
	main._sync_developer_night_vision()
	var original: Environment = player.camera.environment
	var battery: float = player.horror_battery_seconds
	var ward_count: int = runtime.monster_warding_lights.size()
	var bay: Node3D = runtime.dark_crossings.crossings[0].node
	player.global_position = bay.to_global(Vector3(1.5, 0.48, -3.5))
	player.camera.global_position = bay.to_global(Vector3(1.5, 1.65, -3.5))
	runtime.monster_root.global_position = bay.to_global(Vector3(1.5, 0, 2.5))
	player.camera.look_at(runtime.monster_root.global_position + Vector3.UP * 0.8)
	player.flashlight_on = false
	player._update_horror_flashlight_visibility()
	runtime.flashlight_blocking_player = player
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	main.transition.hide()
	for enabled in [false, true, false]:
		player.set_developer_mode(enabled)
		main._sync_developer_night_vision()
		check((main.developer_night_vision != null) == enabled, "Night vision toggle failed")
		check(not player.flashlight_on, "Night vision enabled flashlight")
		check(player.horror_battery_seconds == battery, "Night vision changed battery")
		check(runtime.monster_warding_lights.size() == ward_count, "Night vision added safe lights")
		check(runtime._monster_flashlight_exposure(player) == 0.0, "Night vision repels creature")
		check(main.world_environment.ambient_light_energy == 0.0, "Shared environment changed")
		if not enabled: check(player.camera.environment == original, "Original camera environment not restored")
		for frame in 4: await process_frame
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png("/private/tmp/developer_night_vision_%s.png" % enabled)
	player.set_developer_mode(true)
	main._sync_developer_night_vision()
	main.level_index = 0
	main._sync_developer_night_vision()
	check(main.developer_night_vision == null and player.camera.environment == original, "Night vision leaked into combat")
	if failures == 0: print("DEVELOPER_NIGHT_VISION_OK")
	main.queue_free()
	for frame in 4: await process_frame
	quit(1 if failures else 0)
