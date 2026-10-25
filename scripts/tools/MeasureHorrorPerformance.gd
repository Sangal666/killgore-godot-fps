extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	change_scene_to_file("res://Main.tscn")
	for i in 8:
		await process_frame
	var main = current_scene
	var runtime = main.level_manager.horror_runtime
	var player = main.player
	player.set_process_input(false)
	player.yaw=0.0
	player.target_yaw=0.0
	player.pitch=0.0
	player.target_pitch=0.0
	main.set_physics_process(false)
	var start := Time.get_ticks_usec()
	for i in 100:
		main.level_manager.is_blocked_world(player.global_position,0.85)
	print("PROFILE_COLLISION_100_MS ",(Time.get_ticks_usec()-start)/1000.0," SOLIDS ",main.level_manager.solid_areas.size())
	start=Time.get_ticks_usec()
	runtime.flashlight_blocking_player=player
	runtime._repath_amalgam(player.global_position)
	print("PROFILE_REPATH_MS ",(Time.get_ticks_usec()-start)/1000.0," PATH ",runtime.monster_path.size())
	main.set_physics_process(true)
	for i in 120: await process_frame
	var walking := OS.get_environment("HORROR_PERF_WALK")=="1"
	var route: Array = runtime.dark_crossings.crossings[0].fast
	var waypoint := 1
	if walking:
		player.global_position=route[0]+Vector3.UP*0.48
	var samples: Array[float]=[]
	var last := Time.get_ticks_usec()
	for i in 90:
		if walking and waypoint<route.size():
			var delta: Vector3=route[waypoint]+Vector3.UP*0.48-player.global_position
			if delta.length()<0.18:
				waypoint+=1
			else:
				player._try_move(delta.normalized()*minf(delta.length(),0.08))
				player.target_yaw=atan2(-delta.x,-delta.z)
				player.yaw=player.target_yaw
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now-last)/1000.0)
		last=now
	var total := 0.0
	for value in samples:
		total+=value
	samples.sort()
	print("PROFILE_LIVE_FPS ",90000.0/total," P95_MS ",samples[85]," PHYSICS_MS ",Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
	main.set_physics_process(false)
	for section in ["player","runtime","monster","navigation"]:
		start=Time.get_ticks_usec()
		for i in 20:
			if section=="player": player.tick(1.0/60.0)
			if section=="runtime": runtime.tick(1.0/60.0,player)
			if section=="monster": runtime._tick_amalgam(1.0/60.0,player)
			if section=="navigation": runtime._repath_amalgam(player.global_position)
		print("PROFILE_SECTION ",section," MS ",(Time.get_ticks_usec()-start)/20000.0)
	last=Time.get_ticks_usec()
	for i in 60:
		await process_frame
	print("PROFILE_RENDER_ONLY_FPS ",60000000.0/(Time.get_ticks_usec()-last))
	print("PROFILE_DRAW_CALLS ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," OBJECTS ",Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("/private/tmp/horror-perf-"+OS.get_environment("HORROR_PERF_LABEL")+".png")
	quit()
