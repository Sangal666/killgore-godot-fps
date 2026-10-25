extends SceneTree

var frame_count := 0
var level_requested := false
var runtime = null
var player = null
var level_manager = null
var monster_start := Vector3.ZERO
var patrol_started := false
var elapsed_patrol := 0.0
var player_navigation: AStarGrid2D


func _process(delta: float) -> bool:
	frame_count += 1
	if not level_requested and frame_count >= 4:
		level_requested = true
		set_meta("killgore_start_level", 13)
		set_meta("killgore_level_select", true)
		change_scene_to_file("res://Main.tscn")
		return false
	if not level_requested or runtime == null:
		_try_bind_runtime()
		return false
	if not patrol_started:
		patrol_started = true
		monster_start = runtime.monster_root.global_position
		return false
	elapsed_patrol += delta
	if elapsed_patrol < 4.5:
		return false
	var patrol_distance: float = monster_start.distance_to(runtime.monster_root.global_position)
	print("MONSTER_PATROL_DISTANCE=%.3f" % patrol_distance)
	if patrol_distance < 1.0:
		_fail("Amalgam did not patrol before player interaction")
		return false
	if not _validate_horror_movement_profile():
		return false
	if not _validate_kitchen_corridor():
		return false
	if not _validate_mission_flow():
		return false
	print("HORROR_MONSTER_PATROL_OK")
	print("HORROR_MISSION_FLOW_OK")
	quit(0)
	return false


func _validate_horror_movement_profile() -> bool:
	player.set_horror_flashlight_mode(true)
	player.grounded = true
	player.vertical_velocity = 0.0
	player.horizontal_velocity = Vector3(4.0, 0.0, 0.0)
	var speed_before: float = player.horizontal_velocity.length()
	player.call("_handle_movement", 0.10)
	var speed_after: float = player.horizontal_velocity.length()
	# The dedicated horror brake removes 0.92 m/s over this step. Classic combat
	# friction would remove 1.6 m/s and expose an accidental branch regression.
	if speed_after < 2.90 or speed_after > 3.20 or speed_after >= speed_before:
		return _fail("Horror movement did not use its heavy braking profile: %.3f" % speed_after)
	player.horizontal_velocity = Vector3.ZERO
	player.call("_horror_jump")
	if player.vertical_velocity < 5.20 or player.vertical_velocity > 5.50 or player.grounded:
		return _fail("Horror jump did not use its grounded low jump profile")
	player.vertical_velocity = 0.0
	player.grounded = true
	if player.horror_stamina_ratio() < 0.999:
		return _fail("Horror sprint stamina was not preserved")
	if player.grapple_active or player.slide_active:
		return _fail("Combat traversal state leaked into horror movement")
	# Switching the chapter flag off must immediately return to the untouched
	# classic branch (4.0 - 16.0 * 0.1 = 2.4 m/s with no input).
	player.set_horror_flashlight_mode(false)
	player.horizontal_velocity = Vector3(4.0, 0.0, 0.0)
	player.call("_handle_movement", 0.10)
	var classic_speed_after: float = player.horizontal_velocity.length()
	if classic_speed_after < 2.30 or classic_speed_after > 2.50:
		return _fail("Non-horror movement branch changed unexpectedly: %.3f" % classic_speed_after)
	player.set_horror_flashlight_mode(true)
	player.horizontal_velocity = Vector3.ZERO
	print("HORROR_MOVEMENT_PROFILE_OK")
	return true


func _try_bind_runtime() -> void:
	if frame_count < 180 or current_scene == null:
		return
	level_manager = current_scene.get("level_manager")
	if level_manager == null:
		return
	runtime = level_manager.get("horror_runtime")
	player = current_scene.get("player")
	if runtime == null or player == null or not is_instance_valid(runtime.monster_root):
		runtime = null


