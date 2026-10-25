extends SceneTree

var failures: Array[String] = []
var player
var runtime

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	set_meta("killgore_start_level", 13)
	set_meta("killgore_level_select", true)
	set_meta("killgore_random_seed", 1337)
	change_scene_to_file("res://Main.tscn")
	for i in 300:
		await process_frame
	player = current_scene.player
	runtime = current_scene.level_manager.horror_runtime
	var spawn: Vector3 = current_scene.level_manager.spawn_pos
	print("LIGHT_ROUTE_COUNT=", runtime.route_light_positions.size(), " BATTERY_COUNT=", runtime.battery_pickups.size(), " SPAWN=", spawn)
	check(runtime._monster_position_in_warding_light(spawn), "Spawn must be safe")
	check(runtime.route_light_positions.size() > 8, "Light route missing")
	for a in runtime.route_light_positions.size():
		for b in range(a + 1, runtime.route_light_positions.size()):
			check(runtime.route_light_positions[a].distance_to(runtime.route_light_positions[b]) >= 23.99, "Fixed refuges too close: dark crossing missing")
	check(is_instance_valid(player.flashlight_volume_root.get_node_or_null("DepthClippedFlashlightAir")), "Visible flashlight shaft missing")
	check(player.flashlight_primary.spot_angle <= 35.0, "Flashlight reverted to broad floor flood")
	check(runtime.battery_pickups.size() > 0 and runtime.battery_pickups.size() <= 10, "Battery distribution missing")
	var saved_hp: int = player.hp
	player.global_position = spawn + Vector3.UP * 0.48
	runtime.monster_attack_windup = 0.1
	runtime.monster_pounce_timer = 0.2
	runtime._tick_darkness_and_batteries(0.1, player)
	runtime._tick_amalgam(0.1, player)
	check(runtime.monster_attack_windup == 0.0 and runtime.monster_pounce_timer == 0.0, "Safe light must cancel committed attacks")
	runtime._resolve_monster_attack(player)
	check(player.hp == saved_hp, "Damage in safe light")
	var tested_boundary := false
	for ward in runtime.monster_warding_lights:
		if not ward.safe_zone:
			continue
		var center: Vector3 = ward.position
		for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
			var outside: Vector3 = center + direction * 4.0
			if runtime._monster_motion_position_valid(outside):
				check(not runtime._monster_motion_segment_valid(outside, center - direction * 4.0), "Fast movement tunneled through light")
				check(not runtime._monster_motion_position_valid(center + direction * 2.8), "Body overlaps light boundary")
				tested_boundary = true
				if not has_meta("boundary_simulated"):
					set_meta("boundary_simulated", true)
					player.global_position = center + Vector3.UP * 0.48
					runtime.monster_root.global_position = outside
					runtime.monster_state = "chase"
					runtime.monster_has_visual = true
					runtime.monster_visual_confidence = 1.0
					var safe_hp: int = player.hp
					for frame in 180:
						runtime._tick_darkness_and_batteries(1.0 / 60.0, player)
						runtime._tick_amalgam(1.0 / 60.0, player)
						check(not runtime._monster_position_in_warding_light(runtime.monster_root.global_position, runtime.MONSTER_BODY_RADIUS), "Hunter entered light during pursuit")
					check(player.hp == safe_hp, "Hunter damaged player during sustained safe-zone wait")
	check(tested_boundary, "No boundary case tested")
	for cell in runtime.monster_open_cells:
		check(not runtime._monster_position_in_warding_light(runtime._cell_world(cell), runtime.MONSTER_BODY_RADIUS), "Navigation cell enters safe light")
	for position in runtime.route_light_positions:
		player.global_position = position + Vector3(8, 0.48, 0)
		var candidate: Vector3 = runtime._choose_hunt_reset_position(player)
		if candidate != Vector3.INF:
			check(runtime._monster_motion_position_valid(candidate) and not runtime._monster_spawn_forbidden_near_kitchen(candidate), "Unsafe teleport selected")
	player.horror_battery_seconds = 1.0
	player.flashlight_on = true
	player.paused = false
	player._tick_horror_flashlight(0.5)
	check(absf(player.horror_battery_seconds - 0.2) < 0.001, "Battery drain incorrect")
	player._tick_horror_flashlight(0.6)
	check(not player.flashlight_on and player.horror_battery_seconds == 0.0, "Empty flashlight still enabled")
	player._toggle_horror_flashlight()
	check(not player.flashlight_on, "Empty flashlight can toggle on")
	player._tick_horror_flashlight(10.0)
	check(player.horror_battery_seconds == 0.0, "Battery automatically recharged")
	var pickup: Node3D = runtime.battery_pickups[0]
	player.global_position = pickup.global_position + Vector3.UP * 0.48
	runtime._tick_darkness_and_batteries(0.0, player)
	check(not pickup.visible and player.horror_battery_seconds == 35.0, "Pickup not reflected in battery")
	check(absf(player.horror_battery_ratio() - 0.35) < 0.001, "HUD battery ratio wrong")
	runtime._tick_darkness_and_batteries(0.0, player)
	check(player.horror_battery_seconds == 35.0, "Pickup collected twice")
	# Choose adjacent physically clear dark cells for an actual close attack.
	var attack_tested := false
	for cell in runtime.monster_open_cells:
		var a: Vector3 = runtime._cell_world(cell)
		var b := a + Vector3.RIGHT * 1.8
		if not runtime._monster_motion_segment_valid(a, b):
			continue
		player.global_position = b + Vector3.UP * 0.48
		player.set_horror_hidden(false)
		runtime.monster_root.global_position = a
		runtime.darkness_time = 0.0
		runtime.monster_state = "stalk"
		runtime._tick_darkness_and_batteries(4.1, player)
		check(runtime.monster_state == "chase", "Darkness did not start hunt")
		var before: int = player.hp
		player.developer_mode = false
		player.dodge_immunity_timer = 0.0
		player.armor_float = 0.0
		player.armor = 0
		runtime._resolve_monster_attack(player)
		check(player.hp == before, "Damage occurred without an active animation contact window")
		player.hp = 100
		player.hp_float = 100.0
		player.horizontal_velocity = Vector3.ZERO
		runtime.monster_root.look_at(Vector3(b.x, 0.0, b.z), Vector3.UP)
		runtime.monster_attack_timer = 0.0
		runtime.monster_attack_windup = 0.0
		runtime.monster_strike_timer = 0.0
		runtime.creature_beam_hold = 0.0
		runtime.monster_pounce_timer = 0.0
		runtime.monster_pounce_windup = 0.0
		runtime.monster_motion_velocity = Vector3.ZERO
		runtime.monster_steering_direction = Vector3.ZERO
		runtime.monster_current_speed = 0.0
		runtime.monster_search_pause = 0.0
		runtime.monster_path.clear()
		runtime.monster_repath_timer = 0.0
		runtime.monster_light_stagger_timer = 0.0
		runtime.monster_light_reflex_timer = 0.0
		runtime.monster_reentry_grace_timer = 0.0
		runtime.monster_pounce_cooldown = 10.0
		runtime.monster_pounce_recovery_timer = 0.0
		runtime.monster_light_pain = 0.0
		runtime.monster_light_evasion_timer = 0.0
		runtime.monster_has_visual = true
		runtime.monster_visual_confidence = 1.0
		for frame in 120:
			runtime.tick(1.0 / 60.0, player)
			if player.hp < 100:
				check(runtime.creature_animation_driver.current_state == &"Attack", "Live attack damage did not use Attack animation")
				check(runtime.creature_animation_driver.strike_touches(player.global_position), "Live attack lacked limb contact")
				break
		check(player.hp < 100, "Live darkness hunt never attacked")
		attack_tested = true
		break
	check(attack_tested, "No dark attack scenario found")
	if failures.is_empty():
		print("LIGHT_ESCAPE_RULES_OK")
	if DisplayServer.get_name() != "headless":
		await _capture_game()
	quit(0 if failures.is_empty() else 1)

