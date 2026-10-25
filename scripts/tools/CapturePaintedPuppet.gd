extends SceneTree
## QA only: real horror actor/materials, inspection fill explicitly separated.
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	change_scene_to_file("res://Main.tscn")
	for frame in 90: await process_frame
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600,1000)
	var main = current_scene
	main.set_process(false)
	main.set_physics_process(false)
	main.transition.hide()
	main.hud.hide()
	var p = main.player
	p.set_process(false)
	p.set_physics_process(false)
	p.set_process_input(false)
	var r = main.level_manager.horror_runtime
	var bay: Node3D = r.dark_crossings.crossings[0].node
	r.monster_root.global_position = bay.to_global(Vector3(1.4,0,2.5))
	r.monster_root.rotation.y = bay.global_rotation.y
	r.monster_root.show()
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.current = true
	camera.fov = 48
	camera.cull_mask &= ~p.HORROR_FLASHLIGHT_VIEWMODEL_LAYER
	var fill := OmniLight3D.new()
	main.add_child(fill)
	fill.omni_range = 7.0
	fill.light_energy = 2.0
	var directory := "/private/tmp/killgore_painted_puppet_v2_1023"
	DirAccess.make_dir_recursive_absolute(directory)
	for entry in r.monster_scorch_materials:
		var material: ShaderMaterial = entry.material
		var texture: Texture2D = material.get_shader_parameter("base_texture")
		if texture == null or not "painted_puppet_v2" in texture.resource_path:
			failures += 1
			push_error("Actor is not using the painted-puppet UV texture")
	for mode in ["front","face","side","far","flashlight","dark"]:
		fill.visible = mode in ["front","face","side"]
		fill.light_energy = 0.55 if mode == "face" else 2.0
		var offset := Vector3(0.8,1.4,-2.7)
		var target := Vector3(0,0.68,0)
		if mode == "face":
			offset = Vector3(0.25,1.0,-1.35)
			target = Vector3(0,0.67,-0.40)
		if mode == "side": offset = Vector3(2.2,1.5,0.8)
		if mode == "far":
			offset = Vector3(0.8,1.4,-6.0)
			fill.visible = true
			fill.omni_range = 10.0
			fill.light_energy = 3.5
		camera.global_position = r.monster_root.to_global(offset)
		camera.look_at(r.monster_root.to_global(target))
		fill.global_position = camera.global_position+Vector3.UP*0.3
		p.global_position = camera.global_position-Vector3.UP*1.36
		p.camera.global_transform = camera.global_transform
		p.flashlight_on = mode == "flashlight"
		p.horror_battery_seconds = 100.0
		p._update_horror_flashlight_visibility()
		for frame in 24:
			r.creature_animation_driver.advance_visual(1.0/60.0,&"Idle",0.0)
			p._tick_horror_flashlight(1.0/60.0)
			await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(directory+"/"+mode+".png")
		print("PUPPET_CAPTURE ",mode)
		if mode == "flashlight":
			var samples: Array[float] = []
			var last := Time.get_ticks_usec()
			for frame in 90:
				r.creature_animation_driver.advance_visual(1.0/60.0,&"Locomotion",0.8)
				await process_frame
				var now := Time.get_ticks_usec()
				samples.append((now-last)/1000.0)
				last = now
			samples.sort()
			print("PUPPET_RENDER_P95_MS ",samples[85]," samples=90 resolution=1600x1000")
	print("PUPPET_MATERIAL_QA_OK" if failures == 0 else "PUPPET_MATERIAL_QA_FAILED")
	main.queue_free()
	for frame in 4: await process_frame
	quit(1 if failures else 0)
