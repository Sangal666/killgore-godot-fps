extends SceneTree

const Controller = preload("res://scripts/world/CreatureAnimationController.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func find_type(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child in node.get_children():
		var found := find_type(child, type_name)
		if found != null:
			return found
	return null

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file("res://assets/characters/corridor_creature/corridor_creature.glb", state)
	if error != OK:
		push_error("Missing active creature rig")
		quit(1)
		return
	var model := document.generate_scene(state)
	root.add_child(model)
	var player := find_type(model, "AnimationPlayer") as AnimationPlayer
	var skeleton := find_type(model, "Skeleton3D") as Skeleton3D
	var driver := Controller.new()
	model.add_child(driver)
	if not driver.setup(player, skeleton):
		quit(1)
		return
	check(skeleton.get_bone_count() == 41, "Expected 33 deform/structural bones and 8 foot markers")
	for requested: StringName in [&"Idle", &"Alert", &"Locomotion", &"TurnLeft", &"TurnRight", &"LightStop", &"Retreat", &"WindUp", &"Attack", &"Recovery", &"Blocked"]:
		for frame in 60:
			driver.advance_visual(1.0 / 60.0, requested, 0.8 if requested in [&"Locomotion", &"Retreat"] else 0.0, 0.2)
		if requested in [&"WindUp",&"Attack",&"Recovery"]:
			check(driver.action_playback.get_current_node()==driver.action_clip,"Action layer failed %s" % requested)
		else:
			check(driver.playback.get_current_node() == requested, "AnimationTree failed state %s" % requested)
		for bone in skeleton.get_bone_count():
			check(skeleton.get_bone_pose(bone).is_finite(), "Non-finite creature pose")
		print("CREATURE_TREE_STATE_OK ", requested)
	# The blend and tempo follow measured speed, not the AI's desired velocity.
	for speed in [0.2, 0.7, 1.3, 3.2, 7.35]:
		driver.advance_visual(1.0 / 60.0, &"Locomotion", speed)
		var blend := float(driver.tree.get("parameters/States/Locomotion/Clip/blend_position"))
		var tempo := driver.playback_rate
		var nominal := lerpf(Controller.WALK_SPEED, Controller.RUN_SPEED, blend)
		check(absf(tempo-clampf(speed/nominal,0.25,1.6)) < 0.001, "Creature bounded clip rate mismatch")
		check(absf(driver.actual_speed-speed) < 0.001, "Actual speed must not be clamped with clip time")
	# High locomotion speed must not accelerate behavior-state time.
	driver.advance_visual(0.02,&"Attack",7.35)
	check(absf(driver.state_seconds-0.02)<0.0001 and absf(driver.playback_rate-1.0)<0.001,"Attack inherited locomotion clock")
	# Long-running secondary motion is bounded and touches Head/Neck only.
	var minimum := Vector3(INF,INF,INF)
	var maximum := Vector3(-INF,-INF,-INF)
	for frame in 1800:
		driver.advance_visual(1.0/60.0, &"Idle", 0.0, 0.0, 0.0)
		minimum = minimum.min(driver.head_motion)
		maximum = maximum.max(driver.head_motion)
		check(driver.head_motion.length()<0.4 and driver.neck_motion.length()<0.2, "Unbounded head offset")
		for bone in skeleton.get_bone_count():
			if bone not in [driver.head_index,driver.neck_index]:
				check(skeleton.get_bone_pose(bone).is_equal_approx(driver.authored_poses[bone]), "Head layer modified unrelated bone")
	check((maximum-minimum).x>0.02 and (maximum-minimum).z>0.02, "Stationary head lacks pitch/roll motion")
	for frame in 180:
		driver.behavior_intent = &"FlashlightStalk"
		driver.advance_visual(1.0/60.0, &"Retreat", 1.15, 0.4, 0.4)
	check(driver.head_motion.y>0.2 and driver.head_motion.x<0.0, "Missing gaze or light recoil")
	print("CREATURE_HEAD_MOTION_OK idle_range=",maximum-minimum)
	if failures == 0:
		print("CREATURE_ANIMATION_TREE_OK")
	quit(1 if failures else 0)
