extends SceneTree

## Repeatable, non-interactive runtime benchmark.
##
## Environment variables:
##   KILLGORE_BENCHMARK_LEVEL   Zero-based level index (default: 13).
##   KILLGORE_BENCHMARK_OUTPUT  Optional absolute path for the JSON result.
##   KILLGORE_BENCHMARK_FRAMES  Frames sampled after warm-up (default: 600).
##   KILLGORE_BENCHMARK_STRESS  Set to 1 for repeatable projectile/VFX combat load.
##   KILLGORE_BENCHMARK_ROOM    Optional horror room: kitchen, car or passport.
##   KILLGORE_BENCHMARK_HORROR_HUNT  Set to 1 for a moving player + active hunter run.
##   KILLGORE_DISABLE_STATIC_ROOM_BATCHING  Set to 1 for room A/B diagnostics.

const LOAD_REQUEST_FRAME := 4
const CAP_REMOVAL_FRAME := 300
const SAMPLE_START_FRAME := 420

var frame_count := 0
var requested_level := 13
var sample_frame_target := 600
var level_requested := false
var cap_removed := false
var sampling := false
var sample_time := 0.0
var frame_times_ms: Array[float] = []
var process_times_ms: Array[float] = []
var physics_times_ms: Array[float] = []
var stress_enabled := false
var horror_hunt_enabled := false
var horror_hunt_initialized := false
var horror_hunt_origin := Vector3.ZERO
var horror_hunt_direction := Vector3.FORWARD
var horror_hunt_time := 0.0
var stress_tick := 0
var stress_initialized := false
var benchmark_room := ""

func _initialize() -> void:
	var level_value := OS.get_environment("KILLGORE_BENCHMARK_LEVEL")
	if not level_value.is_empty():
		requested_level = maxi(0, int(level_value))
	var requested_frames := int(OS.get_environment("KILLGORE_BENCHMARK_FRAMES"))
	if requested_frames > 0:
		sample_frame_target = maxi(120, requested_frames)
	stress_enabled = OS.get_environment("KILLGORE_BENCHMARK_STRESS") == "1"
	horror_hunt_enabled = OS.get_environment("KILLGORE_BENCHMARK_HORROR_HUNT") == "1"
	benchmark_room = OS.get_environment("KILLGORE_BENCHMARK_ROOM").to_lower()

func _process(delta: float) -> bool:
	frame_count += 1
	if not level_requested and frame_count >= LOAD_REQUEST_FRAME:
		level_requested = true
		set_meta("killgore_random_seed", 1337)
		set_meta("killgore_disable_static_room_batching", OS.get_environment("KILLGORE_DISABLE_STATIC_ROOM_BATCHING") == "1")
		set_meta("killgore_start_level", requested_level)
		set_meta("killgore_level_select", true)
		change_scene_to_file("res://Main.tscn")
		return false
	if level_requested and not cap_removed and frame_count >= CAP_REMOVAL_FRAME:
		cap_removed = true
		Engine.max_fps = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if stress_enabled and level_requested and frame_count >= 330:
		_drive_combat_stress()
	if horror_hunt_enabled and level_requested and frame_count >= 330:
		_drive_horror_hunt(delta)
	if not benchmark_room.is_empty() and level_requested and frame_count >= 300:
		_place_horror_room(benchmark_room)
	if level_requested and not sampling and frame_count >= SAMPLE_START_FRAME:
		sampling = true
	if not sampling:
		return false
	sample_time += delta
	frame_times_ms.append(delta * 1000.0)
	process_times_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	physics_times_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	if frame_times_ms.size() >= sample_frame_target:
		_finish_benchmark()
	return false

func _finish_benchmark() -> void:
	var result := {
		"level": requested_level,
		"profile": "combat_stress" if stress_enabled else ("horror_hunt" if horror_hunt_enabled else ("horror_room_%s" % benchmark_room if not benchmark_room.is_empty() else "stationary")),
		"sample_frames": frame_times_ms.size(),
		"average_fps": float(frame_times_ms.size()) / maxf(sample_time, 0.0001),
		"frame_ms_p50": _percentile(frame_times_ms, 0.50),
		"frame_ms_p95": _percentile(frame_times_ms, 0.95),
		"frame_ms_p99": _percentile(frame_times_ms, 0.99),
		"process_ms_p95": _percentile(process_times_ms, 0.95),
		"physics_ms_p95": _percentile(physics_times_ms, 0.95),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"rendered_objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"rendered_primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"resource_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"video_memory_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"texture_memory_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"buffer_memory_mb": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
		"renderer": RenderingServer.get_video_adapter_name()
	}
	var json := JSON.stringify(result, "  ")
	print("KILLGORE_BENCHMARK_RESULT ", JSON.stringify(result))
	var output_path := OS.get_environment("KILLGORE_BENCHMARK_OUTPUT")
	if not output_path.is_empty():
		var output := FileAccess.open(output_path, FileAccess.WRITE)
		if output == null:
			push_error("Could not write benchmark result: %s" % output_path)
		else:
			output.store_string(json + "\n")
	quit(0)

