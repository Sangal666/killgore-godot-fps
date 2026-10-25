extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	change_scene_to_file("res://Main.tscn")
	for frame in 20: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	main.transition.hide()
	var p = main.player
	p.set_process_input(false)
	p.set_physics_process(false)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	var bay: Node3D = main.level_manager.horror_runtime.dark_crossings.crossings[0].node
	p.global_position = bay.to_global(Vector3(0,0.48,-7))
	p.camera.global_position = bay.to_global(Vector3(0,1.65,-7))
	p.camera.look_at(bay.to_global(Vector3(-4,1.2,1)))
	p.flashlight_on = true
	p._update_horror_flashlight_visibility()
	p._tick_horror_flashlight(0.016)
	for mode in ["baseline","precision","no_shadow","no_air","no_particles"]:
		root.positional_shadow_atlas_16_bits = mode != "precision"
		p.flashlight_primary.shadow_enabled = mode != "no_shadow"
		p.flashlight_volume_root.visible = mode != "no_air"
		p.flashlight_haze.visible = mode != "no_particles"
		p.flashlight_dust.visible = mode != "no_particles"
		for frame in 12: await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("/private/tmp/wall_%s.png" % mode)
		print("WALL_CAPTURE ",mode)
	quit()
