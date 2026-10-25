extends SceneTree

var frame_count := 0
var level_requested := false
var room_ids := ["kitchen", "car", "passport"]
var room_index := 0
var next_capture_frame := 0
var active_room_id := ""
var capture_pending := false
var capture_ready_frame := 0
var capture_camera: Camera3D
var joint_check_light: OmniLight3D
const CAMERA_SETTLE_FRAMES := 120
const ROOM_CAPTURE_INTERVAL := 150


func _process(_delta: float) -> bool:
	frame_count += 1
	if not level_requested and frame_count >= 4:
		level_requested = true
		set_meta("killgore_random_seed", 1337)
		set_meta("killgore_disable_static_room_batching", OS.get_environment("KILLGORE_DISABLE_STATIC_ROOM_BATCHING") == "1")
		set_meta("killgore_disable_room_culling", OS.get_environment("KILLGORE_DISABLE_ROOM_CULLING") == "1")
		set_meta("killgore_start_level", 13)
		set_meta("killgore_level_select", true)
		change_scene_to_file("res://Main.tscn")
		next_capture_frame = 420
		return false
	if not level_requested or room_index >= room_ids.size():
		return false
	if capture_pending:
		if active_room_id == "kitchen" and OS.get_environment("KILLGORE_KITCHEN_WOMAN_CHECK") == "1" and is_instance_valid(capture_camera):
			capture_camera.current = true
		if frame_count >= capture_ready_frame:
			_save_active_room()
		return false
	if frame_count == next_capture_frame:
		active_room_id = String(room_ids[room_index])
		_place_camera_for_room(active_room_id)
	elif active_room_id != "" and frame_count < next_capture_frame + CAMERA_SETTLE_FRAMES:
		_place_camera_for_room(active_room_id)
	elif frame_count == next_capture_frame + CAMERA_SETTLE_FRAMES and not capture_pending:
		_place_camera_for_room(active_room_id)
		_print_room_capture_state(active_room_id)
		capture_pending = true
		capture_ready_frame = frame_count + 12
	return false


func _save_active_room() -> void:
	root.get_texture().get_image().save_png(_output_path(String(room_ids[room_index])))
	active_room_id = ""
	room_index += 1
	next_capture_frame += ROOM_CAPTURE_INTERVAL
	capture_pending = false
	if room_index >= room_ids.size():
		print("HORROR_ROOM_CAPTURES_OK")
		quit(0)


func _place_camera_for_room(room_id: String) -> void:
	var main = current_scene
	if main == null:
		return
	_hide_transition(main)
	var player = main.get("player")
	var level_manager = main.get("level_manager")
	if player == null or level_manager == null:
		return
	var runtime = level_manager.get("horror_runtime")
	if runtime == null or not runtime.task_anchors.has(room_id):
		return
	var room_names := {
		"kitchen": "MemoryRoom_Kitchen",
		"car": "MemoryRoom_Roadside",
		"passport": "MemoryRoom_PassportControl"
	}
	var room_root = runtime.get_node_or_null(String(room_names[room_id]))
	var anchor: Vector3 = room_root.global_position if room_root != null else runtime.task_anchors[room_id]
	set_meta("killgore_disable_room_culling", true)
	# The closer reference framing sits inside the hunter's aggression radius.
	# Remove it only from this QA shot so repeated deaths cannot replace the
	# captured frame with the level-intro card.
	if room_id == "kitchen" and is_instance_valid(runtime.monster_root):
		runtime.monster_root.queue_free()
	player.hp = maxi(player.hp, 1000)
	if room_root != null:
		room_root.visible = true
	var kitchen_approach := OS.get_environment("KILLGORE_KITCHEN_APPROACH") == "1"
	var kitchen_side_approach := OS.get_environment("KILLGORE_KITCHEN_SIDE_APPROACH") == "1"
	var kitchen_column_joint := OS.get_environment("KILLGORE_KITCHEN_COLUMN_JOINT") == "1"
	var kitchen_woman_check := OS.get_environment("KILLGORE_KITCHEN_WOMAN_CHECK") == "1"
	var offsets := {
		"kitchen": Vector3(0.0, 0.48, 3.2) if kitchen_woman_check else (Vector3(10.00, 0.48, 33.00) if kitchen_column_joint else (Vector3(14.00, 0.48, 32.00) if kitchen_side_approach else (Vector3(0.0, 0.48, 34.00) if kitchen_approach else Vector3(0.0, 0.48, 13.30)))),
		"car": Vector3(-4.0, 0.04, 5.4),
		"passport": Vector3(-4.0, 0.04, 5.4)
	}
	var target_offsets := {
		"kitchen": Vector3(-1.5, 0.82, 0.65) if kitchen_woman_check else (Vector3(5.82, 2.72, 33.0) if kitchen_column_joint else (Vector3(0.0, 1.15, 29.0) if kitchen_side_approach else Vector3(0.0, 1.15, -1.25))),
		"car": Vector3(0.0, 1.05, 0.0),
		"passport": Vector3(0.0, 1.05, 0.0)
	}
	var desired: Vector3 = anchor + offsets[room_id] + Vector3.UP * 1.65
	var target: Vector3 = anchor + target_offsets[room_id]
	if room_id == "kitchen" and kitchen_column_joint:
		_ensure_joint_check_light(main, target)
	elif room_id == "kitchen" and kitchen_woman_check:
		_ensure_capture_camera(main)
		capture_camera.global_position = anchor + offsets[room_id] + Vector3.UP * 1.35
		capture_camera.look_at(target, Vector3.UP)
	player.global_position = anchor + offsets[room_id]
	player.visible = not kitchen_woman_check
	player.vertical_velocity = 0.0
	player.horizontal_velocity = Vector3.ZERO
	var view_direction := (target - desired).normalized()
	var view_yaw := atan2(-view_direction.x, -view_direction.z)
	# Godot's camera looks along -Z; negative X rotation looks upward.
	var view_pitch := -asin(clamp(view_direction.y, -1.0, 1.0))
	player.yaw = view_yaw
	player.target_yaw = view_yaw
	player.pitch = view_pitch
	player.target_pitch = view_pitch
	player.rotation.y = view_yaw
	player.camera.rotation.x = view_pitch
	player.camera.current = true
	if room_id == "kitchen" and kitchen_woman_check and is_instance_valid(capture_camera):
		capture_camera.current = true
	player.flashlight_on = room_id != "kitchen" or kitchen_approach or kitchen_side_approach or kitchen_column_joint
	player.call("_update_horror_flashlight_visibility")
	if frame_count == next_capture_frame:
		print("CAPTURE_%s anchor=%s camera=%s target=%s children=%d bounds=%s" % [
			room_id.to_upper(), anchor, desired, target,
			room_root.get_child_count() if room_root != null else -1,
			_room_world_bounds(room_root)
		])


