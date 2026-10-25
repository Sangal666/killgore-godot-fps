extends RefCounted
## Visual-only world-space contacts. Never moves the navigation/body root.
## Two alternating tetrapods; three-link FABRIK preserves each authored knee.
var skeleton: Skeleton3D
var terrain: WeakRef
var legs: Array[Dictionary] = []
var last_origin := Vector3.INF
var group := 0
var swing_time := 0.0
var swing_duration := 0.22
var moving := false
var weight := 0.0
var active := false
var planted_error := 0.0
var clearance_scale := 1.0
var support_recovery_enabled := false
var support_steps := 0

func setup(bones: Skeleton3D, manager: Node) -> void:
	skeleton = bones
	terrain = weakref(manager)
	for side in ["L", "R"]:
		for number in range(1,5):
			var ids: Array[int] = []
			for suffix in ["Upper", "Lower", "Tip"]:
				ids.append(bones.find_bone("Leg%s%d_%s" % [side,number,suffix]))
			ids.append(bones.find_bone("Foot%s%d" % [side,number]))
			if ids.has(-1):
				push_error("Creature foot plant: incomplete limb")
				legs.clear()
				return
			var lengths: Array[float] = []
			for j in 3:
				lengths.append(bones.get_bone_global_rest(ids[j]).origin.distance_to(bones.get_bone_global_rest(ids[j+1]).origin))
			legs.append({"ids":ids,"lengths":lengths,"rest":bones.get_bone_global_rest(ids[3]).origin,
				"support_age":-1.0,"support_from":Vector3.ZERO,"support_to":Vector3.ZERO,
				"group":(number + (1 if side == "R" else 0)) % 2,"anchor":Vector3.ZERO,
				"from":Vector3.ZERO,"to":Vector3.ZERO,"swing":false})

func _ground(point: Vector3, fallback: Vector3) -> Vector3:
	var manager = terrain.get_ref()
	if manager == null: return fallback
	# Gameplay uses custom grid/AABB collision, so the physics ray is followed
	# by the same terrain oracle used by the player when no collider exists.
	if manager.is_blocked_world(point + Vector3.UP * 0.12, 0.075): return fallback
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.65,point - Vector3.UP * 1.25)
	var hit: Dictionary = skeleton.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and Vector3(hit.normal).dot(Vector3.UP) > 0.7:
		return Vector3(hit.position) + Vector3(hit.normal) * 0.012
	point.y = manager.floor_height_at(point) + 0.012
	return point

func _neutral(leg: Dictionary, origin: Vector3) -> Vector3:
	var point := skeleton.to_global(Vector3(leg.rest))
	# Contract the stance next to props/walls; never put a target inside one.
	for contraction in [1.0,0.8,0.6,0.4]:
		var candidate := origin.lerp(point,contraction)
		candidate.y = origin.y
		var grounded := _ground(candidate,Vector3.INF)
		if grounded != Vector3.INF:
			clearance_scale = minf(clearance_scale,contraction)
			return grounded
	return Vector3(leg.anchor)

