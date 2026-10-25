extends SceneTree
## Actual level fixtures. Capture uses an external inspection light/camera only.
var failures := 0
var r
var p
var main
var capture := false
var camera: Camera3D
var fill: OmniLight3D
var directory := "/private/tmp/killgore_predator_encounters_20261014"
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func position_camera() -> void:
	for offset in [Vector3(0.8,1.35,-2.8),Vector3(-0.8,1.35,-2.8),Vector3(0,1.25,-2.3)]:
		var point: Vector3 = r.monster_root.to_global(offset)
		if not r.level_manager.is_blocked_world(point,0.1) and r._grid_has_clear_line(point,r.monster_root.global_position+Vector3.UP*0.70):
			camera.global_position = point
			break
	camera.look_at(r.monster_root.global_position+Vector3.UP*0.65)
	fill.global_position = camera.global_position+Vector3.UP*0.5
func dark_fixture(gap: float, narrow: bool=false, decor: bool=false, wide: bool=false) -> Array[Vector3]:
	for cell in r.monster_open_cells:
		var a: Vector3 = r._cell_world(cell)
		for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
			var b: Vector3 = a+direction*gap
			if not r._monster_motion_segment_valid(a,b): continue
			if not r._grid_has_clear_line(a+Vector3.UP,b+Vector3.UP): continue
			var side := Vector3(-direction.z,0,direction.x)
			if narrow and not (r.level_manager.is_blocked_world(a+side*2.2,0.32) and r.level_manager.is_blocked_world(a-side*2.2,0.32)): continue
			if wide and (r.level_manager.is_blocked_world(a+side*2.6,0.32) or r.level_manager.is_blocked_world(a-side*2.6,0.32)): continue
			if decor:
				var has_prop := false
				for solid in r.level_manager.query_solid_areas(a-Vector3(3,0,3),a+Vector3(3,0,3)):
					if bool(solid.get("dark_crossing",false)): has_prop=true
				if not has_prop: continue
			return [a,b]
	return []
func decor_fixture() -> Array[Vector3]:
	for crossing in r.dark_crossings.crossings:
		var bay: Node3D = crossing.node
		if bay.name=="KitchenMaintenanceBypass": continue
		var a := bay.to_global(Vector3(0,0,-4.0))
		var b := bay.to_global(Vector3(0,0,4.0))
		if r._monster_motion_position_valid(a) and r._monster_motion_position_valid(b): return [a,b]
	return []
func ceiling_fixture() -> Array[Vector3]:
	for ward in r.monster_warding_lights:
		if ward.has("cycle_active") or not ward.get("safe_zone",false): continue
		var b: Vector3 = ward.position
		for step in 16:
			var angle := step*TAU/16.0
			var a: Vector3 = b+Vector3(cos(angle),0,sin(angle))*(float(ward.radius)+r.MONSTER_BODY_RADIUS+0.25)
			if r._monster_motion_position_valid(a) and r._grid_has_clear_line(a+Vector3.UP,b+Vector3.UP): return [a,b]
	return []
