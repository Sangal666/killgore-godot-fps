extends SceneTree

var frame_count := 0
var level_loaded := false
var player_moved := false


func _process(_delta: float) -> bool:
	frame_count += 1
	if not level_loaded and frame_count >= 5:
		level_loaded = true
		set_meta("killgore_random_seed", 1337)
		set_meta("killgore_disable_room_culling", OS.get_environment("KILLGORE_DISABLE_ROOM_CULLING") == "1")
		set_meta("killgore_start_level", 13)
		set_meta("killgore_level_select", true)
		change_scene_to_file("res://Main.tscn")
	_disable_transition()
	if level_loaded and not player_moved and frame_count >= 150:
		player_moved = true
		_move_player_into_long_corridor()
	if player_moved and frame_count < 520:
		_force_flashlight_on()
	if level_loaded and frame_count == 480:
		_print_flashlight_diagnostics()
	if level_loaded and frame_count == 520:
		var output_path := OS.get_environment("KILLGORE_CAPTURE_OUTPUT")
		if output_path.is_empty():
			output_path = "/private/tmp/killgore_horror_lighting.png"
		root.get_texture().get_image().save_png(output_path)
		quit()
	return false


func _force_flashlight_on() -> void:
	var main = current_scene
	if main == null:
		return
	var player = main.get("player")
	if player == null:
		return
	player.flashlight_on = true
	player.call("_update_horror_flashlight_visibility")


func _disable_transition() -> void:
	var main = current_scene
	if main == null:
		return
	var transition = main.get("transition")
	if transition == null:
		return
	transition.visible = false
	transition.timer = 0.0
	transition.set_process(false)
	transition.queue_redraw()


func _print_flashlight_diagnostics() -> void:
	var main = current_scene
	if main == null:
		return
	var player = main.get("player")
	var level_manager = main.get("level_manager")
	if player == null or level_manager == null:
		return
	var runtime = level_manager.get("horror_runtime")
	print("FLASHLIGHT player=", player.global_position, " aim=", player.aim_dir())
	print("FLASHLIGHT on=", player.flashlight_on, " mode=", player.horror_flashlight_mode,
		" target=", player.flashlight_volume_target_length, " length=", player.flashlight_volume_length)
	if player.flashlight_long_throw != null:
		print("FLASHLIGHT long energy=", player.flashlight_long_throw.light_energy,
			" visible=", player.flashlight_long_throw.visible, " range=", player.flashlight_long_throw.spot_range)
	for index in player.flashlight_corridor_lights.size():
		var light = player.flashlight_corridor_lights[index]
		print("FLASHLIGHT pool ", index, " pos=", light.global_position,
			" visible=", light.visible, " energy=", light.light_energy, " range=", light.omni_range)
	if runtime != null:
		print("FLASHLIGHT reactive materials=", runtime.flashlight_reactive_materials.size())
		if not runtime.flashlight_reactive_materials.is_empty():
			var material = runtime.flashlight_reactive_materials[0]
			print("FLASHLIGHT shader enabled=", material.get_shader_parameter("flashlight_enabled"),
				" origin=", material.get_shader_parameter("flashlight_origin"),
				" direction=", material.get_shader_parameter("flashlight_direction"))


func _move_player_into_long_corridor() -> void:
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
	var raw: Array = runtime.maze_raw
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var best_clear_steps := 0
	var best_col := 0
	var best_row := 0
	var best_direction := Vector2i.ZERO
	for row in range(2, raw.size() - 2):
		var line = String(raw[row])
		for col in range(2, line.length() - 2):
			if _solid(raw, row, col):
				continue
			for direction_cell in directions:
				var clear_steps = 0
				for step in range(1, 20):
					var probe_col = col + direction_cell.x * step
					var probe_row = row + direction_cell.y * step
					if _solid(raw, probe_row, probe_col):
						break
					clear_steps += 1
				if clear_steps > best_clear_steps:
					best_clear_steps = clear_steps
					best_col = col
					best_row = row
					best_direction = direction_cell
	var player_position = Vector3(float(best_col) * 4.0, 0.04, float(best_row) * 4.0)
	if level_manager.is_blocked_world(player_position, 0.30):
		return
	var direction = Vector3(float(best_direction.x), 0.0, float(best_direction.y))
	player.global_position = player_position
	player.vertical_velocity = 0.0
	player.flashlight_on = true
	player.call("_update_horror_flashlight_visibility")
	player.yaw = atan2(-direction.x, -direction.z)
	player.target_yaw = player.yaw
	player.pitch = -0.045
	player.target_pitch = player.pitch


func _solid(raw: Array, row: int, col: int) -> bool:
	if row < 0 or row >= raw.size():
		return true
	var line = String(raw[row])
	return col < 0 or col >= line.length() or line.substr(col, 1) == "#"
