extends RefCounted
## Committed, collision-checked action with one contact gate and recovery.
const TIMINGS = preload("res://scripts/world/CreatureActionLibrary.gd").TIMINGS
var active := false
var kind := "Quick"
var phase := ""
var age := 0.0
var hit := false
var start := Vector3.ZERO
var target := Vector3.ZERO
var direction := Vector3.FORWARD
var side := Vector3.RIGHT
var cooldown := 0.0
var last_kind := ""
var interrupted_landing := 0.0

func allowed(r, p) -> bool:
	return not bool(p.horror_cinematic_locked) and r.creature_light_state=="clear" and r.creature_dark_approach_time<=0.0 and not bool(p.horror_hidden) and not r._monster_position_in_warding_light(p.global_position) and r.darkness_time>=r.DARKNESS_HUNT_DELAY and r._handheld_light_depth(r.monster_root.global_position,r.MONSTER_BODY_RADIUS)<=0.0

func begin(r, p, selection: String) -> bool:
	if active or not allowed(r,p): return false
	start = r.monster_root.global_position
	direction = p.global_position-start
	direction.y = 0.0
	if direction.length_squared()<0.001: return false
	direction = direction.normalized()
	side = Vector3(-direction.z,0,direction.x)
	kind = selection
	var gap: float = start.distance_to(p.global_position)
	target = p.global_position-direction*r.MONSTER_CAMERA_CLEARANCE
	if kind=="Quick": target=start+direction*minf(0.18,maxf(0.0,gap-r.MONSTER_CAMERA_CLEARANCE))
	if kind=="Side": target += side*0.35
	target.y = start.y
	# Reject an action before telegraphing if its whole swept body would cross
	# any prop, wall, ceiling refuge or flashlight. Side motion needs extra room.
	var previous := start
	for sample in range(1,17):
		var u := float(sample)/16.0
		var point := start.lerp(target,u)
		if kind=="Side": point += side*sin(u*PI)*0.55
		if not r._monster_motion_segment_valid(previous,point): return false
		previous = point
	active = true
	interrupted_landing = 0.0
	phase = "Windup"
	age = 0.0
	hit = false
	last_kind = kind
	r.monster_current_speed = 0.0
	r.monster_motion_velocity = Vector3.ZERO
	r.monster_path.clear()
	r.monster_pounce_visual_arc = 0.0
	return true

func cancel(r) -> void:
	if not active: return
	active = false
	phase = ""
	age = 0.0
	cooldown = maxf(cooldown,0.8)
	interrupted_landing = r.monster_pounce_visual_arc
	r.monster_current_speed = 0.0
	r.monster_motion_velocity = Vector3.ZERO
	r.monster_repath_timer = 0.0

func settle_interruption(r, dt: float) -> void:
	if interrupted_landing>0:
		interrupted_landing = move_toward(interrupted_landing,0,dt*3.0)
		r.monster_pounce_visual_arc = interrupted_landing

func tick(r, dt: float, p) -> bool:
	cooldown = maxf(0,cooldown-dt)
	if not active: return false
	if not allowed(r,p):
		cancel(r)
		return false
	age += dt
	var duration: float = TIMINGS[kind][["Windup","Strike","Recover"].find(phase)]
	var u := clampf(age/duration,0.0,1.0)
	if phase=="Windup":
		# Commitment is readable; the target does not magically track a dodge.
		var focus: Vector3 = p.global_position-r.monster_root.global_position
		r.monster_root.rotation.y = lerp_angle(r.monster_root.rotation.y,atan2(-focus.x,-focus.z),1.0-exp(-dt*5.0))
	elif phase=="Strike":
		var point := start.lerp(target,smoothstep(0.0,0.85,u))
		if kind=="Side": point += side*sin(u*PI)*0.55
		var gap: Vector3 = point-p.global_position
		gap.y = 0
		if gap.length()<r.MONSTER_CAMERA_CLEARANCE:
			point = p.global_position+gap.normalized()*r.MONSTER_CAMERA_CLEARANCE
		if r._monster_motion_segment_valid(r.monster_root.global_position,point):
			r.monster_root.global_position = point
		else:
			phase = "Recover"
			age = 0.0
			u = 0.0
		if kind=="Heavy" and phase=="Strike": r.monster_pounce_visual_arc=sin(u*PI)*0.35
		else: r.monster_pounce_visual_arc=move_toward(r.monster_pounce_visual_arc,0,dt*3.0)
	else:
		r.monster_pounce_visual_arc = move_toward(r.monster_pounce_visual_arc,0,dt*3.0)
	r._animate_amalgam(dt,0.0)
	# Extended claws can reach the cone before the body envelope does. Treat
	# that as a light interruption before opening the physical contact gate.
	if phase=="Strike":
		for index in r.creature_animation_driver.strike_bones:
			var point: Vector3 = r.monster_skeleton.to_global(r.monster_skeleton.get_bone_global_pose(index).origin)
			if r._position_in_handheld_light(point,0.08):
				cancel(r)
				r.creature_light_state = "flinch"
				r.creature_light_clear_time = 0.0
				r.creature_light_state_time = 0.0
				r.creature_beam_hold = 0.12
				r.stalk_director.enter()
				return true
	var contact := Vector2(0.13,0.29) if kind=="Quick" else (Vector2(0.38,0.56) if kind=="Heavy" else Vector2(0.20,0.39))
	if phase=="Strike" and not hit and age>=contact.x and age<=contact.y:
		if r.creature_animation_driver.strike_touches(p.global_position) and r._grid_has_clear_line(r.monster_root.global_position+Vector3.UP*0.7,p.global_position+Vector3.UP*0.4):
			hit = true
			p.damage(34 if kind=="Quick" else (28 if kind=="Heavy" else 30))
			if p.has_method("add_shake"): p.add_shake(0.08 if kind=="Quick" else 0.12)
	if age>=duration:
		age = 0.0
		if phase=="Windup": phase="Strike"
		elif phase=="Strike": phase="Recover"
		else:
			active = false
			phase = ""
			cooldown = 0.6 if hit else 1.0
			r.monster_repath_timer = 0.0
	return true