func _validate_kitchen_corridor() -> bool:
	var anchor: Vector3 = runtime.task_anchors["kitchen"]
	# Sample the whole authored walking line from the broad junction to the room.
	for step in range(0, 76):
		var local_z := 33.0 - float(step) * 0.46
		var sample := anchor + Vector3(0.0, 0.48, local_z)
		if level_manager.is_blocked_world(sample, 0.42):
			return _fail("Kitchen corridor center blocked at local z %.2f" % local_z)
	# The long narrow section must still have physical shoulders on both sides.
	for local_z in [4.0, 18.0, 26.0]:
		for local_x in [-1.34, 1.34]:
			if not level_manager.is_blocked_world(anchor + Vector3(local_x, 0.48, local_z), 0.34):
				return _fail("Kitchen corridor wall missing at x %.2f z %.2f" % [local_x, local_z])
	if runtime.has_method("kitchen_replaces_grid_at") or runtime.has_method("kitchen_blocks_player"):
		return _fail("Legacy kitchen grid replacement API still exists")
	# The rebuilt opening service hall must retain its old broad width before it
	# compresses into the narrow final kitchen approach.
	for local_z in [27.0, 32.0, 37.0]:
		var width_cell: Vector2i = runtime._world_cell(anchor + Vector3(20.0, 0.48, local_z))
		if level_manager.get_cell(width_cell.x,width_cell.y) == "#":
			return _fail("Broad pre-kitchen service hall is unexpectedly narrow")
	for local_z in [25.55, 38.45]:
		if not level_manager.is_blocked_world(anchor + Vector3(20.0, 0.48, local_z), 0.30):
			return _fail("Broad pre-kitchen service hall has no outer wall")
	# Exercise the same movement and post-move embed recovery used by gameplay.
	# Follow the real campaign route: arrive from the east through the new broad
	# service hall, turn at the junction, and walk the full authored approach.
	# Walk the complete opening act, not a point spawned conveniently beside the
	# doorway. This catches disconnected chunks and invisible remnants anywhere
	# between the actual player spawn and the kitchen turn.
	var route_start: Vector3 = level_manager.spawn_pos
	var opening_waypoints := [
		runtime._cell_world(Vector2i(42, 128)),
		runtime._cell_world(Vector2i(30, 128)),
		runtime._cell_world(Vector2i(30, 118)),
		runtime._cell_world(Vector2i(10, 118))
	]
	for waypoint: Vector3 in opening_waypoints:
		if not _walk_player_path(route_start, waypoint, 220):
			return _fail("Player could not traverse rebuilt opening route to %s" % waypoint)
		route_start = player.global_position
	if not _walk_player_path(player.global_position, anchor + Vector3(0.0, 0.0, 27.45), 44):
		return _fail("Player could not enter the native kitchen approach")
	if not _walk_player_path(player.global_position, anchor + Vector3(0.0, 0.0, 1.25), 160):
		return _fail("Player could not traverse full kitchen corridor")
	# Reverse the entire compression sequence as well: narrow throat -> turning
	# vestibule -> broad service hall. This catches one-way corner traps caused by
	# new structural shoulders even when the inward centre line remains open.
	if not _walk_player_path(player.global_position, anchor + Vector3(0.0, 0.0, 27.45), 160):
		return _fail("Player could not leave the kitchen throat toward the vestibule")
	if not _walk_player_path(player.global_position, anchor + Vector3(0.0, 0.0, 32.0), 44):
		return _fail("Player could not turn through the service vestibule in reverse")
	if not _walk_player_path(player.global_position, anchor + Vector3(8.0, 0.0, 32.0), 64):
		return _fail("Player could not return from the vestibule to the broad hall")
	print("HORROR_KITCHEN_CORRIDOR_OK")
	return true


