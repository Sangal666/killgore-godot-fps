extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	change_scene_to_file("res://Main.tscn")
	for frame in 90: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	main.transition.hide()
	var player = main.player
	player.set_process_input(false)
	player.set_physics_process(false)
	var bay: Node3D = main.level_manager.horror_runtime.dark_crossings.crossings[0].node
	player.global_position = bay.to_global(Vector3(1.5,0.48,-6))
	player.camera.global_position = bay.to_global(Vector3(1.5,1.65,-6))
	player.camera.look_at(bay.to_global(Vector3(-0.8,0.9,0)))
	player.flashlight_on = true
	player._update_horror_flashlight_visibility()
	player._tick_horror_flashlight(1.0/60.0)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	for mode in ["original", "no_shadow", "bias"]:
		player.flashlight_primary.shadow_enabled = mode != "no_shadow"
		player.flashlight_primary.shadow_reverse_cull_face = mode == "bias"
		player.flashlight_primary.shadow_bias = 0.08
		player.flashlight_primary.shadow_normal_bias = 0.65
		if mode == "bias":
			player.flashlight_primary.shadow_bias = 0.15
			player.flashlight_primary.shadow_normal_bias = 1.5
		for frame in 8: await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("/private/tmp/prop_shadow_%s.png" % mode)
	for variant in range(4):
		bay = main.level_manager.horror_runtime.dark_crossings.crossings[variant].node
		for distance in [4.0, 9.0, 16.0, 28.0]:
			player.global_position = bay.to_global(Vector3(1.5,0.48,-distance))
			player.camera.global_position = bay.to_global(Vector3(1.5,1.65,-distance))
			player.camera.look_at(bay.to_global(Vector3(-0.8,0.9,0)))
			player._tick_horror_flashlight(1.0/60.0)
			for frame in 8: await process_frame
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png("/private/tmp/prop_fixed_%s_%s.png" % [variant, int(distance)])
			player.flashlight_on = false
			player._update_horror_flashlight_visibility()
			player._tick_horror_flashlight(1.0/60.0)
			for frame in 8: await process_frame
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png("/private/tmp/prop_off_%s_%s.png" % [variant,int(distance)])
			player.flashlight_on = true
			player._update_horror_flashlight_visibility()
	print("PROP_SHADOW_AB_CAPTURED")
	quit()
