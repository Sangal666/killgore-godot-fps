extends RefCounted
## Nine authored skeletal sequences, baked from anatomical foot targets.
## This does not rescale/reuse the imported Attack or locomotion clips.
const TIMINGS := {
	"Quick": [0.48, 0.42, 0.72],
	"Heavy": [0.72, 0.68, 1.10],
	"Side": [0.64, 0.52, 0.90]
}
var bones: Skeleton3D
var rest: Array[Transform3D] = []
var legs: Array[Dictionary] = []
var solver = preload("res://scripts/world/CreatureFootPlant.gd").new()

func install(player: AnimationPlayer, skeleton: Skeleton3D) -> Array[StringName]:
	bones = skeleton
	solver.skeleton = bones
	for index in bones.get_bone_count(): rest.append(bones.get_bone_rest(index))
	for side in ["L", "R"]:
		for number in range(1,5):
			var ids: Array[int] = []
			for suffix in ["Upper", "Lower", "Tip"]: ids.append(bones.find_bone("Leg%s%d_%s" % [side,number,suffix]))
			ids.append(bones.find_bone("Foot%s%d" % [side,number]))
			var lengths: Array[float] = []
			for j in 3: lengths.append(bones.get_bone_global_rest(ids[j]).origin.distance_to(bones.get_bone_global_rest(ids[j+1]).origin))
			var foot := bones.get_bone_global_rest(ids[3]).origin
			foot.y = 0.012
			legs.append({"ids":ids,"lengths":lengths,"foot":foot,"side":side,"number":number})
	var library: AnimationLibrary = player.get_animation_library(&"")
	var clips: Array[StringName] = []
	var path := player.get_node(player.root_node).get_path_to(bones)
	for kind in TIMINGS:
		for phase in ["Windup", "Strike", "Recover"]:
			var name := StringName("Predator%s%s" % [kind,phase])
			var animation := Animation.new()
			var phase_index := ["Windup","Strike","Recover"].find(phase)
			animation.length = TIMINGS[kind][phase_index]
			for index in bones.get_bone_count():
				for type in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D]:
					var track := animation.add_track(type)
					animation.track_set_path(track,NodePath("%s:%s" % [path,bones.get_bone_name(index)]))
			var count := ceili(animation.length*40.0)
			for frame in range(count+1):
				var u := float(frame)/count
				pose(kind,phase,u)
				for index in bones.get_bone_count():
					var position := bones.get_bone_pose_position(index)
					var rotation := bones.get_bone_pose_rotation(index)
					var count_position := animation.track_get_key_count(index*2)
					var count_rotation := animation.track_get_key_count(index*2+1)
					if count_position==0 or not position.is_equal_approx(animation.track_get_key_value(index*2,count_position-1)):
						animation.track_insert_key(index*2,u*animation.length,position)
					if count_rotation==0 or rotation.angle_to(animation.track_get_key_value(index*2+1,count_rotation-1))>0.00001:
						animation.track_insert_key(index*2+1,u*animation.length,rotation)
			library.add_animation(name,animation)
			clips.append(name)
	for index in rest.size(): bones.set_bone_pose(index,rest[index])
	return clips

func rotate(name: String, angles: Vector3) -> void:
	var index := bones.find_bone(name)
	var inverse := bones.get_bone_global_rest(index).basis.inverse()
	var q := Quaternion((inverse*Vector3.UP).normalized(),angles.y)*Quaternion((inverse*Vector3.RIGHT).normalized(),angles.x)*Quaternion((inverse*Vector3.FORWARD).normalized(),angles.z)
	bones.set_bone_pose_rotation(index,rest[index].basis.get_rotation_quaternion()*q)

func translate(name: String, offset: Vector3) -> void:
	var index := bones.find_bone(name)
	var parent := bones.get_bone_parent(index)
	var basis := bones.get_bone_global_rest(parent).basis if parent>=0 else Basis.IDENTITY
	bones.set_bone_pose_position(index,rest[index].origin+basis.inverse()*offset)

func pose(kind: String, phase: String, u: float) -> void:
	for index in rest.size(): bones.set_bone_pose(index,rest[index])
	var load := smoothstep(0.0,1.0,u) if phase=="Windup" else (1.0-smoothstep(0.0,0.45,u) if phase=="Strike" else 0.0)
	var hit := sin(smoothstep(0.0,0.70,u)*PI) if phase=="Strike" else 0.0
	if kind=="Heavy" and phase=="Strike": hit=sin(smoothstep(0.40,1.0,u)*PI)
	var settle := (1.0-smoothstep(0.0,1.0,u)) if phase=="Recover" else 0.0
	var body_drop := -load*0.12
	var pitch := -load*0.16+hit*0.18+settle*0.10
	var twist := 0.0
	if kind=="Heavy":
		body_drop = -load*0.20 + hit*0.09 - settle*0.14
		pitch = -load*0.24+hit*0.30+settle*0.16
	elif kind=="Side":
		twist = -load*0.30 + hit*0.38 + settle*0.12
		body_drop = -load*0.10-settle*0.07
	rotate("Body",Vector3(pitch*0.40,twist*0.45,0.0))
	translate("Body",Vector3(0,body_drop,hit*0.07))
	rotate("SpineFront",Vector3(pitch*0.60,twist*0.55,hit*0.07 if kind=="Side" else 0.0))
	rotate("SpineRear",Vector3(-pitch*0.35,-twist*0.30,0))
	rotate("Abdomen",Vector3(-pitch*0.25,0,-twist*0.20))
	rotate("Neck",Vector3(-load*0.13+hit*0.15, -twist*0.4,settle*0.04))
	rotate("Head",Vector3(-load*0.17+hit*0.26,-twist*0.4,-hit*0.08))
	translate("Neck",Vector3(0,-load*0.035,hit*0.05))
	for leg in legs:
		var foot: Vector3 = leg.foot
		var number: int = leg.number
		var sign_x := -1.0 if leg.side=="L" else 1.0
		if number==1:
			if phase=="Windup":
				foot += Vector3(-sign_x*load*0.14,load*0.35,-load*0.20)
			elif phase=="Strike":
				# A scissoring rake has a deliberately staggered left/right contact.
				var strike_u := clampf(u-(0.12 if leg.side=="R" and kind=="Quick" else 0.0),0.0,1.0)
				var reach := sin(smoothstep(0.0,0.78,strike_u)*PI)
				if kind=="Heavy": reach=sin(smoothstep(0.40,1.0,strike_u)*PI)
				var target := Vector3(sign_x*0.12,0.42,1.32)
				if kind=="Heavy": target=Vector3(sign_x*0.20,0.28,1.28)
				if kind=="Side": target=Vector3(lerpf(-0.65,0.55,smoothstep(0.05,0.70,u)),0.48,1.22)
				foot = foot.lerp(target,reach)
				foot.y += load*0.25
			elif phase=="Recover": foot += Vector3(-sign_x*settle*0.10,settle*0.18,settle*0.12)
		elif number==2:
			# Second pair braces then tears forward: not just two arms attacking.
			foot += Vector3(-sign_x*hit*0.20,hit*0.28,hit*0.38)
		elif kind=="Heavy" and phase=="Strike":
			# Rear legs extend off the ground on launch, then gather for landing.
			foot += Vector3(-sign_x*hit*0.16,hit*0.30,-sin(u*PI)*0.18)
		else:
			foot.z -= load*0.08
		# Same anatomical three-link solver; authored attack targets are independent
		# of the grounded locomotion anchors, which resume after recovery.
		solver._solve(leg,foot,1.0)
