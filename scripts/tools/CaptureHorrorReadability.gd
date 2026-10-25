extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level", 13)
	set_meta("killgore_level_select", true)
	set_meta("killgore_random_seed", 1337)
	change_scene_to_file("res://Main.tscn")
	for frame in 120: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	main.transition.visible = false
	var runtime = main.level_manager.horror_runtime
	var player = main.player
	player.set_process_input(false)
	player.set_process(false)
	player.set_physics_process(false)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var pickup: Node3D = runtime.battery_pickups[0]
	var target := pickup.global_position + Vector3.UP * 0.16
	assert(pickup.has_node("BatteryReflectiveBand"))
	var band: MeshInstance3D = pickup.get_node("BatteryReflectiveBand")
	print("BATTERY_MATERIAL ", band.material_override, " visible=", band.is_visible_in_tree(), " position=", band.global_position)
	for distance in [2.5, 7.0, 12.0]:
		var eye := Vector3.INF
		for direction in [Vector3.BACK, Vector3.FORWARD, Vector3.RIGHT, Vector3.LEFT]:
			var candidate: Vector3 = pickup.global_position + direction * distance + Vector3.UP * 1.65
			if not main.level_manager.is_blocked_world(candidate - Vector3.UP * 1.17, 0.32) and runtime._handheld_line_clear(candidate, target):
				eye = candidate
				break
		if eye == Vector3.INF:
			print("BATTERY_VIEW_OCCLUDED ", distance)
			continue
		player.global_position = eye - Vector3.UP * 1.17
		player.camera.global_position = eye
		player.camera.look_at(target)
		player.camera.current = true
		print("BATTERY_DISTANCE ", band.global_position.distance_to(player.camera.global_position), " screen=", player.camera.unproject_position(band.global_position))
		for flashlight in [false, true]:
			player.flashlight_on = flashlight
			player.horror_battery_seconds = 100.0
			player._update_horror_flashlight_visibility()
			for frame in 24:
				player._tick_horror_flashlight(1.0/60.0)
				await process_frame
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png("/private/tmp/battery_%s_%s.png" % [distance, "lit" if flashlight else "dark"])
			print("BATTERY_VIEW_OK ", distance, " flashlight=", flashlight)
	quit()
