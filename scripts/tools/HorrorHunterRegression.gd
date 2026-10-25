extends SceneTree

const HORROR_LEVEL := 13
const PlayerScript = preload("res://scripts/player/PlayerController.gd")
const PLAYER_WALK_SPEED := PlayerScript.HORROR_WALK_SPEED
const PLAYER_SPRINT_SPEED := PlayerScript.HORROR_SPRINT_SPEED

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	set_meta("killgore_start_level", HORROR_LEVEL)
	set_meta("killgore_level_select", true)
	change_scene_to_file("res://Main.tscn")
	await _wait_frames(320)

	var main = current_scene
	var player = main.get("player") if main != null else null
	var level_manager = main.get("level_manager") if main != null else null
	var runtime = level_manager.get("horror_runtime") if level_manager != null else null
	if player == null or runtime == null or not is_instance_valid(runtime.monster_root):
		_fail("Horror level, player, or hunter did not initialize")
		_finish()
		return
	if not is_instance_valid(runtime.monster_model) or runtime.monster_model.name != "CorridorCreatureVisual":
		_fail("Spider-woman maze monster visual did not initialize")
	if not is_instance_valid(runtime.monster_skeleton) or runtime.monster_scorch_materials.is_empty():
		_fail("Spider-woman skeleton or integrated surface response did not initialize")
	if runtime._monster_spawn_forbidden_near_kitchen(runtime.monster_root.global_position):
		_fail("Spider-woman initialized inside the kitchen approach corridor")
	# Director/light-hunt relocations must never materialize the creature inside
	# the narrow kitchen reveal, while ordinary pathfinding remains unrestricted.
	for probe_position in [Vector3(20.0, 0.0, 300.0), Vector3(120.0, 0.0, 220.0), Vector3(36.0, 0.0, 416.0)]:
		player.global_position = probe_position
		var relocation_candidate: Vector3 = runtime._choose_hunt_reset_position(player)
		if relocation_candidate != Vector3.INF and runtime._monster_spawn_forbidden_near_kitchen(relocation_candidate):
			_fail("Spider-woman relocation selected the kitchen approach corridor")
	# The authored face now owns the eye sockets and ink trails. Reintroducing the
	# retired overlay geometry would make the monster glow against the darkness.
	if is_instance_valid(runtime.monster_expression_root) or not runtime.monster_expression_eyes.is_empty() or not runtime.monster_expression_brows.is_empty() or is_instance_valid(runtime.monster_expression_mouth):
		_fail("Retired artificial face overlay was unexpectedly recreated")
	var animation_player = runtime.monster_animation_player
	if not is_instance_valid(animation_player):
		_fail("Spider-woman maze monster has no AnimationPlayer")
	else:
		for required_animation in ["Idle", "Alert", "Walk", "Run", "TurnLeft", "TurnRight", "LightStop", "Retreat", "WindUp", "Attack", "Recovery", "Blocked"]:
			if not animation_player.has_animation(required_animation):
				_fail("Spider-woman maze monster is missing %s animation" % required_animation)
		for locomotion_animation in ["Walk", "Run"]:
			var authored_clip: Animation = animation_player.get_animation(locomotion_animation)
			# Godot removes redundant baked keys on import. Test articulated
			# motion instead of requiring the previous model's raw key count.
			for side in ["L", "R"]:
				for leg in range(1, 5):
					for joint in ["Upper", "Lower", "Tip"]:
						var bone_name := "Leg%s%d_%s" % [side, leg, joint]
						var animated := false
						for track in authored_clip.get_track_count():
							if authored_clip.track_get_type(track) != Animation.TYPE_ROTATION_3D or not String(authored_clip.track_get_path(track)).ends_with(":" + bone_name):
								continue
							var first := authored_clip.rotation_track_interpolate(track, 0.0)
							# Two phase samples can coincide on a symmetric gait. Check
							# the whole cycle without relaxing the articulation threshold.
							for sample in range(1,24):
								var second := authored_clip.rotation_track_interpolate(track,authored_clip.length*float(sample)/24.0)
								animated = animated or (first.is_finite() and second.is_finite() and first.angle_to(second)>0.0001)
						if not animated:
							_fail("%s missing articulated motion for %s" % [locomotion_animation, bone_name])

	# Light exclusion, relocation and full-level safety are tested separately in
	# ValidateHorrorLightEscape. This fixture measures locomotion/perception on
	# uninterrupted dark ground, not a route intentionally divided by safe pools.
	runtime.monster_warding_lights.clear()
	runtime._build_monster_navigation(runtime.maze_raw)
	runtime.darkness_time = runtime.DARKNESS_HUNT_DELAY + 0.1
	runtime.monster_distress_blend = 0.0
	runtime.monster_turn_lean = 0.0
	runtime.monster_visual_pitch = 0.0
	runtime.monster_visual_roll = 0.0
	runtime.monster_flee_blend = 0.0
	runtime.monster_pounce_visual_arc = 0.0
	# Selection and cadence depend on actual displacement, never desired speed.
	runtime.creature_beam_hold = 0.0
	runtime.monster_gesture_timer = 0.0
	runtime.monster_pounce_windup = 0.0
	runtime.monster_pounce_timer = 0.0
	runtime.monster_pounce_recovery_timer = 0.0
	runtime.monster_strike_timer = 0.0
	runtime.player_in_safe_light = false
	for state in ["patrol", "chase"]:
		runtime.monster_state = state
		var speed: float = runtime.MONSTER_PATROL_SPEED if state == "patrol" else runtime.MONSTER_CHASE_SPEED
		runtime.creature_visual_last_position = runtime.monster_root.global_position + runtime.monster_root.global_basis.z * speed / 60.0
		runtime.creature_visual_last_yaw = runtime.monster_root.rotation.y
		runtime._animate_amalgam(1.0 / 60.0, 1.0)
		if String(runtime.monster_active_animation) != "Locomotion":
			_fail("%s did not select locomotion blend" % state)
		var driver = runtime.creature_animation_driver
		var blend: float = driver.tree.get("parameters/States/Locomotion/Clip/blend_position")
		var tempo: float = driver.playback_rate
		var nominal := lerpf(driver.WALK_SPEED, driver.RUN_SPEED, blend)
		if absf(tempo-clampf(speed/nominal,0.25,1.6)) > 0.01:
			_fail("AnimationTree cadence violates its readable rate bound")
		# Beyond the authored stride, world-space IK must carry displacement;
		# the clip must not be accelerated indefinitely to fake that travel.
		if not driver.feet.active:
			_fail("Locomotion has no world-space foot contact solver")
	if abs(float(runtime.monster_model.position.y) - 0.006) > 0.001 or abs(float(runtime.monster_model.rotation.x)) > 0.001 or abs(float(runtime.monster_model.rotation.z)) > 0.001:
		_fail("Runtime whole-model bob/lean is breaking planted foot contacts")
	runtime.monster_attack_windup = runtime.MONSTER_ATTACK_WINDUP
	runtime._animate_amalgam(1.0 / 60.0, 0.0)
	if String(runtime.monster_active_animation) != "WindUp":
		_fail("Attack preparation did not select WindUp")
	runtime.monster_attack_windup = 0.0
	runtime.monster_state = "suspicious"
	runtime._animate_amalgam(1.0 / 60.0, 0.0)
	if String(runtime.monster_active_animation) != "Alert":
		_fail("Suspicious pause did not select Alert")
	runtime.monster_state = "patrol"
	runtime.monster_current_speed = 0.0
	runtime._animate_amalgam(1.0 / 60.0, 0.0)
	if String(runtime.monster_active_animation) != "Idle":
		_fail("Stationary patrol did not select Idle")

	var corridor := _find_straight_corridor(runtime, 14)
	if corridor.is_empty():
		_fail("No straight corridor was available for movement balance checks")
		_finish()
		return

	var start_cell: Vector2i = corridor["start"]
	var direction: Vector2i = corridor["direction"]
	var world_direction := Vector3(float(direction.x), 0.0, float(direction.y)).normalized()
	var hunter_start: Vector3 = runtime._cell_world(start_cell)
	var player_start: Vector3 = runtime._cell_world(start_cell + direction * 5)

	# Direct sight should build awareness and turn roaming into a real hunt.
	player.set_horror_hidden(false)
	player.global_position = player_start
	runtime.monster_root.global_position = hunter_start
	runtime.monster_root.look_at(player_start, Vector3.UP)
	runtime.monster_last_motion_position = hunter_start
	runtime.monster_state = "patrol"
	runtime.monster_awareness = 0.0
	runtime.monster_current_speed = 0.0
	runtime.monster_path.clear()
	runtime.monster_repath_timer = 0.0
	# Keep this perception test stationary. Otherwise the live search steering can
	# turn the hunter into a side branch while the test is trying to measure only
	# sustained clear sight in the rebuilt, more connected corridor network.
	for _frame in 120:
		player.global_position = player_start
		runtime.monster_root.global_position = hunter_start
		runtime.monster_root.look_at(player_start, Vector3.UP)
		runtime.monster_last_motion_position = hunter_start
		await process_frame
	if String(runtime.monster_state) != "chase":
		_fail("Clear sustained sight did not escalate into a chase; state=%s awareness=%.2f" % [runtime.monster_state, runtime.monster_awareness])
	if int(runtime.monster_expression_variant) < 0 or float(runtime.monster_expression_strength) < 0.5 or not is_instance_valid(runtime.monster_face_light):
		_fail("First player sighting did not activate the authored-face response")
	player.set_horror_hidden(true, player.global_position, player.yaw)
	await _wait_frames(3)
	player.set_horror_hidden(false)
	await _wait_frames(5)
	if float(runtime.monster_expression_strength) < 0.35:
		_fail("Authored-face response faded incorrectly when the player was reacquired")

	# A sound is investigated once, without granting permanent player tracking.
	player.set_horror_hidden(true, player.global_position, player.yaw)
	player.flashlight_on = false
	runtime.monster_state = "patrol"
	runtime.monster_awareness = 0.0
	runtime.monster_has_visual = false
	runtime.monster_visible_time = 0.0
	runtime.monster_reentry_grace_timer = 0.0
	runtime.monster_noise_sense_timer = 0.0
	runtime.monster_hunt_retarget_timer = 0.0
	var noise_position := hunter_start + world_direction * 6.0
	runtime._make_noise(noise_position, 0.82, 0.7)
	# Isolate the memory processor from visual-confidence state left by the prior
	# reacquisition scenario; the normal runtime invokes this from its 0.22 s
	# sensory cadence whenever visual contact is absent.
	runtime._process_best_noise_memory(player)
	await _wait_frames(3)
	# Medium-confidence audio intentionally resolves to a nearby navigation cell,
	# not the player's exact coordinates. Keep the uncertainty within one tile.
	if String(runtime.monster_state) not in ["investigate", "search"] or runtime.monster_last_known_position.distance_to(noise_position) > runtime.TILE + 0.1:
		_fail("Audible event was not investigated: state=%s confidence=%.2f event=%d processed=%d source_delta=%.2f" % [
			runtime.monster_state,
			runtime.monster_search_confidence,
			runtime.noise_event_id,
			runtime.monster_processed_noise_event,
			runtime.monster_last_known_position.distance_to(noise_position)
		])
	player.set_horror_hidden(false)

	# At close-but-not-contact range the hunter should telegraph and commit to
	# its dedicated leap instead of reading as a permanently fast walk.
	var pounce_player_position: Vector3 = runtime._cell_world(start_cell + direction)
	runtime.darkness_time = runtime.DARKNESS_HUNT_DELAY + 0.1
	player.global_position = pounce_player_position
	player.horizontal_velocity = Vector3.ZERO
	player.flashlight_on = false
	runtime.monster_root.global_position = hunter_start
	runtime.monster_root.look_at(pounce_player_position, Vector3.UP)
	runtime.monster_state = "chase"
	runtime.monster_awareness = 1.0
	runtime.monster_has_visual = true
	runtime.monster_visual_confidence = 1.0
	runtime.monster_attack_timer = 0.0
	runtime.monster_attack_windup = 0.0
	runtime.monster_pounce_windup = 0.0
	runtime.monster_pounce_timer = 0.0
	runtime.monster_light_pain = 0.0
	runtime.monster_light_evasion_timer = 0.0
	runtime.predator_attack.cancel(runtime)
	runtime.predator_attack.cooldown = 0.0
	await _wait_frames(3)
	if not runtime.predator_attack.active or runtime.predator_attack.kind!="Heavy":
		_fail("Hunter did not begin its close-range pounce")
	# A walking player should lose ground, so hiding and route choices matter.
	_reset_chase(runtime, player, hunter_start, player_start)
	var walk_before: float = runtime.monster_root.global_position.distance_to(player.global_position)
	await _move_player_for(player, world_direction, PLAYER_WALK_SPEED, 3.0)
	var walk_after: float = runtime.monster_root.global_position.distance_to(player.global_position)
	if walk_after >= walk_before - 0.55:
		_fail("Hunter did not gain meaningful ground on a walking player: %.2f -> %.2f" % [walk_before, walk_after])

	# Sprint must create breathing room during a clean escape line.
	_reset_chase(runtime, player, hunter_start, player_start)
	var sprint_before: float = runtime.monster_root.global_position.distance_to(player.global_position)
	await _move_player_for(player, world_direction, PLAYER_SPRINT_SPEED, 1.45)
	var sprint_after: float = runtime.monster_root.global_position.distance_to(player.global_position)
	if sprint_after <= sprint_before + 0.45:
		_fail("Hunter still matched a sprinting player: %.2f -> %.2f" % [sprint_before, sprint_after])

	# Breaking sight must transition from chase into a local search.
	_reset_chase(runtime, player, hunter_start, player_start)
	player.set_horror_hidden(true, player.global_position, player.yaw)
	await _wait_seconds(runtime.MONSTER_LOST_SIGHT_MAX_TIME + 0.35)
	if String(runtime.monster_state) != "search":
		_fail("Hunter did not search after losing sight; state=%s" % String(runtime.monster_state))
	player.set_horror_hidden(false)

	# Its attack is telegraphed and can be dodged during the windup.
	_reset_chase(runtime, player, hunter_start, hunter_start + world_direction * 1.55)
	var health_before: int = int(player.hp)
	await _wait_frames(2)
	if not runtime.predator_attack.active or runtime.predator_attack.phase!="Windup":
		_fail("Close-range attack did not enter its windup")
	player.global_position += world_direction * 4.0
	await _wait_seconds(0.60)
	if int(player.hp) < health_before:
		_fail("Hunter attack hit after the player escaped its windup range")

	# Patrol should move on its own even before the player triggers it.
	player.set_horror_hidden(true, player.global_position, player.yaw)
	runtime.monster_root.global_position = hunter_start
	runtime.monster_last_motion_position = hunter_start
	runtime.monster_state = "patrol"
	runtime.monster_current_speed = 0.0
	runtime.monster_path.clear()
	runtime.monster_repath_timer = 0.0
	var patrol_before: Vector3 = runtime.monster_root.global_position
	await _wait_seconds(5.0)
	var patrol_distance: float = patrol_before.distance_to(runtime.monster_root.global_position)
	# Patrol is deliberately slower; keep a speed-relative progress floor that
	# allows initial turning. Chase/sprint fairness thresholds above stay fixed.
	if patrol_distance < runtime.MONSTER_PATROL_SPEED * 5.0 * 0.35:
		_fail("Hunter remained effectively stationary on patrol: %.2fm" % patrol_distance)
	player.set_horror_hidden(false)

	# A quiet, unseen locker entry must remain a fair hiding option. The hunter may
	# only open that locker when it actually witnessed or clearly heard the entry.
	var locker := _first_locker(runtime)
	if locker.is_empty():
		_fail("No hide locker was available for stealth behavior checks")
	else:
		var locker_node = locker.get("node")
		var locker_position: Vector3 = locker_node.global_position
		player.set_horror_hidden(true, locker.get("hide_position", locker_position), float(locker.get("hide_yaw", player.yaw)))
		runtime.active_locker = locker
		runtime.monster_root.global_position = locker_position
		runtime.monster_state = "search"
		runtime.monster_saw_locker_entry = false
		runtime.monster_heard_locker_entry = false
		runtime.monster_locker_suspicion = 0.0
		runtime.monster_locker_decision_made = false
		runtime._try_search_active_locker(player, 0.25)
		if not bool(player.horror_hidden):
			_fail("Hunter opened a locker without seeing or hearing the player enter")

		runtime.monster_saw_locker_entry = true
		runtime.monster_locker_suspicion = 1.0
		runtime.monster_locker_decision_made = false
		runtime._try_search_active_locker(player, 0.1)
		runtime.monster_locker_check_timer = 0.0
		runtime._try_search_active_locker(player, 0.1)
		if bool(player.horror_hidden) or not runtime.active_locker.is_empty():
			_fail("Hunter did not open a locker after the entry was explicitly witnessed")

	_finish()