func _place_horror_room(room_id: String) -> void:
	if current_scene == null:
		return
	var level_manager = current_scene.get("level_manager")
	var player = current_scene.get("player")
	if level_manager == null or player == null:
		return
	var runtime = level_manager.get("horror_runtime")
	if runtime == null or not runtime.task_anchors.has(room_id):
		return
	var anchor: Vector3 = runtime.task_anchors[room_id]
	var offsets := {
		"kitchen": Vector3(-3.0, 0.04, 13.8),
		"car": Vector3(-10.8, 0.04, 7.6),
		"passport": Vector3(0.0, 0.04, 14.2)
	}
	var target_offsets := {
		"kitchen": Vector3(3.0, 1.20, -3.5),
		"car": Vector3(1.2, 1.05, -0.8),
		"passport": Vector3(0.0, 1.25, -8.0)
	}
	if not offsets.has(room_id):
		return
	var desired: Vector3 = anchor + offsets[room_id] + Vector3.UP * 1.65
	var target: Vector3 = anchor + target_offsets[room_id]
	var view_direction := (target - desired).normalized()
	var view_yaw := atan2(-view_direction.x, -view_direction.z)
	var view_pitch := asin(clamp(view_direction.y, -1.0, 1.0))
	player.global_position = anchor + offsets[room_id]
	player.vertical_velocity = 0.0
	player.horizontal_velocity = Vector3.ZERO
	player.yaw = view_yaw
	player.target_yaw = view_yaw
	player.pitch = view_pitch
	player.target_pitch = view_pitch
	player.rotation.y = view_yaw
	player.flashlight_on = true
	player.call("_update_horror_flashlight_visibility")

func _drive_combat_stress() -> void:
	if current_scene == null:
		return
	var level_manager = current_scene.get("level_manager")
	var player = current_scene.get("player")
	if level_manager == null or player == null or level_manager.projectile_root == null:
		return
	if not stress_initialized:
		stress_initialized = true
		player.set_developer_mode(true)
		level_manager.set_developer_mode(true)
	stress_tick += 1
	var origin: Vector3 = player.camera_origin() + Vector3.UP * 0.10
	var forward: Vector3 = player.aim_dir().normalized()
	if forward.length_squared() < 0.01:
		forward = Vector3.FORWARD
	var side := forward.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	if stress_tick % 3 == 0:
		var spread := sin(float(stress_tick) * 0.37) * 0.16
		var direction := forward.rotated(Vector3.UP, spread)
		level_manager.spawn_player_projectile(origin, direction, 34.0, 5, false, 0.0, 5, Color8(110, 224, 255), 0, false, 0.42)
	if stress_tick % 11 == 0:
		var grenade_velocity := forward * 8.5 + Vector3.UP * 3.8 + side * sin(float(stress_tick) * 0.23) * 1.2
		level_manager.spawn_grenade(player.global_position + Vector3.UP * 1.1, grenade_velocity, "cluster_child", true, 0.34)
	if stress_tick % 17 == 0:
		var impact_position: Vector3 = player.global_position + forward * 5.0 + side * sin(float(stress_tick) * 0.19) * 1.8 + Vector3.UP * 0.7
		level_manager.spawn_impact_fx(impact_position, Color8(255, 142, 48))
	if stress_tick % 31 == 0:
		var blast_position: Vector3 = player.global_position + forward * 6.2 + side * sin(float(stress_tick) * 0.11) * 2.2
		level_manager._spawn_explosion(blast_position, 3.6)

func _drive_horror_hunt(delta: float) -> void:
	if current_scene == null:
		return
	var level_manager = current_scene.get("level_manager")
	var player = current_scene.get("player")
	var runtime = level_manager.get("horror_runtime") if level_manager != null else null
	if runtime == null or player == null or not is_instance_valid(runtime.monster_root):
		return
	if not horror_hunt_initialized:
		var corridor = _find_horror_corridor(runtime, 12)
		if corridor.is_empty():
			push_error("Could not find a straight corridor for horror hunt benchmark")
			horror_hunt_enabled = false
			return
		var start_cell: Vector2i = corridor["start"]
		var direction_cell: Vector2i = corridor["direction"]
		horror_hunt_direction = Vector3(float(direction_cell.x), 0.0, float(direction_cell.y)).normalized()
		horror_hunt_origin = runtime._cell_world(start_cell + direction_cell * 6)
		player.global_position = horror_hunt_origin
		player.horizontal_velocity = Vector3.ZERO
		player.flashlight_on = true
		player.call("_update_horror_flashlight_visibility")
		runtime.monster_root.global_position = runtime._cell_world(start_cell)
		runtime.monster_root.look_at(horror_hunt_origin, Vector3.UP)
		runtime.monster_last_known_position = horror_hunt_origin
		runtime.monster_estimated_player_position = horror_hunt_origin
		runtime.monster_state = "chase"
		runtime.monster_awareness = 1.0
		runtime.monster_has_visual = true
		runtime.monster_repath_timer = 0.0
		horror_hunt_initialized = true
	horror_hunt_time += delta
	# Smooth back-and-forth movement holds the hunter in its active pathfinding,
	# light and animation states without teleporting through collision cells.
	var travel = sin(horror_hunt_time * 0.72) * 4.0
	player.global_position = horror_hunt_origin + horror_hunt_direction * travel
	player.horizontal_velocity = horror_hunt_direction * cos(horror_hunt_time * 0.72) * 2.88

func _find_horror_corridor(runtime, length: int) -> Dictionary:
	if runtime.monster_navigation == null:
		return {}
	var directions = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for cell in runtime.monster_open_cells:
		for direction in directions:
			var clear = true
			for offset in range(1, length + 1):
				var probe = cell + direction * offset
				if not runtime.monster_navigation.is_in_boundsv(probe) or runtime.monster_navigation.is_point_solid(probe):
					clear = false
					break
			if clear:
				return {"start": cell, "direction": direction}
	return {}

func _percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var index := clampi(int(ceil((sorted.size() - 1) * ratio)), 0, sorted.size() - 1)
	return sorted[index]
