extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	set_meta("killgore_start_level", 13)
	set_meta("killgore_level_select", true)
	set_meta("killgore_random_seed", 1337)
	change_scene_to_file("res://Main.tscn")
	for frame in 12: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	var p = main.player
	var r = main.level_manager.horror_runtime
	var cycles = r.light_cycles
	p.set_process_input(false)
	p.set_physics_process(false)
	p.set_developer_mode(false)
	main._sync_developer_night_vision()
	p.flashlight_on = false
	p._update_horror_flashlight_visibility()
	r.flashlight_blocking_player = p
	var kinds := {}
	var dynamic := {}
	for e in cycles.entries:
		kinds[e.kind] = int(kinds.get(e.kind, 0)) + 1
		dynamic[e.index] = true
	print("LIGHT_CYCLE_LAYOUT total=", r.route_light_positions.size(), " types=", kinds)
	for kind in ["regular", "warning", "irregular", "trap"]:
		check(kinds.has(kind), "Missing light kind: " + kind)
	check(kinds.get("trap", 0) == 1, "Trap must be rare")
	check(dynamic.size() <= r.route_light_positions.size() / 4, "Too many dynamic lights")
	for e in cycles.entries:
		for neighbor in cycles.neighbors[e.index]:
			check(not dynamic.has(neighbor), "Adjacent refuges both dynamic")
	# Six simulated minutes: material, rendered light and safety agree.
	var seen := {}
	for frame in 3600:
		cycles.tick(0.1, p)
		for e in cycles.entries:
			seen[e.kind + ":" + e.state] = true
			check(e.light.light_energy >= 0.0 and e.light.light_energy <= 24.001, "Unbounded relight energy")
			if e.state == "off":
				check(not r._monster_position_in_warding_light(e.ward.position), "Dark pool still wards")
				check(is_zero_approx(e.light.light_energy) and is_zero_approx(e.material.emission_energy_multiplier), "Off fixture still emits")
	for kind in kinds:
		for state in ["on", "warning", "off", "relight"]:
			check(seen.has(kind + ":" + state), "Untested phase " + kind + ":" + state)
	var encounter: Dictionary = cycles.entries[0]
	p.global_position = encounter.ward.position
	p.hp = 100
	p.hp_float = 100.0
	p.armor = 0
	p.armor_float = 0.0
	p.dodge_immunity_timer = 0.0
	r.darkness_time = 0.0
	encounter.state = "warning"
	encounter.time = encounter.duration
	cycles.tick(0.01, p)
	var approach_found := false
	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var start: Vector3 = p.global_position + direction * 4.0
		if not r._monster_motion_segment_valid(start, p.global_position): continue
		r.monster_root.position = start
		r.monster_root.look_at(p.global_position)
		r.monster_state = "patrol"
		r.monster_awareness = 0.0
		r.monster_has_visual = false
		r.monster_visual_confidence = 0.0
		r.monster_reentry_grace_timer = 0.0
		r.monster_attack_timer = 0.0
		r.monster_motion_velocity = Vector3.ZERO
		r.monster_current_speed = 0.0
		r.creature_light_state = "clear"
		for frame in 480:
			r.tick(1.0 / 60.0, p)
			if frame < 230: check(p.hp == 100, "Blackout caused damage before reaction grace")
			if p.hp < 100: break
		check(p.hp < 100, "Creature failed to attack inside extinguished refuge")
		approach_found = true
		print("BLACKOUT_ENCOUNTER hp=", p.hp, " darkness=", r.darkness_time)
		break
	check(approach_found, "No valid blackout encounter approach")
	p.hp = 100
	p.hp_float = 100.0
	# Force each topology through an extinguish/relight with creature inside.
	for e in cycles.entries:
		p.global_position = e.ward.position
		r.darkness_time = 0.0
		e.state = "warning"
		e.time = e.duration
		cycles.tick(0.01, p)
		r._tick_darkness_and_batteries(0.1, p)
		check(r.darkness_time < r.DARKNESS_HUNT_DELAY, "No reaction time on blackout")
		var cell: Vector2i = r._world_cell(e.ward.position)
		if not main.level_manager.is_blocked_world(e.ward.position + Vector3.UP * 0.48, r.MONSTER_BODY_RADIUS):
			check(not r.monster_navigation.is_point_solid(cell), "Extinguished pool remains navigation-solid")
		p.global_position = e.ward.position + Vector3(8, 0, 0)
		r.monster_root.position = e.ward.position
		r.monster_motion_velocity = Vector3.ZERO
		r.monster_current_speed = 0.0
		r.creature_light_state = "clear"
		e.state = "relight"
		e.time = 0.45
		e.duration = 0.85
		cycles.tick(0.01, p)
		check(r.monster_navigation.is_point_solid(cell), "Relit pool missing navigation exclusion")
		for frame in 240:
			r._hold_ceiling_light_boundary(1.0 / 60.0, p)
		check(not r._monster_position_in_warding_light(r.monster_root.position, r.MONSTER_BODY_RADIUS), "Creature trapped inside relit pool index=" + str(e.index))
		print("RELIGHT_ESCAPE index=", e.index, " moved=", r.monster_root.position.distance_to(e.ward.position))
	if OS.get_environment("LIGHT_CYCLES_CAPTURE") == "1":
		main.transition.hide()
		var e: Dictionary = cycles.entries[0]
		p.global_position = e.ward.position + Vector3(0, 0, 5.0)
		p.camera.position = p.camera_base_position
		p.camera.look_at(e.ward.position + Vector3.UP * 1.5)
		for state in ["on", "warning", "off", "relight"]:
			e.state = state
			e.time = 0.3 if state == "relight" else 0.4
			e.duration = 4.0
			cycles.tick(0.01, p)
			for frame in 6: await process_frame
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png("/private/tmp/light_cycle_%s.png" % state)
	if failures == 0: print("HORROR_LIGHT_CYCLES_OK")
	main.queue_free()
	for frame in 4: await process_frame
	quit(1 if failures else 0)