func _find_straight_corridor(runtime, required_cells: int) -> Dictionary:
	for start_cell: Vector2i in runtime.monster_open_cells:
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var step_direction: Vector2i = direction
			var clear := true
			for step in range(required_cells):
				var cell: Vector2i = start_cell + step_direction * step
				if not runtime.monster_navigation.is_in_boundsv(cell) or runtime.monster_navigation.is_point_solid(cell):
					clear = false
					break
			if clear:
				var start_world: Vector3 = runtime._cell_world(start_cell) + Vector3.UP
				var end_world: Vector3 = runtime._cell_world(start_cell + step_direction * (required_cells - 1)) + Vector3.UP
				clear = runtime._grid_has_clear_line(start_world, end_world)
				# Grid centres alone miss thin props between cells. This fixture
				# needs a genuinely uninterrupted body-width sprint lane.
				clear = clear and runtime._monster_motion_segment_valid(start_world-Vector3.UP,end_world-Vector3.UP)
			if clear:
				return {"start": start_cell, "direction": step_direction}
	return {}


func _first_locker(runtime) -> Dictionary:
	for item in runtime.interactables:
		if String(item.get("action", "")) == "hide_locker" and is_instance_valid(item.get("node")):
			return item
	return {}


func _reset_chase(runtime, player, hunter_position: Vector3, player_position: Vector3) -> void:
	runtime.predator_attack.cancel(runtime)
	runtime.predator_attack.cooldown = 0.0
	runtime.creature_light_state = "clear"
	runtime.creature_light_clear_time = 0.0
	runtime.creature_retreat_path.clear()
	runtime.monster_strike_timer = 0.0
	runtime.creature_beam_hold = 0.0
	runtime.monster_pounce_recovery_timer = 0.0
	runtime.monster_motion_velocity = Vector3.ZERO
	runtime.monster_steering_direction = Vector3.ZERO
	runtime.monster_turn_velocity = 0.0
	runtime.monster_pounce_windup = 0.0
	runtime.monster_pounce_timer = 0.0
	player.flashlight_on = false
	runtime.darkness_time = runtime.DARKNESS_HUNT_DELAY + 0.1
	player.set_horror_hidden(false)
	player.global_position = player_position
	player.horizontal_velocity = Vector3.ZERO
	player.flashlight_on = false
	runtime.monster_motion_velocity = Vector3.ZERO
	runtime.monster_steering_direction = Vector3.ZERO
	runtime.monster_turn_velocity = 0.0
	runtime.monster_pounce_windup = 0.0
	runtime.monster_pounce_timer = 0.0
	runtime.monster_root.global_position = hunter_position
	runtime.monster_root.look_at(player_position, Vector3.UP)
	runtime.monster_last_motion_position = hunter_position
	runtime.monster_last_known_position = player_position
	runtime.monster_state = "chase"
	runtime.monster_state_timer = 10.0
	runtime.monster_awareness = 1.0
	runtime.monster_has_visual = true
	runtime.monster_lost_sight_timer = 0.0
	runtime.monster_attack_timer = 0.0
	runtime.monster_attack_windup = 0.0
	runtime.monster_current_speed = 0.0
	runtime.monster_path.clear()
	runtime.monster_repath_timer = 0.0


func _move_player_for(player, direction: Vector3, speed: float, duration: float) -> void:
	var frames := ceili(duration * 60.0)
	for _frame in frames:
		player.global_position += direction * speed / 60.0
		await physics_frame


func _wait_seconds(duration: float) -> void:
	await _wait_frames(ceili(duration * 60.0))


func _wait_frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _fail(reason: String) -> void:
	failures.append(reason)
	push_error(reason)


func _finish() -> void:
	if failures.is_empty():
		print("HORROR_HUNTER_REGRESSION_OK")
		quit(0)
	else:
		print("HORROR_HUNTER_REGRESSION_FAILED: %s" % str(failures))
		quit(1)
