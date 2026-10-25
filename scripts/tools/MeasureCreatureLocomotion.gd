extends SceneTree
## Baseline telemetry. Does not change production resources or claim visual QA.
const DT := 1.0 / 60.0
var samples: Array = []
func _initialize() -> void: call_deferred("run")
func foot_positions(skeleton: Skeleton3D) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for side in ["L", "R"]:
		for leg in range(1,5):
			var index := skeleton.find_bone("Foot%s%d" % [side,leg])
			result.append(skeleton.to_global(skeleton.get_bone_global_pose(index).origin))
	return result
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	change_scene_to_file("res://Main.tscn")
	for frame in 5: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	var player = main.player
	player.set_process_input(false)
	player.paused = false
	var r = main.level_manager.horror_runtime
	var skeleton: Skeleton3D = r.monster_skeleton
	var metadata := {"model":r.MONSTER_MODEL_PATH,"skeleton_path":str(skeleton.get_path()),"bones":skeleton.get_bone_count(),"tree_path":str(r.creature_animation_driver.tree.get_path()),"clips":{},"scenarios":{}}
	for clip in r.monster_animation_player.get_animation_list():
		metadata.clips[clip] = r.monster_animation_player.get_animation(clip).length
	var bay: Node3D = r.dark_crossings.crossings[0].node
	for scenario in ["patrol","suspicious","investigate","search","stalk","chase","flee_light","turn","beam"]:
		r.monster_state = "chase" if scenario in ["turn","beam"] else scenario
		r.monster_root.global_position = bay.to_global(Vector3(1.5,0,-6.5))
		r.monster_root.rotation.y = bay.rotation.y + PI
		if scenario == "turn": r.monster_root.rotation.y += PI * 0.5
		r.creature_visual_last_position = r.monster_root.global_position
		r.creature_visual_last_yaw = r.monster_root.rotation.y
		r.monster_current_speed = 0.0
		r.monster_motion_velocity = Vector3.ZERO
		r.monster_steering_direction = Vector3.ZERO
		r.monster_turn_velocity = 0.0
		r.creature_beam_hold = 0.0
		r.creature_light_state = "clear"
		r.creature_light_clear_time = 0.0
		r.creature_retreat_path.clear()
		r.creature_animation_driver.feet.last_origin = Vector3.INF
		r.monster_path.clear()
		r.monster_path.append(Vector2i.ZERO)
		r.monster_path_index = 1
		r.monster_path_endpoint = bay.to_global(Vector3(1.5,0,6.5))
		player.global_position = bay.to_global(Vector3(1.5,0.48,-11))
		player.camera.global_position = player.global_position + Vector3.UP * 1.17
		player.camera.look_at(r.monster_root.global_position + Vector3.UP * 0.8)
		player.flashlight_on = scenario == "beam"
		player._update_horror_flashlight_visibility()
		r.flashlight_blocking_player = player
		r.player_in_safe_light = false
		var previous_feet := foot_positions(skeleton)
		var previous_stance: Array[bool] = [false,false,false,false,false,false,false,false]
		var planted_slip := 0.0
		var planted_samples := 0
		var peak_plant_error := 0.0
		var speed_sum := 0.0
		var peak_speed := 0.0
		var peak_tempo := 0.0
		var slip_sum := 0.0
		var contact_samples := 0
		var peak_heading_error := 0.0
		var transitions := 0
		var previous_state := ""
		for frame in 240:
			var before: Vector3 = r.monster_root.global_position
			var desired: float = r._monster_state_speed(15.0)
			if scenario == "beam":
				player.camera.look_at(r.monster_root.global_position + Vector3.UP * 0.8)
				player._tick_horror_flashlight(DT)
				if not r._hold_flashlight_boundary(DT,player): r._animate_amalgam(DT,0.0)
			else:
				r.monster_current_speed = move_toward(r.monster_current_speed,desired,4.8*DT)
				r._advance_monster_motion(DT,player,desired)
				r._animate_amalgam(DT,0.0)
			var delta: Vector3 = r.monster_root.global_position - before
			var speed := delta.length()/DT
			var error := 0.0
			if speed > 0.1:
				error = rad_to_deg(acos(clampf(delta.normalized().dot(-r.monster_root.global_basis.z),-1,1)))
			var feet := foot_positions(skeleton)
			var frame_slip := 0.0
			for leg in feet.size():
				var contacts = r.creature_animation_driver.feet
				var stance: bool = contacts.weight > 0.99 and not contacts.legs[leg].swing
				if stance and previous_stance[leg]:
					planted_slip += feet[leg].distance_to(previous_feet[leg])
					planted_samples += 1
				previous_stance[leg] = stance
				if contacts.weight > 0.99: peak_plant_error = maxf(peak_plant_error,contacts.planted_error)
				# Existing rig has no stance flags. This is explicitly a ground-height
				# proxy, not proof that a foot is in the authored stance interval.
				if feet[leg].y < 0.045 and previous_feet[leg].y < 0.045:
					var slip := Vector2(feet[leg].x-previous_feet[leg].x,feet[leg].z-previous_feet[leg].z).length()
					frame_slip += slip
					slip_sum += slip
					contact_samples += 1
			previous_feet = feet
			var state: String = r.monster_active_animation
			if previous_state != "" and previous_state != state: transitions += 1
			previous_state = state
			var tempo := float(r.creature_animation_driver.playback_rate)
			speed_sum += speed
			peak_speed = maxf(peak_speed,speed)
			peak_tempo = maxf(peak_tempo,tempo)
			peak_heading_error = maxf(peak_heading_error,error)
			samples.append({"scenario":scenario,"frame":frame,"position":[r.monster_root.position.x,r.monster_root.position.y,r.monster_root.position.z],"yaw":r.monster_root.rotation.y,"ai":r.monster_state,"animation":state,"speed":speed,"tempo":tempo,"heading_error_degrees":error,"ground_proxy_slip_m":frame_slip})
		metadata.scenarios[scenario] = {"mean_speed":speed_sum/240.0,"peak_speed":peak_speed,"peak_tempo":peak_tempo,"peak_heading_error_degrees":peak_heading_error,"animation_transitions":transitions,"ground_proxy_mean_slip_speed":slip_sum/maxf(1,contact_samples)/DT,"ground_proxy_samples":contact_samples}
		metadata.scenarios[scenario]["planted_slip_speed"] = planted_slip/maxi(1,planted_samples)/DT
		metadata.scenarios[scenario]["peak_plant_error"] = peak_plant_error
		print("LOCOMOTION_BASELINE ",scenario," ",JSON.stringify(metadata.scenarios[scenario]))
		await process_frame
	var output := OS.get_environment("CREATURE_METRICS_OUTPUT")
	if output.is_empty(): output = "/private/tmp/creature_baseline_20261005.json"
	var file := FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"metadata":metadata,"samples":samples},"\t"))
	file.close()
	print("CREATURE_METRICS_CAPTURED ",output)
	# Release the active looping audio before immediate headless shutdown.
	main.queue_free()
	for frame in 4: await process_frame
	quit()
