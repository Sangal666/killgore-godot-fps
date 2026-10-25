extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	change_scene_to_file("res://Main.tscn")
	for frame in 8: await process_frame
	var main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	var p = main.player
	p.set_physics_process(false)
	p.set_process_input(false)
	p.developer_mode = false
	p.paused = false
	p.set_horror_hidden(false)
	p.hp = 100
	p.hp_float = 100.0
	var r = main.level_manager.horror_runtime
	var found := false
	for cell in r.monster_open_cells:
		var a: Vector3 = r._cell_world(cell)
		var b := a+Vector3.RIGHT*5.0
		if not r._monster_motion_segment_valid(a,b): continue
		if not r._grid_has_clear_line(a+Vector3.UP,b+Vector3.UP): continue
		p.global_position = b
		p.camera.global_position = b+Vector3.UP*1.36
		r.monster_root.global_position = a
		r.monster_root.look_at(b)
		r.monster_state = "chase"
		r.monster_has_visual = true
		r.monster_awareness = 1.0
		r.monster_attack_windup = 0.3
		r.darkness_time = 6.0
		p.flashlight_on = true
		p.horror_battery_seconds = 100.0
		p.camera.look_at(a+Vector3.UP*0.85)
		p._update_horror_flashlight_visibility()
		r.flashlight_blocking_player = p
		if r._handheld_light_depth(a,r.MONSTER_BODY_RADIUS)<=0.0: continue
		var max_gap := 0.0
		var min_gap := INF
		var lateral := 0.0
		for frame in 360:
			p.camera.look_at(r.monster_root.global_position+Vector3.UP*0.85)
			p._tick_horror_flashlight(1.0/60.0)
			var before: Vector3 = r.monster_root.global_position
			r.tick(1.0/60.0,p)
			var after: Vector3 = r.monster_root.global_position
			check(after.distance_to(before)<0.1,"Stalk teleported or lunged")
			check(not r._monster_position_in_warding_light(after),"Stalk entered ceiling refuge")
			check(not r.level_manager.is_blocked_world(after+Vector3.UP*0.48,r.MONSTER_BODY_RADIUS),"Stalk entered geometry")
			check(r.monster_attack_windup<=0.0 and r.monster_strike_timer<=0.0 and r.monster_pounce_timer<=0.0,"Attack active under beam")
			max_gap = maxf(max_gap,after.distance_to(b))
			min_gap = minf(min_gap,after.distance_to(b))
			lateral = maxf(lateral,absf(after.z-a.z))
		check(p.hp==100,"Stalk dealt damage")
		check(max_gap<7.5 and min_gap>2.7,"Stalk failed comfortable range")
		check(p.horror_battery_seconds<100.0,"Stalk stopped battery drain")
		print("STALK_TRACE gap=",min_gap,"..",max_gap," lateral=",lateral," battery=",p.horror_battery_seconds)
		p.flashlight_on = false
		p._update_horror_flashlight_visibility()
		for frame in 90:
			r.tick(1.0/60.0,p)
			check(p.hp==100,"Unfair damage immediately after beam release")
			check(r.monster_strike_timer<=0.0 and r.monster_pounce_timer<=0.0,"Attack skipped release grace")
		check(r.creature_light_state=="clear","Stalk failed to release")
		found = true
		break
	check(found,"No dark stalk fixture")
	main.queue_free()
	for frame in 4: await process_frame
	if failures==0: print("CREATURE_STALK_OK")
	quit(1 if failures else 0)
