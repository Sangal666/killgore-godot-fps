extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	set_meta("killgore_start_level", 13)
	set_meta("killgore_level_select", true)
	set_meta("killgore_random_seed", 1337)
	change_scene_to_file("res://Main.tscn")
	for i in 180:
		await process_frame
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	current_scene.set_process(false)
	current_scene.set_physics_process(false)
	var player = current_scene.player
	var runtime = current_scene.level_manager.horror_runtime
	player.set_process(false)
	player.set_physics_process(false)
	player.paused = false
	player.hp = 100
	player.horror_battery_seconds = 100.0
	current_scene.transition.visible = false
	var spawn: Vector3 = current_scene.level_manager.spawn_pos
	print("QA_SPAWN ", spawn, " LIGHTS ", runtime.route_light_positions.size())
	for shot in [
		{"id":"corridor_on", "offset":Vector3(0,0,-10), "dir":Vector3(0,-0.02,-1), "on":true},
		{"id":"corridor_off", "offset":Vector3(0,0,-10), "dir":Vector3(0,-0.02,-1), "on":false},
		{"id":"side_wall", "offset":Vector3(0,0,-10), "dir":Vector3(-1,0,-0.35), "on":true},
		{"id":"dressed_bay", "offset":Vector3(-2,0,-24), "dir":Vector3(-0.35,0,-1), "on":true},
		{"id":"near_wall", "offset":Vector3(5.1,0,-10), "dir":Vector3(1,0,0), "on":true}
	]:
		player.global_position = spawn + shot.offset + Vector3.UP * 0.48
		player.rotation = Vector3.ZERO
		player.camera.global_position = spawn + shot.offset + Vector3.UP * 1.65
		player.camera.look_at(player.camera.global_position + shot.dir)
		player.camera.current = true
		player.flashlight_on = shot.on
		player._update_horror_flashlight_visibility()
		runtime.memory_room_visibility_timer = 0.0
		runtime._update_memory_room_visibility(0.1, player)
		for i in 100:
			player._tick_horror_flashlight(1.0 / 60.0)
			await process_frame
		RenderingServer.force_draw(false)
		print("CAM ",player.camera.global_position," DIR ",-player.camera.global_basis.z," LENS ",player.flashlight_emitter.global_position," VOL ", player.flashlight_volume_root.visible)
		root.get_texture().get_image().save_png("/private/tmp/service_" + shot.id + ".png")
		print("CAPTURE ", shot.id, " FPS ", Engine.get_frames_per_second())
	quit()