func advance(dt: float, enabled: bool, velocity: Vector3, turn_rate: float) -> void:
	if legs.is_empty(): return
	clearance_scale = 1.0
	var origin := skeleton.global_position
	var reset := last_origin == Vector3.INF or origin.distance_to(last_origin) > 2.0
	last_origin = origin
	if reset or (enabled and not active):
		for leg in legs:
			leg.anchor = _ground(skeleton.to_global(Vector3(leg.rest)),origin)
			leg.from = leg.anchor
			leg.to = leg.anchor
			leg.swing = false
			leg.support_age = -1.0
		moving = false
		weight = 0.0
	active = enabled
	weight = move_toward(weight,1.0 if enabled else 0.0,dt*8.0)
	if weight <= 0.0: return
	var speed := velocity.length()
	if enabled and not moving:
		var needs_step := false
		for leg in legs:
			if int(leg.group) == group and Vector3(leg.anchor).distance_to(_neutral(leg,origin)) > 0.16:
				needs_step = true
		if needs_step:
			moving = true
			swing_time = 0.0
			swing_duration = clampf(0.27-maxf(speed,absf(turn_rate)*1.5)*0.038,0.15,0.27)
			for leg in legs:
				leg.swing = int(leg.group) == group or float(leg.support_age)>=0.0
				if not leg.swing: continue
				leg.from = leg.anchor
				var neutral := _neutral(leg,origin)
				var radius := neutral-origin
				var angular_velocity := Vector3.UP.cross(radius)*turn_rate
				# Land ahead of the future hip, leaving equal reach for the next
				# stance. A one-swing prediction landed under the hip and overextended
				# the trailing leg by the time its partner group finished stepping.
				var lead := (velocity+angular_velocity)*(swing_duration*1.55)
				lead = lead.limit_length(1.12)
				leg.to = _ground(neutral+lead,neutral)
		else:
			# Let the other tetrapod request a step while stationary/pivoting.
			group = 1-group
	if moving:
		swing_time += dt
		var t := clampf(swing_time/swing_duration,0.0,1.0)
		for leg in legs:
			if not leg.swing: continue
			# Re-predict only airborne feet when the body brakes or turns. Keeping
			# an old running touchdown after a stop stretched a leg past its reach.
			var neutral := _neutral(leg,origin)
			var angular_velocity := Vector3.UP.cross(neutral-origin)*turn_rate
			var remaining := maxf(0.0,swing_duration-swing_time)
			var predicted := neutral+(velocity+angular_velocity)*(remaining+swing_duration*0.55)
			var hip := skeleton.to_global(skeleton.get_bone_global_pose(leg.ids[0]).origin)+velocity*remaining
			var reach: float = (leg.lengths[0]+leg.lengths[1]+leg.lengths[2])*0.94
			var horizontal := Vector3(predicted.x-hip.x,0,predicted.z-hip.z)
			var horizontal_reach := sqrt(maxf(0.01,reach*reach-pow(hip.y-neutral.y,2)))
			horizontal = horizontal.limit_length(horizontal_reach)
			predicted = Vector3(hip.x+horizontal.x,neutral.y,hip.z+horizontal.z)
			leg.to = _ground(predicted,leg.to)
			leg.anchor = Vector3(leg.from).lerp(Vector3(leg.to),smoothstep(0.0,1.0,t)) + Vector3.UP * sin(t*PI) * lerpf(0.09,0.17,clampf(speed/3.2,0,1))
		if t >= 1.0:
			moving = false
			group = 1-group
			for leg in legs: leg.swing = float(leg.support_age)>=0.0
	# Large torso changes/abrupt cornering can exhaust a planted leg's reach
	# before its normal alternating group comes around. Lift and replant a
	# maximum of two support feet; never drag an impossible anchor along the floor.
	if enabled and support_recovery_enabled:
		var supporting := 0
		for leg in legs:
			if float(leg.support_age)>=0: supporting+=1
		for leg in legs:
			var hip := skeleton.to_global(skeleton.get_bone_global_pose(leg.ids[0]).origin)
			var reach: float = (leg.lengths[0]+leg.lengths[1]+leg.lengths[2])*0.94
			if not leg.swing and float(leg.support_age)<0 and supporting<2 and hip.distance_to(leg.anchor)>reach:
				leg.support_age = 0.0
				leg.support_from = leg.anchor
				var target := _neutral(leg,origin)+velocity*0.08
				leg.support_to = _ground(target,_neutral(leg,origin))
				leg.swing = true
				supporting+=1
				support_steps+=1
			if float(leg.support_age)>=0:
				leg.support_age += dt
				var u := clampf(float(leg.support_age)/0.14,0,1)
				leg.anchor = Vector3(leg.support_from).lerp(leg.support_to,smoothstep(0,1,u))+Vector3.UP*sin(u*PI)*0.08
				if u>=1:
					leg.support_age = -1.0
					leg.swing = false
	planted_error = 0.0
	for leg in legs:
		_solve(leg,skeleton.to_local(Vector3(leg.anchor)),weight)
		if not leg.swing:
			planted_error = maxf(planted_error,skeleton.to_global(skeleton.get_bone_global_pose(leg.ids[3]).origin).distance_to(leg.anchor))

func _solve(leg: Dictionary, target: Vector3, blend: float) -> void:
	var ids: Array = leg.ids
	var points: Array[Vector3] = []
	for index in ids: points.append(skeleton.get_bone_global_pose(index).origin)
	var hip := points[0]
	var total: float = leg.lengths[0]+leg.lengths[1]+leg.lengths[2]
	target = hip + (target-hip).limit_length(total*0.98)
	# FABRIK uses the current authored knee plane as its starting shape. Segment
	# lengths never change; only rotations are written back to the existing rig.
	for iteration in 24:
		points[3] = target
		for j in range(2,-1,-1): points[j] = points[j+1]+(points[j]-points[j+1]).normalized()*float(leg.lengths[j])
		points[0] = hip
		for j in 3: points[j+1] = points[j]+(points[j+1]-points[j]).normalized()*float(leg.lengths[j])
		if points[3].distance_squared_to(target) < 0.00000001: break
	for j in 3:
		var index: int = ids[j]
		var pose := skeleton.get_bone_global_pose(index)
		var old_direction := skeleton.get_bone_global_pose(ids[j+1]).origin-pose.origin
		var new_direction := points[j+1]-points[j]
		if old_direction.length_squared() < 0.00001 or new_direction.length_squared() < 0.00001: continue
		var change := Quaternion(old_direction.normalized(),new_direction.normalized())
		var parent_basis := skeleton.get_bone_global_pose(skeleton.get_bone_parent(index)).basis
		var local_basis := parent_basis.inverse()*Basis(change)*pose.basis
		var rotation := local_basis.orthonormalized().get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index).slerp(rotation,blend))
