extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
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
	main.transition.hide()
	var bay: Node3D = runtime.dark_crossings.crossings[0].node
	player.global_position = bay.to_global(Vector3(1.5, 0, -3.5))
	player.global_position.y = main.level_manager.floor_height_at(player.global_position)
	player.camera.position = player.camera_base_position
	player.camera.look_at(bay.to_global(Vector3(1.5, 0, -2.0)))
	var pickup: Node3D = runtime.battery_pickups[0]
	pickup.global_position = bay.to_global(Vector3(1.5, 0, -1.15))
	pickup.show()
	runtime.monster_root.global_position = bay.to_global(Vector3(1.5, 0, 2.5))
	runtime.flashlight_blocking_player = player
	var wards: int = runtime.monster_warding_lights.size()
	player.horror_battery_seconds = 0.05
	player.flashlight_on = true
	player._tick_horror_flashlight(0.05)
	check(not player.flashlight_on, "Battery failed to shut down flashlight")
	check(player.horror_near_adaptation < 0.05, "Abrupt adaptation")
	for frame in 120: player._tick_horror_flashlight(1.0 / 60.0)
	check(player.horror_near_visibility.visible, "No near support at empty battery")
	check(is_equal_approx(player.horror_near_visibility.omni_range, 2.80), "Incorrect support range")
	check(runtime._monster_flashlight_exposure(player) == 0.0, "Near support detected as flashlight")
	check(runtime.monster_warding_lights.size() == wards, "Near support registered as safety")
	var unsupported_image: Image
	for enabled in [false, true]:
		player.horror_near_visibility.visible = enabled
		for frame in 8: await process_frame
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)
			var captured := root.get_texture().get_image()
			captured.save_png("/private/tmp/near_visibility_%s.png" % enabled)
			if not enabled:
				unsupported_image = captured
			else:
				var gain := 0.0
				var samples := 0
				for y in range(int(captured.get_height() * 0.55), int(captured.get_height() * 0.78), 16):
					for x in range(int(captured.get_width() * 0.3), int(captured.get_width() * 0.6), 16):
						gain += captured.get_pixel(x, y).get_luminance() - unsupported_image.get_pixel(x, y).get_luminance()
						samples += 1
				print("NEAR_VISIBILITY_RENDER_GAIN=", gain / maxf(samples, 1))
				check(gain / maxf(samples, 1) > 0.025, "Support has no meaningful rendered floor visibility")
	player.camera.look_at(runtime.monster_root.global_position + Vector3.UP * 0.9)
	for frame in 8: await process_frame
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("/private/tmp/near_visibility_forward.png")
	var route_end := bay.to_global(Vector3(1.5, 0, 3.5))
	for frame in 140:
		var step: Vector3 = route_end - player.global_position
		step.y = 0.0
		player._try_move(step.limit_length(0.05))
		player._tick_horror_flashlight(1.0 / 60.0)
	check(player.global_position.distance_to(route_end) < 0.15, "Empty-battery crossing traversal blocked")
	var wall_found := false
	for cell in runtime.monster_open_cells:
		if wall_found: break
		for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
			var center: Vector3 = runtime._cell_world(cell)
			var close: Vector3 = center + direction * 1.45
			close.y = main.level_manager.floor_height_at(close)
			if main.level_manager.is_blocked_world(close, 0.30) or not main.level_manager.is_blocked_world(close + direction * 0.70, 0.1): continue
			if runtime._monster_position_in_warding_light(close): continue
			player.global_position = close
			player.camera.position = player.camera_base_position
			player.camera.look_at(close + direction * 0.60 + Vector3.UP * 0.25)
			for frame in 8: await process_frame
			if DisplayServer.get_name() != "headless":
				RenderingServer.force_draw(false)
				root.get_texture().get_image().save_png("/private/tmp/near_visibility_wall.png")
			wall_found = true
			break
	check(wall_found, "No close-wall fixture")
	player.collect_horror_battery()
	player.flashlight_on = true
	player._update_horror_flashlight_visibility()
	for frame in 20: player._tick_horror_flashlight(1.0 / 60.0)
	check(not player.horror_near_visibility.visible, "Near support overlaps restored flashlight")
	player.flashlight_on = false
	for frame in 120: player._tick_horror_flashlight(1.0 / 60.0)
	check(player.horror_near_visibility.visible, "Manual flashlight off lacks support")
	player.set_horror_flashlight_mode(false)
	check(not player.horror_near_visibility.visible, "Near support leaked into combat")
	if failures == 0: print("HORROR_NEAR_VISIBILITY_OK")
	main.queue_free()
	for frame in 4: await process_frame
	quit(1 if failures else 0)
