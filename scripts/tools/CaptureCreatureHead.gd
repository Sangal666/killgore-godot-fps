extends SceneTree
## Actual runtime with an external inspection camera/fill, never gameplay lighting.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	change_scene_to_file("res://Main.tscn")
	for frame in 30: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	main.transition.hide()
	var p = main.player
	p.set_physics_process(false)
	p.set_process_input(false)
	p.hp = 1000
	p.hp_float = 1000.0
	var r = main.level_manager.horror_runtime
	var bay: Node3D = r.dark_crossings.crossings[0].node
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.current = true
	camera.fov = 48
	var fill := OmniLight3D.new()
	fill.light_energy = 2.0
	fill.omni_range = 9.0
	main.add_child(fill)
	var directory := "/private/tmp/creature_head_20261014"
	DirAccess.make_dir_recursive_absolute(directory)
	for mode in ["chase","beam"]:
		r.monster_root.global_position = bay.to_global(Vector3(1.5,0,2.5))
		r.monster_state = "chase"
		r.monster_awareness = 1.0
		r.monster_has_visual = true
		r.monster_visual_confidence = 1.0
		r.monster_path.clear()
		for frame in 360:
			# Main's HUD update is paused; clear the inspection-only stale hit tint.
			p.damage_flash = 0.0
			p.global_position = bay.to_global(Vector3(1.5+sin(frame/90.0)*1.2,0,-4.0))
			p.camera.global_position = p.global_position+Vector3.UP*1.36
			p.camera.look_at(r.monster_root.global_position+Vector3.UP*0.85)
			p.flashlight_on = mode == "beam"
			p.horror_battery_seconds = 100.0
			p._update_horror_flashlight_visibility()
			p._tick_horror_flashlight(1.0/60.0)
			r.tick(1.0/60.0,p)
			camera.global_position = r.monster_root.to_global(Vector3(2.4,1.5,-2.6))
			camera.look_at(r.monster_root.global_position+Vector3.UP*0.85)
			fill.global_position = r.monster_root.to_global(Vector3(0,2,-1.8))
			await process_frame
			if frame%6 == 0:
				RenderingServer.force_draw(false)
				root.get_texture().get_image().save_jpg(directory+"/%s_%03d.jpg" % [mode,frame/6],0.9)
		print("HEAD_CAPTURE ",mode," state=",r.monster_active_animation," offset=",r.creature_animation_driver.head_motion)
	main.queue_free()
	for frame in 4: await process_frame
	print("HEAD_CAPTURE_OK")
	quit()