func _walk_player_path(from: Vector3, to: Vector3, steps: int) -> bool:
	# The new encounter props deliberately interrupt the old straight centreline.
	# Walk the real collision-aware route, not a line through the new obstacles.
	if player_navigation == null:
		player_navigation = AStarGrid2D.new()
		player_navigation.region = Rect2i(0,0,level_manager.map_cols,level_manager.map_rows)
		player_navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		player_navigation.update()
		for row in level_manager.map_rows:
			for col in level_manager.map_cols:
				var cell := Vector2i(col,row)
				player_navigation.set_point_solid(cell,level_manager.is_blocked_world(runtime._cell_world(cell)+Vector3.UP*0.48,0.42))
	var path := player_navigation.get_id_path(runtime._world_cell(from),runtime._world_cell(to))
	if path.is_empty():
		return false
	player.global_position = from
	for index in range(1,path.size()):
		var waypoint: Vector3 = runtime._cell_world(path[index])
		waypoint.y = from.y
		if not _walk_direct(player.global_position,waypoint,maxi(32,ceili(player.global_position.distance_to(waypoint)/0.12))):
			return false
	return _walk_direct(player.global_position,to,steps)

func _walk_direct(from: Vector3, to: Vector3, steps: int) -> bool:
	player.global_position = from
	player.grounded = true
	player.horizontal_velocity = Vector3.ZERO
	for step in steps:
		var remaining := maxi(steps - step, 1)
		var delta: Vector3 = (to - player.global_position) / float(remaining)
		player.call("_try_move", delta)
		player.call("_resolve_solid_embed")
	return player.global_position.distance_to(to) <= 0.32


func _validate_mission_flow() -> bool:
	for item_id in ["pan", "knife", "ingredients"]:
		if not _interact("kitchen_item", item_id):
			return _fail("Missing kitchen item: %s" % item_id)
	if not _interact("kitchen_stove", "stove"):
		return _fail("Kitchen stove is not interactive")
	runtime._tick_tasks(8.1)
	if not bool(runtime.task_states["kitchen"].get("complete", false)):
		return _fail("Kitchen task did not complete")
	if not _collect_task_fragment("kitchen"):
		return _fail("Kitchen fragment did not materialize")

	for item_id in ["tire", "fuel", "engine"]:
		if not _interact("car_part", item_id):
			return _fail("Missing car part: %s" % item_id)
		if not _interact("car_install", "car"):
			return _fail("Car installation point is not interactive")
	if not bool(runtime.task_states["car"].get("complete", false)):
		return _fail("Roadside repair did not complete")
	if not _collect_task_fragment("car"):
		return _fail("Roadside fragment did not materialize")

	if not _interact("passport_guide", "guide"):
		return _fail("Passport guide is not interactive")
	for item_id in ["passport", "visa", "declaration"]:
		if not _interact("passport_doc", item_id):
			return _fail("Missing passport document: %s" % item_id)
	for item_id in ["passport", "visa", "declaration"]:
		if not _interact("passport_submit", item_id):
			return _fail("Submission tray did not activate: %s" % item_id)
	if not bool(runtime.task_states["passport"].get("complete", false)):
		return _fail("Passport sequence did not complete")
	if not _collect_task_fragment("passport"):
		return _fail("Passport fragment did not materialize")
	if int(runtime.fragments_collected) != 3:
		return _fail("Expected 3 collected fragments, got %d" % int(runtime.fragments_collected))
	if runtime.objective_text() != "All memories recovered. Reach the memory gate":
		return _fail("Final exit objective did not unlock")
	return true


func _interact(action: String, item_id: String) -> bool:
	for item in runtime.interactables:
		if String(item.get("action", "")) == action and String(item.get("id", "")) == item_id and bool(item.get("active", true)):
			runtime._handle_interaction(item)
			return true
	return false


func _collect_task_fragment(task_id: String) -> bool:
	for fragment in runtime.fragments:
		if String(fragment.get("task", "")) == task_id and not bool(fragment.get("collected", false)):
			runtime._collect_fragment(fragment)
			return true
	return false


func _fail(reason: String) -> bool:
	push_error(reason)
	quit(1)
	return false
