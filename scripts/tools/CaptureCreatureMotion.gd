extends SceneTree
## Actual level/runtime, external QA camera and fill light. Not gameplay lighting.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	change_scene_to_file("res://Main.tscn")
	for frame in 30: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	main.set_process_input(false)
	main.transition.hide()
	var p = main.player
	p.set_physics_process(false)
	p.set_process_input(false)
	p.hp = 1000
	p.hp_float = 1000.0
	var r = main.level_manager.horror_runtime
	var bay: Node3D = r.dark_crossings.crossings[0].node
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960,540)
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.current = true
	camera.fov = 62
	var fill := OmniLight3D.new()
	fill.light_energy = 2.0
	fill.omni_range = 9.0
	fill.shadow_enabled = false
	main.add_child(fill)
	var directory := "/private/tmp/creature_motion_20261006"
	DirAccess.make_dir_recursive_absolute(directory)
	for mode in ["near","far","beam"]:
		DirAccess.make_dir_recursive_absolute(directory+"/"+mode)
		r.monster_root.global_position = bay.to_global(Vector3(1.5,0,2.5))
		r.monster_root.rotation.y = bay.rotation.y
		r.monster_state = "chase"
		r.monster_awareness = 1.0
		r.monster_has_visual = true
		r.monster_visual_confidence = 1.0
		r.creature_light_state = "clear"
		r.creature_light_clear_time = 0.0
		r.monster_motion_velocity = Vector3.ZERO
		r.monster_current_speed = 0.0
		r.monster_path.clear()
		var states := {}
		for frame in 1200:
			var t := float(frame)/60.0
			p.global_position = bay.to_global(Vector3(1.5,0.48,-5.0+sin(t*0.5)*2.0))
			p.camera.global_position = p.global_position+Vector3.UP*1.17
			p.camera.look_at(r.monster_root.global_position+Vector3.UP*0.85)
			p.flashlight_on = mode == "beam" and fmod(t,8.0)<6.0
			p.horror_battery_seconds = 100.0
			p._update_horror_flashlight_visibility()
			p._tick_horror_flashlight(1.0/60.0)
			r.tick(1.0/60.0,p)
			states[r.monster_active_animation] = true
			var offset := Vector3(2.4,1.6,2.1) if mode != "far" else Vector3(2.8,1.8,6.0)
			camera.global_position = r.monster_root.global_position+bay.global_basis*offset
			camera.look_at(r.monster_root.global_position+Vector3.UP*0.55)
			fill.global_position = r.monster_root.global_position+Vector3(0,2.0,0)
			await process_frame
			if frame % 2 == 0:
				RenderingServer.force_draw(false)
				root.get_texture().get_image().save_jpg(directory+"/%s/%04d.jpg" % [mode,frame/2],0.82)
		print("MOTION_CAPTURE ",mode," frames=600 states=",states)
	print("MOTION_CAPTURE_COMPLETE ",directory)
	quit()