func _ensure_joint_check_light(main: Node, target: Vector3) -> void:
	if not is_instance_valid(joint_check_light):
		joint_check_light = OmniLight3D.new()
		joint_check_light.name = "KitchenJointQALight"
		joint_check_light.light_color = Color8(232, 224, 198)
		joint_check_light.light_energy = 3.8
		joint_check_light.omni_range = 7.0
		joint_check_light.shadow_enabled = true
		main.add_child(joint_check_light)
	joint_check_light.global_position = target + Vector3(1.25, -0.35, 0.0)


func _output_path(room_id: String) -> String:
	var prefix := OS.get_environment("KILLGORE_ROOM_CAPTURE_PREFIX")
	if prefix.is_empty():
		prefix = "/private/tmp/killgore_horror"
	return "%s_%s.png" % [prefix, room_id]


func _print_room_capture_state(room_id: String) -> void:
	var main = current_scene
	if main == null:
		return
	var player = main.get("player")
	var level_manager = main.get("level_manager")
	if player == null or level_manager == null:
		return
	var runtime = level_manager.get("horror_runtime")
	if runtime == null:
		return
	var room_names := {
		"kitchen": "MemoryRoom_Kitchen",
		"car": "MemoryRoom_Roadside",
		"passport": "MemoryRoom_PassportControl"
	}
	var room_root = runtime.get_node_or_null(String(room_names[room_id]))
	print("CAPTURE_STATE_%s player=%s room_visible=%s camera=%s flashlight=%s active_camera=%s" % [
		room_id.to_upper(), player.global_position,
		room_root.visible if room_root != null else false,
		player.camera.global_position if player.get("camera") != null else Vector3.ZERO,
		player.flashlight_on,
		current_scene.get_viewport().get_camera_3d().name if current_scene.get_viewport().get_camera_3d() != null else "NONE"
	])


func _hide_transition(main: Node) -> void:
	var transition = main.get("transition")
	if transition == null:
		return
	transition.set("timer", 0.0)
	transition.visible = false


func _ensure_capture_camera(main: Node) -> void:
	if is_instance_valid(capture_camera):
		return
	capture_camera = Camera3D.new()
	capture_camera.name = "HorrorRoomCaptureCamera"
	capture_camera.fov = 62.0
	capture_camera.near = 0.03
	main.add_child(capture_camera)
	capture_camera.current = true


func _room_world_bounds(room_root: Node3D) -> AABB:
	if room_root == null:
		return AABB()
	var found := false
	var bounds := AABB()
	for node in _walk_nodes(room_root):
		if not node is MeshInstance3D:
			continue
		var mesh_node := node as MeshInstance3D
		var local_box := mesh_node.get_aabb()
		if local_box.size == Vector3.ZERO:
			continue
		for corner in _aabb_corners(local_box):
			var point := mesh_node.to_global(corner)
			if not found:
				bounds = AABB(point, Vector3.ZERO)
				found = true
			else:
				bounds = bounds.expand(point)
	return bounds if found else AABB()


func _walk_nodes(root_node: Node) -> Array:
	var nodes: Array = [root_node]
	for child in root_node.get_children():
		nodes.append_array(_walk_nodes(child))
	return nodes


func _aabb_corners(box: AABB) -> Array[Vector3]:
	var p := box.position
	var s := box.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s
	]
