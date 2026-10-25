extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	change_scene_to_file("res://Main.tscn")
	for frame in 120: await process_frame
	var main = current_scene
	main.set_process_input(false)
	main.set_process_unhandled_input(false)
	main.transition.hide()
	var player = main.player
	var runtime = main.level_manager.horror_runtime
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	player.set_physics_process(false)
	player.hp = 1000
	player.hp_float = 1000.0
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1728,1117)
	var bay: Node3D = runtime.dark_crossings.crossings[0].node
	player.flashlight_on = true
	player.horror_battery_seconds = 100.0
	player._update_horror_flashlight_visibility()
	var start_ms := Time.get_ticks_msec()
	var sample := 0
	var duration := 180.0
	var total_checks := 0
	var whiteout_checks := 0
	var peak_white_fraction := 0.0
	while Time.get_ticks_msec() - start_ms < int(duration * 1000.0):
		player.paused = false
		var t := (Time.get_ticks_msec() - start_ms) / 1000.0
		player.global_position = bay.to_global(Vector3(1.5,0.48,-5.0 + sin(t * 0.3)*2.0))
		player.camera.global_position = player.global_position + Vector3.UP * 1.17
		player.camera.look_at(bay.to_global(Vector3(sin(t * 0.4)*5.0,1.1,4)))
		# Sweep wall, ceiling, floor and creature directions; periodically switch
		# the flashlight off/on to exercise transparent-pass state changes.
		if t > 65.0:
			player.camera.look_at(player.camera.global_position + bay.global_basis * Vector3(sin(t*0.7)*8.0,sin(t*0.43)*2.0,cos(t*0.7)*8.0))
		player.flashlight_on = fmod(t,17.0) < 14.0
		player._update_horror_flashlight_visibility()
		if runtime.monster_root.global_position.distance_to(player.global_position) > 8.0:
			runtime.monster_root.global_position = bay.to_global(Vector3(1.5,0,0))
			runtime.monster_state = "chase"
			runtime.monster_awareness = 1.0
		if t > 45.0: player.horror_battery_seconds = 50.0
		await process_frame
		# Every rendered frame is checked, not just occasional stills. Sampling
		# the framebuffer has overhead, so this is NOT a performance benchmark.
		RenderingServer.force_draw(false)
		var live := root.get_texture().get_image()
		var light_pixels := 0
		var checked := 0
		for y in range(150,live.get_height()-200,80):
			for x in range(100,live.get_width()-100,80):
				var color := live.get_pixel(x,y)
				if minf(color.r,minf(color.g,color.b)) > 0.65: light_pixels += 1
				checked += 1
		var fraction := float(light_pixels)/maxi(checked,1)
		peak_white_fraction = maxf(peak_white_fraction,fraction)
		total_checks += 1
		if fraction > 0.6:
			whiteout_checks += 1
			if whiteout_checks <= 3: live.save_png("/private/tmp/sustained_failure_%02d.png" % whiteout_checks)
		if t > sample * 5:
			RenderingServer.force_draw(false)
			var img := root.get_texture().get_image()
			img.save_png("/private/tmp/sustained_%02d.png" % sample)
			var bright := 0
			for y in range(150,img.get_height()-200,40):
				for x in range(100,img.get_width()-100,40):
					var c := img.get_pixel(x,y)
					if minf(c.r,minf(c.g,c.b)) > 0.65: bright += 1
			print("SUSTAINED t=",t," bright=",bright," energy=",player.flashlight_primary.light_energy," battery=",player.horror_battery_seconds)
			sample += 1
	print("SUSTAINED_COMPLETE checks=",total_checks," whiteouts=",whiteout_checks," peak_fraction=",peak_white_fraction)
	quit()
