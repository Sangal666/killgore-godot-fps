extends RefCounted
## Intent, attention and posture, independent from clip time and navigation.
var clock := 0.0
var intent: StringName = &"Idle"
var intent_age := 0.0
var head := Vector3.ZERO
var neck := Vector3.ZERO
var neck_offset := Vector3.ZERO
var body_offset := Vector3.ZERO
var body_angles := Vector3.ZERO
var attention := 0.0
var scan := 0.0
var weight := 1.0

func advance(dt: float, desired: StringName, yaw: float, look_pitch: float, distance: float, seen: bool, action_weight: float, stride: float) -> void:
	clock += dt
	if desired != intent:
		intent = desired
		intent_age = 0.0
	intent_age += dt
	attention = lerpf(attention,1.0 if seen or desired in [&"FlashlightStalk",&"LightBoundary"] else 0.0,1.0-exp(-dt*8.0))
	# Listen, hold, then glance. Two incommensurate phases avoid a metronomic loop.
	var listening := smoothstep(0.2,0.65,sin(clock*0.67))
	var scan_target := listening*sin(clock*0.31+0.7)*0.32
	scan = lerpf(scan,scan_target,1.0-exp(-dt*2.4))
	var breathing := sin(clock*1.9+sin(clock*0.29)*0.35)
	var h := Vector3(look_pitch*0.6,yaw*0.70,breathing*0.025)
	var n := Vector3(look_pitch*0.4,yaw*0.30,0)
	var position := Vector3.ZERO
	var torso := Vector3.ZERO
	var angles := Vector3.ZERO
	match desired:
		&"Idle", &"Patrol":
			h.x += breathing*0.02
			h.y += scan*(1.0-attention)
			n.y += scan*0.4*(1.0-attention)
			position.y = breathing*0.018
		&"Alert":
			# A visible lift and short stillness announces target acquisition.
			var lock := sin(clampf(intent_age/0.55,0.0,1.0)*PI)
			position = Vector3(0,0.075+lock*0.025,0.06)
			h.x -= 0.16
			torso.y = 0.015
			angles.x = -0.025
		&"Search":
			h.y += scan*0.7
			position = Vector3(0,0.025,0.045)
		&"Chase", &"CloseHunt", &"Reacquire":
			var near := 1.0-smoothstep(2.0,7.0,distance)
			position = Vector3(0,-0.035-near*0.06,0.045+near*0.07)
			h.x += 0.085+near*0.06
			torso = Vector3(0,-near*0.07,0.025)
			angles.x = 0.06+near*0.045
			h.z -= stride*0.045
		&"FlashlightStalk":
			position = Vector3(0,0.06,-0.07)
			h.x -= 0.20
			n.x -= 0.085
			torso.y = -0.055
			angles.x = -0.085
			h.z += sin(clock*0.83)*0.045
		&"LightBoundary":
			position = Vector3(0,-0.02,-0.10)
			h.x -= 0.26
			n.x -= 0.10
			h.y += listening*sin(clock*0.49)*0.16
			torso.y = -0.09
			angles.x = -0.10
		&"Recover":
			position.y = -0.03+breathing*0.025
		&"Retreat":
			position = Vector3(0,0.025,-0.06)
			h.x -= 0.18
	h.x -= angles.x*0.70
	n.x -= angles.x*0.30
	h.x = clampf(h.x,-0.32,0.32)
	h.y = clampf(h.y,-0.53,0.53)
	n.y = clampf(n.y,-0.24,0.24)
	# Action graph owns the complete attack pose. Expression gives it priority,
	# then returns gradually through the same weights on a light interruption.
	weight = lerpf(weight,1.0-action_weight,1.0-exp(-dt*12.0))
	var response := 17.0 if desired==&"Alert" and intent_age<0.3 else 6.0
	head = head.lerp(h*weight,1.0-exp(-dt*response))
	neck = neck.lerp(n*weight,1.0-exp(-dt*4.5))
	neck_offset = neck_offset.lerp(position*weight,1.0-exp(-dt*5.0))
	body_offset = body_offset.lerp(torso*weight,1.0-exp(-dt*4.0))
	body_angles = body_angles.lerp(angles*weight,1.0-exp(-dt*4.0))

func apply_rotation(bones: Skeleton3D, index: int, angles: Vector3) -> void:
	var inverse := bones.get_bone_global_rest(index).basis.inverse()
	var q := Quaternion((inverse*Vector3.UP).normalized(),angles.y)*Quaternion((inverse*Vector3.RIGHT).normalized(),angles.x)*Quaternion((inverse*Vector3.FORWARD).normalized(),angles.z)
	bones.set_bone_pose_rotation(index,bones.get_bone_pose_rotation(index)*q)

func apply_translation(bones: Skeleton3D, index: int, offset: Vector3) -> void:
	var parent := bones.get_bone_parent(index)
	var basis := bones.get_bone_global_pose(parent).basis if parent>=0 else Basis.IDENTITY
	bones.set_bone_pose_position(index,bones.get_bone_pose_position(index)+basis.inverse()*offset)

func apply_head(bones: Skeleton3D, head_id: int, neck_id: int) -> void:
	apply_rotation(bones,neck_id,neck)
	apply_rotation(bones,head_id,head)
	apply_translation(bones,neck_id,neck_offset)
	apply_translation(bones,head_id,Vector3(0,neck_offset.y*0.35,neck_offset.z*0.25))
