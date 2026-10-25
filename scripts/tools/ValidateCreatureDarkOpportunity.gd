extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	set_meta("killgore_start_level", 13)
	set_meta("killgore_level_select", true)
	set_meta("killgore_random_seed", 1337)
	change_scene_to_file("res://Main.tscn")
	for frame in 12: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	var player = main.player
	var runtime = main.level_manager.horror_runtime
	player.set_process_input(false)
	player.set_physics_process(false)
	player.developer_mode = false
	player.hp = 1000
	player.hp_float = 1000.0
	player.armor = 0
	player.armor_float = 0.0
	var bay: Node3D = runtime.dark_crossings.crossings[0].node
	player.global_position = bay.to_global(Vector3(1.5, 0.48, -3.5))
	player.camera.global_position = bay.to_global(Vector3(1.5, 1.65, -3.5))
	var start := bay.to_global(Vector3(1.5, 0, 2.5))
	if OS.get_environment("CREATURE_OPPORTUNITY_MELEE") == "1":
		start = bay.to_global(Vector3(1.5, 0, -0.5))
		runtime.monster_pounce_cooldown = 60.0
	runtime.monster_root.global_position = start
	runtime.monster_root.look_at(Vector3(player.global_position.x, 0, player.global_position.z))
	runtime.monster_state = "patrol"
	runtime.monster_has_visual = false
	runtime.monster_awareness = 0.0
	runtime.monster_visual_confidence = 0.0
	runtime.darkness_time = 6.0
	player.flashlight_on = true
	player._update_horror_flashlight_visibility()
	var capture := OS.get_environment("CREATURE_OPPORTUNITY_CAPTURE") == "1"
	var observer: Camera3D
	if capture:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 720)
		main.transition.hide()
		observer = Camera3D.new()
		main.add_child(observer)
		observer.make_current()
		var fill := OmniLight3D.new()
		fill.omni_range = 12.0
		fill.light_energy = 0.65
		main.add_child(fill)
		fill.global_position = player.global_position + Vector3.UP * 3.0
	var initial_hp: int = player.hp
	for frame in 900:
		if frame < 120:
			player.camera.look_at(runtime.monster_root.global_position + Vector3.UP * 0.9)
		else:
			player.camera.look_at(player.camera.global_position + (player.global_position - start).normalized() * 10.0)
		player._tick_horror_flashlight(1.0 / 60.0)
		runtime.tick(1.0 / 60.0, player)
		if capture:
			observer.global_position = runtime.monster_root.global_position + Vector3(2.4, 1.8, 2.0)
			observer.look_at(runtime.monster_root.global_position + Vector3.UP * 0.6)
			await process_frame
			if frame in [90, 210, 240]:
				RenderingServer.force_draw(false)
				root.get_texture().get_image().save_png("/private/tmp/dark_opportunity_%s.png" % frame)
		if frame == 119 and player.hp != initial_hp:
			failures += 1
			push_error("Damage under focused flashlight")
		if frame % 60 == 0:
			print("DARK_OPPORTUNITY frame=", frame, " state=", runtime.monster_state, " light=", runtime.creature_light_state, " gap=", runtime.monster_root.global_position.distance_to(player.global_position), " speed=", runtime.monster_motion_velocity.length(), " visual=", runtime.monster_has_visual, " safe=", runtime.player_in_safe_light, " depth=", runtime._handheld_light_depth(runtime.monster_root.global_position, runtime.MONSTER_BODY_RADIUS), " hp=", player.hp)
		if player.hp < initial_hp: break
	if player.hp == initial_hp:
		failures += 1
		push_error("No attack after flashlight turned away in darkness")
	if failures == 0: print("CREATURE_DARK_OPPORTUNITY_OK")
	main.queue_free()
	for frame in 4: await process_frame
	quit(1 if failures else 0)
