extends SceneTree
## Native project window/render settings, no readback or QA fill light.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	change_scene_to_file("res://Main.tscn")
	for frame in 120: await process_frame
	var main = current_scene
	main.set_process_input(false)
	main.set_process_unhandled_input(false)
	var p = main.player
	p.set_process_input(false)
	p.set_physics_process(false)
	p.hp = 1000
	p.hp_float = 1000.0
	var r = main.level_manager.horror_runtime
	var start := Time.get_ticks_msec()
	var last := Time.get_ticks_usec()
	var durations: Array[float] = []
	var report_second := 0
	while Time.get_ticks_msec()-start < 45000:
		var t := float(Time.get_ticks_msec()-start)/1000.0
		var zone := mini(2,int(t/15.0))*30
		var bay: Node3D = r.dark_crossings.crossings[zone].node
		p.paused = false
		p.global_position = bay.to_global(Vector3(1.5,0.48,-4.0+sin(t*0.4)))
		p.camera.global_position = p.global_position+Vector3.UP*1.17
		p.camera.look_at(bay.to_global(Vector3(sin(t*0.35)*3.0,0.9,3)))
		p.flashlight_on = true
		p.horror_battery_seconds = 100.0
		p._update_horror_flashlight_visibility()
		if r.monster_root.global_position.distance_to(p.global_position)>12.0:
			r.monster_root.global_position = bay.to_global(Vector3(1.5,0,1.5))
			r.monster_state = "chase"
			r.monster_awareness = 1.0
		await process_frame
		var now := Time.get_ticks_usec()
		if t>3.0: durations.append(float(now-last)/1000.0)
		last = now
		if int(t)>=report_second:
			print("PERF_SAMPLE t=",int(t)," fps=",Engine.get_frames_per_second()," zone=",zone)
			report_second += 5
	durations.sort()
	var total := 0.0
	for value in durations: total += value
	print("PERF_RESULT frames=",durations.size()," mean_ms=",total/durations.size()," p95_ms=",durations[int(durations.size()*0.95)]," p99_ms=",durations[int(durations.size()*0.99)]," max_ms=",durations.back()," window=",root.size)
	main.queue_free()
	for frame in 4: await process_frame
	quit()
