extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	set_meta("killgore_start_level", 13)
	set_meta("killgore_level_select", true)
	set_meta("killgore_random_seed", 1337)
	change_scene_to_file("res://Main.tscn")
	for frame in 8: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	var runtime = main.level_manager.horror_runtime
	var player = main.player
	player.set_process_input(false)
	player.set_physics_process(false)
	player.flashlight_on = false
	player.developer_mode = false
	for frame in 120:
		player._tick_horror_flashlight(1.0 / 60.0)
	check(player.horror_near_visibility.visible, "Dark attack fixture lacks near visibility support")
	player.hp = 100
	player.hp_float = 100.0
	player.armor = 0
	player.armor_float = 0.0
	player.dodge_immunity_timer = 0.0
	var found := false
	var test_pounce := OS.get_environment("CREATURE_COMBAT_POUNCE") == "1"
	var capture := OS.get_environment("CREATURE_COMBAT_CAPTURE") == "1"
	var camera: Camera3D
	if capture:
		main.set_process(false)
		main.transition.hide()
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280,720)
		camera = Camera3D.new()
		main.add_child(camera)
		camera.current = true
		camera.fov = 55
		var fill := OmniLight3D.new()
		camera.add_child(fill)
		fill.light_energy = 2.0
		fill.omni_range = 10.0
	for cell in runtime.monster_open_cells:
		var a: Vector3 = runtime._cell_world(cell)
		var gap := 1.50 if OS.get_environment("CREATURE_COMBAT_GAP").is_empty() else OS.get_environment("CREATURE_COMBAT_GAP").to_float()
		var b := a + Vector3.RIGHT * gap
		if not runtime._monster_motion_segment_valid(a, b): continue
		player.global_position = b
		player.set_horror_hidden(false)
		runtime.monster_root.global_position = a
		runtime.monster_root.look_at(b)
		runtime.monster_state = "chase"
		runtime.monster_has_visual = true
		runtime.monster_awareness = 1.0
		runtime.monster_visual_confidence = 1.0
		runtime.monster_attack_timer = 0.0
		runtime.monster_attack_windup = 0.0
		runtime.monster_strike_timer = 0.0
		runtime.monster_pounce_cooldown = 10.0
		runtime.monster_pounce_timer = 0.0
		runtime.monster_pounce_windup = 0.0
		runtime.monster_pounce_recovery_timer = 0.0
		runtime.monster_reentry_grace_timer = 0.0
		runtime.monster_search_pause = 0.0
		runtime.monster_light_pain = 0.0
		runtime.creature_beam_hold = 0.0
		runtime.monster_motion_velocity = Vector3.ZERO
		runtime.monster_current_speed = 0.0
		runtime.monster_path.clear()
		runtime.monster_repath_timer = 0.0
		runtime.darkness_time = 5.0
		var kind := OS.get_environment("CREATURE_COMBAT_KIND")
		if kind.is_empty(): kind = "Heavy" if test_pounce else "Quick"
		if not runtime.predator_attack.begin(runtime,player,kind): continue
		var phases := {}
		for frame in 200:
			var before: int = player.hp
			runtime._tick_amalgam(1.0/60.0,player)
			var driver = runtime.creature_animation_driver
			var action = runtime.predator_attack
			phases[action.phase] = true
			if capture:
				camera.global_position = runtime.monster_root.to_global(Vector3(2.2,1.5,-2.5))
				camera.look_at(runtime.monster_root.global_position+Vector3.UP*0.75)
				await process_frame
				if frame%6==0 or player.hp<before:
					RenderingServer.force_draw(false)
					root.get_texture().get_image().save_png("/private/tmp/predator_%s_%03d.png" % [kind,frame])
			if player.hp<before:
				check(action.phase=="Strike" and driver.current_state==&"Attack","Damage outside strike phase")
				var contact := Vector2(0.13,0.29) if kind=="Quick" else (Vector2(0.38,0.56) if kind=="Heavy" else Vector2(0.20,0.39))
				check(action.age>=contact.x and action.age<=contact.y,"Damage outside contact window")
				check(driver.strike_touches(player.global_position),"Damage without animated limb contact")
				print("PREDATOR_CONTACT ",kind," t=",action.age)
			if not action.active: break
		check(phases.has("Windup") and phases.has("Strike") and phases.has("Recover"),"Missing attack phase")
		check(player.hp<100,"Creature failed to land "+kind)
		found = true
		break
	check(found,"No valid dark combat fixture")
	main.queue_free()
	for frame in 4: await process_frame
	if failures==0: print("CREATURE_COMBAT_OK")
	quit(1 if failures else 0)
