extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	change_scene_to_file("res://Main.tscn")
	for i in 180:
		await process_frame
	current_scene.set_physics_process(false)
	var player = current_scene.player
	var runtime = current_scene.level_manager.horror_runtime
	var manager = current_scene.level_manager
	var encounters = runtime.dark_crossings
	check(encounters.omitted.is_empty(),"A light crossing has no route choice")
	player.flashlight_on = false
	player.grounded = true
	for link in encounters.omitted:
		print("UNRESOLVED_LINK ",link.lights," CELLS ",link.cells)
	for crossing in encounters.crossings:
		for lane in ["fast","cover"]:
			var points: Array = crossing[lane]
			player.global_position = points[0] + Vector3.UP * 0.48
			for index in range(1,points.size()):
				var target: Vector3 = points[index] + Vector3.UP * 0.48
				var from: Vector3 = player.global_position
				var steps := maxi(1,ceili(from.distance_to(target)/0.16))
				for step in steps:
					player._try_move((target-player.global_position)/float(steps-step))
					player._resolve_solid_embed()
				check(player.global_position.distance_to(target)<0.18,"Player blocked %s %s segment %d" % [crossing.node.name,lane,index])
				for step in range(steps+1):
					var sample := from.lerp(target,float(step)/steps)
					if manager.is_blocked_world(sample,runtime.MONSTER_BODY_RADIUS):
						check(false,"Spider clearance %s %s at %s" % [crossing.node.name,lane,sample])
						break
	# Drive the actual monster navigation/locomotion around representative bays.
	for crossing_index in [0,encounters.crossings.size()/2,encounters.crossings.size()-1]:
		var crossing: Dictionary = encounters.crossings[int(crossing_index)]
		for lane in ["fast","cover"]:
			var points: Array = crossing[lane]
			runtime.monster_root.global_position = points[1] if points.size()>2 else points[0]
			print("AI_ROUTE ",crossing.node.name," ",lane," POINTS ",points," PLAYER ",player.global_position)
			runtime.monster_state = "chase"
			runtime.monster_motion_velocity = Vector3.ZERO
			runtime.monster_steering_direction = Vector3.ZERO
			runtime.monster_turn_velocity = 0.0
			runtime.monster_root.rotation.y = 0.0
			runtime.monster_current_speed = 3.2
			for index in range(2,points.size()-1):
				if runtime._monster_position_in_warding_light(points[index],runtime.MONSTER_BODY_RADIUS):
					check(not runtime._monster_motion_position_valid(points[index]),"Safe endpoint must exclude spider")
					continue
				runtime._repath_amalgam(points[index])
				var reached := false
				for frame in 480:
					if frame % 30 == 0:
						runtime._repath_amalgam(points[index])
					runtime._advance_monster_motion(1.0/60.0,player,3.2)
					if runtime.monster_root.global_position.distance_to(points[index])<1.25:
						reached=true
						break
				check(reached,"Live spider stuck %s %s waypoint %d at %s" % [crossing.node.name,lane,index,runtime.monster_root.global_position])
				if not reached:
					print("TARGET ",points[index]," SAFE=",runtime._monster_position_in_warding_light(points[index],runtime.MONSTER_BODY_RADIUS)," PATH=",runtime.monster_path," END=",runtime.monster_path_endpoint)
	# Face along a real dark bay. Test source-aligned exclusion, occlusion,
	# swept movement, recoil, attack cancellation and immediate off/empty release.
	var bay: Node3D = encounters.crossings[0].node
	player.global_position = bay.to_global(Vector3(1.5,0.48,-4.0))
	player.camera.global_position = player.global_position + Vector3.UP * 1.17
	player.camera.look_at(player.camera.global_position + bay.basis.z)
	player.horror_battery_seconds = 100.0
	player.flashlight_on = true
	player._update_horror_flashlight_visibility()
	player._tick_horror_flashlight(0.0)
	runtime.flashlight_blocking_player = player
	var inside: Vector3 = bay.to_global(Vector3(1.5,0,1.8))
	check(not runtime._handheld_line_clear(bay.to_global(Vector3(1.5,0.95,0)),bay.to_global(Vector3(-3,0.95,0))),"Thin table leaks beam or melee line of sight")
	check(runtime._position_in_handheld_light(inside,runtime.MONSTER_BODY_RADIUS),"Beam misses its actual lens axis")
	check(not runtime._monster_motion_position_valid(inside),"Spider allowed inside beam")
	check(not runtime._monster_motion_segment_valid(bay.to_global(Vector3(4,0,1.8)),inside),"Swept spider motion tunnels into beam")
	runtime.monster_root.global_position = inside
	runtime.darkness_time = 5.0
	var hp: int = player.hp
	var initial_depth: float = runtime._handheld_light_depth(inside,runtime.MONSTER_BODY_RADIUS)
	for frame in 120:
		runtime._tick_amalgam(1.0/60.0,player)
		runtime._resolve_monster_attack(player)
	check(player.hp==hp,"Beam hold damaged player")
	var recoiled_away: bool = runtime.monster_root.global_position.distance_to(player.global_position) > inside.distance_to(player.global_position) + 0.5
	var escaped_sideways: bool = runtime._handheld_light_depth(runtime.monster_root.global_position,runtime.MONSTER_BODY_RADIUS) < initial_depth
	check(recoiled_away or escaped_sideways,"Spider neither retreated from player nor escaped beam around obstacle")
	player._tick_horror_flashlight(10.0)
	check(absf(player.horror_battery_seconds-84.0)<0.01,"Battery not 60 percent faster")
	player.flashlight_on=false
	check(not runtime._position_in_handheld_light(inside,0.85),"Disabled beam still blocks")
	check(runtime._monster_motion_position_valid(inside),"Switching flashlight off does not release physical barrier")
	player.flashlight_on=true
	player.horror_battery_seconds=0.0
	check(not runtime._position_in_handheld_light(inside,0.85),"Empty beam still blocks")
	check(player.collect_horror_battery() and player.horror_battery_seconds==35.0,"Battery pickup broken")
	print("DARK_CROSSING_FAILURES=",failures.size())
	if failures.is_empty():
		print("HORROR_DARK_CROSSINGS_OK")
	quit(0 if failures.is_empty() else 1)
