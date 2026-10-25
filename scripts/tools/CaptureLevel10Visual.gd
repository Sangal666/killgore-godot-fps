extends SceneTree

var frame_count := 0
var level_loaded := false
var moved_to_midpoint := false
var moved_to_exit := false


func _process(_delta: float) -> bool:
	frame_count += 1
	if not level_loaded and frame_count >= 5:
		level_loaded = true
		set_meta("killgore_random_seed", 1337)
		set_meta("killgore_start_level", 10)
		set_meta("killgore_level_select", true)
		change_scene_to_file("res://Main.tscn")
	if level_loaded and frame_count == 300:
		_capture("/private/tmp/killgore_level10_spawn.png")
	if level_loaded and not moved_to_midpoint and frame_count >= 310:
		moved_to_midpoint = true
		_move_player_to_route_index(4)
	if level_loaded and frame_count == 350:
		_capture("/private/tmp/killgore_level10_mid.png")
	if level_loaded and not moved_to_exit and frame_count >= 360:
		moved_to_exit = true
		_move_player_to_route_index(7)
	if level_loaded and frame_count == 400:
		_capture("/private/tmp/killgore_level10_exit.png")
		quit()
	return false


func _capture(path: String) -> void:
	root.get_texture().get_image().save_png(path)


func _move_player_to_route_index(index: int) -> void:
	var main = current_scene
	if main == null:
		return
	var player = main.get("player")
	var level_manager = main.get("level_manager")
	if player == null or level_manager == null:
		return
	var runtime = level_manager.get("trench_runtime")
	if runtime == null:
		return
	var route_faces: Array = runtime.call("_route_floor_faces", 9)
	if route_faces.is_empty():
		return
	index = clampi(index, 0, route_faces.size() - 1)
	var target = _face_center(route_faces[index])
	var floor_y = runtime.floor_height_at(target)
	if floor_y != -INF:
		target.y = floor_y + 0.04
	player.global_position = target
	player.vertical_velocity = 0.0
	var look_index = mini(index + 1, route_faces.size() - 1)
	var look_target = _face_center(route_faces[look_index])
	var direction = look_target - target
	direction.y = 0.0
	if direction.length_squared() > 0.01:
		player.yaw = atan2(-direction.x, -direction.z)
		player.target_yaw = player.yaw
	player.pitch = 0.0
	player.target_pitch = 0.0


func _face_center(face: Dictionary) -> Vector3:
	var points: Array = face.get("points", [])
	if points.is_empty():
		return Vector3.ZERO
	var center := Vector3.ZERO
	for point in points:
		center += Vector3(point)
	return center / float(points.size())
