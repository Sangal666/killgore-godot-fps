extends SceneTree

const DEFAULT_OUTPUT_PATH := "/private/tmp/killgore_maze_monster.png"

var frame_count := 0
var level_requested := false
var staged := false
var capture_camera: Camera3D
var staged_runtime
var staged_monster_position := Vector3.ZERO
var staged_camera_position := Vector3.ZERO
var capture_requested := false


func _process(_delta: float) -> bool:
	frame_count += 1
	if not level_requested and frame_count >= 4:
		level_requested = true
		set_meta("killgore_random_seed", 1337)
		set_meta("killgore_start_level", 13)
		set_meta("killgore_level_select", true)
		change_scene_to_file("res://Main.tscn")
		return false
	if not level_requested or current_scene == null:
		return false
	if not staged and frame_count >= 320:
		staged = _stage_monster()
	if staged:
		_hide_transition(current_scene)
		staged_runtime.monster_root.global_position = staged_monster_position
		staged_runtime.monster_root.look_at(staged_camera_position, Vector3.UP)
	# Dense imported animations can make the first rendered frames lag behind
	# process ticks while shaders warm up. Wait long enough for a clean viewport.
	if staged and frame_count >= 720 and not capture_requested:
		capture_requested = true
		print("MAZE_MONSTER_CAPTURE_STATE monster=%s camera=%s behind=%s screen=%s visible=%s" % [
			staged_runtime.monster_root.global_position,
			capture_camera.global_position,
			capture_camera.is_position_behind(staged_runtime.monster_root.global_position + Vector3.UP),
			capture_camera.unproject_position(staged_runtime.monster_root.global_position + Vector3.UP),
			staged_runtime.monster_model.visible,
		])
		# The staged scene may become fully static, in which case Compatibility mode
		# does not emit another frame_post_draw signal. Force the final draw so the
		# capture cannot wait forever or read the former transition frame.
		RenderingServer.force_draw(false)
		_save_staged_frame()
	return false


func _save_staged_frame() -> void:
	var output_path := OS.get_environment("KILLGORE_MONSTER_CAPTURE_PATH")
	if output_path.is_empty():
		output_path = DEFAULT_OUTPUT_PATH
	root.get_texture().get_image().save_png(output_path)
	print("MAZE_MONSTER_CAPTURE_OK path=%s" % output_path)
	quit(0)


func _stage_monster() -> bool:
	var main = current_scene
	var player = main.get("player")
	var level_manager = main.get("level_manager")
	var runtime = level_manager.get("horror_runtime") if level_manager != null else null
	if player == null or runtime == null or not is_instance_valid(runtime.monster_model):
		return false
	var corridor := _find_straight_corridor(runtime, 10)
	if corridor.is_empty():
		return false
	var start_cell: Vector2i = corridor["start"]
	var direction: Vector2i = corridor["direction"]
	var monster_position: Vector3 = runtime._cell_world(start_cell + direction)
	var camera_position: Vector3 = runtime._cell_world(start_cell) + Vector3.UP * 1.38
	staged_runtime = runtime
	staged_monster_position = monster_position
	staged_camera_position = camera_position
	main.set_physics_process(false)
	if player.get("camera") != null:
		player.get("camera").current = false
	runtime.monster_root.global_position = monster_position
	runtime.monster_root.look_at(camera_position, Vector3.UP)
	runtime.creature_animation_driver.advance_visual(0.20, &"Alert", 0.0)
	runtime.monster_has_visual = true
	runtime._trigger_monster_expression()
	runtime._update_monster_expression(0.20)
	_hide_transition(main)
	capture_camera = Camera3D.new()
	capture_camera.name = "MazeMonsterCaptureCamera"
	capture_camera.fov = 68.0
	capture_camera.near = 0.03
	main.add_child(capture_camera)
	capture_camera.global_position = camera_position
	capture_camera.look_at(monster_position + Vector3.UP * 0.72, Vector3.UP)
	capture_camera.current = true
	var fill = SpotLight3D.new()
	fill.name = "FlashlightFill"
	fill.light_color = Color8(224, 214, 181)
	fill.light_energy = 5.2
	fill.spot_range = 24.0
	fill.spot_angle = 38.0
	fill.spot_attenuation = 0.92
	fill.shadow_enabled = true
	capture_camera.add_child(fill)
	print("MAZE_MONSTER_STAGE model=%s animations=%s scale=%s distance=%.2f" % [
		runtime.monster_model.name,
		runtime.monster_animation_player.get_animation_list(),
		runtime.monster_model.scale,
		camera_position.distance_to(monster_position)
	])
	return true


func _find_straight_corridor(runtime, required_cells: int) -> Dictionary:
	for start_cell: Vector2i in runtime.monster_open_cells:
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var clear := true
			for step in range(required_cells):
				var cell: Vector2i = start_cell + direction * step
				if not runtime.monster_navigation.is_in_boundsv(cell) or runtime.monster_navigation.is_point_solid(cell):
					clear = false
					break
			if clear:
				return {"start": start_cell, "direction": direction}
	return {}


func _hide_transition(main: Node) -> void:
	var hud = main.get("hud")
	if hud != null:
		hud.set("horror_map_open", false)
		hud.set("options_open", false)
		if hud is CanvasItem:
			hud.visible = false
	var transition = main.get_node_or_null("Transition")
	if transition == null:
		return
	transition.process_mode = Node.PROCESS_MODE_DISABLED
	transition.set("timer", 0.0)
	transition.visible = false
	transition.queue_redraw()
	transition.queue_free()