func reset(fixture: Array[Vector3]) -> void:
	p.global_position = fixture[1]
	p.horizontal_velocity = Vector3.ZERO
	p.hp = 1000
	p.hp_float = 1000.0
	p.damage_flash = 0.0
	p.flashlight_on = false
	p.horror_battery_seconds = 100.0
	p.camera.global_position = p.global_position+Vector3.UP*1.36
	p._update_horror_flashlight_visibility()
	r.flashlight_blocking_player = p
	r.predator_attack.cancel(r)
	r.predator_attack.cooldown = 0.0
	r.predator_attack.last_kind = ""
	r.creature_light_state = "clear"
	r.creature_light_clear_time = 0.0
	r.creature_dark_approach_time = 0.0
	r.creature_beam_hold = 0.0
	r.ceiling_escape_active = false
	r.boundary_watch_active = false
	r.boundary_watch_age = 0.0
	r.boundary_plan_timer = 0.0
	r.monster_attack_timer = 0.0
	r.monster_attack_windup = 0.0
	r.monster_strike_timer = 0.0
	r.monster_pounce_timer = 0.0
	r.monster_pounce_windup = 0.0
	r.monster_pounce_recovery_timer = 0.0
	r.monster_reentry_grace_timer = 0.0
	r.monster_search_pause = 0.0
	r.monster_root.global_position = fixture[0]
	r.monster_root.look_at(fixture[1])
	r.monster_motion_velocity = Vector3.ZERO
	r.monster_steering_direction = Vector3.ZERO
	r.monster_current_speed = 0.0
	r.monster_path.clear()
	r.creature_retreat_path.clear()
	r.monster_repath_timer = 0.0
	r.monster_state = "chase"
	r.monster_has_visual = true
	r.monster_awareness = 1.0
	r.monster_visual_confidence = 1.0
	r.darkness_time = 6.0
	r.creature_visual_last_position = fixture[0]
	r.creature_visual_last_yaw = r.monster_root.rotation.y
	if capture:
		camera.global_position = r.monster_root.to_global(Vector3(2.3,1.5,-3.5))
		camera.look_at(r.monster_root.global_position+Vector3.UP*0.75)
		fill.global_position = r.monster_root.to_global(Vector3(0,2,-2))
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	change_scene_to_file("res://Main.tscn")
	for frame in 40: await process_frame
	main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	main.transition.hide()
	p = main.player
	p.set_physics_process(false)
	p.set_process_input(false)
	p.developer_mode = false
	p.paused = false
	p.set_horror_hidden(false)
	r = main.level_manager.horror_runtime
	capture = OS.get_environment("PREDATOR_CAPTURE")=="1"
	if capture:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280,720)
		camera = Camera3D.new()
		main.add_child(camera)
		camera.current = true
		camera.cull_mask &= ~p.HORROR_FLASHLIGHT_VIEWMODEL_LAYER
		camera.fov = 52
		fill = OmniLight3D.new()
		fill.light_energy = 1.8
		fill.omni_range = 10.0
		main.add_child(fill)
		main.hud.hide()
		DirAccess.make_dir_recursive_absolute(directory)
	var modes := ["detect","approach","close","Quick","Heavy","Side","open_stalk","narrow_stalk","release","battery_empty","ceiling","decor","interrupt","heavy_interrupt"]
	if not OS.get_environment("PREDATOR_SCENARIOS").is_empty(): modes=Array(OS.get_environment("PREDATOR_SCENARIOS").split(","))
	for mode in modes:
		var gap := 1.6 if mode in ["Quick","close","interrupt"] else (2.2 if mode=="Side" else (8.0 if mode=="detect" else 5.0))
		var fixture := ceiling_fixture() if mode=="ceiling" else dark_fixture(gap,mode=="narrow_stalk",mode=="decor",mode=="open_stalk")
		if mode=="decor": fixture=decor_fixture()
		check(not fixture.is_empty(),"Missing actual fixture: "+mode)
		if fixture.is_empty(): continue
		reset(fixture)
		if mode=="detect":
			r.monster_has_visual = false
			r.creature_previous_visual = false
			r.monster_awareness = 0.35
			r.monster_state = "suspicious"
		if mode in ["approach","release","battery_empty"]: r.creature_dark_approach_time=1.4
		if mode in ["Quick","Heavy","Side","interrupt","heavy_interrupt"]:
			var kind: String = "Quick" if mode=="interrupt" else ("Heavy" if mode=="heavy_interrupt" else mode)
			check(r.predator_attack.begin(r,p,kind),"Rejected attack fixture "+mode)
		var states := {}
		var phases := {}
		var max_step := 0.0
		var head_low := INF
		var head_high := -INF
		var dynamic_contact := 0.0
		var stance_error := 0.0
		var previous_model_height: float = r.monster_model.position.y
		for frame in 300:
			var t := frame/60.0
			if mode=="decor":
				var direction: Vector3 = (fixture[1]-fixture[0]).normalized()
				var side := Vector3(-direction.z,0,direction.x)
				var proposed: Vector3 = fixture[1]+side*sin(t*1.1)*0.9
				if not r.level_manager.is_blocked_world(proposed,0.3): p.global_position=proposed
				p.camera.global_position = p.global_position+Vector3.UP*1.36
			p.flashlight_on = mode in ["open_stalk","narrow_stalk"] or (mode in ["release","battery_empty"] and t<2.0) or (mode=="interrupt" and t>0.20) or (mode=="heavy_interrupt" and t>0.95)
			p.camera.look_at(r.monster_root.global_position+Vector3.UP*0.80)
			if mode=="open_stalk": p.camera.rotation.y += sin(t*1.3)*0.12
			if mode=="battery_empty" and t>=2.0:
				p.horror_battery_seconds = 0.0
				p.flashlight_on = true
			p._update_horror_flashlight_visibility()
			p._tick_horror_flashlight(1.0/60.0)
			var before: Vector3 = r.monster_root.global_position
			r.tick(1.0/60.0,p)
			if mode=="heavy_interrupt":
				check(absf(r.monster_model.position.y-previous_model_height)<0.08,"Interrupted lunge dropped in one frame")
			previous_model_height = r.monster_model.position.y
			max_step = maxf(max_step,before.distance_to(r.monster_root.global_position))
			var feet = r.creature_animation_driver.feet
			if feet.active and feet.weight>0.99 and r.creature_animation_driver.action_weight<0.01:
				stance_error = maxf(stance_error,feet.planted_error)
			states[r.creature_threat_state] = true
			phases[r.predator_attack.phase] = true
			var head_id: int = r.monster_skeleton.find_bone("Head")
			var h: float = r.monster_skeleton.get_bone_global_pose(head_id).origin.y
			head_low = minf(head_low,h)
			head_high = maxf(head_high,h)
			check(not r.level_manager.is_blocked_world(r.monster_root.global_position+Vector3.UP*0.48,r.MONSTER_BODY_RADIUS),"Body penetration "+mode)
			var position: Vector3 = r.monster_root.global_position
			var inside_cycle := false
			for ward in r.monster_warding_lights:
				if not bool(ward.get("safe_zone",false)) or not bool(ward.get("cycle_active",true)): continue
				if position.distance_to(ward.position)>=float(ward.radius)+r.MONSTER_BODY_RADIUS-0.02: continue
				if not r._grid_has_clear_line(position+Vector3.UP*0.5,Vector3(ward.position)+Vector3.UP*0.5): continue
				if ward.has("cycle_active"): inside_cycle=true
				else: check(false,"Fixed ward penetration "+mode)
			dynamic_contact = dynamic_contact+1.0/60.0 if inside_cycle else 0.0
			check(dynamic_contact<1.8,"Failed to leave a relit dynamic ward "+mode)
			if mode in ["open_stalk","narrow_stalk","ceiling","interrupt","heavy_interrupt"]: check(p.hp==1000,"Light defense damage "+mode)
			if mode in ["release","battery_empty"] and t<3.3: check(p.hp==1000,"Unfair release damage "+mode)
			if capture and frame%6==0:
				position_camera()
				await process_frame
				RenderingServer.force_draw(false)
				root.get_texture().get_image().save_jpg(directory+"/%s_%03d.jpg" % [mode,frame/6],0.88)
		if mode in ["Quick","Heavy","Side"]:
			check(phases.has("Windup") and phases.has("Strike") and phases.has("Recover"),"Missing action stages "+mode)
			check(p.hp<1000,"No physical attack contact "+mode)
		if mode in ["open_stalk","narrow_stalk"]: check(max_step<0.04,"Fast or forced stalk motion")
		check(stance_error<0.01,"Planted foot exceeds support reach in "+mode)
		print("ENCOUNTER ",mode," states=",states," phases=",phases," head_height=",head_low,"..",head_high," max_step=",max_step," hp=",p.hp," stance_error=",stance_error)
	main.queue_free()
	for frame in 4: await process_frame
	if failures==0: print("PREDATOR_ENCOUNTERS_OK")
	quit(1 if failures else 0)