func _capture_game() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	current_scene.set_process(false)
	current_scene.set_physics_process(false)
	player.set_process(false)
	player.set_physics_process(false)
	player.flashlight_on = false
	player._update_horror_flashlight_visibility()
	player.hp = 100
	player.hp_float = 100.0
	current_scene.transition.visible = false
	var camera := Camera3D.new()
	current_scene.add_child(camera)
	camera.current = true
	camera.fov = 78.0
	var spawn: Vector3 = current_scene.level_manager.spawn_pos
	for shot in [
		{"id": "safe_route", "pos": spawn + Vector3(0, 1.65, 0), "target": spawn + Vector3(0, 1.2, -24)},
		{"id": "dark_gap", "pos": spawn + Vector3(0, 1.65, -8), "target": spawn + Vector3(0, 1.2, -28)},
		{"id": "kitchen_route", "pos": Vector3(runtime.task_anchors["kitchen"]) + Vector3(0, 1.65, 26), "target": Vector3(runtime.task_anchors["kitchen"]) + Vector3(0, 1.0, 0)}
	]:
		camera.global_position = shot.pos
		camera.look_at(shot.target)
		player.global_position = shot.pos - Vector3.UP * 1.17
		runtime._tick_darkness_and_batteries(0.0, player)
		runtime.memory_room_visibility_timer = 0.0
		runtime._update_memory_room_visibility(0.1, player)
		for i in 35:
			await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("/private/tmp/light_escape_" + shot.id + ".png")
		print("LIGHT_ESCAPE_CAPTURE_", shot.id)
		print("RENDER_FPS=", Engine.get_frames_per_second())
