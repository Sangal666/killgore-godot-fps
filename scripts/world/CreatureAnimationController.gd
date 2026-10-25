extends Node
## Visual-only driver for CorridorCreatureRig. Navigation owns root movement.
## The live hunter supplies measured displacement and authoritative AI state.

const CLIPS: Array[StringName] = [&"Idle", &"Alert", &"Walk", &"Run", &"TurnLeft", &"TurnRight", &"LightStop", &"Retreat", &"WindUp", &"Attack", &"Recovery", &"Blocked"]
const WALK_SPEED := 0.22 * 1.7 / (0.9 * 0.64)
const RUN_SPEED := 0.36 * 1.7 / (0.48 * 0.64)
const RETREAT_SPEED := 0.18 * 1.7 / (0.8 * 0.64)

var tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var skeleton: Skeleton3D
var current_state: StringName = &"Idle"
var state_seconds := 0.0
var actual_speed := 0.0
var head_index := -1
var neck_index := -1
var strike_bones: Array[int] = []
var gaze := 0.0
var head_clock := 0.0
var head_stride := 0.0
var head_motion := Vector3.ZERO
var neck_motion := Vector3.ZERO
var head_speed := 0.0
var behavior_intent: StringName = &"Idle"
var heavy_attack := false
var upper_body_pitch := 0.0
var target_distance := 10.0
var target_visible := false
var target_pitch := 0.0
var attack_kind := "Quick"
var action_weight := 0.0
var action_playback: AnimationNodeStateMachinePlayback
var action_clip: StringName = &""
var expression = preload("res://scripts/world/CreatureExpressionLayer.gd").new()
var ready_for_animation := false
var playback_rate := 1.0
var authored_poses: Array[Transform3D] = []
var feet = preload("res://scripts/world/CreatureFootPlant.gd").new()

func configure_terrain(manager: Node) -> void:
	feet.setup(skeleton,manager)
	feet.support_recovery_enabled = true

func pounce_pose(progress: float) -> void:
	# Push from the rear legs, gather them in flight, then let the authored
	# contact clip take over. No frozen WindUp pose carried through the air.
	if progress >= 0.70: return
	var push := sin(clampf(progress/0.20,0.0,1.0)*PI)
	var tuck := sin(clampf((progress-0.12)/0.58,0.0,1.0)*PI)
	for side in ["L","R"]:
		for number in range(1,5):
			var index := skeleton.find_bone("Leg%s%d_Upper" % [side,number])
			var rest := skeleton.get_bone_global_rest(index).basis
			var axis := (rest.inverse()*Vector3.RIGHT).normalized()
			var angle := tuck*0.23-push*(0.18 if number >= 3 else 0.06)
			skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index)*Quaternion(axis,angle))

func ground_visual(delta: float, velocity: Vector3, turn_rate: float, pitch: float, lean: float, crouch: float) -> void:
	var grounded := action_weight < 0.15 and current_state not in [&"WindUp", &"Attack"]
	var body := skeleton.find_bone("Body")
	if body >= 0:
		var basis := skeleton.get_bone_global_rest(body).basis
		var offset := Quaternion((basis.inverse()*Vector3.RIGHT).normalized(),clampf(pitch + upper_body_pitch,-0.12,0.12)) * Quaternion((basis.inverse()*Vector3.FORWARD).normalized(),clampf(lean,-1,1)*0.07)
		skeleton.set_bone_pose_rotation(body,skeleton.get_bone_pose_rotation(body)*offset)
		var position := skeleton.get_bone_pose_position(body)
		# Parent space is root space, converted through its global orientation.
		var parent_basis := skeleton.get_bone_global_pose(skeleton.get_bone_parent(body)).basis
		position += parent_basis.inverse()*Vector3.DOWN*clampf(crouch,0,1)*0.045
		skeleton.set_bone_pose_position(body,position)
		expression.apply_rotation(skeleton,body,expression.body_angles)
		expression.apply_translation(skeleton,body,expression.body_offset)
	feet.advance(delta,grounded,velocity,turn_rate)

func _timed_node(animation: AnimationNode) -> AnimationNodeBlendTree:
	var timed := AnimationNodeBlendTree.new()
	timed.add_node(&"Clip", animation)
	timed.add_node(&"Rate", AnimationNodeTimeScale.new())
	timed.connect_node(&"Rate", 0, &"Clip")
	timed.connect_node(&"output", 0, &"Rate")
	return timed

