extends SceneTree

const CAPTURE_SETTLE_FRAMES := 90
const CAPTURE_INTERVAL := 120

var frame_count := 0
var level_requested := false
var capture_index := 0
var next_capture_frame := 0
var active_capture := false
var shots: Array[Dictionary] = []
var capture_camera: Camera3D
var capture_light: SpotLight3D


func _process(_delta: float) -> bool:
	frame_count += 1
	if not level_requested and frame_count >= 4:
		level_requested = true
		set_meta("killgore_random_seed", 1337)
		set_meta("killgore_disable_room_culling", true)
		set_meta("killgore_start_level", 13)
		set_meta("killgore_level_select", true)
		change_scene_to_file("res://Main.tscn")
		next_capture_frame = 420
		return false
	if not level_requested:
		return false
	_hide_transition()
	if shots.is_empty():
		_prepare_shots()
	if shots.is_empty() or capture_index >= shots.size():
		return false
	if not active_capture and frame_count >= next_capture_frame:
		# Scene startup can occasionally finish after the originally requested frame.
		# Retry until the QA camera is genuinely placed instead of saving the live
		# player view under the requested shot name.
		if _place_shot(shots[capture_index]):
			active_capture = true
			next_capture_frame = frame_count
	elif active_capture and frame_count < next_capture_frame + CAPTURE_SETTLE_FRAMES:
		if not _place_shot(shots[capture_index]):
			_retry_active_shot()
	elif active_capture and frame_count >= next_capture_frame + CAPTURE_SETTLE_FRAMES:
		if not _place_shot(shots[capture_index]) or not _capture_camera_is_current():
			_retry_active_shot()
			return false
		var shot: Dictionary = shots[capture_index]
		root.get_texture().get_image().save_png(_output_path(String(shot["id"])))
		print("OPENING_CAPTURE_%s_OK" % String(shot["id"]).to_upper())
		active_capture = false
		capture_index += 1
		next_capture_frame += CAPTURE_INTERVAL
		if capture_index >= shots.size():
			print("HORROR_OPENING_CAPTURES_OK")
			if OS.get_environment("KILLGORE_OPENING_CAPTURE_HOLD") != "1":
				quit(0)
	return false


func _retry_active_shot() -> void:
	active_capture = false
	next_capture_frame = frame_count + 1


func _capture_camera_is_current() -> bool:
	if not is_instance_valid(capture_camera) or current_scene == null:
		return false
	return current_scene.get_viewport().get_camera_3d() == capture_camera


func _prepare_shots() -> void:
	var main = current_scene
	if main == null:
		return
	var level_manager = main.get("level_manager")
	if level_manager == null:
		return
	var runtime = level_manager.get("horror_runtime")
	if runtime == null or not runtime.task_anchors.has("kitchen"):
		return
	var anchor: Vector3 = runtime.task_anchors["kitchen"]
	shots = [
		{"id": "spawn", "position": runtime._cell_world(Vector2i(42, 138)), "target": runtime._cell_world(Vector2i(42, 128))},
		{"id": "first_turn", "position": runtime._cell_world(Vector2i(42, 130)), "target": runtime._cell_world(Vector2i(30, 128))},
		{"id": "second_turn", "position": runtime._cell_world(Vector2i(30, 128)), "target": runtime._cell_world(Vector2i(30, 118))},
		{"id": "broad_run", "position": runtime._cell_world(Vector2i(22, 118)), "target": runtime._cell_world(Vector2i(10, 118))},
		{"id": "kitchen_turn", "position": anchor + Vector3(14.0, 0.0, 32.0), "target": anchor + Vector3(0.0, 1.0, 29.0)},
		{"id": "ceiling_transition", "position": anchor + Vector3(9.5, 0.0, 34.2), "target": anchor + Vector3(4.0, 3.15, 31.8)},
		{"id": "threshold_ceiling", "position": anchor + Vector3(0.0, 0.0, 25.6), "target": anchor + Vector3(0.0, 3.05, 28.2)},
		{"id": "narrow_run", "position": anchor + Vector3(0.0, 0.0, 26.0), "target": anchor + Vector3(0.0, 1.0, 0.0)},
		{"id": "kitchen_reveal", "position": anchor + Vector3(0.0, 0.0, 7.0), "target": anchor + Vector3(0.0, 1.0, -1.0)}
	]
	var requested_id := OS.get_environment("KILLGORE_OPENING_CAPTURE_ID")
	if not requested_id.is_empty():
		shots = shots.filter(func(shot: Dictionary) -> bool: return String(shot["id"]) == requested_id)


func _place_shot(shot: Dictionary) -> bool:
	var main = current_scene
	if main == null:
		return false
	var player = main.get("player")
	var level_manager = main.get("level_manager")
	if player == null or level_manager == null:
		return false
	var runtime = level_manager.get("horror_runtime")
	if runtime == null:
		return false
	if is_instance_valid(runtime.monster_root):
		runtime.monster_root.queue_free()
	player.hp = maxi(player.hp, 1000)
	# The independent QA camera below is unaffected by the live controller, so the
	# player must remain unpaused; pausing would correctly summon the pause HUD.
	player.paused = false
	# CharacterBody3D's origin sits above the floor. Keeping it at raw cell Y
	# embeds the capture player in the floor and can retrigger the level intro.
	var position: Vector3 = shot["position"] + Vector3.UP * 0.48
	var target: Vector3 = shot["target"]
	player.global_position = position
	player.vertical_velocity = 0.0
	player.horizontal_velocity = Vector3.ZERO
	var camera_origin := position + Vector3.UP * 1.36
	var direction := (target - camera_origin).normalized()
	var yaw := atan2(-direction.x, -direction.z)
	var pitch := asin(clampf(direction.y, -1.0, 1.0))
	player.yaw = yaw
	player.target_yaw = yaw
	player.pitch = pitch
	player.target_pitch = pitch
	player.rotation.y = yaw
	player.camera.rotation.x = pitch
	player.flashlight_on = false
	player.call("_update_horror_flashlight_visibility")
	_ensure_capture_camera(main)
	capture_camera.global_position = camera_origin
	capture_camera.look_at(target, Vector3.UP)
	capture_camera.current = true
	_hide_transition()
	return true


func _hide_transition() -> void:
	var main = current_scene
	if main == null:
		return
	var transition = main.get("transition")
	if transition == null or not is_instance_valid(transition):
		return
	transition.set_process(false)
	transition.set("timer", 0.0)
	transition.set("title", "")
	transition.hide()
	transition.queue_redraw()


func _ensure_capture_camera(main: Node) -> void:
	if is_instance_valid(capture_camera):
		return
	capture_camera = Camera3D.new()
	capture_camera.name = "OpeningRouteCaptureCamera"
	capture_camera.fov = 74.0
	capture_camera.near = 0.03
	main.add_child(capture_camera)
	capture_light = SpotLight3D.new()
	capture_light.name = "OpeningRouteFlashlight"
	capture_light.light_color = Color8(238, 232, 205)
	capture_light.light_energy = 5.20
	capture_light.light_specular = 0.72
	capture_light.spot_range = 20.0
	capture_light.spot_angle = 72.0
	capture_light.spot_attenuation = 2.16
	capture_light.shadow_enabled = true
	capture_light.shadow_bias = 0.045
	capture_light.shadow_normal_bias = 1.25
	capture_camera.add_child(capture_light)


func _output_path(id: String) -> String:
	var prefix := OS.get_environment("KILLGORE_OPENING_CAPTURE_PREFIX")
	if prefix.is_empty():
		prefix = "/private/tmp/killgore_horror_opening"
	return "%s_%s.png" % [prefix, id]
