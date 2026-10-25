extends SceneTree
var failures := 0
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
	var runtime = main.level_manager.horror_runtime
	player.set_process_input(false)
	player.set_physics_process(false)
	player.hp = 1000
	player.hp_float = 1000.0
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	var bay: Node3D = runtime.dark_crossings.crossings[0].node
	player.global_position = bay.to_global(Vector3(1.5,0.48,-3.5))
	player.camera.global_position = bay.to_global(Vector3(1.5,1.65,-3.5))
	var start := bay.to_global(Vector3(1.5,0,2.5))
	player.camera.look_at(start + Vector3.UP * 0.9)
	for mode in ["chase", "beam", "vfx"]:
		runtime.monster_root.global_position = start
		runtime.monster_root.look_at(Vector3(player.global_position.x,0,player.global_position.z))
		runtime.monster_state = "chase"
		runtime.monster_has_visual = true
		runtime.monster_awareness = 1.0
		runtime.monster_visual_confidence = 1.0
		runtime.darkness_time = 6.0
		player.flashlight_on = mode != "chase"
		player._update_horror_flashlight_visibility()
		var bone: int = runtime.monster_skeleton.find_bone("LegL1_Lower")
		var previous: Quaternion = runtime.monster_skeleton.get_bone_pose_rotation(bone)
		var motion := 0.0
		var poses := {}
		var hp_before: int = player.hp
		var initial_gap: float = start.distance_to(player.global_position)
		for frame in 240:
			player.damage_flash = 0.0
			if mode == "beam":
				player.camera.look_at(runtime.monster_root.global_position + Vector3.UP * 0.9)
			player._tick_horror_flashlight(1.0/60.0)
			if mode == "vfx":
				runtime.monster_light_pain = 1.0
				runtime.monster_distress_blend = 1.0
				runtime.monster_light_flare = 1.0
				runtime._update_monster_light_vfx(1.0/60.0)
			else:
				runtime.tick(1.0/60.0, player)
			var pose: Quaternion = runtime.monster_skeleton.get_bone_pose_rotation(bone)
			motion += previous.angle_to(pose)
			previous = pose
			poses[runtime.monster_active_animation] = true
			await process_frame
			if frame in [30,120,239]:
				RenderingServer.force_draw(false)
				root.get_texture().get_image().save_png("/private/tmp/live_creature_%s_%s.png" % [mode,frame])
		print("LIVE_RESPONSE ",mode," moved=",start.distance_to(runtime.monster_root.global_position)," leg_rotation_total=",motion," states=",poses)
		if mode == "beam":
			if player.hp != hp_before or runtime.monster_root.global_position.distance_to(player.global_position) < initial_gap + 1.0:
				push_error("Beam failed to prevent damage or produce physical retreat")
				failures += 1
		if mode != "vfx" and motion < 1.0:
			push_error("Live locomotion has insufficient leg articulation")
			failures += 1
	if failures == 0: print("CREATURE_LIVE_RESPONSE_OK")
	quit(1 if failures else 0)