func setup(player: AnimationPlayer, bones: Skeleton3D) -> bool:
	if player == null or bones == null:
		push_error("Creature rig requires AnimationPlayer and Skeleton3D")
		return false
	for clip in CLIPS:
		if not player.has_animation(clip):
			push_error("Creature rig missing animation: %s" % clip)
			return false
	skeleton = bones
	head_index = bones.find_bone("Head")
	neck_index = bones.find_bone("Neck")
	for bone_name in ["FootL1", "FootR1"]:
		var index := bones.find_bone(bone_name)
		if index < 0:
			push_error("Creature rig missing strike marker: %s" % bone_name)
			return false
		strike_bones.append(index)
	if head_index < 0 or neck_index < 0:
		push_error("Creature rig missing Head/Neck bones")
		return false
	for clip in CLIPS:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if clip in [&"Idle", &"Walk", &"Run", &"Retreat", &"Blocked", &"TurnLeft", &"TurnRight"] else Animation.LOOP_NONE
	player.stop()
	var actions := preload("res://scripts/world/CreatureActionLibrary.gd").new().install(player,bones)
	var machine := AnimationNodeStateMachine.new()
	var states: Array[StringName] = []
	for clip in CLIPS:
		if clip in [&"Walk", &"Run"]:
			continue
		var node := AnimationNodeAnimation.new()
		node.animation = &"Idle" if clip in [&"WindUp",&"Attack",&"Recovery"] else clip
		machine.add_node(clip, _timed_node(node))
		states.append(clip)
	var locomotion := AnimationNodeBlendSpace1D.new()
	locomotion.min_space = 0.0
	locomotion.max_space = 1.0
	locomotion.sync = true
	var walk := AnimationNodeAnimation.new()
	walk.animation = &"Walk"
	var run := AnimationNodeAnimation.new()
	run.animation = &"Run"
	locomotion.add_blend_point(walk, 0.0)
	locomotion.add_blend_point(run, 1.0)
	machine.add_node(&"Locomotion", _timed_node(locomotion))
	states.append(&"Locomotion")
	for from_state in states:
		for to_state in states:
			if from_state == to_state:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.045 if to_state in [&"Attack", &"Blocked"] else 0.14
			machine.add_transition(from_state, to_state, transition)
	var graph := AnimationNodeBlendTree.new()
	graph.add_node(&"States", machine)
	var action_states := AnimationNodeStateMachine.new()
	for clip in actions:
		var node := AnimationNodeAnimation.new()
		node.animation = clip
		action_states.add_node(clip,node)
	for a in actions:
		for b in actions:
			if a==b: continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.08
			action_states.add_transition(a,b,transition)
	graph.add_node(&"Actions",action_states)
	graph.add_node(&"ActionBlend",AnimationNodeBlend2.new())
	graph.connect_node(&"ActionBlend",0,&"States")
	graph.connect_node(&"ActionBlend",1,&"Actions")
	# State transitions always use real seconds. Only the clip inside a state
	# changes rate; outgoing and incoming clips keep independent clocks.
	graph.connect_node(&"output", 0, &"ActionBlend")
	tree = AnimationTree.new()
	tree.name = "CreatureAnimationTree"
	add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.root_node = tree.get_path_to(player.get_node(player.root_node))
	tree.tree_root = graph
	tree.deterministic = true
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.active = true
	playback = tree.get("parameters/States/playback")
	playback.start(&"Idle")
	action_playback = tree.get("parameters/Actions/playback")
	action_playback.start(&"PredatorQuickWindup")
	ready_for_animation = true
	return true

func advance_visual(delta: float, requested: StringName, speed: float, look_yaw: float = 0.0, turn_speed: float = 1.0, clip_tempo: float = 1.0) -> void:
	if not ready_for_animation or delta <= 0.0:
		return
	actual_speed = maxf(speed, 0.0)
	if requested != current_state:
		current_state = requested
		state_seconds = delta
		playback.travel(requested)
	else:
		state_seconds += delta
	var tempo := 1.0
	if requested == &"Locomotion":
		var blend := clampf(inverse_lerp(WALK_SPEED, RUN_SPEED, actual_speed), 0.0, 1.0)
		tree.set("parameters/States/Locomotion/Clip/blend_position", blend)
		tempo = clampf(actual_speed / lerpf(WALK_SPEED, RUN_SPEED, blend), 0.25, 1.6)
	elif requested == &"Retreat":
		tempo = clampf(actual_speed / RETREAT_SPEED, 0.25, 1.6)
	elif requested in [&"TurnLeft", &"TurnRight"]:
		tempo = clampf(absf(turn_speed), 0.4, 1.5)
	else:
		tempo = clip_tempo
	playback_rate = tempo
	tree.set("parameters/States/%s/Rate/scale" % requested, tempo)
	var action_phase := "Windup" if requested==&"WindUp" else ("Strike" if requested==&"Attack" else ("Recover" if requested==&"Recovery" else ""))
	if not action_phase.is_empty():
		var next := StringName("Predator%s%s" % [attack_kind,action_phase])
		if next != action_clip:
			action_clip = next
			if action_phase=="Windup" and action_weight<0.15: action_playback.start(next)
			else: action_playback.travel(next)
	else:
		action_clip = &""
	action_weight = move_toward(action_weight,1.0 if not action_phase.is_empty() else 0.0,delta*7.5)
	tree.set("parameters/ActionBlend/blend_amount",action_weight)
	# Imported constant tracks may be optimized away. Restore last authored
	# poses before advancing, otherwise post-animation IK/gaze/crouch accumulates.
	for index in authored_poses.size():
		skeleton.set_bone_pose(index,authored_poses[index])
	tree.advance(delta)
	authored_poses.clear()
	for index in skeleton.get_bone_count():
		authored_poses.append(skeleton.get_bone_pose(index))
	_update_head_motion(delta, look_yaw, turn_speed)

func _update_head_motion(delta: float, look_yaw: float, _turn_speed: float) -> void:
	head_clock += delta
	head_stride += delta*clampf(actual_speed*5.0,0.0,12.0)
	var stride := sin(head_stride)
	if feet.active:
		stride = sin(clampf(feet.swing_time/feet.swing_duration,0,1)*PI)*(1.0 if feet.group==0 else -1.0) if feet.moving else 0.0
	gaze = lerpf(gaze,clampf(look_yaw,-0.72,0.72),1.0-exp(-delta*9.0))
	expression.advance(delta,behavior_intent,gaze,target_pitch,target_distance,target_visible,action_weight,stride)
	expression.apply_head(skeleton,head_index,neck_index)
	head_motion = expression.head
	neck_motion = expression.neck
	upper_body_pitch = 0.0

func strike_touches(player_position: Vector3) -> bool:
	if not ready_for_animation:
		return false
	for index in strike_bones:
		var point := skeleton.to_global(skeleton.get_bone_global_pose(index).origin)
		var flat := Vector2(point.x - player_position.x, point.z - player_position.z)
		if flat.length() <= 0.48 and point.y >= player_position.y - 0.42 and point.y <= player_position.y + 1.3:
			return true
	return false
