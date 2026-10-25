extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level", 13)
	set_meta("killgore_level_select", true)
	change_scene_to_file("res://Main.tscn")
	for frame in 120: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	main.transition.hide()
	var player = main.player
	player.set_process_input(false)
	player.set_physics_process(false)
	player.flashlight_on = true
	player._update_horror_flashlight_visibility()
	player._tick_horror_flashlight(1.0/60.0)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var sample := MeshInstance3D.new()
	sample.mesh = player.flashlight_haze.draw_pass_1
	player.camera.add_child(sample)
	sample.position = Vector3(0, 0, -0.18)
	for index in 17:
		var copy := MeshInstance3D.new()
		copy.mesh = sample.mesh
		sample.add_child(copy)
	var label := OS.get_environment("FLASHLIGHT_QA_LABEL")
	for enabled in [false, true]:
		sample.visible = enabled
		for frame in 8: await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("/private/tmp/flashlight_haze_%s_%s.png" % [label, enabled])
	sample.hide()
	var route: Array = main.level_manager.horror_runtime.dark_crossings.crossings[0].fast
	var peak := 0.0
	var whiteout := false
	for step in 36:
		var segment := mini(step / 12, route.size() - 2)
		player.global_position = route[segment].lerp(route[segment + 1], float(step % 12) / 12.0) + Vector3.UP * 0.48
		player.camera.rotation = Vector3(sin(step * 0.6) * 0.9, step * 0.35, 0)
		for frame in 8:
			player._tick_horror_flashlight(1.0 / 60.0)
			await process_frame
		RenderingServer.force_draw(false)
		var capture := root.get_texture().get_image()
		var bright := 0
		var tested := 0
		for y in range(100, capture.get_height() - 100, 16):
			for x in range(100, capture.get_width() - 100, 16):
				var pixel := capture.get_pixel(x, y)
				tested += 1
				if minf(pixel.r, minf(pixel.g, pixel.b)) > 0.7: bright += 1
		if float(bright) / maxf(1.0, tested) > 0.65:
			whiteout = true
		if bright > peak:
			peak = bright
			capture.save_png("/private/tmp/flashlight_motion_peak.png")
	if whiteout:
		push_error("Flashlight whiteout detected during motion sweep")
	else:
		print("FLASHLIGHT_MOTION_SWEEP_OK samples=36 peak_bright_samples=", peak)
	print("FLASHLIGHT_NEAR_HAZE_CAPTURE_OK")
	quit(1 if whiteout else 0)
