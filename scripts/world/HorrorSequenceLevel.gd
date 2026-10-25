extends Node3D
class_name HorrorSequenceLevel
const DarkCrossingsScript = preload("res://scripts/world/HorrorDarkCrossings.gd")
const CreatureAnimationScript = preload("res://scripts/world/CreatureAnimationController.gd")
var dark_crossings

signal fragment_collected(current: int, total: int)
signal sequence_completed

const TILE = 4.0
const WALL_HEIGHT = 3.65
const FRAGMENT_TOTAL = 3
const URBAN_ASSET_ROOT = "res://assets/environment/brutalist_city/urban/"
const SEATED_WOMAN_MODEL_PATH = "res://assets/models/kadin_oturuyor.glb"
const MONSTER_PATROL_SPEED = 1.80
const MONSTER_SUSPICIOUS_SPEED = 0.85
const MONSTER_INVESTIGATE_SPEED = 1.80
const MONSTER_SEARCH_SPEED = 1.35
const MONSTER_CHASE_SPEED = 4.15
const MONSTER_CHASE_BURST_SPEED = 4.80
const MONSTER_SIGHT_RANGE = 34.0
const MONSTER_RELOCATE_DISTANCE = 52.0
const MONSTER_ATTACK_RANGE = 1.65
const MONSTER_ATTACK_WINDUP = 0.56
const MONSTER_STRIKE_DURATION = 0.28
const MONSTER_POUNCE_MIN_RANGE = 3.60
const MONSTER_POUNCE_MAX_RANGE = 6.55
const MONSTER_POUNCE_WINDUP = 0.70
const MONSTER_POUNCE_DURATION = 0.58
const MONSTER_POUNCE_COOLDOWN = 6.20
const MONSTER_POUNCE_RECOVERY = 1.05
const MONSTER_POUNCE_ARC_HEIGHT = 0.58
const MONSTER_POUNCE_DAMAGE = 28
const MONSTER_POUNCE_LIGHT_CANCEL_EXPOSURE = 0.16
const MONSTER_POUNCE_LIGHT_FLEE_EXPOSURE = 0.38
const MONSTER_CAMERA_CLEARANCE = 1.20
const MONSTER_FLASHLIGHT_RANGE = 22.0
const MONSTER_FLASHLIGHT_FULL_STRENGTH_RANGE = 10.0
const MONSTER_FLASHLIGHT_EDGE_DOT = 0.91
const MONSTER_FLASHLIGHT_CORE_DOT = 0.985
const MONSTER_LIGHT_REFLEX_DURATION = 0.52
const MONSTER_LIGHT_FOCUS_DELAY = 0.55
const MONSTER_LIGHT_FOCUS_BUILD_TIME = 0.65
const MONSTER_LIGHT_HUNT_BREAK_STRENGTH = 0.56
const MONSTER_LIGHT_EVASION_DURATION = 2.40
const MONSTER_LIGHT_FLEE_SPEED = 3.20
const MONSTER_LIGHT_FLEE_MIN_VISIBLE_TIME = 0.22
const MONSTER_HUNT_RESET_MIN_TIME = 4.8
const MONSTER_HUNT_RESET_MAX_TIME = 7.2
const MONSTER_VISUAL_ACQUIRE_CONFIDENCE = 0.62
const MONSTER_VISUAL_RELEASE_CONFIDENCE = 0.16
const MONSTER_LOST_SIGHT_MIN_TIME = 1.35
const MONSTER_LOST_SIGHT_MAX_TIME = 2.55
const MONSTER_REENTRY_ATTACK_GRACE = 1.35
const MONSTER_NOISE_MEMORY_LIMIT = 6
const MONSTER_SEARCH_POINT_LIMIT = 8
const MONSTER_MODEL_PATH = "res://assets/characters/corridor_creature/corridor_creature.glb"
const MONSTER_SMOKE_CLOUD_PATH = "res://assets/vfx/smoke/kenney_smoke_cloud.png"
const MONSTER_SMOKE_DARK_PATH = "res://assets/vfx/smoke/kenney_smoke_dark.png"
const MONSTER_MODEL_SCALE = 1.0
const MAX_LOCAL_MIST_PATCHES = 11
const MEMORY_ROOM_VISIBILITY_MARGIN = 30.0
const MEMORY_ROOM_VISIBILITY_UPDATE_INTERVAL = 0.20
# These systems drive effects with smoothing, so their expensive *decisions*
# can be sampled independently from the render frame.  This avoids periodic
# main-thread spikes without making the flashlight, flicker, or hunter move at
# a visibly lower frame rate.
const FLASHLIGHT_SURFACE_UPDATE_INTERVAL = 1.0 / 30.0
const FLICKER_LIGHT_UPDATE_INTERVAL = 1.0 / 30.0
const MONSTER_PERCEPTION_UPDATE_INTERVAL = 1.0 / 30.0
const MONSTER_STATIC_LIGHT_UPDATE_INTERVAL = 1.0 / 24.0
const KITCHEN_WOMAN_FOCUS_DURATION = 0.55
const KITCHEN_WOMAN_BLACKOUT_DURATION = 1.0
const KITCHEN_WOMAN_REVEAL_DURATION = 0.35

const SAFE_LIGHT_RADIUS = 2.40
const MONSTER_BODY_RADIUS = 0.85
const DARKNESS_HUNT_DELAY = 4.0
var darkness_time = 0.0
var player_in_safe_light = false
var flashlight_blocking_player = null
var creature_light_state := "clear"
var creature_light_clear_time := 0.0
var light_cycles: Node
var ceiling_escape_active := false
var creature_dark_approach_time := 0.0
var creature_light_state_time := 0.0
var creature_light_plan_time := 0.0
var creature_retreat_path: Array[Vector3] = []
var predator_attack = preload("res://scripts/world/CreaturePredatorAttack.gd").new()
var stalk_director = preload("res://scripts/world/CreatureStalkDirector.gd").new()
var creature_threat_state := "Patrol"
var creature_notice_timer := 0.0
var creature_previous_visual := false
var boundary_watch_active := false
var boundary_watch_age := 0.0
var boundary_plan_timer := 0.0
var monster_requested_motion := 0.0
var monster_path_endpoint := Vector3.ZERO
var battery_pickups: Array[Node3D] = []
var route_light_positions: Array[Vector3] = []
var level_manager
var wall_material: ShaderMaterial
var floor_material: ShaderMaterial
var ceiling_material: ShaderMaterial
var flashlight_reactive_materials: Array[ShaderMaterial] = []
var fragments: Array = []
var fragments_collected = 0
var exit_position = Vector3.ZERO
var exit_light: OmniLight3D
var exit_panel: MeshInstance3D
var flicker_lights: Array = []
var shader_light_positions := PackedVector3Array()
var shader_light_colors := PackedVector3Array()
var shader_light_strengths := PackedFloat32Array()
var monster_warding_lights: Array[Dictionary] = []
var completion_sent = false
var locked_hint_cooldown = 0.0
var elapsed = 0.0
var maze_raw: Array = []
var task_anchors: Dictionary = {}
var task_states: Dictionary = {}
var kitchen_woman_figure: Node3D
var kitchen_woman_jumpscare_state = "waiting"
var kitchen_woman_jumpscare_timer = 0.0
var kitchen_woman_blackout: ColorRect
var memory_room_visuals: Array[Dictionary] = []
var memory_room_visibility_timer = 0.0
var flashlight_surface_update_timer = 0.0
var flicker_light_update_timer = 0.0
var interactables: Array = []
var cooking_timer = 0.0
var passport_queue: Array[String] = []
var passport_guide_read = false
var noise_position = Vector3.ZERO
var noise_strength = 0.0
var noise_timer = 0.0
var noise_event_id = 0
var monster_processed_noise_event = -1
var monster_root: Node3D
var monster_limbs: Array = []
var monster_model: Node3D
var monster_animation_player: AnimationPlayer
var monster_skeleton: Skeleton3D
var creature_animation_driver
var creature_visual_last_position := Vector3.ZERO
var creature_visual_last_yaw := 0.0
var creature_beam_hold := 0.0
var monster_strike_timer := 0.0
var monster_strike_hit := false
var monster_active_animation = ""
var monster_gesture_timer = 2.2
var monster_gesture_index = 0
var monster_visual_roll = 0.0
var monster_visual_pitch = 0.0
var monster_previous_facing = 0.0
var monster_expression_root: Node3D
var monster_expression_material: StandardMaterial3D
var monster_expression_eyes: Array[Node3D] = []
var monster_expression_brows: Array[Node3D] = []
var monster_expression_mouth: Node3D
var monster_expression_strength = 0.0
var monster_expression_variant = -1
var monster_expression_flash_timer = 0.0
var monster_audio: AudioStreamPlayer3D
var monster_reentry_audio: AudioStreamPlayer3D
var monster_hunt_audio: AudioStreamPlayer3D
var monster_presence_light: OmniLight3D
var monster_face_light: OmniLight3D
var monster_navigation: AStarGrid2D
var monster_path: Array[Vector2i] = []
var monster_path_index = 0
var monster_repath_timer = 0.0
var monster_attack_timer = 0.0
var monster_awake = false
var monster_pounce_windup = 0.0
var monster_pounce_timer = 0.0
var monster_pounce_cooldown = 0.0
var monster_pounce_recovery_timer = 0.0
var monster_pounce_start = Vector3.ZERO
var monster_pounce_target = Vector3.ZERO
var monster_pounce_direction = Vector3.FORWARD
var monster_pounce_hit = false
var monster_pounce_visual_arc = 0.0
var monster_patrol_index = 0
var monster_patrol_points: Array[Vector3] = []
var monster_last_known_position = Vector3.ZERO
var monster_alert_timer = 0.0
var monster_search_pause = 0.0
var monster_state = "patrol"
var monster_state_timer = 0.0
var monster_lost_sight_timer = 0.0
var monster_search_points: Array[Vector3] = []
var monster_search_index = 0
var monster_stuck_timer = 0.0
var monster_relocate_cooldown = 0.0
var monster_last_motion_position = Vector3.ZERO
var monster_open_cells: Array[Vector2i] = []
var monster_player_trail: Array[Vector3] = []
var monster_trail_sample_timer = 0.0
var monster_unseen_timer = 0.0
var monster_path_failure_timer = 0.0
var monster_hunt_retarget_timer = 0.0
var monster_player_step_noise_timer = 0.0
var monster_current_speed = 0.0
var monster_motion_velocity = Vector3.ZERO
var monster_steering_direction = Vector3.ZERO
var monster_turn_velocity = 0.0
var monster_turn_lean = 0.0
var monster_stride_phase = 0.0
var monster_stride_cadence = 1.0
var monster_stride_cadence_target = 1.0
var monster_stride_variation_timer = 0.0
var monster_stride_side_bias = 0.0
var monster_head_gaze_offset = 0.0
var monster_head_gaze_velocity = 0.0
var monster_predator_crouch = 0.0
var monster_probe_timer = 0.0
var monster_probe_cooldown = 0.0
var monster_distress_blend = 0.0
var monster_flee_blend = 0.0
var monster_light_source_local = Vector3(0.0, 0.0, -1.0)
var monster_light_stagger_timer = 0.0
var monster_light_stagger_cooldown = 0.0
var monster_light_speed_impairment = 0.0
var monster_light_impact_timer = 0.0
var monster_escape_weave_sign = 1.0
var monster_escape_weave_seed = 0.0
var monster_awareness = 0.0
var monster_visual_confidence = 0.0
var monster_raw_visual_strength = 0.0
var monster_last_seen_direction = Vector3.ZERO
var monster_estimated_player_position = Vector3.ZERO
var monster_pursuit_target = Vector3.ZERO
var monster_pursuit_commit_timer = 0.0
var monster_visible_time = 0.0
var monster_has_visual = false
var monster_chase_time = 0.0
var monster_attack_windup = 0.0
var monster_last_seen_velocity = Vector3.ZERO
var monster_far_unseen_timer = 0.0
var monster_saw_locker_entry = false
var monster_heard_locker_entry = false
var monster_flashlight_exposure = 0.0
var monster_light_pain = 0.0
var monster_light_enrage = 0.0
var monster_light_contact_time = 0.0
var monster_light_reflex_timer = 0.0
var monster_light_reaction_cooldown = 0.0
var monster_light_flare = 0.0
var monster_light_burn_pulse_timer = 0.0
var monster_ambient_light_pressure = 0.0
var monster_light_evasion_timer = 0.0
var monster_light_evasion_retarget_timer = 0.0
var monster_light_evasion_target = Vector3.ZERO
var monster_light_flee_elapsed = 0.0
var monster_hunt_reset_timer = 0.0
var monster_hunt_reset_count = 0
var monster_reentry_grace_timer = 0.0
var monster_reentry_cue_timer = 0.0
var monster_recent_reentry_cells: Array[Vector2i] = []
var monster_director_tension = 0.34
var monster_director_quiet_time = 0.0
var monster_director_reposition_timer = 0.0
var monster_search_center = Vector3.ZERO
var monster_search_direction = Vector3.ZERO
var monster_search_wave = 0
var monster_search_seed = 0.0
var monster_search_scan_timer = 0.0
var monster_search_scan_anchor = 0.0
var monster_search_scan_sign = 1.0
var monster_search_scan_offset = 0.0
var monster_search_scan_target = 0.0
var monster_search_confidence = 0.0
var monster_search_visited: Array[Vector3] = []
var monster_noise_memories: Array[Dictionary] = []
var monster_next_noise_memory_id = 0
var monster_noise_sense_timer = 0.0
var monster_safe_zone_behavior = "watch"
var monster_safe_zone_behavior_timer = 0.0
var monster_locker_suspicion = 0.0
var monster_locker_check_timer = 0.0
var monster_locker_decision_made = false
var monster_safe_zone_target = Vector3.ZERO
var monster_perception_update_timer = 0.0
var monster_cached_audio_occluded = false
var monster_static_light_update_timer = 0.0
var monster_cached_static_light_pressure = 0.0
var ward_spatial_buckets: Dictionary = {}
var ward_spatial_count := -1
var monster_burn_smoke: GPUParticles3D
var monster_burn_smoke_wake: GPUParticles3D
var monster_burn_embers: GPUParticles3D
var monster_burn_aura: MeshInstance3D
var monster_burn_aura_material: ShaderMaterial
var monster_contact_shadow: MeshInstance3D
var monster_contact_shadow_material: ShaderMaterial
var monster_light_wisps: Array[Dictionary] = []
var monster_scorch_materials: Array[Dictionary] = []
var monster_pain_audio: AudioStreamPlayer3D
var active_locker: Dictionary = {}
var hide_lockers: Array = []
var room_asset_cache: Dictionary = {}
var light_shaft_material_cache: Dictionary = {}
var mist_material_cache: Dictionary = {}
var fixture_pool_material_cache: Dictionary = {}

func prepare(manager) -> void:
	level_manager = manager
	memory_room_visibility_timer = 0.0
	flashlight_surface_update_timer = 0.0
	flicker_light_update_timer = 0.0
	flashlight_reactive_materials.clear()
	shader_light_positions.clear()
	shader_light_colors.clear()
	shader_light_strengths.clear()
	monster_warding_lights.clear()
	ward_spatial_count = -1
	ward_spatial_buckets.clear()
	monster_light_pain = 0.0
	monster_light_enrage = 0.0
	monster_flashlight_exposure = 0.0
	monster_light_flare = 0.0
	monster_light_evasion_timer = 0.0
	monster_pounce_windup = 0.0
	monster_pounce_timer = 0.0
	monster_pounce_cooldown = 0.0
	monster_pounce_recovery_timer = 0.0
	monster_pounce_start = Vector3.ZERO
	monster_pounce_target = Vector3.ZERO
	monster_pounce_direction = Vector3.FORWARD
	monster_pounce_hit = false
	monster_pounce_visual_arc = 0.0
	monster_motion_velocity = Vector3.ZERO
	monster_steering_direction = Vector3.ZERO
	monster_turn_velocity = 0.0
	monster_turn_lean = 0.0
	monster_stride_phase = 0.0
	monster_stride_cadence = 1.0
	monster_stride_cadence_target = 1.0
	monster_stride_variation_timer = 0.0
	monster_stride_side_bias = 0.0
	monster_head_gaze_offset = 0.0
	monster_head_gaze_velocity = 0.0
	monster_predator_crouch = 0.0
	monster_probe_timer = 0.0
	monster_probe_cooldown = 0.0
	monster_distress_blend = 0.0
	monster_flee_blend = 0.0
	monster_light_source_local = Vector3(0.0, 0.0, -1.0)
	monster_light_stagger_timer = 0.0
	monster_light_stagger_cooldown = 0.0
	monster_light_speed_impairment = 0.0
	monster_light_impact_timer = 0.0
	monster_escape_weave_sign = 1.0
	monster_escape_weave_seed = randf_range(0.0, TAU)
	monster_light_flee_elapsed = 0.0
	monster_hunt_reset_timer = 0.0
	monster_hunt_reset_count = 0
	monster_reentry_grace_timer = 0.0
	monster_reentry_cue_timer = 0.0
	monster_recent_reentry_cells.clear()
	monster_director_tension = 0.34
	monster_director_quiet_time = 0.0
	monster_director_reposition_timer = 0.0
	monster_visual_confidence = 0.0
	monster_raw_visual_strength = 0.0
	monster_last_seen_direction = Vector3.ZERO
	monster_estimated_player_position = Vector3.ZERO
	monster_pursuit_target = Vector3.ZERO
	monster_pursuit_commit_timer = 0.0
	monster_search_center = Vector3.ZERO
	monster_search_direction = Vector3.ZERO
	monster_search_wave = 0
	monster_search_seed = randf_range(0.0, TAU)
	monster_search_scan_timer = 0.0
	monster_search_scan_anchor = 0.0
	monster_search_scan_sign = 1.0
	monster_search_scan_offset = 0.0
	monster_search_scan_target = 0.0
	monster_search_confidence = 0.0
	monster_search_visited.clear()
	monster_noise_memories.clear()
	monster_next_noise_memory_id = 0
	monster_noise_sense_timer = 0.0
	monster_safe_zone_behavior = "watch"
	monster_safe_zone_behavior_timer = 0.0
	monster_locker_suspicion = 0.0
	monster_locker_check_timer = 0.0
	monster_locker_decision_made = false
	monster_perception_update_timer = 0.0
	monster_cached_audio_occluded = false
	monster_static_light_update_timer = 0.0
	monster_cached_static_light_pressure = 0.0
	monster_scorch_materials.clear()
	monster_light_wisps.clear()
	kitchen_woman_figure = null
	kitchen_woman_jumpscare_state = "waiting"
	kitchen_woman_jumpscare_timer = 0.0
	kitchen_woman_blackout = null
	wall_material = _make_concrete_shader(Color(0.35, 0.36, 0.33), 0.30, 0.94)
	floor_material = _make_concrete_shader(Color(0.34, 0.35, 0.31), 0.42, 0.82)
	ceiling_material = _make_concrete_shader(Color(0.15, 0.16, 0.14), 0.22, 0.98)
	wall_material.set_shader_parameter("surface_kind", 1)
	floor_material.set_shader_parameter("surface_kind", 2)

func build(raw: Array, fragment_positions: Array, requested_exit: Vector3) -> void:
	maze_raw = raw.duplicate(true)
	exit_position = requested_exit
	# Resolve the three native room anchors before corridor dressing and authored
	# room construction. The base grid already contains their intended volumes.
	var ordered_anchors = fragment_positions.duplicate()
	ordered_anchors.sort_custom(func(a, b): return a.z > b.z)
	if ordered_anchors.size() >= 3:
		task_anchors = {
			"kitchen": ordered_anchors[0],
			"car": ordered_anchors[1],
			"passport": ordered_anchors[2]
		}
	_build_corridor_dressing(raw)
	_build_exit_marker()
	if task_anchors.size() >= 3:
		_build_kitchen_scenario(task_anchors["kitchen"])
		_build_kitchen_woman_blackout()
		_build_deferred_car_placeholder(task_anchors["car"])
		_build_deferred_passport_placeholder(task_anchors["passport"])
	_build_safe_light_route(raw)
	dark_crossings = DarkCrossingsScript.new()
	dark_crossings.name = "DarkCrossingEncounters"
	add_child(dark_crossings)
	dark_crossings.build(self, raw)
	level_manager.rebuild_horror_solid_index()
	_build_merged_walls(raw)
	_build_battery_pickups(raw)
	dark_crossings.relocate_batteries(battery_pickups)
	_sync_fixture_shader_lights()
	_build_monster_navigation(raw)
	light_cycles = preload("res://scripts/world/HorrorLightCycles.gd").new()
	add_child(light_cycles)
	light_cycles.build(self)
	_build_monster_search_route()
	_build_hide_lockers(raw)
	_spawn_amalgam()

func tick(dt: float, player) -> void:
	if player == null or bool(player.paused):
		return
	elapsed += dt
	if is_instance_valid(light_cycles):
		light_cycles.tick(dt, player)
	_tick_darkness_and_batteries(dt, player)
	if is_instance_valid(dark_crossings):
		dark_crossings.tick(dt, player)
	_update_memory_room_visibility(dt, player)
	_tick_kitchen_woman_jumpscare(dt, player)
	locked_hint_cooldown = max(0.0, locked_hint_cooldown - dt)
	noise_timer = max(0.0, noise_timer - dt)
	monster_attack_timer = max(0.0, monster_attack_timer - dt)
	monster_pounce_cooldown = max(0.0, monster_pounce_cooldown - dt)
	monster_alert_timer = max(0.0, monster_alert_timer - dt)
	monster_search_pause = max(0.0, monster_search_pause - dt)
	monster_search_scan_timer = max(0.0, monster_search_scan_timer - dt)
	if monster_search_pause <= 0.0:
		monster_search_scan_target = 0.0
		monster_search_scan_offset = move_toward(monster_search_scan_offset, 0.0, dt * 1.35)
	monster_state_timer = max(0.0, monster_state_timer - dt)
	monster_relocate_cooldown = max(0.0, monster_relocate_cooldown - dt)
	monster_trail_sample_timer -= dt
	monster_hunt_retarget_timer = max(0.0, monster_hunt_retarget_timer - dt)
	monster_player_step_noise_timer = max(0.0, monster_player_step_noise_timer - dt)
	if player != null and not bool(player.horror_hidden) and monster_trail_sample_timer <= 0.0:
		monster_trail_sample_timer = 0.42
		monster_player_trail.append(player.global_position)
		if monster_player_trail.size() > 20:
			monster_player_trail.pop_front()
	if player != null and not bool(player.horror_hidden) and bool(player.grounded) and float(player.horizontal_speed) > 0.85 and monster_player_step_noise_timer <= 0.0:
		var sprinting = bool(player.horror_sprint_active)
		var movement_noise = 0.84 if sprinting else lerp(0.22, 0.38, clamp(float(player.horizontal_speed) / 5.2, 0.0, 1.0))
		_make_noise(player.global_position, movement_noise, 0.72 if sprinting else 0.48)
		monster_player_step_noise_timer = 0.27 if sprinting else 0.64
	_update_flashlight_materials(dt, player)
	_update_lights(dt)
	_tick_tasks(dt)
	_tick_interactables(dt, player)
	_tick_amalgam(dt, player)
	for fragment in fragments:
		if bool(fragment["collected"]) or not is_instance_valid(fragment["node"]):
			continue
		fragment["node"].rotation.y += dt * 0.72
		fragment["node"].position.y = float(fragment["base_y"]) + sin(elapsed * 1.55 + float(fragment["phase"])) * 0.10
		if player.global_position.distance_to(fragment["node"].global_position) <= 1.35:
			_collect_fragment(fragment)
	if completion_sent or player == null:
		return
	if player.global_position.distance_to(exit_position) <= 1.75:
		if fragments_collected >= FRAGMENT_TOTAL:
			completion_sent = true
			sequence_completed.emit()
		elif locked_hint_cooldown <= 0.0:
			locked_hint_cooldown = 2.2
			level_manager.message.emit("MEMORY GATE: %d / %d" % [fragments_collected, FRAGMENT_TOTAL])

func _register_memory_room_visual(root: Node3D, half_extents: Vector2) -> void:
	memory_room_visuals.append({"root": root, "half_extents": half_extents})

func _inside_kitchen_art_zone(position: Vector3) -> bool:
	# Used only to keep generic corridor props out of the deliberately composed
	# kitchen reveal. Geometry and collision do not depend on a grid override.
	if not task_anchors.has("kitchen"):
		return false
	var local := position - Vector3(task_anchors["kitchen"])
	return absf(local.x) <= 6.25 and local.z >= -6.25 and local.z <= 32.25

func _update_memory_room_visibility(dt: float, player) -> void:
	memory_room_visibility_timer -= dt
	if memory_room_visibility_timer > 0.0 or player == null:
		return
	memory_room_visibility_timer = MEMORY_ROOM_VISIBILITY_UPDATE_INTERVAL
	if bool(get_tree().get_meta("killgore_disable_room_culling", false)):
		for room_data in memory_room_visuals:
			var debug_room: Node3D = room_data.get("root")
			if is_instance_valid(debug_room) and not debug_room.visible:
				debug_room.visible = true
		return
	var player_position: Vector3 = player.global_position
	var margin_squared := MEMORY_ROOM_VISIBILITY_MARGIN * MEMORY_ROOM_VISIBILITY_MARGIN
	for room_data in memory_room_visuals:
		var room: Node3D = room_data.get("root")
		if not is_instance_valid(room):
			continue
		var half_extents: Vector2 = room_data.get("half_extents", Vector2.ZERO)
		var local_position := player_position - room.global_position
		var outside_x := maxf(absf(local_position.x) - half_extents.x, 0.0)
		var outside_z := maxf(absf(local_position.z) - half_extents.y, 0.0)
		var should_be_visible = outside_x * outside_x + outside_z * outside_z <= margin_squared
		# Re-applying the same visibility state forces unnecessary renderer work on
		# every 0.20-second room check. Only crossing a real room boundary changes
		# the render tree, keeping the authored culling behaviour intact.
		if room.visible != should_be_visible:
			room.visible = should_be_visible

func use(player) -> bool:
	var item = _nearest_interactable(player, 2.45)
	if item.is_empty():
		return false
	_handle_interaction(item, player)
	return true

func interact_prompt(player) -> String:
	var item = _nearest_interactable(player, 2.45)
	if item.is_empty():
		return ""
	if String(item.get("action", "")) == "hide_locker" and bool(player.horror_hidden):
		return "E  LEAVE LOCKER"
	return "E  %s" % String(item.get("label", "INTERACT"))

func objective_text() -> String:
	if not bool(task_states.get("kitchen", {}).get("complete", false)):
		var state: Dictionary = task_states.get("kitchen", {})
		if bool(state.get("cooking", false)):
			return "KITCHEN: The stove is loud. Stay alive until the meal is ready"
		return "KITCHEN: Find the pan, knife and ingredients (%d / 3)" % int(state.get("found", {}).size())
	if not _task_fragment_collected("kitchen"):
		return "KITCHEN: Collect the materialized memory fragment"
	if not bool(task_states.get("car", {}).get("complete", false)):
		var state: Dictionary = task_states.get("car", {})
		return "ROADSIDE: Recover and install the tire, fuel and engine part (%d / 3)" % int(state.get("installed", 0))
	if not _task_fragment_collected("car"):
		return "ROADSIDE: Collect the materialized memory fragment"
	if not bool(task_states.get("passport", {}).get("complete", false)):
		var state: Dictionary = task_states.get("passport", {})
		if not passport_guide_read:
			return "CHECKPOINT: Find and read the processing guide"
		return "CHECKPOINT: Submit PASSPORT, VISA, DECLARATION (%d / 3)" % int(state.get("submitted", 0))
	if not _task_fragment_collected("passport"):
		return "CHECKPOINT: Collect the materialized memory fragment"
	return "All memories recovered. Reach the memory gate"

func _task_fragment_collected(task_id: String) -> bool:
	for fragment in fragments:
		if String(fragment.get("task", "")) == task_id:
			return bool(fragment.get("collected", false))
	return false

func map_markers() -> Array:
	var out: Array = []
	for task_id in ["kitchen", "car", "passport"]:
		if task_anchors.has(task_id):
			out.append({
				"id": task_id,
				"position": task_anchors[task_id],
				"complete": bool(task_states.get(task_id, {}).get("complete", false))
			})
	return out

func monster_map_marker() -> Dictionary:
	if not is_instance_valid(monster_root):
		return {}
	return {
		"position": monster_root.global_position,
		"state": monster_state
	}

func _tick_tasks(dt: float) -> void:
	if cooking_timer <= 0.0:
		return
	cooking_timer = max(0.0, cooking_timer - dt)
	_make_noise(task_anchors["kitchen"], 1.0, 0.35)
	if cooking_timer <= 0.0:
		_complete_task("kitchen")
		level_manager.message.emit("THE MEAL REMEMBERS YOU")

func _tick_interactables(dt: float, player) -> void:
	for item in interactables:
		var node = item.get("node")
		if not bool(item.get("active", true)) or not is_instance_valid(node):
			continue
		if bool(item.get("bob", true)):
			node.rotation.y += dt * 0.55
			node.position.y = float(item.get("base_y", node.position.y)) + sin(elapsed * 1.7 + float(item.get("phase", 0.0))) * 0.035

func _nearest_interactable(player, radius: float) -> Dictionary:
	if player == null:
		return {}
	if bool(player.horror_hidden) and not active_locker.is_empty():
		return active_locker
	var best: Dictionary = {}
	var best_distance = radius * radius
	for item in interactables:
		if not bool(item.get("active", true)):
			continue
		var node = item.get("node")
		if not is_instance_valid(node):
			continue
		var distance = player.global_position.distance_squared_to(node.global_position)
		if distance < best_distance:
			best_distance = distance
			best = item
	return best

func _handle_interaction(item: Dictionary, player = null) -> void:
	var action = String(item.get("action", ""))
	var item_id = String(item.get("id", ""))
	match action:
		"hide_locker":
			if player == null:
				return
			if bool(player.horror_hidden):
				var leave_position: Vector3 = item.get("exit_position", player.global_position)
				player.set_horror_hidden(false)
				player.global_position = leave_position
				_make_noise(leave_position, 0.34, 0.42)
				active_locker = {}
				monster_saw_locker_entry = false
				monster_heard_locker_entry = false
				monster_locker_suspicion = 0.0
				monster_locker_decision_made = false
			else:
				var locker_position: Vector3 = item["node"].global_position
				var monster_distance = monster_root.global_position.distance_to(player.global_position) if is_instance_valid(monster_root) else INF
				monster_saw_locker_entry = is_instance_valid(monster_root) and _monster_can_see_player(player, monster_distance)
				monster_heard_locker_entry = is_instance_valid(monster_root) and monster_root.global_position.distance_to(locker_position) <= 9.5
				active_locker = item
				monster_locker_check_timer = 0.0
				monster_locker_decision_made = false
				if monster_saw_locker_entry:
					monster_locker_suspicion = 1.0
				elif monster_heard_locker_entry:
					monster_locker_suspicion = 0.66
				elif monster_state == "chase":
					monster_locker_suspicion = 0.46
				else:
					monster_locker_suspicion = 0.18
				if monster_saw_locker_entry:
					monster_last_known_position = locker_position
					_begin_monster_search(locker_position)
				elif monster_state == "chase":
					_begin_monster_search(monster_last_known_position)
				_make_noise(locker_position, 0.30, 0.38)
				player.set_horror_hidden(true, item.get("hide_position", player.global_position), float(item.get("hide_yaw", player.yaw)))
		"kitchen_item":
			var found: Dictionary = task_states["kitchen"]["found"]
			if not found.has(item_id):
				found[item_id] = true
				_consume_interactable(item)
				_make_noise(item["node"].global_position if is_instance_valid(item.get("node")) else task_anchors["kitchen"], 0.42, 2.4)
				level_manager.message.emit("KITCHEN ITEM: %s" % String(item.get("short", item_id)).to_upper())
		"kitchen_stove":
			var state: Dictionary = task_states["kitchen"]
			if bool(state.get("complete", false)) or bool(state.get("cooking", false)):
				return
			if int(state["found"].size()) < 3:
				level_manager.message.emit("THE RECIPE IS INCOMPLETE")
				return
			state["cooking"] = true
			cooking_timer = 8.0
			_make_noise(task_anchors["kitchen"], 1.0, 8.5)
			level_manager.message.emit("COOKING STARTED")
		"car_part":
			var collected: Dictionary = task_states["car"]["collected"]
			if not collected.has(item_id):
				collected[item_id] = true
				_consume_interactable(item)
				level_manager.message.emit("CAR PART: %s" % String(item.get("short", item_id)).to_upper())
		"car_install":
			var state: Dictionary = task_states["car"]
			if bool(state.get("complete", false)):
				return
			var next_part = ""
			for part in ["tire", "fuel", "engine"]:
				if state["collected"].has(part) and not state["fitted"].has(part):
					next_part = part
					break
			if next_part == "":
				level_manager.message.emit("FIND A MISSING CAR PART")
				return
			state["fitted"][next_part] = true
			state["installed"] = int(state.get("installed", 0)) + 1
			_make_noise(task_anchors["car"], 0.88, 4.0)
			level_manager.message.emit("INSTALLED %s (%d / 3)" % [next_part.to_upper(), int(state["installed"])])
			if int(state["installed"]) >= 3:
				_complete_task("car")
		"passport_guide":
			passport_guide_read = true
			level_manager.message.emit("ORDER: PASSPORT > VISA > DECLARATION")
		"passport_doc":
			var documents: Dictionary = task_states["passport"]["documents"]
			if not documents.has(item_id):
				documents[item_id] = true
				_consume_interactable(item)
				_activate_submission_pad(item_id)
				level_manager.message.emit("DOCUMENT FOUND: %s" % item_id.to_upper())
		"passport_submit":
			_submit_passport_document(item_id)

func _consume_interactable(item: Dictionary) -> void:
	item["active"] = false
	var node = item.get("node")
	if is_instance_valid(node):
		node.visible = false

func _activate_submission_pad(document_id: String) -> void:
	for item in interactables:
		if String(item.get("action", "")) == "passport_submit" and String(item.get("id", "")) == document_id:
			item["active"] = true
			var node = item.get("node")
			if is_instance_valid(node):
				node.visible = true

func _submit_passport_document(document_id: String) -> void:
	if not passport_guide_read:
		level_manager.message.emit("READ THE PROCESSING GUIDE FIRST")
		return
	var state: Dictionary = task_states["passport"]
	var order = ["passport", "visa", "declaration"]
	var expected = String(order[int(state.get("submitted", 0))])
	if document_id != expected:
		state["submitted"] = 0
		_make_noise(task_anchors["passport"], 1.0, 5.0)
		level_manager.message.emit("PROCESSING ERROR. ORDER RESET")
		return
	state["submitted"] = int(state.get("submitted", 0)) + 1
	level_manager.message.emit("ACCEPTED: %s" % document_id.to_upper())
	if int(state["submitted"]) >= 3:
		_complete_task("passport")

func _complete_task(task_id: String) -> void:
	var state: Dictionary = task_states[task_id]
	if bool(state.get("complete", false)):
		return
	state["complete"] = true
	monster_director_tension = min(1.0, monster_director_tension + 0.20)
	_add_memory_fragment(task_anchors[task_id], task_id)
	level_manager.message.emit("MEMORY FRAGMENT MATERIALIZED")

func _make_noise(position: Vector3, strength: float, duration: float) -> void:
	noise_position = position
	noise_strength = max(noise_strength, strength)
	noise_timer = max(noise_timer, duration)
	noise_event_id += 1
	var merged_memory = false
	if not monster_noise_memories.is_empty():
		var latest: Dictionary = monster_noise_memories.back()
		var latest_position: Vector3 = latest.get("position", Vector3.INF)
		if latest_position.distance_to(position) < 1.0 and float(latest.get("remaining", 0.0)) > 0.0:
			latest["strength"] = max(float(latest.get("strength", 0.0)), clamp(strength, 0.0, 1.0))
			latest["duration"] = max(float(latest.get("duration", 0.0)), max(duration, 0.12))
			latest["remaining"] = max(float(latest.get("remaining", 0.0)), max(duration, 0.12))
			merged_memory = true
	if not merged_memory:
		monster_next_noise_memory_id += 1
		monster_noise_memories.append({
			"id": monster_next_noise_memory_id,
			"position": position,
			"strength": clamp(strength, 0.0, 1.0),
			"duration": max(duration, 0.12),
			"remaining": max(duration, 0.12),
			"processed": false
		})
	while monster_noise_memories.size() > MONSTER_NOISE_MEMORY_LIMIT:
		monster_noise_memories.pop_front()
	monster_director_tension = min(1.0, monster_director_tension + strength * (0.0008 if merged_memory else 0.055))
	if strength >= 0.55:
		monster_awake = true

func _build_kitchen_scenario(anchor: Vector3) -> void:
	task_states["kitchen"] = {"complete": false, "found": {}, "cooking": false}
	var root = Node3D.new()
	root.name = "MemoryRoom_Kitchen"
	root.position = anchor
	root.set_meta("skip_static_room_batch", true)
	add_child(root)
	_register_memory_room_visual(root, Vector2(6.3, 32.4))
	var enamel = _dim_lit_material(Color8(117, 108, 89), 0.84, 0.62)
	var tile = _room_surface(Color8(58, 58, 52), 0.94)
	var cabinet = _dim_lit_material(Color8(43, 36, 29), 0.94, 0.38)
	var room_wall = _room_surface(Color8(45, 43, 37), 0.97)
	var wood = _dim_lit_material(Color8(77, 48, 29), 0.82, 0.54)
	var steel = _dim_lit_material(Color8(79, 76, 66), 0.52, 0.46)
	var grease = _dim_lit_material(Color8(20, 18, 15), 0.97, 0.14)
	var warm = _glow_material(Color8(218, 169, 86), 1.42)
	# Slightly larger than the first pass: furniture remains domestic scale while
	# circulation around the table gains enough room to stop feeling cramped.
	const ROOM_WIDTH := 5.90
	const ROOM_DEPTH := 4.60
	const ROOM_HEIGHT := 2.75
	const BASE_CELL_HALF := 6.0
	const BASE_CEILING := 3.65
	# The new base map reserves this complete volume as open space. The kitchen
	# shell below is therefore the only architecture here, rather than a room
	# layered over an older maze room.
	for ceiling_x in [-1.98, 0.0, 1.98]:
		for ceiling_z in [-1.15, 1.15]:
			_add_box(root, Vector3(1.90, 0.09, 2.20), Vector3(ceiling_x, ROOM_HEIGHT, ceiling_z), tile)
	_add_structure_box(root, Vector3(ROOM_WIDTH, ROOM_HEIGHT, 0.16), Vector3(0, ROOM_HEIGHT * 0.5, -2.30), room_wall)
	_add_structure_box(root, Vector3(0.16, ROOM_HEIGHT, ROOM_DEPTH), Vector3(-2.95, ROOM_HEIGHT * 0.5, 0), room_wall)
	# Right wall keeps the framed picture visible while retaining the service exit
	# at the back corner for the continuing level route.
	_add_structure_box(root, Vector3(0.16, ROOM_HEIGHT, 0.72), Vector3(2.95, ROOM_HEIGHT * 0.5, -1.94), room_wall)
	_add_structure_box(root, Vector3(0.16, ROOM_HEIGHT, 2.32), Vector3(2.95, ROOM_HEIGHT * 0.5, 1.14), room_wall)
	_add_box(root, Vector3(0.18, 0.20, 1.56), Vector3(2.95, 2.65, -0.80), cabinet)
	# South wall and door frame create the exact corridor-to-room reveal.
	_add_structure_box(root, Vector3(1.95, ROOM_HEIGHT, 0.16), Vector3(-1.975, ROOM_HEIGHT * 0.5, 2.30), room_wall)
	_add_structure_box(root, Vector3(1.95, ROOM_HEIGHT, 0.16), Vector3(1.975, ROOM_HEIGHT * 0.5, 2.30), room_wall)
	_add_box(root, Vector3(2.00, 0.20, 0.20), Vector3(0, 2.65, 2.30), cabinet)
	for x in [-1.00, 1.00]:
		_add_box(root, Vector3(0.14, 2.61, 0.22), Vector3(x, 1.305, 2.24), steel)
	# The reserved grid envelope is twelve metres wide. These solid shoulders form
	# the compact room inside that envelope and meet its native outer walls cleanly.
	_add_structure_box(root, Vector3(3.05, BASE_CEILING, ROOM_DEPTH), Vector3(-4.475, BASE_CEILING * 0.5, 0), room_wall)
	_add_structure_box(root, Vector3(3.05, BASE_CEILING, 0.72), Vector3(4.475, BASE_CEILING * 0.5, -1.94), room_wall)
	_add_structure_box(root, Vector3(3.05, BASE_CEILING, 2.28), Vector3(4.475, BASE_CEILING * 0.5, 1.16), room_wall)
	_add_structure_box(root, Vector3(BASE_CELL_HALF * 2.0, BASE_CEILING, 3.70), Vector3(0, BASE_CEILING * 0.5, -4.15), room_wall)
	# Dark final approach. The surrounding base grid is intentionally open across
	# three cells; these are its real walls and ordinary registered collision.
	const APPROACH_START_Z := 2.30
	const APPROACH_END_Z := 27.90
	const APPROACH_LENGTH := APPROACH_END_Z - APPROACH_START_Z
	const APPROACH_CENTER_Z := (APPROACH_START_Z + APPROACH_END_Z) * 0.5
	# A real left-hand maintenance bypass preserves the kitchen doorway and the
	# original direct passage. Both openings exceed the hunter's body clearance.
	for segment in [[2.30,10.4], [24.8,27.90]]:
		_add_structure_box(root, Vector3(4.92, BASE_CEILING, segment[1]-segment[0]), Vector3(-3.54, BASE_CEILING*0.5, (segment[0]+segment[1])*0.5), room_wall)
	_add_structure_box(root, Vector3(0.16, BASE_CEILING, 14.4), Vector3(-5.92, BASE_CEILING*0.5,17.6),room_wall)
	_add_structure_box(root, Vector3(1.20, BASE_CEILING,7.0), Vector3(-1.70,BASE_CEILING*0.5,17.6),room_wall)
	_add_box(root, Vector3(4.76,0.09,14.4),Vector3(-3.46,ROOM_HEIGHT,17.6),tile)
	_add_structure_box(root, Vector3(4.92, BASE_CEILING, APPROACH_LENGTH), Vector3(3.54, BASE_CEILING * 0.5, APPROACH_CENTER_Z), room_wall)
	_add_box(root, Vector3(2.15, 0.09, APPROACH_LENGTH), Vector3(0, ROOM_HEIGHT, APPROACH_CENTER_Z), tile)
	# The broad service hall now enters a real orthogonal vestibule before the
	# retained 2.15 m kitchen throat. Four staggered structural shoulders replace
	# the former pair of monolithic blocks, opening a 4.2 m first bay and a 4.0 m
	# turning bay before the final compression. Every visible floor-level mass is
	# registered through ordinary collision.
	_add_box(root, Vector3(2.15, 0.90, 0.18), Vector3(0, 3.20, 27.88), room_wall)
	_add_structure_box(root, Vector3(2.80, BASE_CEILING, 5.60), Vector3(-4.60, BASE_CEILING * 0.5, 30.70), room_wall)
	_add_structure_box(root, Vector3(2.12, BASE_CEILING, 3.10), Vector3(-2.14, BASE_CEILING * 0.5, 29.45), room_wall)
	_add_structure_box(root, Vector3(2.80, BASE_CEILING, 2.75), Vector3(4.60, BASE_CEILING * 0.5, 29.225), room_wall)
	_add_structure_box(root, Vector3(2.12, BASE_CEILING, 1.15), Vector3(2.14, BASE_CEILING * 0.5, 28.425), room_wall)
	_build_kitchen_service_transition(root, room_wall, cabinet, steel, grease, tile)
	# Left recessed door and right picture panel reproduce the interior landmarks.
	_add_box(root, Vector3(0.035, 2.10, 1.12), Vector3(-2.855, 1.05, 0.30), grease)
	for frame_z in [-0.36, 0.96]:
		_add_box(root, Vector3(0.055, 2.28, 0.07), Vector3(-2.825, 1.14, frame_z), steel)
	_add_box(root, Vector3(0.055, 0.07, 1.39), Vector3(-2.825, 2.245, 0.30), steel)
	_add_box(root, Vector3(0.035, 1.02, 1.20), Vector3(2.855, 1.48, 0.88), grease)
	for frame_z in [0.22, 1.54]:
		_add_box(root, Vector3(0.045, 1.12, 0.06), Vector3(2.825, 1.48, frame_z), steel)
	for frame_y in [0.92, 2.04]:
		_add_box(root, Vector3(0.045, 0.06, 1.32), Vector3(2.825, frame_y, 0.88), steel)
	# Fine floor joints replace the oversized grid seen in the previous version.
	for x in [-1.80, -0.90, 0.0, 0.90, 1.80]:
		_add_box(root, Vector3(0.016, 0.012, 4.40), Vector3(x, -0.012, 0), grease)
	for z in [-1.40, -0.70, 0.0, 0.70, 1.40]:
		_add_box(root, Vector3(5.65, 0.012, 0.016), Vector3(0, -0.012, z), grease)
	_build_compact_kitchen_table(root, Vector3(0.0, 0.0, 0.55), wood, enamel, steel, grease, warm)
	_build_compact_kitchen_line(root, enamel, cabinet, steel, grease, warm)
	_build_kitchen_pendant(root, cabinet, steel, warm)
	# The corridor stays black; these pools terminate inside the room so the warm
	# tableau remains legible through the doorway even with the flashlight off.
	_add_hero_spot(root, Vector3(0.0, 1.92, 0.42), Vector3(0.0, 0.78, 0.55), Color8(224, 172, 91), 6.40, 4.15, 51.0)
	_add_practical_omni(root, Vector3(0.0, 1.88, 0.42), Color8(214, 153, 70), 1.20, 2.75)
	_add_hero_spot(root, Vector3(0.0, 2.05, -1.66), Vector3(0.0, 0.86, -1.92), Color8(207, 153, 82), 3.80, 3.20, 58.0)
	_add_room_fill_light(root, Vector3(0.0, 1.42, -0.35), Color8(118, 82, 48), 0.42, 4.25)
	var stove = Node3D.new()
	stove.name = "Stove_Interact"
	stove.position = Vector3(0.58, 0.0, -1.90)
	root.add_child(stove)
	_add_box(stove, Vector3(0.78, 0.88, 0.68), Vector3(0, 0.44, 0), enamel)
	_add_box(stove, Vector3(0.82, 0.055, 0.72), Vector3(0, 0.91, 0), steel)
	for burner_position in [Vector3(-0.20, 0.95, -0.18), Vector3(0.20, 0.95, -0.18), Vector3(-0.20, 0.95, 0.18), Vector3(0.20, 0.95, 0.18)]:
		_add_disc(stove, burner_position, 0.10, 0.025, grease)
	_add_box(stove, Vector3(0.58, 0.36, 0.035), Vector3(0, 0.48, 0.36), grease)
	_add_interactable("stove", "kitchen_stove", stove, "COOK THE MEAL", "STOVE", false)
	var pan_prop = _make_task_prop(root, Vector3(0.58, 1.02, -1.88), "pan", steel)
	pan_prop.scale = Vector3.ONE * 0.48
	var knife_prop = _make_task_prop(root, Vector3(-0.62, 0.92, 0.52), "knife", steel)
	knife_prop.scale = Vector3.ONE * 0.52
	var ingredient_prop = _make_task_prop(root, Vector3(-0.25, 1.06, -1.86), "box", warm)
	ingredient_prop.scale = Vector3.ONE * 0.58
	_add_interactable("pan", "kitchen_item", pan_prop, "TAKE PAN", "PAN")
	_add_interactable("knife", "kitchen_item", knife_prop, "TAKE KNIFE", "KNIFE")
	_add_interactable("ingredients", "kitchen_item", ingredient_prop, "TAKE INGREDIENTS", "INGREDIENTS")
	_batch_static_room_boxes(root)

func _build_kitchen_service_transition(root: Node3D, wall: Material, dark_metal: Material, steel: Material, recess: Material, ceiling_tile: Material) -> void:
	# The route arrives from +X, turns left, then commits to the narrow -Z run.
	# Everything in this pass is cladding or overhead architecture: the ordinary
	# structural boxes above remain the single source of collision and navigation.
	var transition = Node3D.new()
	transition.name = "KitchenServiceTransition"
	root.add_child(transition)
	var service_amber := _dim_lit_material(Color8(88, 70, 40), 0.92, 0.24)

	# Three separate ceiling rafts follow only open floor and lower at each portal.
	# Deliberate gaps contain the bulkhead headers, so no ceiling face intersects a
	# wall or appears to float through another slab.
	_add_box(transition, Vector3(5.55, 0.14, 9.70), Vector3(8.925, 3.47, 32.0), ceiling_tile)
	_add_box(transition, Vector3(4.30, 0.14, 4.15), Vector3(3.65, 3.13, 33.025), ceiling_tile)
	_add_box(transition, Vector3(2.14, 0.12, 2.50), Vector3(0.0, 2.77, 29.30), ceiling_tile)

	# First portal: the broad hall compresses to a clearly supported 4.2 m service
	# bay. The jambs stop exactly at the header underside; separate caps previously
	# penetrated both pieces and made the joint flicker from oblique views.
	for portal_z in [30.78, 35.22]:
		_add_structure_box(transition, Vector3(0.38, 2.76, 0.38), Vector3(5.82, 1.38, portal_z), wall)
	_add_box(transition, Vector3(0.38, 0.30, 4.82), Vector3(5.82, 2.91, 33.0), dark_metal)

	# Second portal turns the widened bay toward the narrow approach. Its left end
	# meets the west shoulder face while the right jamb stops at its underside.
	_add_structure_box(transition, Vector3(0.36, 2.55, 0.36), Vector3(3.02, 1.275, 30.82), wall)
	_add_box(transition, Vector3(4.28, 0.28, 0.34), Vector3(1.06, 2.69, 30.82), dark_metal)
	_add_box(transition, Vector3(3.92, 0.055, 0.12), Vector3(0.97, 2.52, 30.69), service_amber)

	# Shallow wall piers echo the ceiling bays without stealing any of the broad
	# circulation lane. Their decreasing separation leads the eye around the bend.
	for pier_data in [
		[9.35, 26.16, 0.42, 2.62], [9.35, 37.84, 0.42, 2.62],
		[6.25, 26.16, 0.46, 2.78], [6.25, 37.84, 0.46, 2.78],
		[3.35, 26.16, 0.50, 2.94], [3.35, 37.84, 0.50, 2.94]
	]:
		var pier_x := float(pier_data[0])
		var pier_z := float(pier_data[1])
		var pier_width := float(pier_data[2])
		var pier_height := float(pier_data[3])
		_add_box(transition, Vector3(pier_width, pier_height, 0.30), Vector3(pier_x, pier_height * 0.5, pier_z), dark_metal)
		_add_box(transition, Vector3(pier_width + 0.14, 0.10, 0.38), Vector3(pier_x, pier_height - 0.18, pier_z), steel)
	# Slightly raised wall fields make the pilasters read as attached articulation,
	# not columns dropped into the floor. They remain flush with the native walls.
	for side_z in [26.17, 37.83]:
		for panel_data in [[9.35, 2.38], [6.25, 2.24], [3.35, 2.08]]:
			_add_box(transition, Vector3(float(panel_data[1]), 1.62, 0.035), Vector3(float(panel_data[0]), 1.42, float(side_z)), recess)
			_add_box(transition, Vector3(float(panel_data[1]) + 0.12, 0.07, 0.045), Vector3(float(panel_data[0]), 0.57, float(side_z)), dark_metal)

	# The structural shoulder facing the incoming hall becomes a deliberate service
	# divider rather than an unarticulated rectangular end cap. The illuminated
	# corner stile marks the side on which the route continues.
	_add_box(transition, Vector3(0.035, 1.92, 1.76), Vector3(6.015, 1.38, 28.95), recess)
	for edge_z in [28.03, 29.87]:
		_add_box(transition, Vector3(0.050, 2.08, 0.08), Vector3(6.035, 1.38, edge_z), dark_metal)
	for edge_y in [0.40, 2.36]:
		_add_box(transition, Vector3(0.050, 0.08, 1.92), Vector3(6.035, edge_y, 28.95), dark_metal)
	_add_box(transition, Vector3(0.24, 2.82, 0.24), Vector3(6.02, 1.41, 30.08), dark_metal)
	_add_box(transition, Vector3(0.065, 1.42, 0.10), Vector3(6.16, 1.55, 30.10), service_amber)
	# Two battered horizontal rails continue the broad-hall wall rhythm across the
	# divider face and terminate cleanly at the lit corner.
	_add_box(transition, Vector3(0.055, 0.09, 1.52), Vector3(6.055, 0.72, 28.95), steel)
	_add_box(transition, Vector3(0.055, 0.09, 1.52), Vector3(6.055, 2.04, 28.95), steel)

	# Recessed panels and paired pilasters turn the long approach into a believable
	# back-of-house service passage. All faces sit on or behind the existing wall
	# plane, preserving the full 2.15 m collision opening.
	for side in [-1.0, 1.0]:
		var side_value := float(side)
		var wall_x: float = side_value * 1.086
		for bay_z in [25.65, 20.05, 14.45, 8.85]:
			var panel_x: float = -5.826 if side_value < 0 and bay_z in [20.05,14.45] else wall_x
			_add_box(transition, Vector3(0.035, 1.66, 3.60), Vector3(panel_x, 1.39, bay_z), recess)
			_add_box(transition, Vector3(0.055, 0.08, 3.72), Vector3(panel_x - side_value * 0.018, 0.54, bay_z), dark_metal)
			_add_box(transition, Vector3(0.055, 0.08, 3.72), Vector3(panel_x - side_value * 0.018, 2.25, bay_z), dark_metal)
		for rib_z in [22.90, 17.30, 11.70, 6.10]:
			var rib_x: float = -5.79 if side_value < 0 and rib_z in [22.90,17.30,11.70] else side_value * 1.075
			_add_box(transition, Vector3(0.18, 2.58, 0.30), Vector3(rib_x, 1.29, rib_z), dark_metal)
			_add_box(transition, Vector3(0.10, 0.11, 0.42), Vector3(rib_x - side_value * 0.085, 2.48, rib_z), steel)

	# Portal headers step down only twice after the threshold. Long dark gaps remain
	# between them, retaining the corridor's black rhythm and the warm kitchen reveal.
	for header_data in [[22.90, 2.66], [17.30, 2.62], [11.70, 2.62], [6.10, 2.62]]:
		var header_z := float(header_data[0])
		var header_y := float(header_data[1])
		_add_box(transition, Vector3(2.18, 0.20, 0.32), Vector3(0.0, header_y, header_z), dark_metal)
		_add_box(transition, Vector3(1.72, 0.045, 0.11), Vector3(0.0, header_y - 0.12, header_z - 0.05), steel)

	# Only two weak practicals punctuate the run. The first explains the threshold;
	# the second is deliberately sickly and dim, leaving the kitchen yellow as the
	# sole strong destination light.
	_add_practical_omni(transition, Vector3(6.15, 3.08, 32.0), Color8(126, 124, 105), 0.46, 4.20)
	_add_practical_omni(transition, Vector3(0.0, 2.51, 14.36), Color8(116, 124, 105), 0.40, 3.10)

func _build_deferred_car_placeholder(anchor: Vector3) -> void:
	# Preserve the existing task state and interactions while deferring the final
	# roadside art pass. This is a compact neutral staging room, not an arena.
	task_states["car"] = {"complete": false, "collected": {}, "fitted": {}, "installed": 0}
	var root := Node3D.new()
	root.name = "MemoryRoom_Roadside"
	root.position = anchor
	add_child(root)
	_register_memory_room_visual(root, Vector2(6.0, 6.0))
	var dark := _room_surface(Color8(35, 34, 30), 0.96)
	var neutral := _dim_lit_material(Color8(72, 66, 55), 0.90, 0.18)
	var metal := _dim_lit_material(Color8(82, 79, 69), 0.62, 0.22)
	# One covered service plinth is enough to retain the mechanic without falsely
	# presenting this as the finished road memory.
	var car := Node3D.new()
	car.name = "DeferredVehicle_Interact"
	car.position = Vector3(0.0, 0.0, -0.35)
	root.add_child(car)
	_add_box(car, Vector3(2.20, 0.68, 1.25), Vector3(0.0, 0.36, 0.0), dark)
	_add_box(car, Vector3(1.55, 0.32, 1.05), Vector3(-0.18, 0.82, 0.0), neutral)
	_add_interactable("car", "car_install", car, "INSTALL A CAR PART", "CAR", false)
	_add_interactable("tire", "car_part", _make_task_prop(root, Vector3(-2.65, 0.64, 2.25), "wheel", dark), "TAKE TIRE", "TIRE")
	_add_interactable("fuel", "car_part", _make_task_prop(root, Vector3(0.0, 0.55, 2.65), "can", neutral), "TAKE FUEL", "FUEL")
	_add_interactable("engine", "car_part", _make_task_prop(root, Vector3(2.65, 0.58, 2.25), "engine", metal), "TAKE ENGINE PART", "ENGINE")
	_add_room_light(root, Vector3(0.0, 3.05, 0.0), Color8(157, 137, 94), 1.25, 7.0)
	_batch_static_room_boxes(root)

func _build_deferred_passport_placeholder(anchor: Vector3) -> void:
	# Neutral processing room reserved for a later dedicated design pass. The
	# existing document-order mechanic remains operational and otherwise intact.
	task_states["passport"] = {"complete": false, "documents": {}, "submitted": 0}
	var root := Node3D.new()
	root.name = "MemoryRoom_PassportControl"
	root.position = anchor
	add_child(root)
	_register_memory_room_visual(root, Vector2(6.0, 6.0))
	var dark := _room_surface(Color8(34, 35, 32), 0.96)
	var paper := _dim_lit_material(Color8(148, 142, 119), 0.88, 0.25)
	var metal := _room_surface(Color8(62, 64, 58), 0.78)
	# A single temporary desk and loose documents mark the reserved interaction
	# points without creating a premature airport/checkpoint composition.
	_add_box(root, Vector3(4.80, 0.12, 1.20), Vector3(0.0, 0.88, 0.20), dark)
	for x in [-2.10, 2.10]:
		_add_box(root, Vector3(0.12, 0.88, 1.05), Vector3(x, 0.44, 0.20), metal)
	var guide := _make_task_prop(root, Vector3(-1.65, 1.02, 0.15), "guide", paper)
	_add_interactable("guide", "passport_guide", guide, "READ PROCESSING GUIDE", "GUIDE")
	_add_interactable("passport", "passport_doc", _make_task_prop(root, Vector3(-2.75, 0.72, 2.55), "paper", paper), "TAKE PASSPORT", "PASSPORT")
	_add_interactable("visa", "passport_doc", _make_task_prop(root, Vector3(0.0, 0.72, 2.85), "paper", paper), "TAKE VISA", "VISA")
	_add_interactable("declaration", "passport_doc", _make_task_prop(root, Vector3(2.75, 0.72, 2.55), "paper", paper), "TAKE DECLARATION", "DECLARATION")
	for index in 3:
		var document_id := String(["passport", "visa", "declaration"][index])
		var pad := _make_task_prop(root, Vector3(-1.35 + float(index) * 1.35, 1.02, 0.15), "paper", paper)
		pad.visible = false
		_add_interactable(document_id, "passport_submit", pad, "SUBMIT %s" % document_id.to_upper(), document_id.to_upper(), true, false)
	_add_room_light(root, Vector3(0.0, 3.05, 0.0), Color8(151, 143, 112), 1.10, 7.0)
	_batch_static_room_boxes(root)

func _build_compact_kitchen_table(root: Node3D, position: Vector3, wood: Material, enamel: Material, steel: Material, grease: Material, warm: Material) -> void:
	var table = Node3D.new()
	table.name = "DomesticMemory_DiningTable"
	table.position = position
	table.rotation_degrees.y = -3.0
	root.add_child(table)
	# Real dining-table proportions: 2.45 x 0.95 m, 0.80 m high.
	_add_box(table, Vector3(2.45, 0.10, 0.95), Vector3(0, 0.78, 0), wood)
	_add_box(table, Vector3(2.32, 0.025, 0.84), Vector3(0, 0.845, 0), enamel)
	for plank_z in [-0.28, 0.0, 0.28]:
		_add_box(table, Vector3(2.24, 0.010, 0.016), Vector3(0, 0.865, plank_z), grease)
	for leg in [Vector3(-1.02, 0.38, -0.34), Vector3(1.02, 0.38, -0.34), Vector3(-1.02, 0.38, 0.34), Vector3(1.02, 0.38, 0.34)]:
		_add_box(table, Vector3(0.075, 0.76, 0.075), leg, steel)
	_add_box(table, Vector3(2.10, 0.08, 0.07), Vector3(0, 0.63, -0.40), wood)
	_add_box(table, Vector3(2.10, 0.08, 0.07), Vector3(0, 0.63, 0.40), wood)
	for plate_x in [-0.62, 0.62]:
		_add_disc(table, Vector3(plate_x, 0.875, 0.02), 0.18, 0.022, enamel)
		_add_disc(table, Vector3(plate_x, 0.890, 0.02), 0.11, 0.012, warm)
		_add_disc(table, Vector3(plate_x + 0.27, 0.955, -0.25), 0.045, 0.15, steel)
	_add_disc(table, Vector3(0.0, 0.96, -0.04), 0.10, 0.20, _room_surface(Color8(96, 58, 39), 0.70))
	_add_disc(table, Vector3(0.0, 1.07, -0.04), 0.075, 0.018, grease)
	var runner = _add_box(table, Vector3(0.28, 0.014, 0.72), Vector3(0, 0.870, 0), _room_surface(Color8(90, 49, 34), 0.94))
	runner.rotation_degrees.y = 1.0
	for chair_data in [[Vector3(-1.70, 0, 0.0), -90.0], [Vector3(1.70, 0, 0.0), 90.0]]:
		var chair = Node3D.new()
		chair.position = chair_data[0]
		chair.rotation_degrees.y = float(chair_data[1])
		table.add_child(chair)
		_add_box(chair, Vector3(0.48, 0.07, 0.48), Vector3(0, 0.45, 0), wood)
		_add_box(chair, Vector3(0.48, 0.52, 0.055), Vector3(0, 0.76, 0.22), steel)
		for chair_leg in [Vector3(-0.19, 0.21, -0.18), Vector3(0.19, 0.21, -0.18), Vector3(-0.19, 0.21, 0.18), Vector3(0.19, 0.21, 0.18)]:
			_add_box(chair, Vector3(0.045, 0.42, 0.045), chair_leg, steel)
	_add_seated_kitchen_woman(table)


func _add_seated_kitchen_woman(table: Node3D) -> void:
	var packed := load(SEATED_WOMAN_MODEL_PATH) as PackedScene
	if packed == null:
		push_warning("Seated kitchen woman could not be loaded: %s" % SEATED_WOMAN_MODEL_PATH)
		return
	var imported := packed.instantiate()
	if not imported is Node3D:
		imported.queue_free()
		push_warning("Seated kitchen woman root is not Node3D")
		return
	var holder := Node3D.new()
	holder.name = "SeatedWoman_MemoryFigure"
	# Match the reference: she sits sideways on the left chair with her back
	# toward the kitchen corridor, looking inward across the table.
	holder.position = Vector3(-1.70, 0.0, 0.0)
	holder.rotation_degrees.y = 0.0
	table.add_child(holder)
	kitchen_woman_figure = holder
	holder.add_child(imported)
	_prepare_memory_figure(imported)
	_normalize_room_asset(imported, 1.35)


func _build_kitchen_woman_blackout() -> void:
	var layer := CanvasLayer.new()
	layer.name = "KitchenWomanJumpscareLayer"
	layer.layer = 120
	add_child(layer)
	kitchen_woman_blackout = ColorRect.new()
	kitchen_woman_blackout.name = "Blackout"
	kitchen_woman_blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kitchen_woman_blackout.color = Color(0.0, 0.0, 0.0, 0.0)
	kitchen_woman_blackout.visible = false
	layer.add_child(kitchen_woman_blackout)
	kitchen_woman_blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _tick_kitchen_woman_jumpscare(dt: float, player) -> void:
	if player == null or kitchen_woman_jumpscare_state == "done" or not is_instance_valid(kitchen_woman_figure):
		return
	if kitchen_woman_jumpscare_state == "waiting":
		if _should_trigger_kitchen_woman_jumpscare(player):
			kitchen_woman_jumpscare_state = "focus"
			kitchen_woman_jumpscare_timer = KITCHEN_WOMAN_FOCUS_DURATION
			player.set_horror_cinematic_lock(true)
			_aim_player_at_kitchen_woman(player)
		return
	_aim_player_at_kitchen_woman(player)
	if kitchen_woman_jumpscare_state == "focus":
		kitchen_woman_jumpscare_timer = maxf(0.0, kitchen_woman_jumpscare_timer - dt)
		if kitchen_woman_jumpscare_timer <= 0.0:
			kitchen_woman_jumpscare_state = "blackout"
			kitchen_woman_jumpscare_timer = KITCHEN_WOMAN_BLACKOUT_DURATION
			if is_instance_valid(kitchen_woman_blackout):
				kitchen_woman_blackout.color = Color.BLACK
				kitchen_woman_blackout.visible = true
			kitchen_woman_figure.visible = false
	elif kitchen_woman_jumpscare_state == "blackout":
		kitchen_woman_jumpscare_timer = maxf(0.0, kitchen_woman_jumpscare_timer - dt)
		if kitchen_woman_jumpscare_timer <= 0.0:
			kitchen_woman_jumpscare_state = "reveal"
			kitchen_woman_jumpscare_timer = KITCHEN_WOMAN_REVEAL_DURATION
			if is_instance_valid(kitchen_woman_blackout):
				kitchen_woman_blackout.visible = false
	elif kitchen_woman_jumpscare_state == "reveal":
		kitchen_woman_jumpscare_timer = maxf(0.0, kitchen_woman_jumpscare_timer - dt)
		if kitchen_woman_jumpscare_timer <= 0.0:
			kitchen_woman_jumpscare_state = "done"
			player.set_horror_cinematic_lock(false)


func _should_trigger_kitchen_woman_jumpscare(player) -> bool:
	if not task_anchors.has("kitchen") or bool(player.horror_hidden):
		return false
	var local_position: Vector3 = player.global_position - Vector3(task_anchors["kitchen"])
	# The authored doorway plane is at local z=2.30. The short band accounts for
	# the player's capsule so the sequence begins as they cross the threshold,
	# before they can walk toward the table.
	if absf(local_position.x) > 1.05 or local_position.z < 2.05 or local_position.z > 2.58:
		return false
	return _player_can_see_position(player, kitchen_woman_figure.global_position + Vector3.UP * 0.86)


func _aim_player_at_kitchen_woman(player) -> void:
	var target := kitchen_woman_figure.global_position + Vector3.UP * 0.86
	var direction: Vector3 = (target - player.camera_origin()).normalized()
	if direction.length_squared() <= 0.0001:
		return
	player.target_yaw = atan2(-direction.x, -direction.z)
	player.target_pitch = asin(clampf(direction.y, -1.0, 1.0))


func _prepare_memory_figure(root: Node) -> void:
	if root is MeshInstance3D:
		(root as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		(root as MeshInstance3D).extra_cull_margin = 0.45
	if root is CollisionObject3D:
		(root as CollisionObject3D).collision_layer = 0
		(root as CollisionObject3D).collision_mask = 0
	if root is CollisionShape3D:
		(root as CollisionShape3D).disabled = true
	if root is Light3D or root is Camera3D:
		(root as Node3D).visible = false
	for child in root.get_children():
		_prepare_memory_figure(child)

func _build_kitchen_pendant(root: Node3D, housing: Material, steel: Material, warm: Material) -> void:
	# The reference fixture hangs low and visually locks the table to the room.
	_add_box(root, Vector3(2.05, 0.09, 0.14), Vector3(0.0, 2.60, 0.42), housing)
	for suspension_x in [-0.72, 0.72]:
		_add_pipe(root, Vector3(suspension_x, 2.29, 0.42), Vector3.ZERO, 0.025, 0.62, steel)
	_add_box(root, Vector3(1.92, 0.15, 0.48), Vector3(0.0, 1.98, 0.42), housing)
	_add_box(root, Vector3(1.68, 0.028, 0.30), Vector3(0.0, 1.89, 0.42), warm)
	# Thin bevel strips stop the shade reading as a single floating cuboid.
	_add_box(root, Vector3(1.78, 0.035, 0.035), Vector3(0.0, 1.91, 0.65), steel)
	_add_box(root, Vector3(1.78, 0.035, 0.035), Vector3(0.0, 1.91, 0.19), steel)

func _build_compact_kitchen_line(root: Node3D, enamel: Material, cabinet: Material, steel: Material, grease: Material, warm: Material) -> void:
	var line = Node3D.new()
	line.name = "CompactKitchen_WorkLine"
	line.position = Vector3(0.0, 0.0, -1.96)
	root.add_child(line)
	# A 3.6 m run plus one domestic fridge fills the five-metre back wall.
	for unit_x in [-1.65, -0.85, -0.05]:
		_add_box(line, Vector3(0.72, 0.84, 0.62), Vector3(unit_x, 0.42, 0), cabinet)
		_add_box(line, Vector3(0.61, 0.66, 0.025), Vector3(unit_x, 0.46, 0.325), enamel)
		_add_box(line, Vector3(0.22, 0.025, 0.035), Vector3(unit_x, 0.48, 0.345), steel)
	_add_box(line, Vector3(3.62, 0.07, 0.72), Vector3(-0.48, 0.89, 0), steel)
	_add_box(line, Vector3(3.72, 0.54, 0.035), Vector3(-0.48, 1.20, -0.33), _room_surface(Color8(67, 61, 51), 0.90))
	# Sink and correctly scaled faucet.
	_add_box(line, Vector3(0.72, 0.045, 0.45), Vector3(-1.42, 0.94, 0.02), grease)
	_add_box(line, Vector3(0.56, 0.025, 0.34), Vector3(-1.42, 0.97, 0.02), _room_surface(Color8(50, 57, 54), 0.38, 0.38))
	_add_pipe(line, Vector3(-1.42, 1.24, -0.08), Vector3.ZERO, 0.025, 0.45, steel)
	_add_pipe(line, Vector3(-1.42, 1.40, 0.05), Vector3(90, 0, 0), 0.025, 0.26, steel)
	# Shallow upper cabinets and an open shelf break up the silhouette.
	for upper_x in [-1.55, -0.78, -0.01]:
		_add_box(line, Vector3(0.70, 0.62, 0.34), Vector3(upper_x, 1.92, -0.12), cabinet)
		_add_box(line, Vector3(0.59, 0.51, 0.025), Vector3(upper_x, 1.92, 0.06), enamel)
		# A concealed strip reads as reflected light on the backsplash, not as a
		# row of floating bulbs.
		_add_box(line, Vector3(0.58, 0.022, 0.12), Vector3(upper_x, 1.595, 0.055), warm)
	_add_box(line, Vector3(0.88, 0.055, 0.30), Vector3(1.20, 1.72, 0.06), steel)
	_add_box(line, Vector3(0.88, 0.055, 0.30), Vector3(1.20, 2.18, 0.06), steel)
	for index in 3:
		var jar_color = Color8(112, 70 + index * 13, 43 + index * 8) if index % 2 == 0 else Color8(76, 96, 67)
		_add_disc(line, Vector3(0.92 + float(index) * 0.28, 1.88, 0.07), 0.055, 0.20, _room_surface(jar_color, 0.76))
	# Normal 60 cm cooker hood above the integrated stove.
	_add_box(root, Vector3(0.82, 0.18, 0.44), Vector3(0.58, 1.88, -1.98), cabinet)
	_add_box(root, Vector3(0.54, 0.48, 0.27), Vector3(0.58, 2.21, -2.11), steel)
	_add_box(root, Vector3(0.58, 0.025, 0.28), Vector3(0.58, 1.78, -1.76), warm)
	# Fridge and narrow pantry use domestic dimensions, layered doors and trims.
	_add_box(root, Vector3(0.78, 1.92, 0.68), Vector3(2.36, 0.96, -1.94), enamel)
	_add_box(root, Vector3(0.66, 0.54, 0.025), Vector3(2.36, 1.59, -1.585), cabinet)
	_add_box(root, Vector3(0.66, 1.08, 0.025), Vector3(2.36, 0.75, -1.585), cabinet)
	_add_box(root, Vector3(0.025, 0.50, 0.035), Vector3(2.64, 1.12, -1.56), steel)

func _build_car_scenario(anchor: Vector3) -> void:
	task_states["car"] = {"complete": false, "collected": {}, "fitted": {}, "installed": 0}
	var root = Node3D.new()
	root.name = "MemoryRoom_Roadside"
	root.position = anchor
	add_child(root)
	_register_memory_room_visual(root, Vector2(39.0, 17.0))
	var asphalt = _room_surface(Color8(52, 54, 54), 0.96)
	var road_line = _glow_material(Color8(166, 151, 103), 0.72)
	var car_paint = _room_surface(Color8(98, 113, 106), 0.56, 0.38)
	var rust = _room_surface(Color8(105, 63, 43), 0.88, 0.12)
	var rubber = _room_surface(Color8(15, 16, 16), 0.98)
	_add_box(root, Vector3(78.0, 0.10, 34.0), Vector3.ZERO, asphalt)
	# The road memory is an enclosed underpass, not an open black arena. Broad
	# ceiling slabs are intentionally cheap meshes; the pools below do the work.
	_add_segmented_ceiling(root, Vector2(77.0, 33.0), 7, 3, rubber, rust)
	_add_box(root, Vector3(76.0, 0.20, 1.1), Vector3(0.0, 2.94, -14.5), asphalt)
	_add_box(root, Vector3(76.0, 0.20, 1.1), Vector3(0.0, 2.94, 14.5), asphalt)
	for x in [-32.0, -20.0, -8.0, 4.0, 16.0, 28.0]:
		_add_box(root, Vector3(6.0, 0.025, 0.18), Vector3(x, 0.075, 0.0), road_line)
	for z in [-15.2, 15.2]:
		_add_box(root, Vector3(76.0, 0.35, 0.32), Vector3(0, 0.20, z), rust)
		for x in [-33.0, -22.0, -11.0, 0.0, 11.0, 22.0, 33.0]:
			_add_box(root, Vector3(9.2, 3.4, 0.18), Vector3(x, 1.72, z), asphalt)
			_add_box(root, Vector3(0.18, 3.5, 0.26), Vector3(x + 4.55, 1.75, z), rust)
			_add_box(root, Vector3(3.6, 0.06, 0.28), Vector3(x, 2.72, z * 0.992), road_line)
	# Raised maintenance sidewalks establish a road cross-section at a glance.
	for z in [-12.8, 12.8]:
		_add_box(root, Vector3(74.0, 0.22, 3.8), Vector3(0.0, 0.14, z), rubber)
		_add_box(root, Vector3(74.0, 0.055, 0.18), Vector3(0.0, 0.28, z - sign(z) * 1.78), road_line)
	# Tunnel service alcoves and abandoned road furniture.
	for x in [-31.0, 31.0]:
		_add_box(root, Vector3(5.5, 2.4, 4.2), Vector3(x, 1.2, 12.0), rust)
		_add_box(root, Vector3(5.0, 0.12, 3.8), Vector3(x, 2.45, 12.0), road_line)
	for x in [-26.0, -12.0, 15.0, 29.0]:
		_add_box(root, Vector3(0.18, 1.1, 0.18), Vector3(x, 0.55, -12.8), road_line)
		_add_box(root, Vector3(2.4, 0.28, 0.36), Vector3(x, 1.1, -12.8), rust)
	# Tunnel-distance markers and arrow boards turn the roadside room into a
	# believable abandoned underpass rather than a dark open arena.
	for marker_x in [-25.0, -9.0, 7.0, 23.0]:
		_add_box(root, Vector3(3.2, 1.05, 0.12), Vector3(marker_x, 1.70, 14.83), rubber)
		_add_box(root, Vector3(2.45, 0.12, 0.15), Vector3(marker_x, 1.78, 14.72), road_line)
		_add_box(root, Vector3(0.42, 0.12, 0.15), Vector3(marker_x + 0.85, 1.55, 14.70), road_line).rotation_degrees.z = -28.0
	# Concrete ribs, drainage and emergency infrastructure give the tunnel a
	# believable scale and provide landmarks while the monster searches it.
	for rib_x in [-33.0, -17.0, -1.0, 15.0, 31.0]:
		_add_box(root, Vector3(0.65, 3.45, 2.0), Vector3(rib_x, 1.73, -14.0), rust)
		_add_box(root, Vector3(0.65, 3.45, 2.0), Vector3(rib_x, 1.73, 14.0), rust)
		_add_box(root, Vector3(0.78, 0.32, 26.0), Vector3(rib_x, 3.30, 0.0), rubber)
	_add_box(root, Vector3(74.0, 0.04, 0.22), Vector3(0, 0.08, -8.4), rust)
	_add_box(root, Vector3(74.0, 0.04, 0.22), Vector3(0, 0.08, 8.4), rust)
	var call_box = Node3D.new()
	call_box.name = "EmergencyCallBox"
	call_box.position = Vector3(-31.0, 0.0, -12.4)
	root.add_child(call_box)
	_add_box(call_box, Vector3(1.1, 1.85, 0.62), Vector3(0, 0.94, 0), rust)
	_add_box(call_box, Vector3(0.72, 0.56, 0.08), Vector3(0, 1.28, -0.34), road_line)
	_add_room_sign(root, "SOS", Vector3(-31.0, 2.05, -12.72), Color8(190, 145, 88), 0.010)
	var car = Node3D.new()
	car.name = "BrokenCar_Interact"
	car.position = Vector3(1.0, 0.0, 0.0)
	root.add_child(car)
	car.rotation_degrees.y = -8.0
	car.scale = Vector3.ONE * 1.26
	_add_box(car, Vector3(7.2, 0.92, 3.0), Vector3(0, 0.76, 0), car_paint)
	# Layered bodywork, cabin glass and wheel arches keep the vehicle readable as
	# a stranded estate car instead of a single rectangular prop.
	_add_box(car, Vector3(3.25, 0.82, 2.58), Vector3(-0.72, 1.48, 0), car_paint)
	var car_glass = _room_surface(Color8(35, 54, 56), 0.22, 0.42)
	_add_box(car, Vector3(1.18, 0.62, 2.42), Vector3(-1.42, 1.53, 0), car_glass).rotation_degrees.z = -17.0
	_add_box(car, Vector3(1.18, 0.62, 2.42), Vector3(0.06, 1.53, 0), car_glass).rotation_degrees.z = 13.0
	_add_box(car, Vector3(2.50, 0.14, 2.72), Vector3(-0.68, 1.94, 0), rust)
	_add_box(car, Vector3(0.13, 0.72, 2.70), Vector3(-0.68, 1.49, 0), rust)
	_add_box(car, Vector3(0.08, 0.78, 2.38), Vector3(-2.05, 1.42, 0), rust).rotation_degrees.z = 48.0
	_add_box(car, Vector3(0.08, 0.78, 2.38), Vector3(0.85, 1.42, 0), rust).rotation_degrees.z = -48.0
	_add_box(car, Vector3(0.12, 0.54, 2.72), Vector3(-3.58, 0.82, 0), rust)
	_add_box(car, Vector3(0.34, 0.30, 3.12), Vector3(-3.68, 0.54, 0), rubber)
	_add_box(car, Vector3(0.34, 0.30, 3.12), Vector3(3.68, 0.54, 0), rubber)
	_add_box(car, Vector3(1.9, 0.14, 2.62), Vector3(3.45, 0.66, 0), rust)
	_add_box(car, Vector3(2.4, 0.16, 2.68), Vector3(2.15, 1.54, 0), car_paint).rotation_degrees.z = -24.0
	_add_box(car, Vector3(1.75, 0.07, 2.30), Vector3(2.20, 1.66, 0), rubber).rotation_degrees.z = -24.0
	_add_box(car, Vector3(1.65, 0.46, 2.18), Vector3(2.36, 1.13, 0), rust)
	for seat_z in [-0.72, 0.72]:
		_add_box(car, Vector3(0.72, 0.72, 0.58), Vector3(-0.55, 1.12, seat_z), rubber)
	for headlight_z in [-0.88, 0.88]:
		_add_box(car, Vector3(0.12, 0.30, 0.48), Vector3(3.64, 0.86, headlight_z), _glow_material(Color8(196, 178, 124), 1.2))
	for wheel_pos in [Vector3(-2.1, 0.43, -1.42), Vector3(-2.1, 0.43, 1.42), Vector3(2.1, 0.43, -1.42)]:
		var wheel = MeshInstance3D.new()
		var wheel_mesh = CylinderMesh.new()
		wheel_mesh.top_radius = 0.52
		wheel_mesh.bottom_radius = 0.52
		wheel_mesh.height = 0.30
		wheel_mesh.radial_segments = 12
		wheel.mesh = wheel_mesh
		wheel.position = wheel_pos
		wheel.rotation_degrees.z = 90.0
		wheel.material_override = rubber
		car.add_child(wheel)
	_dress_broken_car(car, car_paint, rust, rubber, road_line)
	# The missing wheel, jack and scattered tools turn the vehicle into a task
	# scene instead of an abstract car-shaped block.
	_add_disc(car, Vector3(2.1, 0.43, 1.42), 0.30, 0.22, rust, Vector3(0, 0, 90))
	_add_box(root, Vector3(1.4, 0.12, 0.18), Vector3(3.1, 0.18, 3.2), rust).rotation_degrees.y = 24.0
	_add_box(root, Vector3(0.20, 0.70, 0.20), Vector3(2.7, 0.38, 2.6), road_line).rotation_degrees.z = 27.0
	for cone_pos in [Vector3(-5.0, 0.35, -4.4), Vector3(7.0, 0.35, 4.6), Vector3(12.0, 0.35, -5.2)]:
		_add_traffic_cone(root, cone_pos, rust, road_line)
	# The concrete underpass ribs already define the ceiling. Additional rafts
	# made the road read as a stack of black slabs from player height.
	# Headlight spill remains emissive, so the broken car reads without another
	# realtime light pair.
	_add_box(root, Vector3(9.0, 0.025, 2.0), Vector3(8.4, 0.09, -1.0), _dim_lit_material(Color8(128, 116, 79), 0.92, 1.42)).rotation_degrees.y = -8.0
	_add_box(root, Vector3(7.0, 0.025, 1.2), Vector3(8.0, 0.10, 1.2), _dim_lit_material(Color8(105, 94, 66), 0.92, 1.15)).rotation_degrees.y = -8.0
	for light_pos in [Vector3(1.0, 2.70, 4.5)]:
		_add_room_light(root, light_pos, Color8(191, 170, 116), 4.6, 16.5)
	_add_room_fill_light(root, Vector3(1.0, 2.25, 0.0), Color8(124, 104, 76), 1.10, 31.0)
	_add_room_floor_pool(root, Vector3(-22.0, 0.082, -6.0), Vector2(18.0, 13.0), Color8(96, 84, 60), 0.24)
	_add_room_floor_pool(root, Vector3(1.0, 0.082, 0.0), Vector2(20.0, 14.0), Color8(99, 75, 54), 0.30)
	_add_room_floor_pool(root, Vector3(24.0, 0.082, 6.0), Vector2(18.0, 13.0), Color8(84, 71, 52), 0.22)
	_add_room_sign(root, "SERVICE BAY 19", Vector3(-17.0, 2.30, -14.82), Color8(178, 142, 94), 0.0042)
	_dress_roadside_memory(root, asphalt, rust, rubber, road_line)
	_add_roadside_hero_dressing(root, car, asphalt, rust, rubber, road_line)
	_add_interactable("car", "car_install", car, "INSTALL A CAR PART", "CAR", false)
	_add_interactable("tire", "car_part", _make_task_prop(root, Vector3(-30.0, 0.64, -10.5), "wheel", rubber), "TAKE TIRE", "TIRE")
	_add_interactable("fuel", "car_part", _make_task_prop(root, Vector3(31.0, 0.55, 11.5), "can", rust), "TAKE FUEL", "FUEL")
	_add_interactable("engine", "car_part", _make_task_prop(root, Vector3(-27.0, 0.58, 11.5), "engine", road_line), "TAKE ENGINE PART", "ENGINE")
	_batch_static_room_boxes(root)

func _build_passport_scenario(anchor: Vector3) -> void:
	task_states["passport"] = {"complete": false, "documents": {}, "submitted": 0}
	var root = Node3D.new()
	root.name = "MemoryRoom_PassportControl"
	root.position = anchor
	add_child(root)
	_register_memory_room_visual(root, Vector2(42.0, 17.5))
	var institutional = _room_surface(Color8(111, 115, 108), 0.82, 0.12)
	var dirty_white = _room_surface(Color8(188, 186, 165), 0.72, 0.04)
	var dark = _room_surface(Color8(44, 48, 47), 0.96)
	var rubber = _room_surface(Color8(37, 39, 37), 0.92)
	var glass = _room_surface(Color(0.16, 0.25, 0.25, 0.48), 0.20, 0.22)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var cyan = _glow_material(Color8(68, 115, 111), 1.40)
	var amber = _glow_material(Color8(191, 137, 55), 1.9)
	var warning = _glow_material(Color8(155, 48, 38), 2.0)
	_add_box(root, Vector3(84.0, 0.10, 35.0), Vector3.ZERO, dark)
	# Full ceiling and a pale central concourse make the architecture readable
	# before the player reaches the desk. Side lanes stay darker and abandoned.
	_add_segmented_ceiling(root, Vector2(83.0, 34.0), 10, 5, institutional, dark)
	_add_box(root, Vector3(19.0, 0.026, 33.0), Vector3(0.0, 0.075, 0.0), _dim_lit_material(Color8(96, 103, 95), 0.90, 0.32))
	# Side cladding encloses the checkpoint in human-scale bays while preserving
	# the wide central entrance and all mission-object access.
	for z in [-11.8, -4.0, 3.8, 11.6]:
		_add_box(root, Vector3(0.20, 3.35, 7.2), Vector3(-41.55, 1.69, z), institutional)
		_add_box(root, Vector3(0.20, 3.35, 7.2), Vector3(41.55, 1.69, z), institutional)
		_add_box(root, Vector3(0.055, 0.72, 5.6), Vector3(-41.40, 1.88, z), dirty_white)
		_add_box(root, Vector3(0.055, 0.72, 5.6), Vector3(41.40, 1.88, z), dirty_white)
	# Dirty terrazzo bands lead the player through the queue and prevent the
	# entire checkpoint from collapsing into one black floor.
	for x in [-30.0, -18.0, -6.0, 6.0, 18.0, 30.0]:
		_add_box(root, Vector3(9.0, 0.025, 31.0), Vector3(x, 0.07, 0.0), _dim_lit_material(Color8(70, 74, 70), 0.90, 0.10))
	_add_box(root, Vector3(3.6, 0.035, 30.0), Vector3(0.0, 0.085, 0.0), rubber)
	# Repeating institutional wall bays establish the room before the booths are
	# reached and keep the checkpoint legible from its entrance.
	for x in [-35.0, -25.0, -15.0, -5.0, 5.0, 15.0, 25.0, 35.0]:
		_add_box(root, Vector3(8.8, 3.2, 0.16), Vector3(x, 1.62, -16.55), institutional)
		_add_box(root, Vector3(0.16, 3.25, 0.24), Vector3(x + 4.35, 1.64, -16.45), dark)
		_add_box(root, Vector3(2.8, 0.055, 0.26), Vector3(x, 2.64, -16.34), cyan)
	# A single readable security threshold leaves a broad path into the hall.
	for x in [-9.0, 9.0]:
		_add_box(root, Vector3(0.34, 2.85, 0.34), Vector3(x - 2.35, 1.43, 9.0), institutional)
		_add_box(root, Vector3(0.34, 2.85, 0.34), Vector3(x + 2.35, 1.43, 9.0), institutional)
		_add_box(root, Vector3(5.0, 0.28, 0.34), Vector3(x, 2.76, 9.0), dark)
		_add_box(root, Vector3(1.15, 0.08, 0.38), Vector3(x, 2.74, 8.82), cyan if x < 0.0 else warning)
	_add_room_sign(root, "DOCUMENT CONTROL", Vector3(0.0, 2.46, 9.15), Color8(171, 184, 169), 0.0064)
	# Low segmented queue rails form a serpentine route without becoming a wall.
	for rail in [
		[Vector3(-20.0, 0.78, 4.8), Vector3(25.0, 0.065, 0.065)],
		[Vector3(17.0, 0.78, 1.2), Vector3(25.0, 0.065, 0.065)],
		[Vector3(-17.0, 0.78, -2.4), Vector3(25.0, 0.065, 0.065)]
	]:
		var rail_position: Vector3 = rail[0]
		var rail_size: Vector3 = rail[1]
		_add_box(root, rail_size, rail_position, institutional)
		for x_offset in [-rail_size.x * 0.48, 0.0, rail_size.x * 0.48]:
			_add_box(root, Vector3(0.13, 0.88, 0.13), rail_position + Vector3(x_offset, -0.40, 0), institutional)
			_add_box(root, Vector3(0.19, 0.09, 0.19), rail_position + Vector3(x_offset, 0.02, 0), amber)
	# Three compact inspection booths, each with a lit window and document tray.
	for booth_index in 3:
		var x = -24.0 + float(booth_index) * 24.0
		_add_box(root, Vector3(13.0, 1.15, 3.4), Vector3(x, 0.58, -11.8), institutional)
		_add_box(root, Vector3(13.4, 0.18, 3.65), Vector3(x, 1.22, -11.8), dirty_white)
		_add_box(root, Vector3(11.8, 1.12, 0.09), Vector3(x, 1.83, -10.15), glass)
		_add_box(root, Vector3(3.8, 0.10, 0.18), Vector3(x, 2.66, -10.08), cyan if booth_index == 1 else warning)
		_add_box(root, Vector3(3.1, 0.08, 1.25), Vector3(x, 1.36, -9.76), rubber)
		_add_box(root, Vector3(0.22, 2.9, 0.22), Vector3(x - 6.25, 1.46, -11.75), dark)
		_add_box(root, Vector3(0.22, 2.9, 0.22), Vector3(x + 6.25, 1.46, -11.75), dark)
		if booth_index == 1:
			_add_room_sign(root, "OPEN", Vector3(x, 2.35, -9.98), Color8(151, 194, 178), 0.010)
	# Break the showroom symmetry: one lane is abandoned, one is operating, and
	# one has been dismantled into a baggage-inspection station.
	_add_box(root, Vector3(10.5, 1.05, 3.0), Vector3(-26.0, 0.54, -5.8), rubber)
	for belt_x in [-30.0, -27.5, -25.0, -22.5]:
		_add_box(root, Vector3(1.8, 0.10, 2.5), Vector3(belt_x, 1.08, -5.8), institutional)
	_add_box(root, Vector3(5.2, 2.7, 0.42), Vector3(26.0, 1.36, -7.2), dark)
	_add_box(root, Vector3(3.4, 1.7, 0.12), Vector3(26.0, 1.55, -6.96), warning)
	_add_room_sign(root, "LANE CLOSED", Vector3(26.0, 2.12, -6.88), Color8(181, 79, 65), 0.010)
	# Heavy overhead bulkhead and suspended lane indicators create the airport /
	# border-control silhouette that was missing from the old room.
	_add_box(root, Vector3(76.0, 0.42, 3.2), Vector3(0.0, 3.18, -12.2), institutional)
	for x in [-24.0, 0.0, 24.0]:
		_add_box(root, Vector3(5.8, 0.12, 0.30), Vector3(x, 2.82, -8.8), cyan if x == 0.0 else warning)
	# The segmented institutional ceiling remains visible and continuous. Only
	# the working lane keeps a focused canopy, avoiding a low black false ceiling.
	# The central lane is the only functioning checkpoint. A broad canopy and
	# backlit control wall give it hierarchy over the dismantled side lanes.
	_add_box(root, Vector3(15.0, 0.24, 3.8), Vector3(0.0, 2.82, -9.0), institutional)
	_add_box(root, Vector3(12.0, 0.06, 2.2), Vector3(0.0, 2.51, -8.7), cyan)
	# Build the working lane as a believable transaction point instead of a row
	# of abstract boxes. The split counter keeps the interaction pads reachable.
	_add_box(root, Vector3(15.0, 0.92, 2.35), Vector3(0.0, 0.48, -8.75), institutional)
	_add_box(root, Vector3(15.4, 0.16, 2.55), Vector3(0.0, 1.00, -8.75), dirty_white)
	_add_box(root, Vector3(13.8, 0.055, 0.18), Vector3(0.0, 0.88, -7.53), cyan)
	_add_box(root, Vector3(14.2, 1.35, 0.08), Vector3(0.0, 1.83, -9.78), glass)
	for divider_x in [-7.0, -2.7, 2.7, 7.0]:
		_add_box(root, Vector3(0.12, 1.55, 1.92), Vector3(divider_x, 1.78, -9.02), dark)
	for screen_x in [-5.2, 5.2]:
		_add_box(root, Vector3(2.15, 1.15, 0.18), Vector3(screen_x, 1.78, -8.82), dark)
		_add_box(root, Vector3(1.72, 0.82, 0.06), Vector3(screen_x, 1.80, -8.70), cyan)
		_add_box(root, Vector3(0.14, 0.72, 0.14), Vector3(screen_x, 1.22, -8.92), institutional)
	# Three separate document trays visually explain the required order before
	# the player reads it, while the guide still provides the exact solution.
	for tray_index in 3:
		var tray_x = -2.0 + float(tray_index) * 2.0
		_add_box(root, Vector3(1.45, 0.09, 1.12), Vector3(tray_x, 1.12, -8.15), rubber)
		_add_box(root, Vector3(1.12, 0.035, 0.82), Vector3(tray_x, 1.18, -8.15), [cyan, amber, dirty_white][tray_index])
	# Desk hardware and a single abandoned chair make the working position read
	# as a human checkpoint rather than another abstract arena barricade.
	_add_box(root, Vector3(0.55, 0.12, 0.34), Vector3(-0.55, 1.18, -8.03), dark)
	_add_box(root, Vector3(0.10, 0.42, 0.10), Vector3(-0.55, 1.40, -8.03), institutional)
	_add_box(root, Vector3(0.38, 0.42, 0.08), Vector3(-0.55, 1.58, -8.00), warning)
	_add_box(root, Vector3(1.25, 0.16, 1.15), Vector3(0.0, 0.55, -11.25), rubber)
	_add_box(root, Vector3(1.12, 1.05, 0.14), Vector3(0.0, 1.05, -11.76), institutional)
	_add_box(root, Vector3(0.16, 0.58, 0.16), Vector3(-0.42, 0.27, -11.25), institutional)
	_add_box(root, Vector3(0.16, 0.58, 0.16), Vector3(0.42, 0.27, -11.25), institutional)
	# A walk-through baggage scanner gives the dismantled lane a recognisable
	# silhouette and creates visual contrast with the active central booth.
	for scanner_x in [-31.1, -18.9]:
		_add_box(root, Vector3(0.48, 2.85, 1.15), Vector3(scanner_x, 1.43, -4.9), institutional)
	_add_box(root, Vector3(12.7, 0.48, 1.15), Vector3(-25.0, 2.72, -4.9), institutional)
	_add_box(root, Vector3(8.6, 0.08, 0.92), Vector3(-25.0, 2.45, -4.9), warning)
	_add_box(root, Vector3(3.6, 1.85, 0.24), Vector3(-17.6, 1.10, -4.6), dark)
	_add_box(root, Vector3(2.8, 1.25, 0.08), Vector3(-17.6, 1.22, -4.44), _dim_lit_material(Color8(88, 110, 102), 0.82, 1.30))
	_add_box(root, Vector3(12.5, 2.5, 0.30), Vector3(-25.0, 1.27, -8.0), rubber)
	_add_box(root, Vector3(8.0, 1.7, 0.12), Vector3(-25.0, 1.55, -7.80), _dim_lit_material(Color8(53, 66, 64), 0.82, 1.30))
	_add_box(root, Vector3(16.0, 2.2, 0.34), Vector3(25.0, 1.12, -7.7), dark)
	for closed_x in [20.0, 25.0, 30.0]:
		_add_box(root, Vector3(0.24, 2.1, 0.24), Vector3(closed_x, 1.05, -6.6), warning)
		_add_box(root, Vector3(4.2, 0.12, 0.18), Vector3(closed_x, 1.35, -6.5), warning).rotation_degrees.z = -22.0
	for column_pos in [Vector3(-35.0, 1.6, 7.5), Vector3(35.0, 1.6, 7.5), Vector3(-35.0, 1.6, -4.5), Vector3(35.0, 1.6, -4.5)]:
		_add_box(root, Vector3(1.5, 3.2, 1.5), column_pos, institutional)
		_add_box(root, Vector3(1.7, 0.10, 1.7), column_pos + Vector3(0, 1.42, 0), amber)
	# Waiting furniture stays at the sides, keeping the entrance and guide visible.
	for bench_pos in [Vector3(-31.0, 0.52, 13.4), Vector3(27.0, 0.52, 13.4)]:
		_add_box(root, Vector3(10.0, 0.18, 1.45), bench_pos, dirty_white)
		_add_box(root, Vector3(0.20, 0.52, 1.30), bench_pos + Vector3(-4.0, -0.26, 0), institutional)
		_add_box(root, Vector3(0.20, 0.52, 1.30), bench_pos + Vector3(4.0, -0.26, 0), institutional)
	# Smaller seats, discarded luggage and a clock establish the checkpoint as
	# a place people once waited in, supporting the lonely-memory theme.
	for seat_x in [-16.0, -12.5, 12.5, 16.0]:
		_add_box(root, Vector3(2.6, 0.14, 1.25), Vector3(seat_x, 0.58, 13.4), dirty_white)
		_add_box(root, Vector3(2.6, 0.95, 0.14), Vector3(seat_x, 1.02, 14.0), institutional)
	_add_box(root, Vector3(1.25, 0.92, 0.72), Vector3(21.0, 0.48, 12.4), rubber)
	_add_box(root, Vector3(0.16, 1.18, 0.16), Vector3(21.0, 1.46, 12.4), institutional)
	_add_disc(root, Vector3(0.0, 2.35, -16.32), 0.58, 0.10, dirty_white, Vector3(90, 0, 0))
	_add_box(root, Vector3(0.04, 0.33, 0.04), Vector3(0.0, 2.35, -16.18), warning).rotation_degrees.z = 22.0
	var guide_kiosk = Node3D.new()
	guide_kiosk.position = Vector3(-20.0, 0.0, 12.0)
	root.add_child(guide_kiosk)
	_add_box(guide_kiosk, Vector3(4.8, 1.15, 2.0), Vector3(0, 0.58, 0), institutional)
	_add_box(guide_kiosk, Vector3(3.8, 1.35, 0.18), Vector3(0, 1.65, -0.72), cyan)
	_add_room_sign(root, "PROCESSING GUIDE", Vector3(-20.0, 2.22, 11.25), Color8(112, 194, 184), 0.010)
	_add_room_sign(root, "ARRIVALS / PROCESSING", Vector3(0.0, 2.70, 16.32), Color8(173, 183, 166), 0.014)
	# Color-coded floor guidance remains visible at flashlight range and explains
	# the three functional zones without adding more realtime lights.
	_add_box(root, Vector3(0.18, 0.028, 19.0), Vector3(0.0, 0.10, 3.0), cyan)
	_add_box(root, Vector3(0.18, 0.028, 14.0), Vector3(-24.0, 0.10, 2.5), amber)
	_add_box(root, Vector3(0.18, 0.028, 14.0), Vector3(24.0, 0.10, 2.5), warning)
	var clerk = Node3D.new()
	clerk.name = "CheckpointClerk"
	clerk.position = Vector3(0, 1.55, -10.5)
	root.add_child(clerk)
	_add_box(clerk, Vector3(0.95, 1.45, 0.65), Vector3.ZERO, dark)
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.32
	head_mesh.height = 0.64
	head.mesh = head_mesh
	head.position = Vector3(0, 0.88, 0)
	head.material_override = institutional
	clerk.add_child(head)
	for light_pos in [Vector3(-13, 2.66, -5), Vector3(13, 2.66, 7)]:
		_add_room_light(root, light_pos, Color8(177, 196, 180), 5.2, 16.5)
	_add_room_fill_light(root, Vector3(0.0, 2.35, -3.0), Color8(126, 146, 136), 1.20, 33.0)
	_add_room_floor_pool(root, Vector3(-24.0, 0.082, -6.0), Vector2(17.0, 15.0), Color8(76, 91, 84), 0.25)
	_add_room_floor_pool(root, Vector3(0.0, 0.082, -6.0), Vector2(17.0, 15.0), Color8(87, 103, 95), 0.28)
	_add_room_floor_pool(root, Vector3(24.0, 0.082, -6.0), Vector2(17.0, 15.0), Color8(76, 91, 84), 0.25)
	_dress_passport_memory(root, institutional, dirty_white, dark, rubber, glass, cyan, amber, warning)
	_add_passport_hero_dressing(root, institutional, dirty_white, dark, rubber, glass, cyan, amber, warning)
	var guide = _make_task_prop(root, Vector3(-20.0, 2.38, 11.22), "guide", cyan)
	_add_interactable("guide", "passport_guide", guide, "READ PROCESSING GUIDE", "GUIDE")
	_add_interactable("passport", "passport_doc", _make_task_prop(root, Vector3(-29.0, 0.72, 5.2), "paper", cyan), "TAKE PASSPORT", "PASSPORT")
	_add_interactable("visa", "passport_doc", _make_task_prop(root, Vector3(30.0, 0.72, 4.0), "paper", warning), "TAKE VISA", "VISA")
	_add_interactable("declaration", "passport_doc", _make_task_prop(root, Vector3(18.0, 0.72, 14.8), "paper", dirty_white), "TAKE DECLARATION", "DECLARATION")
	for index in 3:
		var document_id = ["passport", "visa", "declaration"][index]
		var pad = _make_task_prop(root, Vector3(-2.0 + index * 2.0, 1.48, -9.65), "paper", [cyan, warning, dirty_white][index])
		pad.visible = false
		_add_interactable(document_id, "passport_submit", pad, "SUBMIT %s" % document_id.to_upper(), document_id.to_upper(), true, false)
	_batch_static_room_boxes(root)

func _add_interactable(item_id: String, action: String, node: Node3D, label: String, short_label: String, bob: bool = true, active: bool = true, extra: Dictionary = {}) -> void:
	node.set_meta("skip_static_room_batch", true)
	var entry = {
		"id": item_id,
		"action": action,
		"node": node,
		"label": label,
		"short": short_label,
		"active": active,
		"bob": bob,
		"base_y": node.position.y,
		"phase": float(interactables.size()) * 1.31
	}
	for key in extra.keys():
		entry[key] = extra[key]
	interactables.append(entry)

func _batch_static_room_boxes(room_root: Node3D) -> void:
	if get_tree().has_meta("killgore_disable_static_room_batching") and bool(get_tree().get_meta("killgore_disable_static_room_batching")):
		return
	if bool(room_root.get_meta("skip_static_room_batch", false)):
		return
	var groups := {}
	var originals: Array[MeshInstance3D] = []
	_collect_static_room_boxes(room_root, room_root, groups, originals)
	var unit_box := BoxMesh.new()
	unit_box.size = Vector3.ONE
	var batch_index := 0
	for group_key in groups.keys():
		var group: Dictionary = groups[group_key]
		var transforms: Array = group["transforms"]
		if transforms.size() < 2:
			continue
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = unit_box
		multimesh.instance_count = transforms.size()
		for transform_index in transforms.size():
			multimesh.set_instance_transform(transform_index, transforms[transform_index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "StaticRoomBatch_%03d" % batch_index
		instance.multimesh = multimesh
		instance.material_override = group["material"]
		instance.cast_shadow = group["cast_shadow"]
		room_root.add_child(instance)
		batch_index += 1
		for original in group["nodes"]:
			originals.append(original)
	for original in originals:
		if not is_instance_valid(original):
			continue
		var parent := original.get_parent()
		if parent != null:
			parent.remove_child(original)
		original.free()

func _collect_static_room_boxes(node: Node, room_root: Node3D, groups: Dictionary, originals: Array[MeshInstance3D]) -> void:
	if node != room_root and bool(node.get_meta("skip_static_room_batch", false)):
		return
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh is BoxMesh and mesh_instance.material_override != null and mesh_instance.visible:
			var material := mesh_instance.material_override
			var transparent := material is BaseMaterial3D and (material as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
			if not transparent:
				var local_transform := room_root.global_transform.affine_inverse() * mesh_instance.global_transform
				var mesh_size: Vector3 = (mesh_instance.mesh as BoxMesh).size
				var packed_transform := local_transform * Transform3D(Basis.IDENTITY.scaled(mesh_size), Vector3.ZERO)
				# Keep batches local enough that a visible cabinet or wall section does
				# not pull an entire room's hidden boxes through the frustum culler.
				# Eight metres retains most of the submission reduction while avoiding
				# the overdraw seen with the original 16 m groups.
				var chunk_x := floori(local_transform.origin.x / 8.0)
				var chunk_z := floori(local_transform.origin.z / 8.0)
				var key := "%d:%d:%d:%d" % [material.get_instance_id(), int(mesh_instance.cast_shadow), chunk_x, chunk_z]
				if not groups.has(key):
					groups[key] = {
						"material": material,
						"cast_shadow": mesh_instance.cast_shadow,
						"transforms": [],
						"nodes": []
					}
				groups[key]["transforms"].append(packed_transform)
				groups[key]["nodes"].append(mesh_instance)
	for child in node.get_children():
		_collect_static_room_boxes(child, room_root, groups, originals)

func _make_task_prop(parent: Node3D, position: Vector3, kind: String, material: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "TaskProp_%s" % kind
	root.position = position
	parent.add_child(root)
	match kind:
		"wheel":
			var mesh = CylinderMesh.new()
			mesh.top_radius = 0.58
			mesh.bottom_radius = 0.58
			mesh.height = 0.32
			mesh.radial_segments = 12
			var wheel = MeshInstance3D.new()
			wheel.mesh = mesh
			wheel.rotation_degrees.z = 90.0
			wheel.material_override = material
			root.add_child(wheel)
		"pan":
			_add_box(root, Vector3(1.0, 0.10, 0.72), Vector3.ZERO, material)
			_add_box(root, Vector3(0.85, 0.07, 0.13), Vector3(0.85, 0, 0), material)
		"knife":
			_add_box(root, Vector3(1.1, 0.06, 0.16), Vector3.ZERO, material)
		"paper", "guide":
			_add_box(root, Vector3(0.72 if kind == "paper" else 1.2, 0.035, 0.48 if kind == "paper" else 0.82), Vector3.ZERO, material)
		"engine":
			_add_box(root, Vector3(1.15, 0.72, 0.85), Vector3.ZERO, material)
			_add_box(root, Vector3(0.68, 0.32, 1.12), Vector3(0, 0.18, 0), material)
		"can":
			_add_box(root, Vector3(0.62, 0.92, 0.38), Vector3.ZERO, material)
		_:
			_add_box(root, Vector3(0.72, 0.62, 0.72), Vector3.ZERO, material)
	return root

func _add_room_light(parent: Node3D, position: Vector3, color: Color, energy: float, light_range: float) -> void:
	var fixture = Node3D.new()
	fixture.name = "CeilingFixture"
	fixture.position = position
	parent.add_child(fixture)
	var housing = _dim_lit_material(Color8(20, 22, 21), 0.82, 0.30)
	_add_box(fixture, Vector3(3.25, 0.18, 0.72), Vector3(0, 0.07, 0), housing)
	_add_box(fixture, Vector3(2.70, 0.035, 0.15), Vector3(0, -0.035, -0.17), _glow_material(color, 2.8))
	_add_box(fixture, Vector3(2.70, 0.035, 0.15), Vector3(0, -0.035, 0.17), _glow_material(color, 2.8))
	var pool = SpotLight3D.new()
	pool.name = "DownwardRoomPool"
	pool.position.y = -0.24
	pool.rotation_degrees.x = -90.0
	pool.light_color = color
	pool.light_energy = energy * 1.55
	pool.spot_range = light_range
	pool.spot_angle = 67.0
	pool.spot_attenuation = 0.92
	pool.light_specular = 0.22
	pool.shadow_enabled = true
	fixture.add_child(pool)
	# Global Environment fog supplies the atmosphere for this level. Do not add
	# a polygonal shaft here: it reads as a fixed cone once real fog is dense.
	_register_shader_light(
		parent.to_global(position + Vector3(0.0, -0.24, 0.0)),
		color,
		clamp(energy * 0.32, 1.05, 1.65),
		true,
		true
	)

func _add_room_fill_light(_parent: Node3D, _position: Vector3, _color: Color, _energy: float, _light_range: float) -> void:
	pass # No source-less bounce light or emissive floor overlays.

func _add_room_floor_pool(parent: Node3D, position: Vector3, dimensions: Vector2, color: Color, emission: float) -> void:
	var pool_material = _dim_lit_material(color, 0.94, emission)
	_add_box(parent, Vector3(dimensions.x, 0.018, dimensions.y), position, pool_material)

func _add_ceiling_raft(parent: Node3D, position: Vector3, dimensions: Vector3, frame_material: Material, strip_material: Material) -> void:
	var raft = Node3D.new()
	raft.name = "SuspendedCeilingRaft"
	raft.position = position
	parent.add_child(raft)
	# An open service frame keeps the authored room visible. The former solid slab
	# filled most of the camera and made the detailed rooms read like a blockout.
	var rail_height = min(0.14, dimensions.y * 0.42)
	var edge_z = max(0.20, dimensions.z * 0.5 - 0.12)
	var edge_x = max(0.20, dimensions.x * 0.5 - 0.12)
	for z in [-edge_z, edge_z]:
		_add_box(raft, Vector3(dimensions.x, rail_height, 0.18), Vector3(0, 0, z), frame_material)
	for x in [-edge_x, edge_x]:
		_add_box(raft, Vector3(0.18, rail_height, dimensions.z), Vector3(x, 0, 0), frame_material)
	for x in [-dimensions.x * 0.22, dimensions.x * 0.22]:
		_add_box(raft, Vector3(0.12, rail_height * 0.72, dimensions.z * 0.82), Vector3(x, -0.015, 0), frame_material)
	_add_box(raft, Vector3(dimensions.x * 0.42, 0.025, 0.12), Vector3(0, -rail_height * 0.72, 0), strip_material)
	for x in [-dimensions.x * 0.42, dimensions.x * 0.42]:
		_add_box(raft, Vector3(0.07, 0.34, 0.07), Vector3(x, 0.22, 0), frame_material)

func _add_pipe(parent: Node3D, position: Vector3, rotation_degrees_value: Vector3, radius: float, height: float, material: Material) -> void:
	var pipe = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	pipe.mesh = mesh
	pipe.position = position
	pipe.rotation_degrees = rotation_degrees_value
	pipe.material_override = material
	parent.add_child(pipe)

func _add_disc(parent: Node3D, position: Vector3, radius: float, height: float, material: Material, rotation_degrees_value: Vector3 = Vector3.ZERO) -> void:
	var disc = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	disc.mesh = mesh
	disc.position = position
	disc.rotation_degrees = rotation_degrees_value
	disc.material_override = material
	parent.add_child(disc)

func _add_kitchen_chair(parent: Node3D, position: Vector3, frame_material: Material, seat_material: Material) -> void:
	_add_box(parent, Vector3(1.25, 0.14, 1.15), position + Vector3(0, 0.58, 0), seat_material)
	_add_box(parent, Vector3(1.25, 1.20, 0.13), position + Vector3(0, 1.16, 0.52), frame_material)
	for offset in [Vector3(-0.48, 0.28, -0.42), Vector3(0.48, 0.28, -0.42), Vector3(-0.48, 0.28, 0.42), Vector3(0.48, 0.28, 0.42)]:
		_add_box(parent, Vector3(0.12, 0.56, 0.12), position + offset, frame_material)

func _add_traffic_cone(parent: Node3D, position: Vector3, cone_material: Material, stripe_material: Material) -> void:
	_add_box(parent, Vector3(0.75, 0.08, 0.75), position + Vector3(0, -0.30, 0), cone_material)
	_add_box(parent, Vector3(0.26, 0.70, 0.26), position, cone_material)
	_add_box(parent, Vector3(0.31, 0.11, 0.31), position + Vector3(0, 0.05, 0), stripe_material)

func _add_room_sign(parent: Node3D, text: String, position: Vector3, color: Color, pixel_size: float) -> void:
	var label = Label3D.new()
	label.text = text
	label.position = position
	label.pixel_size = min(pixel_size, 0.0048)
	label.font_size = 32
	label.modulate = color
	label.outline_modulate = Color(0.02, 0.025, 0.025, 1.0)
	label.outline_size = 4
	label.no_depth_test = false
	parent.add_child(label)

func _room_surface(color: Color, roughness: float, metallic: float = 0.0) -> Material:
	# Task-room surfaces use the same compatibility-safe flashlight response as
	# the maze shell. Relying only on realtime lights made these meshes black once
	# the renderer's per-object light budget was exhausted.
	# Transparent glass/puddles stay on StandardMaterial3D because their callers
	# configure BaseMaterial3D transparency after this helper returns.
	if color.a < 0.995:
		var transparent_material = _flat_material(color, roughness)
		transparent_material.metallic = metallic
		return transparent_material
	var material = _make_concrete_shader(color, 0.08, roughness)
	material.set_shader_parameter("metallic_value", metallic)
	material.set_shader_parameter("ambient_lift", lerp(0.018, 0.045, 1.0 - color.get_luminance()))
	return material

func _add_segmented_ceiling(parent: Node3D, room_size: Vector2, columns: int, rows: int, panel_material: Material, frame_material: Material) -> void:
	var cell_width = room_size.x / float(columns)
	var cell_depth = room_size.y / float(rows)
	for row_index in rows:
		for column_index in columns:
			var panel_position = Vector3(
				-room_size.x * 0.5 + cell_width * (float(column_index) + 0.5),
				WALL_HEIGHT - 0.12,
				-room_size.y * 0.5 + cell_depth * (float(row_index) + 0.5)
			)
			_add_box(parent, Vector3(cell_width - 0.16, 0.12, cell_depth - 0.16), panel_position, panel_material)
	for column_index in range(columns + 1):
		var x = -room_size.x * 0.5 + cell_width * float(column_index)
		_add_box(parent, Vector3(0.13, 0.18, room_size.y), Vector3(x, WALL_HEIGHT - 0.20, 0), frame_material)
	for row_index in range(rows + 1):
		var z = -room_size.y * 0.5 + cell_depth * float(row_index)
		_add_box(parent, Vector3(room_size.x, 0.18, 0.13), Vector3(0, WALL_HEIGHT - 0.20, z), frame_material)

func _add_emissive_task_marker(parent: Node3D, position: Vector3, material: Material, length: float = 2.4) -> void:
	_add_box(parent, Vector3(length, 0.028, 0.13), position, material)
	_add_box(parent, Vector3(0.13, 0.028, 0.72), position + Vector3(-length * 0.5, 0, 0.30), material)

func _add_kitchen_hero_dressing(root: Node3D, enamel: Material, cabinet: Material, steel: Material, grease: Material, warm: Material, sick: Material) -> void:
	# A compact cook line gives the oversized room one unmistakable focal point.
	var cook_line = Node3D.new()
	cook_line.name = "KitchenHero_CookLine"
	cook_line.position = Vector3(23.0, 0.0, -14.45)
	root.add_child(cook_line)
	_add_box(cook_line, Vector3(8.0, 0.22, 3.0), Vector3(0, 2.55, 0.10), grease)
	_add_box(cook_line, Vector3(6.9, 0.16, 2.35), Vector3(0, 2.38, 0.10), steel)
	_add_box(cook_line, Vector3(0.22, 1.45, 0.22), Vector3(-3.15, 1.78, 0.10), cabinet)
	_add_box(cook_line, Vector3(0.22, 1.45, 0.22), Vector3(3.15, 1.78, 0.10), cabinet)
	_add_box(cook_line, Vector3(6.5, 0.055, 0.32), Vector3(0, 2.19, 1.30), warm)
	for burner_x in [-1.8, -0.6, 0.6, 1.8]:
		_add_disc(cook_line, Vector3(burner_x, 1.28, 0.0), 0.34, 0.055, warm)
	for utensil_x in [-2.6, -1.75, -0.9, 0.9, 1.75, 2.6]:
		_add_pipe(cook_line, Vector3(utensil_x, 1.78, 1.36), Vector3.ZERO, 0.035, 0.72, steel)
	_add_room_sign(cook_line, "COOK / MEMORY SERVICE", Vector3(0, 2.82, 1.43), Color8(224, 183, 104), 0.010)
	_add_practical_omni(root, Vector3(23.0, 1.65, -13.1), Color8(255, 151, 72), 2.4, 5.8)

	# The domestic table is the emotional counterpoint to the industrial cook line.
	_add_hero_spot(root, Vector3(-18.5, 2.72, 5.0), Vector3(-18.5, 0.85, 8.8), Color8(225, 194, 137), 4.9, 9.5, 46.0)
	_add_practical_omni(root, Vector3(-18.5, 2.25, 8.8), Color8(231, 187, 119), 1.8, 5.0)
	# A service threshold frames the entrance without closing the route.
	for frame_x in [-6.4, 6.4]:
		_add_box(root, Vector3(0.34, 2.8, 0.34), Vector3(frame_x, 1.42, 11.0), cabinet)
	_add_box(root, Vector3(13.2, 0.22, 0.34), Vector3(0, 2.88, 11.0), cabinet)
	_add_box(root, Vector3(4.4, 0.028, 0.20), Vector3(0, 2.72, 10.96), sick)

	_add_room_asset(root, "duct_long.glb", Vector3(0.0, 2.78, -2.5), 90.0, 0.56)
	_add_room_asset(root, "pipe_rusted.glb", Vector3(-28.8, 2.48, -2.0), 0.0, 2.25)

	# Central preparation island: visible immediately from the entrance and dense
	# enough to make the room read as a working kitchen before any UI prompt does.
	var island = Node3D.new()
	island.name = "KitchenHero_PreparationIsland"
	island.position = Vector3(3.0, 0.0, -3.0)
	island.rotation_degrees.y = -7.0
	root.add_child(island)
	_add_box(island, Vector3(10.8, 0.92, 3.9), Vector3(0, 0.50, 0), cabinet)
	_add_box(island, Vector3(11.2, 0.16, 4.25), Vector3(0, 1.02, 0), steel)
	_add_box(island, Vector3(4.2, 0.12, 2.25), Vector3(-2.55, 1.12, 0), grease)
	_add_box(island, Vector3(3.65, 0.08, 1.75), Vector3(2.75, 1.13, 0), _room_surface(Color8(44, 53, 50), 0.34, 0.38))
	for burner_position in [Vector3(-3.6, 1.20, -0.58), Vector3(-1.55, 1.20, -0.58), Vector3(-3.6, 1.20, 0.58), Vector3(-1.55, 1.20, 0.58)]:
		_add_disc(island, burner_position, 0.46, 0.055, warm)
	_add_pipe(island, Vector3(2.75, 1.72, 0.72), Vector3.ZERO, 0.075, 1.12, steel)
	_add_pipe(island, Vector3(2.75, 2.12, 0.22), Vector3(90, 0, 0), 0.075, 0.82, steel)
	for cabinet_x in [-4.25, -1.45, 1.45, 4.25]:
		_add_box(island, Vector3(2.45, 0.66, 0.065), Vector3(cabinet_x, 0.52, 1.98), enamel)
		_add_box(island, Vector3(0.72, 0.045, 0.09), Vector3(cabinet_x, 0.60, 2.03), steel)
	_add_box(island, Vector3(8.6, 0.34, 3.0), Vector3(0, 2.77, 0), grease)
	_add_box(island, Vector3(7.7, 0.055, 2.32), Vector3(0, 2.57, 0), warm)
	for support_x in [-3.55, 3.55]:
		_add_box(island, Vector3(0.20, 1.52, 0.20), Vector3(support_x, 1.94, 0), steel)
	_add_room_sign(island, "PREP  /  SERVICE", Vector3(0, 2.33, 1.58), Color8(223, 190, 125), 0.009)
	_add_hero_spot(root, Vector3(3.0, 3.05, 2.0), Vector3(3.0, 0.92, -3.0), Color8(255, 205, 139), 8.7, 12.5, 58.0)
	_add_practical_omni(root, Vector3(3.0, 2.20, -3.0), Color8(247, 188, 111), 3.4, 8.5)

	# Refrigerator and pantry silhouettes stop the far wall feeling like generic
	# corridor cladding. One door is left ajar as a small memory-story beat.
	for fridge_x in [-26.0, -22.2, -18.4]:
		_add_box(root, Vector3(3.35, 2.72, 2.15), Vector3(fridge_x, 1.38, -13.65), enamel)
		_add_box(root, Vector3(2.92, 1.98, 0.08), Vector3(fridge_x, 1.48, -12.54), cabinet)
		_add_box(root, Vector3(0.08, 1.22, 0.10), Vector3(fridge_x + 1.13, 1.55, -12.46), steel)
	_add_box(root, Vector3(3.0, 2.45, 0.12), Vector3(-17.0, 1.38, -12.0), enamel).rotation_degrees.y = -24.0
	_add_practical_omni(root, Vector3(-19.2, 1.55, -11.8), Color8(151, 188, 166), 1.45, 4.6)

	# Hand-worked preparation clutter. These silhouettes are concentrated around
	# the hero island so the room reads as a kitchen from the doorway, not only
	# after the player reaches the objective marker.
	for pot_x in [-3.35, -2.35]:
		_add_disc(island, Vector3(pot_x, 1.30, 0.48), 0.42, 0.30, steel)
		_add_disc(island, Vector3(pot_x, 1.48, 0.48), 0.32, 0.045, grease)
	_add_box(island, Vector3(1.45, 0.065, 0.82), Vector3(0.35, 1.22, -0.55), enamel).rotation_degrees.y = -8.0
	for knife_x in [-0.12, 0.18, 0.48]:
		var knife = _add_box(island, Vector3(0.72, 0.035, 0.10), Vector3(knife_x, 1.28, -0.52), steel)
		knife.rotation_degrees.y = -18.0 + knife_x * 12.0
	for jar_data in [
		[Vector3(3.35, 1.38, -0.65), Color8(147, 76, 48)],
		[Vector3(3.85, 1.33, -0.55), Color8(107, 132, 91)],
		[Vector3(4.28, 1.30, -0.42), Color8(177, 143, 72)]
	]:
		_add_disc(island, jar_data[0], 0.18, 0.42, _room_surface(jar_data[1], 0.74))
	# Warm backsplash cards fake reflected practical light at a fraction of the
	# cost of extra dynamic lights.
	_add_box(root, Vector3(16.0, 1.75, 0.035), Vector3(3.0, 1.50, -16.34), _dim_lit_material(Color8(91, 78, 58), 0.86, 0.28))
	_add_box(root, Vector3(10.0, 0.035, 6.0), Vector3(3.0, 0.115, -3.0), _dim_lit_material(Color8(82, 70, 50), 0.92, 0.30))

func _add_roadside_hero_dressing(root: Node3D, car: Node3D, asphalt: Material, rust: Material, rubber: Material, road_line: Material) -> void:
	# Imported street furniture establishes a believable roadside scale.
	_add_room_asset(root, "street_light.glb", Vector3(-20.0, 0.26, -11.6), 0.0, 2.95)
	_add_room_asset(root, "street_light.glb", Vector3(6.0, 0.26, 11.6), 180.0, 2.95)
	_add_room_asset(root, "street_light.glb", Vector3(28.0, 0.26, -11.6), 0.0, 2.95)
	_add_room_asset(root, "busstop.glb", Vector3(-22.0, 0.26, 10.8), 180.0, 2.45)
	_add_room_asset(root, "dumpster_lid_closed.glb", Vector3(27.0, 0.28, 11.2), -12.0, 1.10)
	_add_room_asset(root, "pipe_rusted.glb", Vector3(34.0, 0.28, -11.6), 90.0, 1.85)
	# A contained pool of light makes the repair scene legible without exposing
	# the whole tunnel. Red hazards and cool street lamps create depth layers.
	_add_hero_spot(root, Vector3(1.0, 3.05, 6.8), Vector3(1.0, 0.75, 0.0), Color8(238, 183, 116), 8.5, 13.5, 54.0)
	_add_practical_omni(root, car.position + Vector3(3.8, 0.85, -0.9), Color8(255, 213, 142), 2.8, 6.5)
	_add_practical_omni(root, car.position + Vector3(-2.8, 0.65, 0.0), Color8(168, 46, 35), 1.9, 4.8)
	_add_practical_omni(root, car.position + Vector3(0.0, 2.35, 0.0), Color8(230, 180, 116), 3.6, 9.5)
	for hazard_position in [Vector3(-5.0, 0.72, -4.4), Vector3(7.0, 0.72, 4.6), Vector3(12.0, 0.72, -5.2)]:
		_add_disc(root, hazard_position, 0.12, 0.08, road_line)
		_add_practical_omni(root, hazard_position + Vector3(0, 0.08, 0), Color8(223, 94, 48), 0.7, 2.3)

	# A rough service island and crash barrier keep the vehicle from floating in
	# an empty arena while preserving every path around it.
	_add_box(root, Vector3(13.5, 0.10, 0.22), Vector3(0.5, 0.12, -5.8), road_line)
	for barrier_x in [-5.5, -1.5, 2.5, 6.5]:
		_add_box(root, Vector3(3.3, 0.42, 0.30), Vector3(barrier_x, 0.55, 7.2), rust).rotation_degrees.z = -5.0
		_add_box(root, Vector3(0.16, 0.62, 0.16), Vector3(barrier_x - 1.25, 0.28, 7.2), rubber)
	_add_room_sign(root, "RECOVERY 19", Vector3(1.0, 2.42, -14.70), Color8(202, 129, 77), 0.0040)
	# Wet asphalt patches catch the practical lights without turning the whole road
	# into a mirror. Oil and rain streaks form a path through the repair tableau.
	var wet = _room_surface(Color8(32, 39, 39), 0.22, 0.62)
	for puddle_data in [
		[Vector3(-10.0, 0.105, -3.8), Vector3(8.5, 0.016, 2.2), -5.0],
		[Vector3(1.8, 0.108, 3.8), Vector3(10.5, 0.016, 2.8), -9.0],
		[Vector3(17.0, 0.105, -5.0), Vector3(7.0, 0.016, 1.8), 4.0]
	]:
		var puddle = _add_box(root, puddle_data[1], puddle_data[0], wet)
		puddle.rotation_degrees.y = puddle_data[2]
	for oil_position in [Vector3(-1.2, 0.118, -1.5), Vector3(0.2, 0.119, -1.0), Vector3(1.1, 0.118, -0.4)]:
		_add_disc(root, oil_position, 0.72, 0.018, rubber)
	# Roadside storytelling: a torn cargo trail, repair blanket and distant tunnel
	# thresholds make the scene feel occupied rather than staged on a black plane.
	_add_box(root, Vector3(6.6, 0.035, 3.8), Vector3(-5.2, 0.12, 3.5), _dim_lit_material(Color8(76, 61, 47), 0.96, 0.24)).rotation_degrees.y = 8.0
	for tool_data in [
		[Vector3(-6.4, 0.18, 3.1), Vector3(1.8, 0.08, 0.13), -21.0],
		[Vector3(-4.8, 0.18, 3.8), Vector3(1.25, 0.10, 0.16), 34.0],
		[Vector3(-3.8, 0.22, 2.9), Vector3(0.32, 0.28, 0.22), 0.0]
	]:
		var tool = _add_box(root, tool_data[1], tool_data[0], rust)
		tool.rotation_degrees.y = tool_data[2]
	for debris_data in [
		[Vector3(-12.0, 0.26, 6.4), Vector3(1.5, 0.46, 0.9), -11.0],
		[Vector3(13.0, 0.22, -6.6), Vector3(1.2, 0.38, 0.8), 17.0],
		[Vector3(18.0, 0.18, 5.5), Vector3(0.9, 0.30, 0.6), -28.0]
	]:
		var debris = _add_box(root, debris_data[1], debris_data[0], rubber)
		debris.rotation_degrees.y = debris_data[2]
	# Large low-energy emissive portals retain tunnel depth without another light.
	for portal_x in [-35.5, 35.5]:
		_add_box(root, Vector3(0.22, 3.0, 20.0), Vector3(portal_x, 1.52, 0.0), _dim_lit_material(Color8(48, 45, 39), 0.94, 0.26))
		_add_box(root, Vector3(0.24, 0.16, 12.0), Vector3(portal_x * 0.997, 2.62, 0.0), road_line)

func _add_passport_hero_dressing(root: Node3D, institutional: Material, dirty_white: Material, dark: Material, rubber: Material, glass: Material, cyan: Material, amber: Material, warning: Material) -> void:
	# Central processing portal: the eye catches this before any individual prop.
	var portal = Node3D.new()
	portal.name = "PassportHero_ProcessingPortal"
	portal.position = Vector3(0.0, 0.0, -8.9)
	root.add_child(portal)
	for x in [-7.1, 7.1]:
		_add_box(portal, Vector3(0.42, 2.90, 0.42), Vector3(x, 1.46, 0), institutional)
		_add_box(portal, Vector3(0.10, 2.20, 0.46), Vector3(x, 1.52, 0), cyan)
	_add_box(portal, Vector3(14.7, 0.45, 0.60), Vector3(0, 2.82, 0), dark)
	_add_box(portal, Vector3(9.0, 0.065, 0.64), Vector3(0, 2.57, 0), cyan)
	_add_room_sign(portal, "PROCESSING", Vector3(0, 2.25, 0.36), Color8(153, 207, 199), 0.010)
	_add_hero_spot(root, Vector3(0.0, 3.0, -3.2), Vector3(0.0, 1.0, -9.0), Color8(150, 210, 198), 7.2, 13.0, 46.0)
	_add_practical_omni(root, Vector3(0.0, 1.75, -8.0), Color8(111, 185, 177), 2.4, 6.5)
	_add_practical_omni(root, Vector3(-20.0, 1.6, 10.2), Color8(231, 171, 84), 1.8, 5.2)
	_add_practical_omni(root, Vector3(26.0, 1.7, -6.5), Color8(190, 47, 39), 1.25, 4.8)

	# A suspended clock and paired turnstiles establish airport scale and ritual.
	_add_disc(root, Vector3(10.5, 2.34, 7.4), 0.42, 0.12, dirty_white, Vector3(90, 0, 0))
	_add_pipe(root, Vector3(10.5, 2.67, 7.4), Vector3.ZERO, 0.05, 0.68, institutional)
	_add_box(root, Vector3(0.045, 0.28, 0.045), Vector3(10.5, 2.34, 7.16), dark).rotation_degrees.x = -24.0
	_add_box(root, Vector3(0.045, 0.20, 0.045), Vector3(10.5, 2.34, 7.62), warning).rotation_degrees.x = 38.0
	for gate_x in [-5.0, 5.0]:
		_add_box(root, Vector3(1.25, 0.95, 2.2), Vector3(gate_x, 0.49, 6.0), rubber)
		_add_box(root, Vector3(0.18, 0.75, 2.05), Vector3(gate_x, 1.10, 6.0), glass)
		_add_box(root, Vector3(0.62, 0.08, 0.42), Vector3(gate_x, 1.02, 4.85), amber)
		for arm_angle in [-35.0, 35.0]:
			var arm = _add_box(root, Vector3(1.8, 0.08, 0.08), Vector3(gate_x, 1.18, 6.0), institutional)
			arm.rotation_degrees.y = arm_angle

	# Irregular luggage/document clusters stop the room reading as a mirrored kit.
	for item_data in [
		[Vector3(-13.0, 0.38, 10.5), Vector3(1.4, 0.72, 0.85)],
		[Vector3(-11.6, 0.28, 11.4), Vector3(0.9, 0.52, 0.72)],
		[Vector3(13.5, 0.44, 9.8), Vector3(1.2, 0.82, 0.76)],
		[Vector3(15.0, 0.30, 11.0), Vector3(1.0, 0.56, 0.70)]
	]:
		_add_box(root, item_data[1], item_data[0], rubber)
		_add_box(root, Vector3(0.12, 0.34, 0.12), item_data[0] + Vector3(0, float(item_data[1].y) * 0.65, 0), institutional)
	# Pale wall washes and one worn information island replace the earlier sea of
	# floating labels. The objects now carry the checkpoint story themselves.
	_add_box(root, Vector3(20.0, 2.15, 0.035), Vector3(0.0, 1.45, -16.25), _dim_lit_material(Color8(72, 91, 84), 0.88, 0.32))
	_add_box(root, Vector3(19.0, 0.035, 12.0), Vector3(0.0, 0.118, -7.0), _dim_lit_material(Color8(72, 85, 78), 0.92, 0.29))
	var information = Node3D.new()
	information.name = "PassportInformationIsland"
	information.position = Vector3(14.0, 0.0, 11.8)
	root.add_child(information)
	_add_box(information, Vector3(5.6, 1.00, 2.2), Vector3(0, 0.52, 0), institutional)
	_add_box(information, Vector3(5.9, 0.14, 2.4), Vector3(0, 1.08, 0), dirty_white)
	_add_box(information, Vector3(4.2, 1.20, 0.12), Vector3(0, 1.78, -0.72), dark)
	_add_box(information, Vector3(3.6, 0.82, 0.055), Vector3(0, 1.78, -0.64), cyan)
	_add_room_sign(information, "INFORMATION", Vector3(0, 2.48, -0.74), Color8(154, 191, 180), 0.009)

func _add_hero_spot(parent: Node3D, position: Vector3, target: Vector3, color: Color, energy: float, light_range: float, angle: float) -> void:
	var light = SpotLight3D.new()
	light.name = "HeroSpot"
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.spot_range = light_range
	light.spot_angle = angle
	light.spot_attenuation = 1.15
	light.light_specular = 0.32
	light.shadow_enabled = false
	parent.add_child(light)
	light.look_at(parent.to_global(target), Vector3.UP)
	_register_monster_warding_light(parent.to_global(target), clamp(energy * 0.22, 0.75, 1.65))
	# The light itself feeds the scene fog; no decorative mesh shaft is needed.

func _add_practical_omni(parent: Node3D, position: Vector3, color: Color, energy: float, light_range: float) -> void:
	var glow = MeshInstance3D.new()
	glow.name = "BakedPracticalGlow"
	var mesh = BoxMesh.new()
	mesh.size = Vector3(clamp(light_range * 0.052, 0.22, 0.48), 0.055, 0.13)
	glow.mesh = mesh
	glow.position = position
	glow.material_override = _glow_material(color, clamp(energy * 0.85, 0.8, 2.8))
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(glow)
	# A restrained, shadowless practical carries the fixture's actual color into
	# nearby surfaces without multiplying the expensive shadow-light count.
	var practical = OmniLight3D.new()
	practical.name = "ColoredPracticalLight"
	practical.position = position
	practical.light_color = color
	practical.light_energy = clamp(energy * 0.56, 0.38, 1.65)
	practical.omni_range = min(light_range, 7.5)
	practical.omni_attenuation = 1.45
	practical.light_specular = 0.10
	practical.shadow_enabled = false
	parent.add_child(practical)
	_register_monster_warding_light(parent.to_global(position), clamp(energy * 0.42, 0.55, 1.45))

func _add_light_shaft(parent: Node3D, origin: Vector3, target: Vector3, color: Color, end_radius: float, opacity: float) -> void:
	var direction = target - origin
	var shaft_length = direction.length()
	if shaft_length <= 0.12:
		return
	var shaft = MeshInstance3D.new()
	shaft.name = "VolumetricLightShaft"
	var mesh = CylinderMesh.new()
	mesh.top_radius = max(0.045, end_radius * 0.055)
	mesh.bottom_radius = end_radius
	mesh.height = shaft_length
	mesh.radial_segments = 12
	mesh.cap_top = false
	mesh.cap_bottom = false
	shaft.mesh = mesh
	shaft.position = (origin + target) * 0.5
	var normalized_direction = direction / shaft_length
	var rotation_axis = Vector3.UP.cross(normalized_direction)
	if rotation_axis.length_squared() > 0.00001:
		shaft.rotate(rotation_axis.normalized(), acos(clamp(Vector3.UP.dot(normalized_direction), -1.0, 1.0)))
	elif normalized_direction.y < 0.0:
		shaft.rotation_degrees.x = 180.0
	shaft.material_override = _light_shaft_material(color, opacity)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(shaft)

func _light_shaft_material(color: Color, opacity: float) -> ShaderMaterial:
	var cache_key = "%s_%.3f" % [color.to_html(false), opacity]
	if light_shaft_material_cache.has(cache_key):
		return light_shaft_material_cache[cache_key]
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 shaft_color : source_color;
void fragment() {
	float length_fade = smoothstep(0.01, 0.13, UV.y) * (1.0 - smoothstep(0.76, 1.0, UV.y));
	float mist_bands = 0.72 + sin((UV.y * 5.0 + UV.x * 0.8) * 6.28318 + TIME * 0.20) * 0.14;
	mist_bands += sin(UV.y * 71.0 - TIME * 0.13) * 0.07;
	ALBEDO = shaft_color.rgb;
	float opacity = shaft_color.a * length_fade * mist_bands;
	EMISSION = shaft_color.rgb * 1.10;
	ALPHA = opacity;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shaft_color", Color(color.r, color.g, color.b, opacity))
	light_shaft_material_cache[cache_key] = material
	return material

func _add_room_asset(parent: Node3D, file_name: String, position: Vector3, yaw: float, target_height: float) -> Node3D:
	var path = URBAN_ASSET_ROOT + file_name
	var packed: PackedScene = room_asset_cache.get(path)
	if packed == null:
		if not ResourceLoader.exists(path):
			return null
		packed = load(path) as PackedScene
		if packed == null:
			return null
		room_asset_cache[path] = packed
	var imported = packed.instantiate()
	if not imported is Node3D:
		imported.queue_free()
		return null
	var holder = Node3D.new()
	holder.name = "UrbanAsset_%s" % file_name.get_basename()
	holder.position = position
	holder.rotation_degrees.y = yaw
	parent.add_child(holder)
	holder.add_child(imported)
	_prepare_room_asset(imported)
	_normalize_room_asset(imported, target_height)
	return holder

func _prepare_room_asset(root: Node) -> void:
	if root is MeshInstance3D:
		root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if root is CollisionObject3D:
		root.collision_layer = 0
		root.collision_mask = 0
	if root is CollisionShape3D:
		root.disabled = true
	if root is Light3D or root is Camera3D:
		root.visible = false
	for child in root.get_children():
		_prepare_room_asset(child)

func _normalize_room_asset(root: Node3D, target_height: float) -> void:
	var bounds = _room_asset_bounds(root)
	if bounds.size == Vector3.ZERO or bounds.size.y <= 0.001:
		return
	var ratio = target_height / bounds.size.y
	var center = bounds.position + bounds.size * 0.5
	root.scale = Vector3.ONE * ratio
	root.position = Vector3(-center.x * ratio, -bounds.position.y * ratio, -center.z * ratio)

func _room_asset_bounds(root: Node3D) -> AABB:
	var found = false
	var bounds = AABB()
	var root_inverse = root.global_transform.affine_inverse()
	for node in _walk_room_asset_nodes(root):
		if not node is MeshInstance3D:
			continue
		var mesh_node = node as MeshInstance3D
		var local_bounds = mesh_node.get_aabb()
		if local_bounds.size == Vector3.ZERO:
			continue
		for corner in _room_aabb_corners(local_bounds):
			var point = root_inverse * mesh_node.to_global(corner)
			if not found:
				bounds = AABB(point, Vector3.ZERO)
				found = true
			else:
				bounds = bounds.expand(point)
	return bounds if found else AABB()

func _walk_room_asset_nodes(root: Node) -> Array:
	var nodes: Array = [root]
	for child in root.get_children():
		nodes.append_array(_walk_room_asset_nodes(child))
	return nodes

func _room_aabb_corners(box: AABB) -> Array:
	var p = box.position
	var s = box.size
	return [p, p + Vector3(s.x, 0, 0), p + Vector3(0, s.y, 0), p + Vector3(0, 0, s.z), p + Vector3(s.x, s.y, 0), p + Vector3(s.x, 0, s.z), p + Vector3(0, s.y, s.z), p + s]

func _dress_kitchen_memory(root: Node3D, enamel: Material, tile: Material, cabinet: Material, steel: Material, grease: Material, warm: Material, sick: Material) -> void:
	# The structural ceiling is built once by _build_kitchen_scenario().
	# Cabinet fronts, handles and vents turn the long counter bank into readable
	# kitchen furniture when it enters the flashlight cone.
	for x in [-26.0, -20.5, -15.0, -9.5, -4.0, 1.5, 7.0, 12.5, 18.0]:
		for offset in [-1.18, 1.18]:
			_add_box(root, Vector3(2.18, 0.73, 0.055), Vector3(x + offset, 0.58, -14.25), cabinet)
			_add_box(root, Vector3(0.62, 0.055, 0.075), Vector3(x + offset, 0.62, -14.19), steel)
	# Open shelving is filled unevenly so it feels abandoned rather than copied.
	for shelf_y in [0.72, 1.52, 2.32]:
		for item_index in 5:
			var item_x = 16.8 + float(item_index) * 1.55
			var item_height = 0.24 + float((item_index + int(shelf_y * 10.0)) % 3) * 0.13
			_add_box(root, Vector3(0.62, item_height, 0.66), Vector3(item_x, shelf_y + 0.12, 14.35), enamel if item_index % 2 == 0 else grease)
			if item_index in [1, 4]:
				_add_box(root, Vector3(0.38, 0.045, 0.70), Vector3(item_x, shelf_y + item_height * 0.55, 14.35), warm)
	# A battered service trolley, trays and a tipped waste bin fill the transition
	# between task stations while leaving the player route broad and clear.
	var trolley = Node3D.new()
	trolley.name = "Kitchen_ServiceTrolley"
	trolley.position = Vector3(18.0, 0.0, 5.8)
	trolley.rotation_degrees.y = -14.0
	root.add_child(trolley)
	for shelf_y in [0.34, 0.96]:
		_add_box(trolley, Vector3(4.0, 0.12, 1.75), Vector3(0, shelf_y, 0), steel)
	for leg in [Vector3(-1.72, 0.48, -0.64), Vector3(1.72, 0.48, -0.64), Vector3(-1.72, 0.48, 0.64), Vector3(1.72, 0.48, 0.64)]:
		_add_box(trolley, Vector3(0.13, 0.88, 0.13), leg, cabinet)
		_add_disc(trolley, leg + Vector3(0, -0.43, 0), 0.16, 0.10, grease, Vector3(90, 0, 0))
	for tray_x in [-1.25, 0.0, 1.25]:
		_add_box(trolley, Vector3(0.94, 0.045, 1.12), Vector3(tray_x, 1.04, 0), enamel)
	var bin = Node3D.new()
	bin.name = "Kitchen_TippedWaste"
	bin.position = Vector3(27.0, 0.30, 5.5)
	bin.rotation_degrees = Vector3(0, 20, 72)
	root.add_child(bin)
	_add_box(bin, Vector3(1.0, 1.25, 1.0), Vector3.ZERO, grease)
	for scrap_position in [Vector3(25.7, 0.12, 5.0), Vector3(24.8, 0.10, 6.1), Vector3(26.0, 0.11, 7.0)]:
		_add_box(root, Vector3(0.72, 0.035, 0.48), scrap_position, enamel)
	# Task markings visually connect the scavenged items to the cooking station.
	_add_emissive_task_marker(root, Vector3(-22.0, 0.105, -12.8), warm, 3.0)
	_add_emissive_task_marker(root, Vector3(-2.0, 0.105, 2.5), sick, 2.6)
	_add_emissive_task_marker(root, Vector3(20.0, 0.105, 12.7), warm, 3.0)
	_add_emissive_task_marker(root, Vector3(23.0, 0.105, -12.7), warm, 4.0)
	_add_room_sign(root, "NO SERVICE / 02:17", Vector3(-24.5, 2.05, 16.42), Color8(151, 116, 70), 0.009)

func _dress_broken_car(car: Node3D, car_paint: Material, rust: Material, rubber: Material, road_line: Material) -> void:
	var glass = _room_surface(Color(0.055, 0.095, 0.10, 0.72), 0.18, 0.36)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var upholstery = _room_surface(Color8(39, 43, 40), 0.92)
	# Windows and pillars create a recognisable cabin silhouette.
	_add_box(car, Vector3(1.36, 0.72, 2.38), Vector3(-0.70, 1.56, 0), glass)
	_add_box(car, Vector3(0.13, 0.86, 2.52), Vector3(-1.42, 1.53, 0), rust).rotation_degrees.z = 15.0
	_add_box(car, Vector3(0.13, 0.86, 2.52), Vector3(0.08, 1.53, 0), rust).rotation_degrees.z = -15.0
	for seat_z in [-0.72, 0.72]:
		_add_box(car, Vector3(0.92, 0.72, 0.64), Vector3(-0.68, 1.08, seat_z), upholstery)
		_add_box(car, Vector3(0.72, 0.92, 0.18), Vector3(-1.05, 1.46, seat_z), upholstery).rotation_degrees.z = -8.0
	# Door seams, handles, bumpers and grille make the car readable up close.
	for side_z in [-1.52, 1.52]:
		_add_box(car, Vector3(2.65, 0.055, 0.035), Vector3(-0.55, 0.91, side_z), rust)
		_add_box(car, Vector3(0.055, 0.75, 0.035), Vector3(-1.85, 0.91, side_z), rust)
		_add_box(car, Vector3(0.62, 0.09, 0.055), Vector3(-0.55, 1.12, side_z), rubber)
		_add_box(car, Vector3(0.62, 0.28, 0.16), Vector3(-0.65, 1.84, side_z), glass)
	_add_box(car, Vector3(0.22, 0.46, 2.78), Vector3(3.68, 0.52, 0), rubber)
	for grille_z in [-0.78, -0.39, 0.0, 0.39, 0.78]:
		_add_box(car, Vector3(0.08, 0.38, 0.16), Vector3(3.79, 0.63, grille_z), rust)
	_add_box(car, Vector3(0.08, 0.52, 1.16), Vector3(-3.68, 0.78, 0), rubber)
	_add_box(car, Vector3(0.09, 0.28, 0.64), Vector3(-3.75, 0.92, 0), road_line)
	# The open bonnet exposes an engine mass, hoses and a weak service light.
	_add_box(car, Vector3(2.05, 0.42, 2.18), Vector3(2.22, 0.88, 0), rubber)
	for engine_z in [-0.68, 0.0, 0.68]:
		_add_pipe(car, Vector3(2.32, 1.16, engine_z), Vector3(0, 0, 90), 0.11, 1.25, rust)
	_add_box(car, Vector3(0.68, 0.52, 0.92), Vector3(2.12, 1.12, 0), car_paint)
	_add_box(car, Vector3(1.36, 0.035, 0.10), Vector3(2.38, 1.46, 0), road_line)

func _dress_roadside_memory(root: Node3D, asphalt: Material, rust: Material, rubber: Material, road_line: Material) -> void:
	# The underpass ceiling is built once by _build_car_scenario().
	# Drainage, oil and old lane repairs make the floor tell the breakdown story.
	var puddle = _room_surface(Color(0.025, 0.030, 0.031, 0.78), 0.16, 0.46)
	puddle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for puddle_data in [
		[Vector3(-8.0, 0.102, 4.5), Vector3(7.5, 0.018, 2.8), -9.0],
		[Vector3(4.0, 0.103, -4.0), Vector3(5.4, 0.018, 2.2), 16.0],
		[Vector3(20.0, 0.103, 7.2), Vector3(4.2, 0.018, 1.8), -21.0]
	]:
		var stain = _add_box(root, puddle_data[1], puddle_data[0], puddle)
		stain.rotation_degrees.y = float(puddle_data[2])
	# A repair kit, luggage and safety triangles form a close-range prop cluster.
	var toolbox = Node3D.new()
	toolbox.name = "Roadside_Toolbox"
	toolbox.position = Vector3(5.8, 0.0, 3.0)
	toolbox.rotation_degrees.y = -17.0
	root.add_child(toolbox)
	_add_box(toolbox, Vector3(2.0, 0.48, 0.92), Vector3(0, 0.28, 0), rust)
	_add_box(toolbox, Vector3(1.72, 0.06, 0.68), Vector3(0, 0.55, 0), road_line)
	_add_box(toolbox, Vector3(0.62, 0.30, 0.12), Vector3(0, 0.78, 0), rubber)
	for tool_x in [-0.68, -0.18, 0.34, 0.72]:
		_add_box(root, Vector3(0.48, 0.055, 0.10), Vector3(6.1 + tool_x, 0.13, 4.0 + tool_x * 0.25), road_line).rotation_degrees.y = 18.0 + tool_x * 21.0
	for case_data in [
		[Vector3(-12.0, 0.48, 11.2), Vector3(1.45, 0.92, 0.74)],
		[Vector3(-10.5, 0.36, 12.2), Vector3(1.10, 0.68, 0.62)]
	]:
		_add_box(root, case_data[1], case_data[0], rubber)
	# Repeating cable trays and dripping pipes fill the ceiling without adding
	# expensive light nodes.
	for z in [-10.5, 10.5]:
		_add_box(root, Vector3(70.0, 0.18, 0.72), Vector3(0, WALL_HEIGHT - 0.42, z), rust)
		for x in [-28.0, -14.0, 0.0, 14.0, 28.0]:
			_add_pipe(root, Vector3(x, WALL_HEIGHT - 0.54, z), Vector3(0, 0, 90), 0.08, 8.0, rubber)
	_add_emissive_task_marker(root, Vector3(-30.0, 0.31, -10.5), road_line, 3.2)
	_add_emissive_task_marker(root, Vector3(31.0, 0.31, 11.5), road_line, 3.2)
	_add_emissive_task_marker(root, Vector3(-27.0, 0.31, 11.5), road_line, 3.2)

func _dress_passport_memory(root: Node3D, institutional: Material, dirty_white: Material, dark: Material, rubber: Material, glass: Material, cyan: Material, amber: Material, warning: Material) -> void:
	# The institutional ceiling is built once by _build_passport_scenario().
	# Large arrivals board and its dead modules establish the room at a glance.
	var board = Node3D.new()
	board.name = "Passport_ArrivalsBoard"
	board.position = Vector3(0.0, 2.46, 15.85)
	root.add_child(board)
	_add_box(board, Vector3(25.0, 1.55, 0.16), Vector3.ZERO, dark)
	for row_index in 3:
		for column_index in 6:
			var alive = (row_index + column_index) % 4 != 0
			var module_material = cyan if alive else rubber
			_add_box(board, Vector3(3.45, 0.22, 0.035), Vector3(-9.2 + column_index * 3.68, 0.45 - row_index * 0.43, -0.10), module_material)
	# Passport stamps, paper stacks and desk lamps make the working booth tactile.
	for desk_x in [-5.2, 0.0, 5.2]:
		for stack_index in 3:
			_add_box(root, Vector3(0.72, 0.035, 0.54), Vector3(desk_x + 1.1, 1.12 + stack_index * 0.045, -8.35), dirty_white)
		_add_disc(root, Vector3(desk_x - 1.05, 1.20, -8.26), 0.16, 0.18, warning, Vector3(90, 0, 0))
		_add_pipe(root, Vector3(desk_x - 1.05, 1.58, -8.55), Vector3.ZERO, 0.055, 0.70, institutional)
		_add_box(root, Vector3(0.62, 0.08, 0.48), Vector3(desk_x - 1.05, 1.88, -8.38), amber)
	# Luggage and document archive storage populate the side lanes while keeping
	# all mission items visible and reachable.
	for archive_x in [-37.0, 37.0]:
		for shelf_y in [0.55, 1.35, 2.15]:
			_add_box(root, Vector3(5.8, 0.10, 1.25), Vector3(archive_x, shelf_y, -1.0), institutional)
			for file_index in 4:
				var file_x = archive_x - 2.0 + file_index * 1.25
				_add_box(root, Vector3(0.72, 0.56, 0.92), Vector3(file_x, shelf_y + 0.34, -1.0), warning if file_index == 0 else rubber)
	for luggage in [Vector3(-31.0, 0.46, 10.8), Vector3(-28.8, 0.35, 11.6), Vector3(26.0, 0.52, 11.0), Vector3(29.0, 0.38, 12.0)]:
		_add_box(root, Vector3(1.25, 0.82, 0.72), luggage, rubber)
		_add_box(root, Vector3(0.12, 0.42, 0.12), luggage + Vector3(0, 0.60, 0), institutional)
	# The guide and the three document locations get restrained floor notation;
	# the color language matches the submission trays rather than floating UI.
	_add_emissive_task_marker(root, Vector3(-20.0, 0.105, 10.4), cyan, 3.0)
	_add_emissive_task_marker(root, Vector3(-29.0, 0.105, 5.2), cyan, 2.6)
	_add_emissive_task_marker(root, Vector3(30.0, 0.105, 4.0), warning, 2.6)
	_add_emissive_task_marker(root, Vector3(18.0, 0.105, 14.8), dirty_white, 2.6)
	# Thin glass side screens catch the flashlight and give the central checkpoint
	# depth without blocking its interaction pads.
	for screen_x in [-8.2, 8.2]:
		_add_box(root, Vector3(0.08, 1.82, 3.4), Vector3(screen_x, 1.72, -8.9), glass)
		_add_box(root, Vector3(0.16, 2.0, 0.16), Vector3(screen_x, 1.70, -10.55), institutional)
		_add_box(root, Vector3(0.16, 2.0, 0.16), Vector3(screen_x, 1.70, -7.25), institutional)
	_add_room_sign(root, "NO RETURN / NO RECORD", Vector3(25.0, 2.15, -16.30), Color8(156, 64, 54), 0.009)

func _build_hide_lockers(_raw: Array) -> void:
	hide_lockers.clear()
	var selected_cells: Array[Vector2i] = []
	var candidates = [
		Vector2i(33, 94), Vector2i(10, 86), Vector2i(14, 79), Vector2i(42, 72),
		Vector2i(20, 62), Vector2i(5, 43), Vector2i(38, 25), Vector2i(9, 29)
	]
	for index in candidates.size():
		var cell = _nearest_locker_cell(candidates[index], selected_cells)
		if cell.x < 0:
			continue
		var wall_direction = _locker_wall_direction(cell)
		if wall_direction == Vector2i.ZERO:
			continue
		selected_cells.append(cell)
		var wall_vector = Vector3(float(wall_direction.x), 0.0, float(wall_direction.y))
		var front = -wall_vector
		var root = Node3D.new()
		root.name = "HideLocker_%02d" % (index + 1)
		root.position = _cell_world(cell) + wall_vector * 1.22
		root.rotation.y = atan2(-front.x, -front.z)
		add_child(root)
		_build_locker_visual(root)
		var hide_position = root.to_global(Vector3(0.0, 0.0, -0.02))
		var exit_position_local = root.to_global(Vector3(0.0, 0.0, -1.05))
		var entry = {
			"hide_position": hide_position,
			"exit_position": exit_position_local,
			"hide_yaw": root.rotation.y
		}
		_add_interactable("locker_%02d" % index, "hide_locker", root, "HIDE IN LOCKER", "LOCKER", false, true, entry)
		hide_lockers.append(root)

func _nearest_locker_cell(origin: Vector2i, selected_cells: Array[Vector2i]) -> Vector2i:
	for radius in range(0, 10):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				if radius > 0 and x > origin.x - radius and x < origin.x + radius and y > origin.y - radius and y < origin.y + radius:
					continue
				var cell = Vector2i(x, y)
				if monster_navigation == null or not monster_navigation.is_in_boundsv(cell) or monster_navigation.is_point_solid(cell):
					continue
				if _inside_kitchen_art_zone(_cell_world(cell)):
					continue
				if _locker_wall_direction(cell) == Vector2i.ZERO:
					continue
				var too_close = false
				for chosen in selected_cells:
					var separation = Vector2(float(cell.x - chosen.x), float(cell.y - chosen.y))
					if separation.length() < 8.0:
						too_close = true
						break
				if not too_close:
					return cell
	return Vector2i(-1, -1)

func _locker_wall_direction(cell: Vector2i) -> Vector2i:
	for direction in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var neighbor = cell + direction
		if monster_navigation != null and monster_navigation.is_in_boundsv(neighbor) and monster_navigation.is_point_solid(neighbor):
			return direction
	return Vector2i.ZERO

func _build_locker_visual(root: Node3D) -> void:
	var blue = _flat_material(Color8(37, 67, 86), 0.54)
	var edge = _flat_material(Color8(18, 31, 39), 0.78)
	var inside = _flat_material(Color8(8, 15, 19), 0.96)
	var worn = _flat_material(Color8(86, 106, 111), 0.68)
	var handle = _glow_material(Color8(188, 151, 72), 0.75)
	var edge_parts: Array = [
		[Vector3(1.12, 2.48, 0.10), Vector3(0.0, 1.24, 0.34), Vector3.ZERO],
		[Vector3(1.12, 0.10, 0.76), Vector3(0.0, 0.05, 0.0), Vector3.ZERO]
	]
	var blue_parts: Array = [
		[Vector3(0.10, 2.48, 0.76), Vector3(-0.51, 1.24, 0.0), Vector3.ZERO],
		[Vector3(0.10, 2.48, 0.76), Vector3(0.51, 1.24, 0.0), Vector3.ZERO],
		[Vector3(1.12, 0.10, 0.76), Vector3(0.0, 2.43, 0.0), Vector3.ZERO]
	]
	var worn_parts: Array = [
		[Vector3(1.00, 0.07, 0.64), Vector3(0.0, 1.22, 0.02), Vector3.ZERO],
		[Vector3(0.06, 2.28, 0.06), Vector3(-0.43, 1.23, -0.30), Vector3.ZERO],
		[Vector3(0.06, 2.28, 0.06), Vector3(0.43, 1.23, -0.30), Vector3.ZERO]
	]
	var inside_parts: Array = [
		[Vector3(0.90, 2.24, 0.04), Vector3(0.0, 1.25, 0.30), Vector3.ZERO]
	]
	var handle_parts: Array = []
	var door_transform := Transform3D(Basis(Vector3.UP, deg_to_rad(-67.0)), Vector3(0.50, 0.0, -0.33))
	_append_locker_part(blue_parts, Vector3(1.02, 2.38, 0.075), Vector3(-0.51, 1.24, 0.0), door_transform)
	for row in 6:
		var y = 1.78 + float(row) * 0.095
		_append_locker_part(edge_parts, Vector3(0.46, 0.026, 0.028), Vector3(-0.52, y, -0.052), door_transform)
	for row in 5:
		var y = 0.42 + float(row) * 0.095
		_append_locker_part(edge_parts, Vector3(0.46, 0.026, 0.028), Vector3(-0.52, y, -0.052), door_transform)
	_append_locker_part(handle_parts, Vector3(0.09, 0.22, 0.08), Vector3(-0.82, 1.22, -0.07), door_transform)
	_add_box_multimesh(root, blue_parts, blue, "BlueShell")
	_add_box_multimesh(root, edge_parts, edge, "DarkEdges")
	_add_box_multimesh(root, worn_parts, worn, "WornMetal")
	_add_box_multimesh(root, inside_parts, inside, "DarkInterior")
	_add_box_multimesh(root, handle_parts, handle, "Handle")

func _append_locker_part(parts: Array, box_size: Vector3, local_position: Vector3, parent_transform: Transform3D) -> void:
	var local_transform := Transform3D(Basis.IDENTITY.scaled(box_size), local_position)
	parts.append(parent_transform * local_transform)

func _add_box_multimesh(parent: Node3D, parts: Array, material: Material, node_name: String) -> MultiMeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = parts.size()
	for index in parts.size():
		var part = parts[index]
		var transform: Transform3D
		if part is Transform3D:
			transform = part
		else:
			var size: Vector3 = part[0]
			var position: Vector3 = part[1]
			var rotation_degrees: Vector3 = part[2]
			transform = Transform3D(Basis.from_euler(rotation_degrees * PI / 180.0).scaled(size), position)
		multimesh.set_instance_transform(index, transform)
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _build_monster_navigation(raw: Array) -> void:
	if raw.is_empty():
		return
	monster_open_cells.clear()
	monster_navigation = AStarGrid2D.new()
	monster_navigation.region = Rect2i(0, 0, String(raw[0]).length(), raw.size())
	monster_navigation.cell_size = Vector2.ONE
	monster_navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	monster_navigation.update()
	for row in raw.size():
		var line = String(raw[row])
		for col in line.length():
			var cell = Vector2i(col, row)
			var cell_position := _cell_world(cell)
			var solid = level_manager.is_blocked_world(cell_position + Vector3.UP * 0.48, MONSTER_BODY_RADIUS)
			if not solid:
				solid = _monster_position_in_warding_light(cell_position, MONSTER_BODY_RADIUS)
			monster_navigation.set_point_solid(cell, solid)
			if not solid:
				monster_open_cells.append(cell)

func _build_monster_search_route() -> void:
	monster_patrol_points.clear()
	# These points cover the critical route, reconnecting loops and all three
	# memory rooms. The creature therefore searches the facility from frame one.
	for cell in [
		Vector2i(30, 40), Vector2i(19, 19), Vector2i(38, 25),
		Vector2i(43, 36), Vector2i(40, 52), Vector2i(20, 62),
		Vector2i(42, 72), Vector2i(14, 79), Vector2i(33, 94),
		Vector2i(8, 97), Vector2i(17, 43), Vector2i(9, 29)
	]:
		monster_patrol_points.append(_cell_world(_nearest_open_cell(cell)))

func _spawn_amalgam() -> void:
	if monster_navigation == null:
		return
	monster_root = Node3D.new()
	monster_root.name = "SpiderHumanStalker"
	var spawn_cell = _nearest_monster_spawn_cell(Vector2i(30, 40))
	if spawn_cell.x < 0:
		monster_root.free()
		monster_root = null
		return
	monster_root.position = _cell_world(spawn_cell)
	monster_last_known_position = monster_root.position
	monster_last_motion_position = monster_root.position
	monster_state = "stalk"
	monster_state_timer = 0.0
	monster_awake = true
	add_child(monster_root)
	monster_previous_facing = monster_root.rotation.y
	_spawn_monster_model()
	_create_monster_light_vfx()
	monster_presence_light = OmniLight3D.new()
	monster_presence_light.name = "StalkerPresenceLight"
	monster_presence_light.position = Vector3(0, 1.15, 0.32)
	monster_presence_light.light_color = Color8(129, 123, 105)
	monster_presence_light.light_energy = 0.0
	monster_presence_light.omni_range = 3.4
	monster_presence_light.omni_attenuation = 2.05
	monster_presence_light.light_specular = 0.02
	monster_presence_light.shadow_enabled = false
	monster_root.add_child(monster_presence_light)
	monster_face_light = OmniLight3D.new()
	monster_face_light.name = "StalkerReflectedFaceLight"
	monster_face_light.position = Vector3(0, 0.88, -0.98)
	monster_face_light.light_color = Color8(154, 151, 132)
	monster_face_light.light_energy = 0.0
	monster_face_light.omni_range = 2.65
	monster_face_light.omni_attenuation = 2.18
	monster_face_light.light_specular = 0.025
	monster_face_light.shadow_enabled = false
	monster_root.add_child(monster_face_light)
	monster_audio = AudioStreamPlayer3D.new()
	monster_audio.name = "StalkerBreath"
	monster_audio.stream = _make_amalgam_breath_loop()
	monster_audio.unit_size = 4.0
	monster_audio.max_distance = 34.0
	monster_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	monster_audio.volume_db = -80.0
	monster_root.add_child(monster_audio)
	monster_audio.play()
	monster_reentry_audio = AudioStreamPlayer3D.new()
	monster_reentry_audio.name = "StalkerReentryScrape"
	monster_reentry_audio.stream = _make_monster_reentry_scrape()
	monster_reentry_audio.volume_db = -13.0
	monster_reentry_audio.unit_size = 5.0
	monster_reentry_audio.max_distance = 42.0
	monster_reentry_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	monster_root.add_child(monster_reentry_audio)
	monster_hunt_audio = AudioStreamPlayer3D.new()
	monster_hunt_audio.name = "StalkerHuntInhale"
	monster_hunt_audio.stream = _make_monster_hunt_inhale()
	monster_hunt_audio.volume_db = -11.5
	monster_hunt_audio.unit_size = 4.5
	monster_hunt_audio.max_distance = 34.0
	monster_hunt_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	monster_root.add_child(monster_hunt_audio)

func _spawn_monster_model() -> void:
	var packed = load(MONSTER_MODEL_PATH)
	if not packed is PackedScene:
		push_error("Maze monster model could not be loaded: %s" % MONSTER_MODEL_PATH)
		return
	var instance = packed.instantiate()
	if not instance is Node3D:
		push_error("Maze monster model root must be Node3D: %s" % MONSTER_MODEL_PATH)
		instance.queue_free()
		return
	monster_model = instance as Node3D
	monster_model.name = "CorridorCreatureVisual"
	monster_model.scale = Vector3.ONE * MONSTER_MODEL_SCALE
	monster_model.position = Vector3(0.0, 0.02, 0.0)
	monster_model.rotation.y = PI
	monster_root.add_child(monster_model)
	_prepare_monster_model(monster_model)
	monster_animation_player = _find_monster_animation_player(monster_model)
	monster_skeleton = _find_monster_skeleton(monster_model)
	_configure_monster_animations()
	_create_monster_expression()
	creature_visual_last_position = monster_root.global_position
	creature_visual_last_yaw = monster_root.rotation.y

func _prepare_monster_model(root: Node) -> void:
	if root is MeshInstance3D:
		(root as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if root is CollisionObject3D:
		(root as CollisionObject3D).collision_layer = 0
		(root as CollisionObject3D).collision_mask = 0
	if root is CollisionShape3D:
		(root as CollisionShape3D).disabled = true
	if root is Camera3D or root is Light3D:
		(root as Node3D).visible = false
	for child in root.get_children():
		_prepare_monster_model(child)

func _create_monster_light_vfx() -> void:
	_capture_monster_scorch_materials(monster_model)
	# The model already casts a real articulated shadow. Screen-facing aura shells
	# and a procedural floor stain made the reaction look like a game status
	# effect, so light pain is carried by performance, material drainage and a
	# layered smoke volume that is left behind in world space as it flees.
	monster_contact_shadow = null
	monster_contact_shadow_material = null
	monster_burn_aura = null
	monster_burn_aura_material = null
	# Light pressure is communicated by the creature's physical recoil and hiss,
	# not overlapping billboard clouds or screen-filling reaction effects.
	monster_burn_smoke = null
	monster_burn_smoke_wake = null
	monster_burn_embers = null
	monster_light_wisps.clear()
	monster_pain_audio = AudioStreamPlayer3D.new()
	monster_pain_audio.name = "LightPainHiss"
	monster_pain_audio.stream = _make_monster_light_pain_sound()
	monster_pain_audio.volume_db = -8.0
	monster_pain_audio.unit_size = 3.0
	monster_pain_audio.max_distance = 30.0
	monster_root.add_child(monster_pain_audio)

func _create_monster_light_wisps() -> void:
	monster_light_wisps.clear()
	var positions = [Vector3(-0.52, 1.00, -0.10), Vector3(0.16, 1.20, 0.08), Vector3(0.62, 0.88, -0.04)]
	for index in range(positions.size()):
		var wisp = MeshInstance3D.new()
		wisp.name = "LightSteamWisp_%d" % index
		var mesh = QuadMesh.new()
		mesh.size = Vector2(0.38 + float(index) * 0.045, 0.94 + float(index % 2) * 0.18)
		wisp.mesh = mesh
		wisp.position = positions[index]
		wisp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material = _make_monster_light_wisp_material(float(index) * 1.83)
		wisp.material_override = material
		wisp.visible = false
		monster_root.add_child(wisp)
		monster_light_wisps.append({"mesh": wisp, "material": material, "phase": float(index) * 1.83, "base_position": positions[index]})

func _make_monster_light_wisp_material(phase: float) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float strength = 0.0;
uniform float phase = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = UV - vec2(0.5);
	p.x *= 2.7;
	float taper = mix(1.0, 0.34, UV.y);
	float drift = sin(UV.y * 8.0 + TIME * 2.4 + phase) * 0.16 + sin(UV.y * 15.0 - TIME * 1.3 + phase * 0.7) * 0.07;
	float strand = 1.0 - smoothstep(taper * 0.18, taper * 0.58, abs(p.x + drift));
	float fade = smoothstep(0.0, 0.20, UV.y) * (1.0 - smoothstep(0.56, 1.0, UV.y));
	float torn = 0.84 + 0.16 * sin(UV.y * 10.0 - TIME * 2.1 + phase);
	vec3 ash = mix(vec3(0.32, 0.35, 0.33), vec3(0.60, 0.64, 0.59), UV.y);
	ALBEDO = ash * 0.58;
	EMISSION = ash * 0.075;
	ALPHA = strand * fade * torn * strength * 0.24;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("strength", 0.0)
	material.set_shader_parameter("phase", phase)
	return material

func _capture_monster_scorch_materials(root: Node) -> void:
	if root is MeshInstance3D:
		var mesh_instance = root as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface_index in mesh_instance.mesh.get_surface_count():
				var active_material = mesh_instance.get_active_material(surface_index)
				if active_material is BaseMaterial3D:
					var source_material = active_material as BaseMaterial3D
					var is_head = "Head" in mesh_instance.name
					var material = _make_monster_integrated_material(source_material, is_head)
					mesh_instance.set_surface_override_material(surface_index, material)
					monster_scorch_materials.append({
						"material": material,
						"region_weight": 1.0 if is_head else 0.72,
						"phase": float(monster_scorch_materials.size()) * 1.73
					})
	for child in root.get_children():
		_capture_monster_scorch_materials(child)

func _make_monster_integrated_material(source: BaseMaterial3D, is_head: bool) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D puppet_roughness : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_mix = 0.0;
uniform float vertex_color_mix = 0.0;
uniform float normal_mix = 0.0;
uniform float head_surface = 0.0;
uniform float distress = 0.0;
uniform float distress_phase = 0.0;
uniform bool flashlight_enabled = false;
uniform vec3 flashlight_origin = vec3(0.0);
uniform vec3 flashlight_direction = vec3(0.0, 0.0, -1.0);
uniform int fixture_count = 0;
uniform vec3 fixture_positions[32];
uniform vec3 fixture_colors[32];
uniform float fixture_strengths[32];
varying vec3 world_position;
varying vec3 model_position;
float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	model_position = VERTEX;
}
void fragment() {
	vec3 texture_color = texture(base_texture, UV).rgb;
	vec3 raw_color = mix(vec3(1.0), texture_color, texture_mix);
	raw_color *= mix(vec3(1.0), COLOR.rgb, vertex_color_mix);
	// Authored UV-baked paint/wood/face regions. Never desaturate the source
	// or generate animated object-space grime: both erased the approved design.
	ALBEDO = raw_color * (1.0 - distress * 0.045);
	ROUGHNESS = clamp(texture(puppet_roughness, UV).r, 0.65, 0.98);
	METALLIC = 0.0;
	SPECULAR = 0.16;
	vec3 sampled_normal = texture(normal_texture, UV).rgb;
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), sampled_normal, normal_mix);
	NORMAL_MAP_DEPTH = mix(0.0, 0.38, normal_mix);
	EMISSION = vec3(0.0);
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	var albedo_texture = load("res://assets/characters/corridor_creature/painted_puppet_v2/puppet_albedo.png") as Texture2D
	material.set_shader_parameter("puppet_roughness", load("res://assets/characters/corridor_creature/painted_puppet_v2/puppet_roughness.png"))
	if albedo_texture != null:
		material.set_shader_parameter("base_texture", albedo_texture)
		material.set_shader_parameter("texture_mix", 1.0)
	else:
		material.set_shader_parameter("texture_mix", 0.0)
	material.set_shader_parameter("vertex_color_mix", 0.0)
	var puppet_normal = load("res://assets/characters/corridor_creature/painted_puppet_v2/puppet_normal.png") as Texture2D
	if puppet_normal != null:
		material.set_shader_parameter("normal_texture", puppet_normal)
		material.set_shader_parameter("normal_mix", 1.0)
	else:
		material.set_shader_parameter("normal_mix", 0.0)
	material.set_shader_parameter("head_surface", 1.0 if is_head else 0.0)
	material.set_shader_parameter("distress", 0.0)
	material.set_shader_parameter("distress_phase", float(monster_scorch_materials.size()) * 1.73)
	material.set_shader_parameter("fixture_count", shader_light_positions.size())
	material.set_shader_parameter("fixture_positions", shader_light_positions)
	material.set_shader_parameter("fixture_colors", shader_light_colors)
	material.set_shader_parameter("fixture_strengths", shader_light_strengths)
	flashlight_reactive_materials.append(material)
	return material

func _make_monster_burn_particles(embers: bool) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.position = Vector3(0.0, 0.78, 0.0)
	particles.amount = 18 if embers else 64
	particles.lifetime = 0.68 if embers else 1.78
	particles.randomness = 0.86
	particles.explosiveness = 0.34 if embers else 0.08
	particles.local_coords = false
	particles.emitting = false
	particles.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	particles.visibility_aabb = AABB(Vector3(-4.5, -0.8, -4.5), Vector3(9.0, 7.5, 9.0))
	var process = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(1.38, 0.58, 0.88)
	process.direction = Vector3.UP
	process.spread = 55.0 if embers else 48.0
	process.initial_velocity_min = 0.70 if embers else 0.18
	process.initial_velocity_max = 1.85 if embers else 0.82
	process.gravity = Vector3(0.0, -0.65 if embers else 0.34, 0.0)
	process.damping_min = 0.38 if embers else 0.12
	process.damping_max = 0.92 if embers else 0.38
	process.scale_min = 0.032 if embers else 0.34
	process.scale_max = 0.085 if embers else 0.92
	process.angle_min = -180.0 if not embers else 0.0
	process.angle_max = 180.0 if not embers else 0.0
	process.angular_velocity_min = -18.0 if not embers else 0.0
	process.angular_velocity_max = 18.0 if not embers else 0.0
	var gradient = Gradient.new()
	if embers:
		gradient.offsets = PackedFloat32Array([0.0, 0.34, 1.0])
		gradient.colors = PackedColorArray([Color(0.70, 0.75, 0.68, 0.58), Color(0.30, 0.34, 0.31, 0.40), Color(0.08, 0.09, 0.085, 0.0)])
	else:
		gradient.offsets = PackedFloat32Array([0.0, 0.16, 0.58, 1.0])
		gradient.colors = PackedColorArray([Color(0.74, 0.78, 0.72, 0.0), Color(0.68, 0.72, 0.66, 0.82), Color(0.30, 0.33, 0.30, 0.52), Color(0.055, 0.061, 0.057, 0.0)])
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	process.color_ramp = gradient_texture
	particles.process_material = process
	if embers:
		var ember_mesh = SphereMesh.new()
		ember_mesh.radius = 0.045
		ember_mesh.height = 0.09
		ember_mesh.radial_segments = 5
		ember_mesh.rings = 3
		var ember_material = StandardMaterial3D.new()
		ember_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ember_material.vertex_color_use_as_albedo = true
		ember_material.albedo_color = Color(0.72, 0.76, 0.68, 0.82)
		ember_material.emission_enabled = false
		ember_mesh.material = ember_material
		particles.draw_pass_1 = ember_mesh
	else:
		var smoke_mesh = QuadMesh.new()
		smoke_mesh.size = Vector2(1.12, 1.12)
		smoke_mesh.material = _make_monster_smoke_material(MONSTER_SMOKE_CLOUD_PATH, Color(0.76, 0.80, 0.74, 0.88))
		particles.draw_pass_1 = smoke_mesh
	return particles

func _make_monster_smoke_wake_particles() -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.position = Vector3(0.0, 0.62, 0.18)
	particles.amount = 42
	particles.lifetime = 2.60
	particles.randomness = 0.94
	particles.explosiveness = 0.04
	particles.local_coords = false
	particles.emitting = false
	particles.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	particles.visibility_aabb = AABB(Vector3(-6.0, -1.0, -6.0), Vector3(12.0, 9.0, 12.0))
	var process = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(1.18, 0.42, 0.78)
	process.direction = Vector3.UP
	process.spread = 47.0
	process.initial_velocity_min = 0.10
	process.initial_velocity_max = 0.46
	process.gravity = Vector3(0.0, 0.20, 0.0)
	process.damping_min = 0.24
	process.damping_max = 0.58
	process.scale_min = 0.42
	process.scale_max = 1.12
	process.angle_min = -180.0
	process.angle_max = 180.0
	process.angular_velocity_min = -11.0
	process.angular_velocity_max = 11.0
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.66, 1.0])
	gradient.colors = PackedColorArray([Color(0.34, 0.37, 0.34, 0.0), Color(0.30, 0.33, 0.30, 0.46), Color(0.12, 0.14, 0.13, 0.30), Color(0.035, 0.041, 0.038, 0.0)])
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	process.color_ramp = gradient_texture
	particles.process_material = process
	var smoke_mesh = QuadMesh.new()
	smoke_mesh.size = Vector2(1.30, 1.42)
	smoke_mesh.material = _make_monster_smoke_material(MONSTER_SMOKE_DARK_PATH, Color(0.82, 0.86, 0.80, 0.78))
	particles.draw_pass_1 = smoke_mesh
	return particles

func _make_monster_smoke_material(texture_path: String, tint: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = load(texture_path)
	material.albedo_color = tint
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_monster_burn_aura_material() -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, unshaded, cull_front, depth_draw_never, shadows_disabled;
uniform float pain = 0.0;
uniform float flash = 0.0;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.2);
	float fracture = 0.55 + 0.45 * sin((VERTEX.x * 13.0 + VERTEX.y * 17.0 + VERTEX.z * 11.0) + TIME * 15.0);
	vec3 distress = mix(vec3(0.035, 0.045, 0.041), vec3(0.32, 0.38, 0.34), clamp(pain + flash * 0.25, 0.0, 1.0));
	ALBEDO = distress * 0.035;
	EMISSION = distress * (rim * (0.34 + flash * 0.22) + fracture * flash * 0.055);
	ALPHA = rim * pain * 0.16 + flash * fracture * 0.032;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("pain", 0.0)
	material.set_shader_parameter("flash", 0.0)
	return material

func _make_monster_contact_shadow_material() -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float motion = 0.0;
uniform float distress = 0.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	p.x *= 1.10 + motion * 0.22;
	p.y *= 0.78 - motion * 0.16;
	float irregular = sin(p.x * 8.0 + TIME * 0.7) * sin(p.y * 6.0 - TIME * 0.43) * 0.035;
	float body = 1.0 - smoothstep(0.04, 1.0, dot(p, p) + irregular);
	vec3 tint = mix(vec3(0.008, 0.010, 0.009), vec3(0.018, 0.026, 0.022), distress);
	ALBEDO = tint;
	ALPHA = body * (0.30 + distress * 0.10);
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("motion", 0.0)
	material.set_shader_parameter("distress", 0.0)
	return material

func _find_monster_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found = _find_monster_animation_player(child)
		if found != null:
			return found
	return null

func _find_monster_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found = _find_monster_skeleton(child)
		if found != null:
			return found
	return null

func _create_monster_expression() -> void:
	# The new 3D model owns its complete facial design, eye sockets, and ink trails.
	# Expression is carried by the authored face and animation; no artificial glow
	# geometry is layered over it.
	monster_expression_eyes.clear()
	monster_expression_brows.clear()
	monster_expression_mouth = null
	monster_expression_root = null

func _trigger_monster_expression() -> void:
	monster_expression_variant = (monster_expression_variant + 1) % 3
	monster_expression_flash_timer = 0.78
	monster_expression_strength = max(monster_expression_strength, 0.35)

func _update_monster_expression(dt: float) -> void:
	monster_expression_flash_timer = max(0.0, monster_expression_flash_timer - dt)
	var target = 1.0 if monster_has_visual else 0.0
	var response_speed = 8.5 if target > monster_expression_strength else 2.1
	monster_expression_strength = move_toward(monster_expression_strength, target, response_speed * dt)
	if is_instance_valid(monster_face_light):
		monster_face_light.light_color = Color8(142, 137, 118).lerp(Color8(158, 159, 142), 1.0 - monster_expression_strength)

func _configure_monster_animations() -> void:
	creature_animation_driver = CreatureAnimationScript.new()
	creature_animation_driver.name = "CreatureAnimationDriver"
	monster_model.add_child(creature_animation_driver)
	if not creature_animation_driver.setup(monster_animation_player, monster_skeleton):
		push_error("Corridor creature animation rig failed validation")
	else:
		creature_animation_driver.configure_terrain(level_manager)

func _tick_amalgam(dt: float, player) -> void:
	if player == null or not is_instance_valid(monster_root):
		return
	if is_instance_valid(monster_audio):
		monster_audio.stream_paused = bool(player.paused)
	if is_instance_valid(monster_pain_audio):
		monster_pain_audio.stream_paused = bool(player.paused)
	if bool(player.paused):
		return
	flashlight_blocking_player = player
	predator_attack.settle_interruption(self,dt)
	_update_predator_audio(dt,player)
	_update_monster_head_lead(dt, player)
	if _hold_flashlight_boundary(dt, player):
		return
	if _hold_ceiling_light_boundary(dt, player):
		return
	player_in_safe_light = _monster_position_in_warding_light(player.global_position)
	if _hold_safe_light_watch(dt,player):
		return
	if predator_attack.tick(self,dt,player):
		return
	monster_repath_timer -= dt
	monster_pursuit_commit_timer = max(0.0, monster_pursuit_commit_timer - dt)
	monster_reentry_grace_timer = max(0.0, monster_reentry_grace_timer - dt)
	monster_reentry_cue_timer = max(0.0, monster_reentry_cue_timer - dt)
	monster_safe_zone_behavior_timer = max(0.0, monster_safe_zone_behavior_timer - dt)
	monster_locker_check_timer = max(0.0, monster_locker_check_timer - dt)
	monster_noise_sense_timer = max(0.0, monster_noise_sense_timer - dt)
	_tick_monster_noise_memories(dt)
	var player_distance = monster_root.global_position.distance_to(player.global_position)
	_update_monster_perception_cache(dt, player)
	_update_monster_static_light_pressure(dt)
	# Light contact and direct sight are gameplay-critical; preserve their
	# immediate response. The cache below only owns the non-critical audio
	# occlusion query, which is where a small temporal delay is inaudible.
	# The handheld beam helps the player see; fixed overhead pools own safety.
	var flashlight_target = 0.0
	_update_monster_light_reaction(dt, player, flashlight_target)
	if monster_state == "hunt_reset":
		monster_hunt_reset_timer = max(0.0, monster_hunt_reset_timer - dt)
		if monster_hunt_reset_timer <= 0.0:
			_begin_directed_reentry(player)
	var hunt_suppressed = monster_state in ["flee_light", "hunt_reset"]
	_update_monster_perception(dt, player, player_distance, hunt_suppressed, _monster_visual_strength(player, player_distance))
	if monster_has_visual and not creature_previous_visual: creature_notice_timer = 0.65
	creature_previous_visual = monster_has_visual
	creature_notice_timer = maxf(0,creature_notice_timer-dt)
	if monster_has_visual and not _monster_position_in_warding_light(player.global_position):
		creature_dark_approach_time = maxf(0.0, creature_dark_approach_time - dt)
		# Old search pauses must not stop an already confirmed pursuit.
		if monster_state == "chase":
			monster_search_pause = 0.0
	if not hunt_suppressed and not monster_has_visual:
		_process_best_noise_memory(player)
	# Footprints only help once the creature is already searching nearby. They do
	# not reveal the player's current position from across the facility.
	if not hunt_suppressed and not monster_has_visual and monster_hunt_retarget_timer <= 0.0 and monster_state == "search":
		var nearby_trail = _nearby_player_trail_point()
		if nearby_trail != Vector3.INF:
			monster_last_known_position = nearby_trail
			monster_state = "investigate"
			monster_state_timer = 5.2
			monster_repath_timer = 0.0
		monster_hunt_retarget_timer = 2.8
	if monster_state == "chase":
		monster_chase_time += dt
	else:
		monster_chase_time = max(0.0, monster_chase_time - dt * 2.0)
	_update_hunt_director(dt, player, player_distance)
	player_in_safe_light = _monster_position_in_warding_light(player.global_position)
	if player_in_safe_light:
		monster_attack_windup = 0.0
		monster_strike_timer = 0.0
		monster_pounce_windup = 0.0
		monster_pounce_timer = 0.0
		monster_pounce_visual_arc = 0.0
	_update_monster_presence_lighting(player_distance)
	if monster_state in ["flee_light", "hunt_reset"] or bool(player.horror_hidden):
		monster_strike_timer = 0.0
	if monster_strike_timer > 0.0:
		monster_current_speed = 0.0
		monster_motion_velocity = Vector3.ZERO
		_animate_amalgam(dt, 0.0)
		var contact_time: float = creature_animation_driver.state_seconds
		if not monster_strike_hit and contact_time >= 0.10 and contact_time <= 0.19:
			monster_strike_hit = _resolve_monster_attack(player)
		monster_strike_timer = maxf(0.0, monster_strike_timer - dt)
		if monster_strike_timer <= 0.0:
			monster_pounce_recovery_timer = 0.65
		return
	if monster_pounce_windup > 0.0:
		_tick_monster_pounce_windup(dt, player, player_in_safe_light)
		return
	if monster_pounce_timer > 0.0:
		_tick_monster_pounce(dt, player, player_in_safe_light)
		return
	if monster_pounce_recovery_timer > 0.0:
		monster_pounce_recovery_timer = max(0.0, monster_pounce_recovery_timer - dt)
		monster_current_speed = move_toward(monster_current_speed, 0.0, 16.0 * dt)
		monster_motion_velocity = monster_motion_velocity.move_toward(Vector3.ZERO, 20.0 * dt)
		monster_predator_crouch = move_toward(monster_predator_crouch, 0.38, dt * 2.4)
		_animate_amalgam(dt, 0.0)
		return
	if monster_attack_windup > 0.0:
		# Crossing the threshold is a real rule of the space, not merely an AI
		# steering suggestion. A committed attack therefore breaks at the light
		# boundary instead of landing through an invisible safety volume.
		if _monster_position_in_warding_light(player.global_position):
			monster_attack_windup = 0.0
			monster_attack_timer = max(monster_attack_timer, 0.55)
			monster_motion_velocity = monster_motion_velocity.move_toward(Vector3.ZERO, 14.0 * dt)
			_choose_safe_zone_behavior(player)
			return
		monster_attack_windup = max(0.0, monster_attack_windup - dt)
		monster_current_speed = move_toward(monster_current_speed, 0.0, 18.0 * dt)
		monster_motion_velocity = monster_motion_velocity.move_toward(Vector3.ZERO, 22.0 * dt)
		var attack_direction = player.global_position - monster_root.global_position
		attack_direction.y = 0.0
		if attack_direction.length_squared() > 0.001:
			monster_root.rotation.y = lerp_angle(monster_root.rotation.y, atan2(-attack_direction.x, -attack_direction.z), clamp(dt * 13.0, 0.0, 1.0))
		if monster_attack_windup <= 0.0:
			monster_strike_timer = MONSTER_STRIKE_DURATION
			monster_strike_hit = false
		_animate_amalgam(dt, 0.0)
		return
	var target = _monster_state_target(player)
	if monster_state == "flee_light":
		target = monster_light_evasion_target
	elif player_in_safe_light and monster_state != "hunt_reset":
		if monster_safe_zone_behavior_timer <= 0.0:
			_choose_safe_zone_behavior(player)
		target = monster_safe_zone_target
	var desired_speed = _monster_effective_speed(player_distance)
	_update_monster_predator_rhythm(dt, player_distance)
	# The creature occasionally checks its footing while it still has room to
	# menace. This is deliberately forbidden at attack distance so it never
	# reads as an arbitrary player-facing slowdown.
	if monster_probe_timer > 0.0:
		desired_speed *= 0.30
	if player_in_safe_light and monster_state not in ["flee_light", "hunt_reset"]:
		desired_speed = min(desired_speed, MONSTER_SEARCH_SPEED * 1.08)
		if monster_safe_zone_behavior == "watch" and monster_root.global_position.distance_to(monster_safe_zone_target) < 1.8:
			desired_speed = 0.0
			var watch_direction = player.global_position - monster_root.global_position
			watch_direction.y = 0.0
			if watch_direction.length_squared() > 0.001:
				monster_root.rotation.y = lerp_angle(monster_root.rotation.y, atan2(-watch_direction.x, -watch_direction.z), clamp(dt * 2.1, 0.0, 1.0))
	if monster_search_pause > 0.0:
		desired_speed = 0.0
		if monster_search_scan_timer <= 0.0:
			# The creature does not scan like a turret. It sometimes holds the
			# same side, sometimes returns toward centre to listen, and only then
			# commits its head and body to the opposite corridor.
			var scan_choice = randf()
			if scan_choice < 0.22:
				monster_search_scan_target = randf_range(-0.10, 0.10)
			elif scan_choice < 0.82:
				monster_search_scan_sign *= -1.0
				var scan_width = lerp(0.42, 0.94, clamp(monster_search_confidence, 0.0, 1.0))
				monster_search_scan_target = monster_search_scan_sign * scan_width * randf_range(0.72, 1.0)
			else:
				monster_search_scan_target *= randf_range(0.72, 0.92)
			monster_search_scan_timer = randf_range(0.54, 1.04)
		monster_search_scan_offset = lerp(monster_search_scan_offset, monster_search_scan_target, 1.0 - exp(-2.55 * dt))
		var scan_yaw = monster_search_scan_anchor + monster_search_scan_offset * 0.58
		monster_root.rotation.y = lerp_angle(monster_root.rotation.y, scan_yaw, 1.0 - exp(-1.85 * dt))
	# The stalker has mass. It commits the torso toward a turn before its body
	# follows, rather than converting a new navigation point into an instant
	# velocity vector every frame.
	var acceleration = (6.5 if monster_state == "flee_light" else (6.5 if monster_state == "chase" else 2.85)) * lerp(1.0, 0.90, monster_light_pain)
	var braking = (34.0 if monster_state == "flee_light" else (7.6 if monster_state == "chase" else 4.4))
	var speed_response = acceleration if desired_speed > monster_current_speed else braking
	monster_current_speed = move_toward(monster_current_speed, desired_speed, speed_response * dt)
	if monster_repath_timer <= 0.0:
		monster_repath_timer = 0.20 if monster_state == "chase" else (0.34 if monster_state in ["search", "investigate", "suspicious"] else 0.58)
		_repath_amalgam(target)
	var target_distance = monster_root.position.distance_to(target)
	if monster_path_index >= monster_path.size() and target_distance > 1.8:
		monster_path_failure_timer += dt
		if monster_path_failure_timer > 0.32:
			monster_repath_timer = 0.0
	else:
		monster_path_failure_timer = max(0.0, monster_path_failure_timer - dt * 3.0)
	var moved = _advance_monster_motion(dt, player, desired_speed)
	_update_monster_stuck_and_relocation(dt, player, moved, player_distance, monster_has_visual)
	_animate_amalgam(dt, moved / max(desired_speed, 0.01))
	if monster_state == "flee_light":
		monster_light_flee_elapsed += dt
		if monster_light_flee_elapsed >= MONSTER_LIGHT_FLEE_MIN_VISIBLE_TIME and not _player_can_see_monster(player):
			_relocate_after_light_hunt(player)
			return
	if bool(player.horror_hidden):
		_try_search_active_locker(player, dt)
	elif monster_state=="chase" and monster_has_visual and monster_reentry_grace_timer<=0 and predator_attack.cooldown<=0 and monster_attack_timer<=0:
		var kind := "Quick" if player_distance<1.85 else ("Side" if player_distance<3.0 else "Heavy")
		if player_distance<=6.0:
			if player_distance<1.85 and predator_attack.last_kind=="Quick": kind="Side"
			if not predator_attack.begin(self,player,kind) and kind=="Side" and player_distance<1.85:
				predator_attack.begin(self,player,"Quick")

func _hold_safe_light_watch(dt: float, player) -> bool:
	var gap: float = monster_root.global_position.distance_to(player.global_position)
	if not player_in_safe_light or gap>12.0 or bool(player.horror_hidden) or not _grid_has_clear_line(monster_root.global_position+Vector3.UP,player.global_position+Vector3.UP):
		if boundary_watch_active:
			creature_retreat_path.clear()
			monster_repath_timer = 0.0
		boundary_watch_active = false
		boundary_watch_age = 0.0
		return false
	predator_attack.cancel(self)
	boundary_watch_active = true
	boundary_watch_age += dt
	boundary_plan_timer -= dt
	monster_has_visual = true
	# Remain on the dark perimeter. A short lateral probe between long watching
	# beats gives the refuge a different rhythm from the flashlight's orbit.
	var probing := fmod(boundary_watch_age,4.8)>3.6
	if probing and boundary_plan_timer<=0:
		_plan_flashlight_retreat()
		boundary_plan_timer = 1.2
	if probing and not creature_retreat_path.is_empty():
		monster_current_speed = move_toward(monster_current_speed,0.45,dt*1.8)
		_advance_monster_motion(dt,player,monster_current_speed)
	else:
		monster_current_speed = move_toward(monster_current_speed,0,dt*3.0)
		monster_motion_velocity = Vector3.ZERO
		var focus: Vector3 = player.global_position-monster_root.global_position
		monster_root.rotation.y = rotate_toward(monster_root.rotation.y,atan2(-focus.x,-focus.z),dt*0.65)
	_animate_amalgam(dt,0.0)
	return true

func _update_predator_audio(dt: float, player) -> void:
	if not is_instance_valid(monster_audio): return
	var gap: float = monster_root.global_position.distance_to(player.global_position)
	var pitch := 1.06 if monster_state=="chase" else 0.84
	var pressure := 3.0 if monster_state=="chase" else 0.0
	if creature_light_state!="clear":
		pitch = 0.79+sin(stalk_director.age*1.3)*0.025
		pressure = -1.0 if stalk_director.state in ["Watch","CornerWatch"] else 1.0
	elif boundary_watch_active:
		pitch = 0.70
		pressure = -2.0
	elif predator_attack.active:
		pitch = 0.88 if predator_attack.phase=="Windup" else (1.18 if predator_attack.phase=="Strike" else 0.80)
		pressure = 4.0 if predator_attack.phase=="Strike" else 1.0
	monster_audio.pitch_scale = lerpf(monster_audio.pitch_scale,pitch,1.0-exp(-dt*3.0))
	var target: float = lerpf(-46.0,-5.0+pressure,clampf(1.0-gap/25.0,0,1))-(6.5 if monster_cached_audio_occluded else 0.0)
	monster_audio.volume_db = lerpf(monster_audio.volume_db,target,1.0-exp(-dt*4.0))

func _update_monster_perception_cache(dt: float, player) -> void:
	monster_perception_update_timer -= dt
	if monster_perception_update_timer > 0.0:
		return
	# Keep the residual rather than resetting to zero so brief frame hitches do
	# not phase-lock the hunter, flashlight and room maintenance on the same
	# expensive frame.
	monster_perception_update_timer += MONSTER_PERCEPTION_UPDATE_INTERVAL
	if monster_perception_update_timer <= 0.0:
		monster_perception_update_timer = MONSTER_PERCEPTION_UPDATE_INTERVAL
	# Audio only needs a stable occlusion result. It avoids a fourth grid walk
	# every render frame while direct sight and flashlight contact remain exact.
	monster_cached_audio_occluded = not _grid_has_clear_line(
		monster_root.global_position + Vector3.UP,
		player.global_position + Vector3.UP
	)

func _can_begin_monster_pounce(player, player_distance: float, player_in_safe_light: bool) -> bool:
	if creature_dark_approach_time > 0.0:
		return false
	if darkness_time < DARKNESS_HUNT_DELAY or monster_state != "chase" or not monster_has_visual or player_in_safe_light:
		return false
	if monster_pounce_cooldown > 0.0 or monster_attack_timer > 0.0 or monster_reentry_grace_timer > 0.0 or _monster_light_prevents_attack():
		return false
	# A centred, readable flashlight beam is a hard counter to the lunge. The
	# player should see the creature recoil rather than have it cross the beam
	# because pain accumulation happened to be one frame behind the charge.
	if _monster_flashlight_exposure(player) >= MONSTER_POUNCE_LIGHT_CANCEL_EXPOSURE:
		return false
	if player_distance < MONSTER_POUNCE_MIN_RANGE or player_distance > MONSTER_POUNCE_MAX_RANGE:
		return false
	var takeoff = monster_root.global_position + Vector3.UP * 0.55
	var landing = player.global_position + player.horizontal_velocity * 0.18 + Vector3.UP * 0.55
	return _grid_has_clear_line(takeoff, landing)

func _begin_monster_pounce(player) -> void:
	monster_pounce_windup = MONSTER_POUNCE_WINDUP
	monster_pounce_start = monster_root.global_position
	monster_pounce_target = player.global_position + player.horizontal_velocity * 0.18
	monster_pounce_target.y = 0.0
	monster_pounce_hit = false
	monster_pounce_visual_arc = 0.0
	monster_pounce_recovery_timer = 0.0
	monster_current_speed = 0.0
	monster_motion_velocity = Vector3.ZERO
	monster_path.clear()
	monster_repath_timer = MONSTER_POUNCE_WINDUP + MONSTER_POUNCE_DURATION
	# The pounce owns a separate, deliberately long cooldown. The creature may
	# continue hunting afterwards, but it cannot turn into an arcade dash loop.
	monster_pounce_cooldown = MONSTER_POUNCE_COOLDOWN
	monster_attack_timer = max(monster_attack_timer, 0.92)
	if player.has_method("add_shake"):
		player.add_shake(0.045)

func _tick_monster_pounce_windup(dt: float, player, player_in_safe_light: bool) -> void:
	var beam_exposure = _monster_flashlight_exposure(player)
	if player_in_safe_light or _monster_light_prevents_attack() or bool(player.horror_hidden) or beam_exposure >= MONSTER_POUNCE_LIGHT_CANCEL_EXPOSURE:
		_interrupt_monster_pounce_for_light(player, beam_exposure)
		return
	monster_pounce_windup = max(0.0, monster_pounce_windup - dt)
	var aim = player.global_position + player.horizontal_velocity * 0.16 - monster_root.global_position
	aim.y = 0.0
	if aim.length_squared() > 0.001:
		monster_pounce_direction = aim.normalized()
		monster_root.rotation.y = lerp_angle(monster_root.rotation.y, atan2(-aim.x, -aim.z), clamp(dt * 12.0, 0.0, 1.0))
	monster_predator_crouch = move_toward(monster_predator_crouch, 1.0, dt * 7.5)
	_animate_amalgam(dt, 0.0)
	if monster_pounce_windup > 0.0:
		return
	monster_pounce_start = monster_root.global_position
	monster_pounce_target = player.global_position + player.horizontal_velocity * 0.20 - monster_pounce_direction * MONSTER_CAMERA_CLEARANCE
	monster_pounce_target.y = 0.0
	monster_pounce_timer = MONSTER_POUNCE_DURATION
	monster_motion_velocity = monster_pounce_direction * monster_pounce_start.distance_to(monster_pounce_target) / MONSTER_POUNCE_DURATION

func _tick_monster_pounce(dt: float, player, player_in_safe_light: bool) -> void:
	var beam_exposure = _monster_flashlight_exposure(player)
	if player_in_safe_light or _monster_light_prevents_attack() or beam_exposure >= MONSTER_POUNCE_LIGHT_CANCEL_EXPOSURE:
		_interrupt_monster_pounce_for_light(player, beam_exposure)
		return
	monster_pounce_timer = max(0.0, monster_pounce_timer - dt)
	var progress = 1.0 - monster_pounce_timer / MONSTER_POUNCE_DURATION
	var eased_progress = progress * progress * (3.0 - 2.0 * progress)
	var landing = monster_pounce_start.lerp(monster_pounce_target, eased_progress)
	landing.y = 0.0
	var player_gap: Vector3 = landing - player.global_position
	player_gap.y = 0.0
	if player_gap.length() < MONSTER_CAMERA_CLEARANCE:
		landing = player.global_position - monster_pounce_direction * MONSTER_CAMERA_CLEARANCE
		landing.y = 0.0
	if _monster_motion_segment_valid(monster_root.global_position, landing):
		monster_root.global_position = landing
	else:
		monster_pounce_timer = 0.0
		monster_pounce_visual_arc = 0.0
		monster_motion_velocity = Vector3.ZERO
		monster_repath_timer = 0.0
		monster_pounce_recovery_timer = MONSTER_POUNCE_RECOVERY
		_animate_amalgam(dt, 0.0)
		return
	monster_pounce_visual_arc = sin(progress * PI) * MONSTER_POUNCE_ARC_HEIGHT
	monster_root.rotation.y = lerp_angle(monster_root.rotation.y, atan2(-monster_pounce_direction.x, -monster_pounce_direction.z), clamp(dt * 7.0, 0.0, 1.0))
	_animate_amalgam(dt, 1.0)
	if not monster_pounce_hit and progress >= 0.78 and progress <= 0.95 and not bool(player.horror_hidden) and darkness_time >= DARKNESS_HUNT_DELAY and not _monster_position_in_warding_light(player.global_position):
		var impact_delta = player.global_position - monster_root.global_position
		impact_delta.y = 0.0
		if creature_animation_driver.strike_touches(player.global_position) and _grid_has_clear_line(monster_root.global_position + Vector3.UP, player.global_position + Vector3.UP):
			monster_pounce_hit = true
			player.damage(MONSTER_POUNCE_DAMAGE)
			if impact_delta.length_squared() > 0.001:
				player.horizontal_velocity += impact_delta.normalized() * 6.4
			if player.has_method("add_shake"):
				player.add_shake(0.14)
	if monster_pounce_timer <= 0.0:
		monster_pounce_visual_arc = 0.0
		monster_motion_velocity = Vector3.ZERO
		monster_repath_timer = 0.0
		monster_pounce_recovery_timer = MONSTER_POUNCE_RECOVERY

func _interrupt_monster_pounce_for_light(player, beam_exposure: float) -> void:
	monster_pounce_windup = 0.0
	monster_pounce_timer = 0.0
	monster_pounce_visual_arc = 0.0
	monster_motion_velocity = Vector3.ZERO
	monster_current_speed = 0.0
	monster_pounce_recovery_timer = max(monster_pounce_recovery_timer, 0.82)
	monster_pounce_cooldown = max(monster_pounce_cooldown, MONSTER_POUNCE_COOLDOWN * 0.70)
	monster_attack_timer = max(monster_attack_timer, 0.85)
	monster_light_stagger_timer = max(monster_light_stagger_timer, 0.22)
	monster_light_reflex_timer = max(monster_light_reflex_timer, 0.18)
	if beam_exposure >= MONSTER_POUNCE_LIGHT_FLEE_EXPOSURE:
		_end_hunt_by_light(player)

func _update_monster_static_light_pressure(dt: float) -> void:
	monster_static_light_update_timer -= dt
	if monster_static_light_update_timer > 0.0:
		return
	monster_static_light_update_timer += MONSTER_STATIC_LIGHT_UPDATE_INTERVAL
	if monster_static_light_update_timer <= 0.0:
		monster_static_light_update_timer = MONSTER_STATIC_LIGHT_UPDATE_INTERVAL
	monster_cached_static_light_pressure = _monster_static_light_pressure(monster_root.global_position)

func _update_monster_perception(dt: float, player, player_distance: float, hunt_suppressed: bool, cached_visual: float) -> void:
	var raw_visual = cached_visual
	if hunt_suppressed:
		raw_visual = 0.0
	monster_raw_visual_strength = raw_visual
	var previously_confirmed = monster_has_visual
	if raw_visual > 0.015:
		var acquire_rate = lerp(0.42, 2.55, pow(raw_visual, 0.72))
		monster_visual_confidence = min(1.0, monster_visual_confidence + acquire_rate * dt)
	else:
		var release_rate = 0.24 if monster_state == "chase" else 0.42
		if hunt_suppressed:
			release_rate = 1.6
		monster_visual_confidence = max(0.0, monster_visual_confidence - release_rate * dt)
	monster_has_visual = monster_visual_confidence >= MONSTER_VISUAL_ACQUIRE_CONFIDENCE or (previously_confirmed and monster_visual_confidence > MONSTER_VISUAL_RELEASE_CONFIDENCE)
	if monster_has_visual and not previously_confirmed:
		_trigger_monster_expression()
	_update_monster_expression(dt)
	if raw_visual > 0.015:
		monster_unseen_timer = 0.0
		monster_last_seen_velocity = player.horizontal_velocity
		var observation_direction = player.global_position - monster_root.global_position
		observation_direction.y = 0.0
		if observation_direction.length_squared() > 0.001:
			monster_last_seen_direction = observation_direction.normalized()
		var prediction_time = lerp(0.12, 0.48, clamp(player_distance / MONSTER_SIGHT_RANGE, 0.0, 1.0))
		var observed_position = player.global_position + monster_last_seen_velocity * prediction_time
		observed_position.y = 0.0
		if monster_estimated_player_position == Vector3.ZERO:
			monster_estimated_player_position = observed_position
		else:
			monster_estimated_player_position = monster_estimated_player_position.lerp(observed_position, clamp(dt * lerp(2.4, 8.5, raw_visual), 0.0, 1.0))
		if monster_has_visual or raw_visual > 0.26:
			monster_last_known_position = monster_estimated_player_position
			monster_path_failure_timer = 0.0
		if not hunt_suppressed:
			monster_awareness = min(1.0, monster_awareness + dt * lerp(0.28, 1.55, raw_visual))
			if monster_has_visual:
				monster_visible_time += dt
				monster_lost_sight_timer = 0.0
				if monster_state == "chase":
					monster_awareness = max(monster_awareness, 0.92)
				if monster_awareness >= 0.78 or player_distance < 3.4:
					if monster_state != "chase":
						_play_monster_hunt_cue()
					monster_alert_timer = 11.0
					monster_state = "chase"
					monster_state_timer = 11.0
					_update_monster_pursuit_target(player, player_distance, true)
				elif monster_state not in ["chase", "investigate"]:
					monster_state = "suspicious"
					monster_state_timer = max(monster_state_timer, 2.8)
			elif raw_visual > 0.07 and monster_state not in ["chase", "investigate"]:
				monster_state = "suspicious"
				monster_state_timer = max(monster_state_timer, lerp(1.4, 3.2, raw_visual))
	else:
		monster_unseen_timer += dt
		monster_visible_time = 0.0
		monster_awareness = max(0.0, monster_awareness - dt * (0.13 if monster_state == "chase" else 0.22))
		if monster_state == "chase":
			monster_lost_sight_timer += dt
			var memory_duration = lerp(MONSTER_LOST_SIGHT_MIN_TIME, MONSTER_LOST_SIGHT_MAX_TIME, clamp(monster_chase_time / 9.0, 0.0, 1.0))
			if monster_lost_sight_timer > memory_duration:
				_begin_monster_search(monster_estimated_player_position if monster_estimated_player_position != Vector3.ZERO else monster_last_known_position)
		elif monster_state == "suspicious" and monster_state_timer <= 0.0:
			_begin_monster_search(monster_estimated_player_position if monster_estimated_player_position != Vector3.ZERO else monster_last_known_position)

func _update_monster_pursuit_target(player, player_distance: float, force: bool = false) -> void:
	if not force and monster_pursuit_commit_timer > 0.0:
		return
	var prediction_time = clamp(player_distance / 22.0, 0.16, 0.52)
	var predicted = player.global_position + player.horizontal_velocity * prediction_time
	predicted.y = 0.0
	if player_distance > 7.0 and player.horizontal_velocity.length_squared() > 0.20:
		var lateral = Vector3(-player.horizontal_velocity.z, 0.0, player.horizontal_velocity.x).normalized()
		var flank_sign = -1.0 if fmod(float(monster_hunt_reset_count + monster_search_wave), 2.0) > 0.5 else 1.0
		predicted += lateral * flank_sign * lerp(0.35, 1.35, clamp((player_distance - 7.0) / 15.0, 0.0, 1.0))
	var predicted_cell = _world_cell(predicted)
	if monster_navigation.is_in_boundsv(predicted_cell) and not monster_navigation.is_point_solid(predicted_cell):
		monster_pursuit_target = predicted
	else:
		monster_pursuit_target = _cell_world(_nearest_open_cell(predicted_cell))
	monster_pursuit_commit_timer = randf_range(0.32, 0.52)

func _tick_monster_noise_memories(dt: float) -> void:
	for index in range(monster_noise_memories.size() - 1, -1, -1):
		var memory: Dictionary = monster_noise_memories[index]
		memory["remaining"] = max(0.0, float(memory.get("remaining", 0.0)) - dt)
		if float(memory["remaining"]) <= 0.0:
			monster_noise_memories.remove_at(index)

func _process_best_noise_memory(_player) -> void:
	if monster_hunt_retarget_timer > 0.0 or monster_noise_sense_timer > 0.0 or monster_noise_memories.is_empty():
		return
	monster_noise_sense_timer = 0.22
	var best_memory: Dictionary = {}
	var best_heard_strength = 0.0
	for memory in monster_noise_memories:
		if bool(memory.get("processed", false)):
			continue
		var heard_strength = _noise_memory_heard_strength(memory)
		if heard_strength > best_heard_strength:
			best_heard_strength = heard_strength
			best_memory = memory
	if best_memory.is_empty() or best_heard_strength <= 0.0:
		return
	best_memory["processed"] = true
	monster_processed_noise_event = int(best_memory.get("id", noise_event_id))
	var estimated_position = _estimate_noise_position(best_memory, best_heard_strength)
	monster_last_known_position = estimated_position
	monster_estimated_player_position = estimated_position
	monster_search_direction = estimated_position - monster_root.global_position
	monster_search_direction.y = 0.0
	if monster_search_direction.length_squared() > 0.001:
		monster_search_direction = monster_search_direction.normalized()
	monster_alert_timer = max(monster_alert_timer, lerp(2.6, 8.2, best_heard_strength))
	monster_awareness = max(monster_awareness, best_heard_strength * 0.48)
	monster_search_confidence = max(monster_search_confidence, best_heard_strength)
	if monster_state != "chase":
		monster_state = "investigate"
		monster_state_timer = max(monster_state_timer, 4.0 + best_heard_strength * 5.0)
		monster_repath_timer = 0.0
	monster_hunt_retarget_timer = lerp(1.5, 0.55, best_heard_strength)

func _noise_memory_heard_strength(memory: Dictionary) -> float:
	var position: Vector3 = memory.get("position", Vector3.ZERO)
	var strength = clamp(float(memory.get("strength", 0.0)), 0.0, 1.0)
	var hearing_range = lerp(8.0, 42.0, strength)
	var path_distance = _navigation_distance(monster_root.global_position, position)
	if path_distance == INF or path_distance > hearing_range:
		return 0.0
	var clarity = 1.0 - path_distance / hearing_range
	if not _grid_has_clear_line(monster_root.global_position + Vector3.UP, position + Vector3.UP):
		clarity *= 0.62
	var lifetime_ratio = clamp(float(memory.get("remaining", 0.0)) / max(float(memory.get("duration", 0.01)), 0.01), 0.0, 1.0)
	return clamp(strength * (0.28 + clarity * 0.72) * lerp(0.62, 1.0, lifetime_ratio), 0.0, 1.0)

func _estimate_noise_position(memory: Dictionary, heard_strength: float) -> Vector3:
	var actual: Vector3 = memory.get("position", monster_root.global_position)
	if heard_strength >= 0.82:
		return _cell_world(_nearest_open_cell(_world_cell(actual)))
	var actual_cell = _world_cell(actual)
	var uncertainty = 1 if heard_strength > 0.48 else 2
	var best_cell = _nearest_open_cell(actual_cell)
	var best_score = INF
	for y in range(actual_cell.y - uncertainty, actual_cell.y + uncertainty + 1):
		for x in range(actual_cell.x - uncertainty, actual_cell.x + uncertainty + 1):
			var cell = Vector2i(x, y)
			if not monster_navigation.is_in_boundsv(cell) or monster_navigation.is_point_solid(cell):
				continue
			var stable_variation = fmod(abs(float(cell.x * 31 + cell.y * 17 + int(memory.get("id", 0)) * 13)), 23.0) * 0.11
			var score = float(cell.distance_squared_to(actual_cell)) * heard_strength + stable_variation
			if heard_strength < 0.48 and cell == actual_cell:
				score += 1.35
			if score < best_score:
				best_score = score
				best_cell = cell
	return _cell_world(best_cell)

func _navigation_distance(from: Vector3, to: Vector3) -> float:
	if monster_navigation == null:
		return from.distance_to(to)
	var from_cell = _nearest_open_cell(_world_cell(from))
	var to_cell = _nearest_open_cell(_world_cell(to))
	var path = monster_navigation.get_id_path(from_cell, to_cell)
	if path.is_empty():
		return INF
	return max(0.0, float(path.size() - 1) * TILE)

func _update_hunt_director(dt: float, player, player_distance: float) -> void:
	monster_director_reposition_timer = max(0.0, monster_director_reposition_timer - dt)
	var completed_tasks = 0
	for state in task_states.values():
		if state is Dictionary and bool(state.get("complete", false)):
			completed_tasks += 1
	var progress_floor = 0.30 + float(completed_tasks) * 0.10
	if darkness_time >= DARKNESS_HUNT_DELAY:
		monster_director_tension = minf(1.0, monster_director_tension + dt * 0.07)
	if monster_state == "chase":
		monster_director_quiet_time = 0.0
		monster_director_tension = max(progress_floor, monster_director_tension - dt * 0.030)
	else:
		monster_director_quiet_time += dt
		var player_noise_pressure = 0.014 if bool(player.horror_sprint_active) else clamp(float(player.horizontal_speed) / 5.2, 0.0, 1.0) * 0.004
		var flashlight_pressure = 0.003 if bool(player.flashlight_on) else 0.0
		monster_director_tension = min(1.0, max(progress_floor, monster_director_tension + dt * (0.0045 + player_noise_pressure + flashlight_pressure)))
	if monster_state in ["flee_light", "hunt_reset"]:
		return
	var can_direct = monster_state in ["patrol", "stalk", "search"] and not monster_has_visual and monster_reentry_grace_timer <= 0.0
	if can_direct and monster_director_tension > 0.64 and monster_director_quiet_time > 5.0 and monster_unseen_timer > 4.0 and player_distance > 24.0 and monster_director_reposition_timer <= 0.0:
		_try_director_shadow_reposition(player)

func _update_monster_light_reaction(dt: float, player, flashlight_target: float) -> void:
	monster_light_reflex_timer = max(0.0, monster_light_reflex_timer - dt)
	monster_light_reaction_cooldown = max(0.0, monster_light_reaction_cooldown - dt)
	monster_light_stagger_timer = max(0.0, monster_light_stagger_timer - dt)
	monster_light_stagger_cooldown = max(0.0, monster_light_stagger_cooldown - dt)
	monster_light_impact_timer = max(0.0, monster_light_impact_timer - dt)
	monster_light_flare = max(0.0, monster_light_flare - dt * 2.4)
	monster_light_burn_pulse_timer = max(0.0, monster_light_burn_pulse_timer - dt)
	monster_light_evasion_timer = max(0.0, monster_light_evasion_timer - dt)
	monster_light_evasion_retarget_timer = max(0.0, monster_light_evasion_retarget_timer - dt)
	monster_ambient_light_pressure = monster_cached_static_light_pressure
	if flashlight_target > 0.08:
		var source_position = player.camera_origin() if player.has_method("camera_origin") else player.global_position + Vector3.UP
		var toward_source = source_position - monster_root.global_position
		toward_source.y *= 0.42
		if toward_source.length_squared() > 0.001:
			var local_source = monster_root.global_transform.basis.inverse() * toward_source.normalized()
			monster_light_source_local = monster_light_source_local.lerp(local_source, 1.0 - exp(-8.0 * dt)).normalized()
	# A broken beam must stop hurting the creature almost immediately. Slow fade
	# was making a distant target retain close-range pain after it left the cone.
	var exposure_response = 4.8 if flashlight_target > monster_flashlight_exposure else 6.8
	monster_flashlight_exposure = move_toward(monster_flashlight_exposure, flashlight_target, exposure_response * dt)
	var focused_contact = flashlight_target > 0.40
	var reflex_contact = flashlight_target > 0.52
	var focus_quality = smoothstep(0.40, 0.86, flashlight_target)
	if focused_contact:
		if reflex_contact and monster_state not in ["flee_light", "hunt_reset"] and monster_light_contact_time <= 0.02 and monster_light_reaction_cooldown <= 0.0:
			monster_light_reflex_timer = MONSTER_LIGHT_REFLEX_DURATION
			monster_light_impact_timer = 0.18
			monster_light_reaction_cooldown = 1.25
			monster_light_enrage = 1.0
			var source_distance = monster_root.global_position.distance_to(player.global_position)
			var source_visual = _monster_visual_strength(player, source_distance)
			if source_distance <= 14.0 or source_visual > 0.22 or monster_visual_confidence > 0.34:
				if monster_state != "chase":
					_play_monster_hunt_cue()
				monster_state = "chase"
				monster_state_timer = max(monster_state_timer, 7.0)
				monster_awareness = max(monster_awareness, 0.84)
				monster_estimated_player_position = player.global_position
				_update_monster_pursuit_target(player, source_distance, true)
			else:
				monster_state = "investigate"
				monster_state_timer = max(monster_state_timer, 5.2)
				monster_awareness = max(monster_awareness, 0.58)
				var source_estimate = player.camera_origin() + player.aim_dir() * randf_range(1.5, 4.0)
				source_estimate.y = 0.0
				monster_last_known_position = _cell_world(_nearest_open_cell(_world_cell(source_estimate)))
				monster_estimated_player_position = monster_last_known_position
			monster_repath_timer = 0.0
			if player.has_method("add_shake"):
				player.add_shake(0.10)
		monster_light_contact_time += dt * focus_quality
	else:
		monster_light_contact_time = max(0.0, monster_light_contact_time - dt * 3.2)
	monster_light_enrage = move_toward(monster_light_enrage, 0.0, dt * (0.42 if reflex_contact else 0.86))
	var focus_response = smoothstep(MONSTER_LIGHT_FOCUS_DELAY, MONSTER_LIGHT_FOCUS_DELAY + MONSTER_LIGHT_FOCUS_BUILD_TIME, monster_light_contact_time)
	var flashlight_pain = monster_flashlight_exposure * lerp(0.08, 0.82, focus_response)
	var pain_target = max(flashlight_pain, monster_ambient_light_pressure * 0.72)
	# Pain stops being gameplay-relevant outside the beam, but it leaves a tiny
	# non-visible afterglow so the material response cools naturally rather than
	# snapping from burned to pristine in a single frame.
	if flashlight_target < 0.10:
		pain_target = max(pain_target, 0.07)
	if monster_light_reflex_timer > 0.0:
		pain_target *= 0.38
	var pain_speed = 2.15 if pain_target > monster_light_pain else (3.6 if flashlight_target < 0.10 else 0.54)
	monster_light_pain = move_toward(monster_light_pain, pain_target, pain_speed * dt)
	var distress_target = clamp(max(monster_light_pain, monster_ambient_light_pressure * 0.78), 0.0, 1.0)
	var distress_response = 3.2 if distress_target > monster_distress_blend else (2.8 if flashlight_target < 0.10 else 0.62)
	monster_distress_blend = move_toward(monster_distress_blend, distress_target, dt * distress_response)
	var flee_target = 1.0 if monster_state == "flee_light" else 0.0
	monster_flee_blend = move_toward(monster_flee_blend, flee_target, dt * (8.5 if flee_target > monster_flee_blend else 1.8))
	var pain_curve = smoothstep(0.16, 0.86, monster_light_pain)
	if focused_contact and focus_response > 0.10 and monster_light_pain > 0.22 and monster_light_stagger_cooldown <= 0.0 and monster_state not in ["flee_light", "hunt_reset"]:
		monster_light_stagger_timer = lerp(0.16, 0.28, pain_curve)
		monster_light_stagger_cooldown = lerp(1.05, 0.72, pain_curve)
	var impairment_wave = 0.5 + 0.5 * sin(elapsed * 7.2 + sin(elapsed * 2.3) * 0.8)
	var impairment_target = pain_curve * lerp(0.10, 0.34, impairment_wave)
	if monster_light_stagger_timer > 0.0:
		impairment_target = max(impairment_target, 0.48)
	if monster_state == "flee_light":
		impairment_target = 0.0
	monster_light_speed_impairment = move_toward(monster_light_speed_impairment, impairment_target, dt * (2.3 if impairment_target > monster_light_speed_impairment else 1.15))
	if focused_contact and focus_response > 0.02:
		var reaction_strength = smoothstep(0.46, 0.94, flashlight_target) * focus_response
		monster_light_flare = max(monster_light_flare, reaction_strength)
		if reaction_strength >= MONSTER_LIGHT_HUNT_BREAK_STRENGTH and monster_state not in ["flee_light", "hunt_reset"]:
			_end_hunt_by_light(player)
		if monster_state == "flee_light":
			monster_light_evasion_timer = max(monster_light_evasion_timer, MONSTER_LIGHT_EVASION_DURATION)
		if monster_state == "flee_light" and monster_light_evasion_retarget_timer <= 0.0:
			monster_light_evasion_target = _choose_dark_escape_target(player)
			monster_light_evasion_retarget_timer = lerp(0.62, 0.34, reaction_strength)
			monster_repath_timer = 0.0
		if reaction_strength > 0.16 and monster_light_burn_pulse_timer <= 0.0:
			monster_light_burn_pulse_timer = lerp(0.34, 0.14, reaction_strength)
			if is_instance_valid(monster_pain_audio) and not monster_pain_audio.playing:
				monster_pain_audio.pitch_scale = randf_range(0.88, 1.15)
				monster_pain_audio.play()
		if reaction_strength > 0.08 and player.has_method("stress_horror_flashlight"):
			player.stress_horror_flashlight(reaction_strength, dt)
	_update_monster_light_vfx(dt)

func _monster_static_light_pressure(position: Vector3) -> float:
	var horizontal_position = Vector3(position.x, 0.0, position.z)
	var strongest = 0.0
	for ward in monster_warding_lights:
		var pulse = _ward_light_pulse(ward)
		var radius = float(ward["radius"])
		var distance = horizontal_position.distance_to(ward["position"])
		var falloff = 1.0 - smoothstep(radius * 0.45, radius + 2.2, distance)
		var pressure_cap = 1.0 if bool(ward.get("safe_zone", false)) else clamp(float(ward.get("strength", 0.6)) * 0.58, 0.18, 0.68)
		strongest = max(strongest, falloff * pressure_cap * pulse)
	return strongest

func _update_monster_light_vfx(_dt: float) -> void:
	var reflex = clamp(monster_light_reflex_timer / MONSTER_LIGHT_REFLEX_DURATION, 0.0, 1.0)
	var distress = clamp(max(monster_distress_blend * 0.92 + monster_light_flare * 0.36, reflex * 0.32), 0.0, 1.0)
	var visual_strength = clamp(max(distress, monster_ambient_light_pressure * 0.52), 0.0, 1.0)
	var shedding_strength = clamp(max((monster_light_pain - 0.28) / 0.58, monster_flee_blend * 0.72, monster_light_impact_timer * 2.8), 0.0, 1.0)
	var wake_direction = Vector3.UP
	if monster_motion_velocity.length_squared() > 0.04:
		wake_direction = (Vector3.UP * 0.62 - monster_motion_velocity.normalized() * 0.78).normalized()
	if is_instance_valid(monster_burn_smoke):
		monster_burn_smoke.emitting = shedding_strength > 0.035
		monster_burn_smoke.amount_ratio = clamp(0.12 + shedding_strength * 0.88, 0.12, 1.0)
		var smoke_process = monster_burn_smoke.process_material as ParticleProcessMaterial
		if smoke_process != null:
			smoke_process.direction = wake_direction
	if is_instance_valid(monster_burn_smoke_wake):
		monster_burn_smoke_wake.emitting = shedding_strength > 0.10
		monster_burn_smoke_wake.amount_ratio = clamp(0.08 + shedding_strength * 0.78, 0.08, 0.86)
		var wake_process = monster_burn_smoke_wake.process_material as ParticleProcessMaterial
		if wake_process != null:
			# The dark layer rises more slowly and is pulled harder behind the
			# fleeing body, leaving a readable path without becoming a solid cloud.
			wake_process.direction = wake_direction.lerp(Vector3.UP, 0.24).normalized()
	if is_instance_valid(monster_burn_embers):
		monster_burn_embers.emitting = shedding_strength > 0.58 or monster_light_impact_timer > 0.0
		monster_burn_embers.amount_ratio = clamp(max((shedding_strength - 0.48) * 0.82, monster_light_impact_timer * 1.35), 0.04, 0.42)
		var dust_process = monster_burn_embers.process_material as ParticleProcessMaterial
		if dust_process != null:
			dust_process.direction = wake_direction
	for entry in monster_light_wisps:
		var wisp = entry.get("mesh") as MeshInstance3D
		var wisp_material = entry.get("material") as ShaderMaterial
		if not is_instance_valid(wisp) or wisp_material == null:
			continue
		var wisp_strength = smoothstep(0.18, 0.78, shedding_strength)
		wisp.visible = wisp_strength > 0.025
		wisp_material.set_shader_parameter("strength", wisp_strength)
		var phase = float(entry.get("phase", 0.0))
		var base_position: Vector3 = entry.get("base_position", wisp.position)
		wisp.position = base_position + Vector3(sin(elapsed * 2.1 + phase) * 0.045, sin(elapsed * 1.4 + phase) * 0.035, 0.0)
		var motion_pull = clamp(monster_motion_velocity.length() / MONSTER_LIGHT_FLEE_SPEED, 0.0, 1.0)
		wisp.rotation.z = -monster_turn_lean * 0.12 + sin(elapsed * 1.7 + phase) * 0.035
		wisp.scale = Vector3(lerp(1.0, 1.35, motion_pull), lerp(1.0, 0.82, motion_pull), 1.0)
	if is_instance_valid(monster_burn_aura):
		monster_burn_aura.visible = visual_strength > 0.08
		var aura_pulse = 1.0 + sin(elapsed * 17.0) * 0.035 * visual_strength
		monster_burn_aura.scale = Vector3(aura_pulse, aura_pulse, aura_pulse)
	if monster_burn_aura_material != null:
		monster_burn_aura_material.set_shader_parameter("pain", visual_strength)
		monster_burn_aura_material.set_shader_parameter("flash", monster_light_flare)
	if monster_contact_shadow_material != null:
		monster_contact_shadow_material.set_shader_parameter("motion", clamp(monster_motion_velocity.length() / MONSTER_LIGHT_FLEE_SPEED, 0.0, 1.0))
		monster_contact_shadow_material.set_shader_parameter("distress", visual_strength)
	if is_instance_valid(monster_contact_shadow):
		var wake_stretch = clamp(monster_motion_velocity.length() / MONSTER_LIGHT_FLEE_SPEED, 0.0, 1.0)
		monster_contact_shadow.scale = Vector3(lerp(1.0, 0.86, wake_stretch), lerp(1.0, 1.48, wake_stretch), 1.0)
	for entry in monster_scorch_materials:
		var material = entry["material"] as ShaderMaterial
		if material == null:
			continue
		var region_wave = 0.88 + sin(elapsed * 3.6 + float(entry.get("phase", 0.0))) * 0.12
		var regional_distress = clamp(distress * float(entry.get("region_weight", 0.72)) * region_wave, 0.0, 1.0)
		material.set_shader_parameter("distress", regional_distress)
	if is_instance_valid(monster_model):
		monster_model.scale = Vector3.ONE * MONSTER_MODEL_SCALE

func _monster_light_prevents_attack() -> bool:
	return monster_light_reflex_timer <= 0.0 and (monster_light_pain > 0.58 or monster_light_evasion_timer > 0.0)

func _end_hunt_by_light(player) -> void:
	monster_state = "flee_light"
	monster_state_timer = MONSTER_LIGHT_EVASION_DURATION
	monster_light_evasion_timer = MONSTER_LIGHT_EVASION_DURATION
	monster_light_flee_elapsed = 0.0
	monster_awareness = 0.0
	monster_alert_timer = 0.0
	monster_chase_time = 0.0
	monster_lost_sight_timer = 0.0
	monster_attack_windup = 0.0
	monster_pounce_windup = 0.0
	monster_pounce_timer = 0.0
	monster_pounce_visual_arc = 0.0
	monster_attack_timer = max(monster_attack_timer, 1.0)
	monster_search_pause = 0.0
	monster_last_known_position = monster_root.global_position
	monster_director_tension = max(0.30, monster_director_tension - 0.18)
	monster_light_evasion_target = _choose_dark_escape_target(player)
	monster_escape_weave_sign = -1.0 if fmod(float(monster_hunt_reset_count), 2.0) > 0.5 else 1.0
	monster_escape_weave_seed = randf_range(0.0, TAU)
	monster_light_evasion_retarget_timer = 0.42
	monster_current_speed = max(monster_current_speed, MONSTER_LIGHT_FLEE_SPEED * 0.72)
	if is_instance_valid(monster_burn_smoke):
		monster_burn_smoke.restart()
	if is_instance_valid(monster_burn_smoke_wake):
		monster_burn_smoke_wake.restart()
	if is_instance_valid(monster_burn_embers):
		monster_burn_embers.restart()
	monster_path.clear()
	monster_repath_timer = 0.0
	monster_processed_noise_event = noise_event_id
	if is_instance_valid(monster_audio):
		monster_audio.pitch_scale = 1.18

func _player_can_see_monster(player) -> bool:
	if player == null or not is_instance_valid(monster_root):
		return false
	return _player_can_see_position(player, monster_root.global_position + Vector3.UP * 1.05)

func _player_can_see_position(player, target: Vector3) -> bool:
	var origin: Vector3 = player.camera_origin()
	var to_target = target - origin
	var distance = to_target.length()
	if distance <= 0.01 or distance > 54.0:
		return false
	var facing = player.aim_dir().normalized().dot(to_target / distance)
	if facing < 0.54:
		return false
	return _grid_has_clear_line(origin, target)

func _relocate_after_light_hunt(player) -> void:
	var reset_position = _choose_hunt_reset_position(player)
	if reset_position == Vector3.INF:
		monster_light_evasion_target = _choose_dark_escape_target(player)
		monster_repath_timer = 0.0
		return
	monster_root.global_position = reset_position
	var reset_cell = _world_cell(reset_position)
	monster_recent_reentry_cells.append(reset_cell)
	while monster_recent_reentry_cells.size() > 5:
		monster_recent_reentry_cells.pop_front()
	monster_last_motion_position = reset_position
	monster_last_known_position = reset_position
	monster_state = "hunt_reset"
	monster_hunt_reset_timer = randf_range(MONSTER_HUNT_RESET_MIN_TIME, MONSTER_HUNT_RESET_MAX_TIME)
	monster_state_timer = monster_hunt_reset_timer
	monster_hunt_reset_count += 1
	monster_light_flee_elapsed = 0.0
	monster_light_evasion_timer = 0.0
	monster_light_evasion_retarget_timer = 0.0
	monster_light_contact_time = 0.0
	monster_flashlight_exposure = 0.0
	monster_light_enrage = 0.0
	monster_current_speed = 0.0
	monster_motion_velocity = Vector3.ZERO
	monster_steering_direction = Vector3.ZERO
	monster_turn_velocity = 0.0
	monster_turn_lean = 0.0
	monster_awareness = 0.0
	monster_search_pause = randf_range(0.35, 0.75)
	monster_player_trail.clear()
	monster_path.clear()
	monster_path_index = 0
	monster_repath_timer = 0.0
	monster_stuck_timer = 0.0
	monster_path_failure_timer = 0.0
	monster_relocate_cooldown = monster_hunt_reset_timer
	if is_instance_valid(monster_audio):
		monster_audio.pitch_scale = 1.0

func _begin_directed_reentry(player) -> void:
	if player == null or not is_instance_valid(monster_root):
		return
	if _player_can_see_monster(player) or monster_root.global_position.distance_to(player.global_position) < 15.0:
		var corrected_position = _choose_hunt_reset_position(player)
		if corrected_position != Vector3.INF:
			monster_root.global_position = corrected_position
			monster_last_motion_position = corrected_position
	monster_state = "investigate"
	monster_state_timer = randf_range(6.5, 9.5)
	monster_hunt_reset_timer = 0.0
	monster_reentry_grace_timer = MONSTER_REENTRY_ATTACK_GRACE
	monster_reentry_cue_timer = 1.1
	monster_visual_confidence = 0.0
	monster_has_visual = false
	monster_awareness = max(monster_awareness, 0.24)
	var uncertainty_direction = monster_last_seen_direction
	if uncertainty_direction.length_squared() <= 0.001:
		uncertainty_direction = -player.aim_dir()
	uncertainty_direction.y = 0.0
	uncertainty_direction = uncertainty_direction.normalized()
	var reentry_estimate = player.global_position + uncertainty_direction * randf_range(2.5, 6.0)
	monster_last_known_position = _cell_world(_nearest_open_cell(_world_cell(reentry_estimate)))
	monster_estimated_player_position = monster_last_known_position
	monster_search_direction = player.global_position - monster_root.global_position
	monster_search_direction.y = 0.0
	if monster_search_direction.length_squared() > 0.001:
		monster_search_direction = monster_search_direction.normalized()
	monster_path.clear()
	monster_path_index = 0
	monster_repath_timer = 0.0
	monster_director_quiet_time = 0.0
	monster_director_reposition_timer = randf_range(8.0, 12.0)
	if is_instance_valid(monster_reentry_audio):
		monster_reentry_audio.pitch_scale = randf_range(0.82, 0.96)
		monster_reentry_audio.play()

func _try_director_shadow_reposition(player) -> void:
	var candidate = _choose_hunt_reset_position(player)
	if candidate == Vector3.INF:
		monster_director_reposition_timer = 4.0
		return
	monster_root.global_position = candidate
	monster_last_motion_position = candidate
	var candidate_cell = _world_cell(candidate)
	monster_recent_reentry_cells.append(candidate_cell)
	while monster_recent_reentry_cells.size() > 5:
		monster_recent_reentry_cells.pop_front()
	monster_motion_velocity = Vector3.ZERO
	monster_steering_direction = Vector3.ZERO
	monster_turn_velocity = 0.0
	monster_path.clear()
	monster_path_index = 0
	monster_repath_timer = 0.0
	monster_reentry_grace_timer = MONSTER_REENTRY_ATTACK_GRACE
	monster_director_tension = max(0.34, monster_director_tension - 0.26)
	monster_relocate_cooldown = randf_range(10.0, 15.0)
	_begin_directed_reentry(player)

func _choose_hunt_reset_position(player) -> Vector3:
	var best_position = Vector3.INF
	var best_score = INF
	var shortlist: Array[Dictionary] = []
	var player_aim = player.aim_dir()
	player_aim.y = 0.0
	player_aim = player_aim.normalized()
	for cell in monster_open_cells:
		var candidate = _cell_world(cell)
		if _monster_spawn_forbidden_near_kitchen(candidate) or not _monster_motion_position_valid(candidate):
			continue
		var player_distance = candidate.distance_to(player.global_position)
		if player_distance < 18.0 or player_distance > 36.0:
			continue
		if candidate.distance_to(monster_root.global_position) < 12.0:
			continue
		if _monster_static_light_pressure(candidate) > 0.56:
			continue
		if _player_can_see_position(player, candidate + Vector3.UP * 1.05):
			continue
		var from_player = candidate - player.global_position
		from_player.y = 0.0
		var view_dot = player_aim.dot(from_player.normalized())
		var occluded = not _grid_has_clear_line(player.global_position + Vector3.UP, candidate + Vector3.UP)
		var score = abs(player_distance - 25.0) + max(0.0, view_dot + 0.28) * 5.0
		if occluded:
			score -= 4.0
		for recent_cell in monster_recent_reentry_cells:
			var recent_distance = float(cell.distance_squared_to(recent_cell))
			if recent_distance < 16.0:
				score += (16.0 - recent_distance) * 0.72
		score += _monster_static_light_pressure(candidate) * 12.0
		score += fmod(abs(float(cell.x * 29 + cell.y * 17 + monster_hunt_reset_count * 7)), 19.0) * 0.025
		shortlist.append({"cell": cell, "position": candidate, "base_score": score})
	shortlist.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["base_score"]) < float(b["base_score"]))
	var shortlist_limit = mini(56, shortlist.size())
	for index in range(shortlist_limit):
		var entry: Dictionary = shortlist[index]
		var candidate: Vector3 = entry["position"]
		var path_metrics = _navigation_path_metrics(player.global_position, candidate)
		var path_distance = float(path_metrics.get("distance", INF))
		var path_turns = int(path_metrics.get("turns", 0))
		if path_distance < 24.0 or path_distance > 68.0:
			continue
		var score = float(entry["base_score"]) + abs(path_distance - 38.0) * 0.16
		score -= min(float(path_turns), 4.0) * 1.15
		if path_turns < 2:
			score += 5.5
		if score < best_score:
			best_score = score
			best_position = candidate
	return best_position


func _monster_spawn_forbidden_near_kitchen(position: Vector3) -> bool:
	# This is deliberately a placement-only exclusion. The navigation grid stays
	# untouched, so a live hunt can still pass through the service corridor.
	if not task_anchors.has("kitchen"):
		return false
	var local_position := position - Vector3(task_anchors["kitchen"])
	return absf(local_position.x) <= 2.40 and local_position.z >= 1.90 and local_position.z <= 29.40


func _nearest_monster_spawn_cell(origin: Vector2i) -> Vector2i:
	var best_cell := Vector2i(-1, -1)
	var best_distance := INF
	for cell in monster_open_cells:
		var candidate := _cell_world(cell)
		if _monster_spawn_forbidden_near_kitchen(candidate):
			continue
		var distance := float(cell.distance_squared_to(origin))
		if distance < best_distance:
			best_distance = distance
			best_cell = cell
	if best_cell.x >= 0:
		return best_cell
	return Vector2i(-1, -1)

func _navigation_path_metrics(from: Vector3, to: Vector3) -> Dictionary:
	if monster_navigation == null:
		return {"distance": from.distance_to(to), "turns": 0}
	var from_cell = _nearest_open_cell(_world_cell(from))
	var to_cell = _nearest_open_cell(_world_cell(to))
	var path = monster_navigation.get_id_path(from_cell, to_cell)
	if path.is_empty():
		return {"distance": INF, "turns": 0}
	var turns = 0
	var previous_direction = Vector2i.ZERO
	for index in range(1, path.size()):
		var direction: Vector2i = path[index] - path[index - 1]
		if previous_direction != Vector2i.ZERO and direction != previous_direction:
			turns += 1
		previous_direction = direction
	return {"distance": max(0.0, float(path.size() - 1) * TILE), "turns": turns}

func _choose_dark_escape_target(player) -> Vector3:
	var best_target = monster_root.global_position
	var best_score = INF
	var fallback_target = monster_root.global_position
	var fallback_score = INF
	var away_from_player = monster_root.global_position - player.global_position
	away_from_player.y = 0.0
	away_from_player = away_from_player.normalized()
	for cell in monster_open_cells:
		var candidate = _cell_world(cell)
		var travel = candidate - monster_root.global_position
		travel.y = 0.0
		var distance = travel.length()
		if distance < 4.5 or distance > 27.0:
			continue
		var static_pressure = _monster_static_light_pressure(candidate)
		var beam_pressure = _flashlight_exposure_at_position(player, candidate + Vector3.UP * 1.05)
		var escape_alignment = travel.normalized().dot(away_from_player)
		var score = static_pressure * 15.0 + beam_pressure * 22.0 + abs(distance - 13.0) * 0.24 - escape_alignment * 2.8
		# Stable variation prevents repeated encounters from choosing the exact same leg.
		score += fmod(abs(float(cell.x * 19 + cell.y * 31)), 13.0) * 0.025
		if score < fallback_score:
			fallback_score = score
			fallback_target = candidate
		if static_pressure <= 0.72 and beam_pressure <= 0.48 and score < best_score:
			best_score = score
			best_target = candidate
	return fallback_target if best_score == INF else best_target

func _choose_safe_zone_perimeter_target(player) -> Vector3:
	var best_target = monster_root.global_position
	var best_score = INF
	for cell in monster_open_cells:
		var candidate = _cell_world(cell)
		var player_distance = candidate.distance_to(player.global_position)
		if player_distance < 5.0 or player_distance > 12.5:
			continue
		var pressure = _monster_static_light_pressure(candidate)
		if pressure > 0.68:
			continue
		var travel_distance = candidate.distance_to(monster_root.global_position)
		var sees_player_from_edge = _grid_has_clear_line(candidate + Vector3.UP * 1.55, player.global_position + Vector3.UP)
		var score = pressure * 18.0 + abs(player_distance - 7.5) * 0.55 + travel_distance * 0.16
		if sees_player_from_edge:
			score -= 1.6
		score += fmod(abs(float(cell.x * 23 + cell.y * 11)), 17.0) * 0.018
		if score < best_score:
			best_score = score
			best_target = candidate
	return best_target

func _choose_safe_zone_behavior(player) -> void:
	var roll = randf()
	if monster_director_tension > 0.72:
		roll -= 0.14
	if roll < 0.42:
		monster_safe_zone_behavior = "watch"
		monster_safe_zone_target = _choose_safe_zone_perimeter_target(player)
		monster_safe_zone_behavior_timer = randf_range(2.8, 4.8)
	elif roll < 0.82:
		monster_safe_zone_behavior = "flank"
		monster_safe_zone_target = _choose_safe_zone_flank_target(player)
		monster_safe_zone_behavior_timer = randf_range(3.4, 5.8)
	else:
		monster_safe_zone_behavior = "watch"
		monster_safe_zone_target = _choose_safe_zone_perimeter_target(player)
		monster_safe_zone_behavior_timer = randf_range(2.2, 3.8)
	monster_repath_timer = 0.0

func _choose_safe_zone_flank_target(player) -> Vector3:
	var best_target = _choose_safe_zone_perimeter_target(player)
	var best_score = INF
	var player_forward = player.aim_dir()
	player_forward.y = 0.0
	player_forward = player_forward.normalized()
	for cell in monster_open_cells:
		var candidate = _cell_world(cell)
		var player_distance = candidate.distance_to(player.global_position)
		if player_distance < 6.0 or player_distance > 13.5:
			continue
		var pressure = _monster_static_light_pressure(candidate)
		if pressure > 0.66:
			continue
		var from_player = candidate - player.global_position
		from_player.y = 0.0
		var side_alignment = abs(player_forward.dot(from_player.normalized()))
		var hidden_from_player = not _player_can_see_position(player, candidate + Vector3.UP * 1.05)
		var score = side_alignment * 3.4 + pressure * 16.0 + candidate.distance_to(monster_root.global_position) * 0.12
		if hidden_from_player:
			score -= 2.2
		if score < best_score:
			best_score = score
			best_target = candidate
	return best_target

func _monster_flashlight_exposure(player) -> float:
	flashlight_blocking_player = player
	return 1.0 if is_instance_valid(monster_root) and _position_in_handheld_light(monster_root.global_position, MONSTER_BODY_RADIUS) else 0.0

func _handheld_light_depth(position: Vector3, margin: float = 0.0, check_occlusion: bool = true) -> float:
	var player = flashlight_blocking_player
	if not is_instance_valid(player) or not player.horror_flashlight_mode or not player.flashlight_on or player.horror_battery_seconds <= 0.0:
		return -1.0
	if not is_instance_valid(player.flashlight_emitter) or not is_instance_valid(player.flashlight_primary):
		return -1.0
	var origin: Vector3 = player.flashlight_emitter.global_position
	var axis: Vector3 = -player.flashlight_emitter.global_basis.z.normalized()
	var target := position + Vector3.UP * 0.95
	var delta := target - origin
	var along := delta.dot(axis)
	if along < 0.0 or along > player.flashlight_primary.spot_range + margin:
		return -1.0
	var radial := (delta - axis * along).length()
	var penetration := minf(tan(deg_to_rad(player.flashlight_primary.spot_angle)) * along + margin - radial, player.flashlight_primary.spot_range + margin - along)
	if penetration <= 0.0:
		return penetration
	if check_occlusion and not _handheld_line_clear(origin, target):
		var exposed_edge := false
		for offset in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK,Vector3.UP]:
			var point: Vector3 = target + offset * margin * 0.85
			var edge_delta := point-origin
			var edge_along := edge_delta.dot(axis)
			if edge_along > 0 and edge_along < player.flashlight_primary.spot_range and (edge_delta-axis*edge_along).length() < tan(deg_to_rad(player.flashlight_primary.spot_angle))*edge_along and _handheld_line_clear(origin,point):
				exposed_edge = true
				break
		if not exposed_edge:
			return -1.0
	return penetration

func _handheld_line_clear(origin: Vector3, target: Vector3) -> bool:
	var delta := target - origin
	for solid in level_manager.query_solid_areas(origin, target):
		var center: Vector3 = solid.center
		var half: Vector2 = solid.half
		var bounds := AABB(Vector3(center.x - half.x, 0.0, center.z - half.y), Vector3(half.x * 2.0, float(solid.height), half.y * 2.0))
		if bounds.intersects_segment(origin, target) != null:
			return false
	var steps := maxi(1, ceili(delta.length() / 0.20))
	for i in range(1, steps):
		var point := origin + delta * (float(i) / steps)
		var cell := _world_cell(point)
		if cell.y < 0 or cell.y >= maze_raw.size() or cell.x < 0 or cell.x >= String(maze_raw[cell.y]).length() or String(maze_raw[cell.y]).substr(cell.x, 1) in ["#", "D"]:
			return false
	return true

func _position_in_handheld_light(position: Vector3, margin: float = 0.0) -> bool:
	return _handheld_light_depth(position, margin) > 0.0

func _hold_flashlight_boundary(dt: float, player) -> bool:
	var position := monster_root.global_position
	var depth := _handheld_light_depth(position, MONSTER_BODY_RADIUS)
	if depth <= 0.0 and creature_light_state == "clear":
		return false
	# A wider exit envelope keeps a creature just outside the cone stalking,
	# rather than alternating Attack/Stalk at the mathematical light edge.
	var edge_pressure := _handheld_light_depth(position, MONSTER_BODY_RADIUS + 0.75)
	creature_light_clear_time = creature_light_clear_time + dt if depth <= 0.0 and edge_pressure <= 0.0 else 0.0
	if creature_light_clear_time >= 0.65:
		creature_light_state = "clear"
		# A short grounded creep precedes renewed pursuit, not an instant dash.
		creature_dark_approach_time = 1.4
		monster_steering_direction = Vector3.ZERO
		creature_retreat_path.clear()
		monster_path.clear()
		monster_repath_timer = 0.0
		stalk_director.release()
		return false
	if creature_light_state == "clear":
		creature_light_state = "flinch"
		creature_light_state_time = 0.0
		creature_light_plan_time = 0.0
		monster_path.clear()
		monster_motion_velocity = Vector3.ZERO
		monster_current_speed = 0.0
		stalk_director.enter()
	predator_attack.cancel(self)
	creature_light_state_time += dt
	creature_light_plan_time -= dt
	monster_attack_windup = 0.0
	monster_strike_timer = 0.0
	creature_beam_hold = 0.12
	monster_pounce_windup = 0.0
	monster_pounce_timer = 0.0
	monster_pounce_visual_arc = predator_attack.interrupted_landing
	if creature_light_state_time > 0.16:
		creature_light_state = "retreat" if depth > 0.0 else "stalk"
		stalk_director.tick(self,dt,player,depth)
	monster_predator_crouch = move_toward(monster_predator_crouch, 0.65, dt * 4.0)
	_animate_amalgam(dt, position.distance_to(monster_root.global_position) / maxf(dt, 0.001))
	return true

func _plan_flashlight_retreat() -> bool:
	# Local navigation refinement uses the same body/prop collision oracle.
	# The 4 m global grid cannot represent the narrow lanes beside furniture.
	var origin: Vector3 = monster_root.position
	var start := Vector2i.ZERO
	var frontier: Array[Vector2i] = [start]
	var parents: Dictionary = {start:start}
	var cursor := 0
	var best := start
	var best_score := INF
	var player_position: Vector3 = flashlight_blocking_player.global_position
	var radial := origin - player_position
	radial.y = 0.0
	var comfortable_range := clampf(radial.length(), 3.2, 6.5)
	var tangent: Vector3 = Vector3(-radial.z, 0, radial.x).normalized()*stalk_director.side
	while cursor < frontier.size() and cursor < 40:
		var cell := frontier[cursor]
		cursor += 1
		var point := origin + Vector3(cell.x,0,cell.y)*0.65
		var pressure := _handheld_light_depth(point,MONSTER_BODY_RADIUS)
		var gap := point.distance_to(player_position)
		# Prefer escaping sideways at roughly the current radius. Distance alone
		# must never reward an endless backwards flee. Stable side preference
		# avoids frame-to-frame left/right indecision; obstacles can override it.
		var score: float = maxf(pressure,0.0)*30.0 + absf(gap-comfortable_range)*2.5 + point.distance_to(origin)*0.35 - (point-origin).dot(tangent)*0.65
		if gap >= 2.8 and score < best_score and point.distance_to(origin) > 0.45:
			best = cell
			best_score = score
		for offset in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next: Vector2i = cell+offset
			if parents.has(next) or next.length() > 6.0: continue
			var next_point := origin+Vector3(next.x,0,next.y)*0.65
			if not _monster_motion_segment_valid(point,next_point): continue
			parents[next] = cell
			frontier.append(next)
	creature_retreat_path.clear()
	if best == start: return false
	var cursor_cell := best
	while cursor_cell != start:
		creature_retreat_path.push_front(origin+Vector3(cursor_cell.x,0,cursor_cell.y)*0.65)
		cursor_cell = parents[cursor_cell]
	return not creature_retreat_path.is_empty()

func _flashlight_exposure_at_position(player, target: Vector3) -> float:
	if player == null or not bool(player.horror_flashlight_mode) or not bool(player.flashlight_on):
		return 0.0
	var origin: Vector3 = player.camera_origin()
	var to_monster = target - origin
	var distance = to_monster.length()
	if distance <= 0.01 or distance > MONSTER_FLASHLIGHT_RANGE:
		return 0.0
	# The gameplay cone cannot extend farther than the actually rendered beam.
	# This keeps an occluded or shortened flashlight from burning a target that
	# the player cannot visibly reach.
	if distance > max(0.0, float(player.flashlight_volume_length) - 0.20):
		return 0.0
	var direction = to_monster / distance
	var facing = player.aim_dir().normalized().dot(direction)
	if facing <= MONSTER_FLASHLIGHT_EDGE_DOT:
		return 0.0
	if not _grid_has_clear_line(origin, target):
		return 0.0
	var cone_strength = smoothstep(MONSTER_FLASHLIGHT_EDGE_DOT, MONSTER_FLASHLIGHT_CORE_DOT, facing)
	cone_strength = pow(cone_strength, 1.45)
	var distance_strength = 1.0 - smoothstep(MONSTER_FLASHLIGHT_FULL_STRENGTH_RANGE, MONSTER_FLASHLIGHT_RANGE, distance)
	distance_strength = pow(max(distance_strength, 0.0), 2.8)
	var focus_output = player.horror_flashlight_focus_ratio() if player.has_method("horror_flashlight_focus_ratio") else 1.0
	return clamp(cone_strength * distance_strength * focus_output, 0.0, 1.0)

func _monster_can_see_player(player, distance: float) -> bool:
	return _monster_visual_strength(player, distance) > 0.01

func _monster_visual_strength(player, distance: float) -> float:
	if bool(player.horror_hidden) or distance > MONSTER_SIGHT_RANGE:
		return 0.0
	var eye_origin = monster_root.global_position + Vector3.UP * 1.58
	var visible_samples = 0
	for sample_height in [0.34, 0.96, 1.58]:
		if _grid_has_clear_line(eye_origin, player.global_position + Vector3.UP * sample_height):
			visible_samples += 1
	if visible_samples == 0:
		return 0.0
	if distance < 2.65:
		return 1.0
	var forward = -monster_root.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var to_player = player.global_position - monster_root.global_position
	to_player.y = 0.0
	to_player = to_player.normalized()
	var view_threshold = 0.24 if bool(player.flashlight_on) else 0.34
	var facing = forward.dot(to_player)
	if facing < view_threshold:
		return 0.0
	var distance_factor = 1.0 - clamp((distance - 2.65) / (MONSTER_SIGHT_RANGE - 2.65), 0.0, 1.0)
	var facing_factor = inverse_lerp(view_threshold, 1.0, facing)
	var occlusion_factor = [0.0, 0.30, 0.68, 1.0][visible_samples]
	var movement_bonus = 0.12 if bool(player.horror_sprint_active) else clamp(float(player.horizontal_speed) / 5.2, 0.0, 1.0) * 0.045
	var light_bonus = 0.075 if bool(player.flashlight_on) else 0.0
	return clamp((distance_factor * (0.28 + facing_factor * 0.72) + movement_bonus + light_bonus) * occlusion_factor, 0.0, 1.0)

func _nearby_player_trail_point() -> Vector3:
	for index in range(monster_player_trail.size() - 1, -1, -1):
		var point: Vector3 = monster_player_trail[index]
		if monster_root.global_position.distance_to(point) <= 7.0 and monster_last_known_position.distance_to(point) <= 10.0:
			return point
	return Vector3.INF

func _resolve_monster_attack(player) -> bool:
	if creature_light_state != "clear" or creature_dark_approach_time > 0.0:
		return false
	if bool(player.horror_hidden) or _monster_position_in_warding_light(player.global_position) or darkness_time < DARKNESS_HUNT_DELAY or _monster_flashlight_exposure(player) > 0.0:
		return false
	if monster_strike_timer <= 0.0 or not is_instance_valid(creature_animation_driver):
		return false
	if creature_animation_driver.current_state != &"Attack" or creature_animation_driver.state_seconds < 0.10 or creature_animation_driver.state_seconds > 0.19:
		return false
	var distance = monster_root.global_position.distance_to(player.global_position)
	var clear = _grid_has_clear_line(monster_root.global_position + Vector3.UP * 0.75, player.global_position + Vector3.UP * 0.25)
	if distance > 1.85 or not clear or not creature_animation_driver.strike_touches(player.global_position):
		return false
	player.damage(34)
	monster_director_tension = max(0.28, monster_director_tension - 0.24)
	var push = player.global_position - monster_root.global_position
	push.y = 0.0
	if push.length_squared() > 0.01:
		player.horizontal_velocity += push.normalized() * 5.0
	return true

func _monster_camera_clearance_position(player, dt: float, position: Vector3) -> Vector3:
	if not is_instance_valid(monster_root):
		return position
	var separation = position - player.global_position
	separation.y = 0.0
	var distance = separation.length()
	if distance >= MONSTER_CAMERA_CLEARANCE:
		return position
	if distance <= 0.001:
		separation = monster_root.global_transform.basis.z
		separation.y = 0.0
	var corrected_position = position + separation.normalized() * min(MONSTER_CAMERA_CLEARANCE - distance, 8.0 * dt)
	if _monster_motion_segment_valid(monster_root.global_position, corrected_position):
		return corrected_position
	return position

func _update_monster_presence_lighting(player_distance: float) -> void:
	var proximity = clamp(1.0 - player_distance / 16.0, 0.0, 1.0)
	var reflected_light = clamp(max(monster_flashlight_exposure, monster_ambient_light_pressure * 0.82), 0.0, 1.0)
	var reveal = smoothstep(0.12, 0.82, reflected_light)
	var pain = clamp(monster_light_pain + monster_light_flare * 0.32, 0.0, 1.0)
	var uneven_reflection = 0.94 + sin(elapsed * 11.7) * 0.06 * pain
	if is_instance_valid(monster_presence_light):
		monster_presence_light.light_energy = 0.0
		monster_presence_light.light_color = Color8(129, 123, 105).lerp(Color8(137, 146, 130), pain)
	if is_instance_valid(monster_face_light):
		monster_face_light.light_energy = 0.0
		monster_face_light.light_color = Color8(154, 151, 132).lerp(Color8(166, 176, 157), pain)

func _monster_state_target(player) -> Vector3:
	match monster_state:
		"chase":
			if monster_has_visual:
				_update_monster_pursuit_target(player, player.global_position.distance_to(monster_root.position))
				return monster_pursuit_target if monster_pursuit_target != Vector3.ZERO else player.global_position
			return monster_estimated_player_position if monster_estimated_player_position != Vector3.ZERO else monster_last_known_position
		"suspicious":
			return monster_estimated_player_position if monster_estimated_player_position != Vector3.ZERO else monster_last_known_position
		"investigate":
			if monster_root.position.distance_to(monster_last_known_position) < 1.7 or monster_state_timer <= 0.0:
				_begin_monster_search(monster_last_known_position)
			return monster_last_known_position
		"search":
			if monster_search_points.is_empty() or monster_state_timer <= 0.0:
				monster_state = "stalk"
				monster_state_timer = 0.0
				return _next_patrol_target()
			var search_target = monster_search_points[monster_search_index % monster_search_points.size()]
			if monster_root.position.distance_to(search_target) < 1.45:
				monster_search_visited.append(search_target)
				if monster_search_visited.size() > 12:
					monster_search_visited.pop_front()
				monster_search_pause = randf_range(0.48, 1.18)
				monster_search_scan_anchor = monster_root.rotation.y
				monster_search_scan_sign = -1.0 if randf() < 0.5 else 1.0
				var opening_width = lerp(0.42, 0.94, clamp(monster_search_confidence, 0.0, 1.0))
				monster_search_scan_target = monster_search_scan_sign * opening_width * randf_range(0.70, 0.94)
				monster_search_scan_timer = randf_range(0.58, 0.92)
				monster_search_index += 1
				if monster_search_index >= monster_search_points.size():
					if monster_search_wave < 2 and monster_state_timer > 4.5 and monster_search_confidence > 0.16:
						monster_search_wave += 1
						monster_search_confidence *= 0.72
						_rebuild_monster_search_points(monster_search_center)
						return monster_search_points[0] if not monster_search_points.is_empty() else _next_patrol_target()
					monster_state = "stalk"
					return _next_patrol_target()
				search_target = monster_search_points[monster_search_index]
			return search_target
		"hunt_reset":
			return monster_root.global_position
		_:
			return _next_patrol_target()

func _next_patrol_target() -> Vector3:
	if monster_patrol_points.is_empty():
		return monster_root.position
	var target = monster_patrol_points[monster_patrol_index % monster_patrol_points.size()]
	if monster_root.position.distance_to(target) < 1.8:
		monster_patrol_index = (monster_patrol_index + 1) % monster_patrol_points.size()
		target = monster_patrol_points[monster_patrol_index]
	return target

func _monster_state_speed(player_distance: float) -> float:
	match monster_state:
		"flee_light": return MONSTER_LIGHT_FLEE_SPEED
		"hunt_reset": return 0.0
		"chase":
			if creature_dark_approach_time > 0.0 and player_distance > MONSTER_ATTACK_RANGE:
				return lerpf(2.0, MONSTER_CHASE_SPEED, smoothstep(0.0, 1.4, 1.4 - creature_dark_approach_time))
			if player_distance > 13.0:
				return MONSTER_CHASE_BURST_SPEED
			if player_distance < 4.2:
				return MONSTER_CHASE_SPEED * 0.88
			return MONSTER_CHASE_SPEED * lerp(0.96, 1.04, clamp(monster_chase_time / 7.0, 0.0, 1.0))
		"suspicious": return MONSTER_SUSPICIOUS_SPEED
		"investigate": return MONSTER_INVESTIGATE_SPEED
		"search": return MONSTER_SEARCH_SPEED
		"stalk": return MONSTER_PATROL_SPEED * 0.86
		_: return MONSTER_PATROL_SPEED

func _monster_effective_speed(player_distance: float) -> float:
	var base_speed = _monster_state_speed(player_distance)
	if monster_state == "flee_light":
		# The escape starts hard, then breathes by only a few percent. Large
		# frame-driven speed oscillations read as an engine throttle rather than
		# an animal gait.
		return MONSTER_LIGHT_FLEE_SPEED * (0.975 + sin(monster_stride_phase * 0.24) * 0.025)
	if monster_light_reflex_timer > 0.0:
		var reflex_progress = monster_light_reflex_timer / MONSTER_LIGHT_REFLEX_DURATION
		var lunge_curve = sin(reflex_progress * PI)
		return base_speed * (1.16 + monster_light_enrage * 0.18 + lunge_curve * 0.16)
	return base_speed * (1.0 - monster_light_speed_impairment)

func _update_monster_predator_rhythm(dt: float, player_distance: float) -> void:
	var can_prowl = monster_state == "chase" and monster_has_visual and monster_attack_windup <= 0.0 and monster_light_pain < 0.24
	var wants_crouch = 0.0
	if can_prowl:
		# The silhouette becomes lower only once it has truly committed to the
		# prey. Keeping the far silhouette taller protects the read in fog.
		wants_crouch = 1.0 - smoothstep(2.8, 10.5, player_distance)
	monster_predator_crouch = move_toward(monster_predator_crouch, wants_crouch, dt * (2.9 if wants_crouch > monster_predator_crouch else 1.45))

	monster_probe_timer = max(0.0, monster_probe_timer - dt)
	monster_probe_cooldown = max(0.0, monster_probe_cooldown - dt)
	if can_prowl and monster_probe_timer <= 0.0 and monster_probe_cooldown <= 0.0 and player_distance > 5.0 and player_distance < 11.5:
		# A brief planted beat makes the pursuit feel observed rather than driven
		# by a continuous motor. The spacing is irregular but bounded.
		monster_probe_timer = randf_range(0.10, 0.18)
		monster_probe_cooldown = randf_range(4.2, 7.4)

	monster_stride_variation_timer = max(0.0, monster_stride_variation_timer - dt)
	if monster_stride_variation_timer <= 0.0:
		monster_stride_variation_timer = randf_range(0.72, 1.35)
		if can_prowl:
			monster_stride_cadence_target = randf_range(0.80, 1.16)
			monster_stride_side_bias = randf_range(-1.0, 1.0)
		else:
			monster_stride_cadence_target = randf_range(0.90, 1.07)
			monster_stride_side_bias = randf_range(-0.35, 0.35)
	monster_stride_cadence = move_toward(monster_stride_cadence, monster_stride_cadence_target, dt * (1.8 if can_prowl else 0.85))

func _update_monster_head_lead(dt: float, player) -> void:
	var desired_offset = 0.0
	if is_instance_valid(monster_root) and player != null:
		var focus = monster_pursuit_target
		if monster_has_visual or creature_light_state != "clear" or player_in_safe_light:
			focus = player.global_position + player.horizontal_velocity * 0.16
		var focus_delta = focus - monster_root.global_position
		focus_delta.y = 0.0
		if focus_delta.length_squared() > 0.01:
			var focus_yaw = atan2(-focus_delta.x, -focus_delta.z)
			desired_offset = clamp(wrapf(focus_yaw - monster_root.rotation.y, -PI, PI), -0.78, 0.78)
	var response = 8.5 if monster_has_visual else 3.2
	var target_velocity = clamp((desired_offset - monster_head_gaze_offset) * response, -3.8, 3.8)
	monster_head_gaze_velocity = lerp(monster_head_gaze_velocity, target_velocity, 1.0 - exp(-7.0 * dt))
	monster_head_gaze_offset = move_toward(monster_head_gaze_offset, desired_offset, abs(monster_head_gaze_velocity) * dt)
	if abs(desired_offset) < 0.015:
		monster_head_gaze_offset = move_toward(monster_head_gaze_offset, 0.0, dt * 0.55)

func _begin_monster_search(center: Vector3) -> void:
	monster_state = "search"
	monster_state_timer = randf_range(17.0, 23.0)
	monster_search_index = 0
	monster_search_center = _cell_world(_nearest_open_cell(_world_cell(center)))
	monster_search_wave = 0
	monster_search_seed = randf_range(0.0, TAU)
	monster_search_confidence = max(monster_search_confidence, clamp(monster_awareness, 0.24, 1.0))
	if monster_last_seen_velocity.length_squared() > 0.12:
		monster_search_direction = monster_last_seen_velocity.normalized()
	elif monster_last_seen_direction.length_squared() > 0.001:
		monster_search_direction = monster_last_seen_direction.normalized()
	_rebuild_monster_search_points(monster_search_center)
	monster_repath_timer = 0.0

func _rebuild_monster_search_points(center: Vector3) -> void:
	monster_search_points.clear()
	monster_search_index = 0
	var center_cell = _nearest_open_cell(_world_cell(center))
	monster_search_points.append(_cell_world(center_cell))
	var forward = monster_search_direction
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = -monster_root.global_transform.basis.z
		forward.y = 0.0
	forward = forward.normalized()
	var projected = center + forward * (TILE * (1.5 + float(monster_search_wave)))
	var projected_position = _cell_world(_nearest_open_cell(_world_cell(projected)))
	if projected_position.distance_to(monster_search_points[0]) > 1.0:
		monster_search_points.append(projected_position)
	var candidates: Array[Dictionary] = []
	var radius_cells = 4 + monster_search_wave * 2
	for y in range(center_cell.y - radius_cells, center_cell.y + radius_cells + 1):
		for x in range(center_cell.x - radius_cells, center_cell.x + radius_cells + 1):
			var cell = Vector2i(x, y)
			if not monster_navigation.is_in_boundsv(cell) or monster_navigation.is_point_solid(cell):
				continue
			var candidate = _cell_world(cell)
			if candidate.distance_to(center) < TILE * 0.75:
				continue
			var delta = candidate - center
			delta.y = 0.0
			var distance_cells = delta.length() / TILE
			var alignment = delta.normalized().dot(forward)
			var junction_bonus = 1.4 if _monster_open_neighbor_count(cell) >= 3 else 0.0
			var visited_penalty = 0.0
			for visited in monster_search_visited:
				if candidate.distance_to(visited) < TILE * 1.4:
					visited_penalty += 3.4
			var stable_variation = fmod(abs(float(cell.x * 37 + cell.y * 19) + monster_search_seed * 13.0), 29.0) * 0.055
			var ideal_radius = 2.2 + float(monster_search_wave) * 1.5
			var score = abs(distance_cells - ideal_radius) * 0.72 - max(alignment, -0.4) * 1.15 - junction_bonus
			score += _monster_static_light_pressure(candidate) * 4.2 + visited_penalty + stable_variation
			candidates.append({"position": candidate, "score": score})
	for locker in hide_lockers:
		if not is_instance_valid(locker):
			continue
		var locker_position: Vector3 = locker.global_position
		if locker_position.distance_to(center) > float(radius_cells) * TILE:
			continue
		var locker_score = 0.45 + locker_position.distance_to(center) / TILE * 0.18
		if not active_locker.is_empty() and locker == active_locker.get("node"):
			locker_score -= monster_locker_suspicion * 2.8
		else:
			locker_score -= 0.35
		candidates.append({"position": _cell_world(_nearest_open_cell(_world_cell(locker_position))), "score": locker_score})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["score"]) < float(b["score"]))
	for candidate_entry in candidates:
		if monster_search_points.size() >= MONSTER_SEARCH_POINT_LIMIT:
			break
		var candidate_position: Vector3 = candidate_entry["position"]
		var separated = true
		for existing in monster_search_points:
			if candidate_position.distance_to(existing) < TILE * 1.20:
				separated = false
				break
		if separated:
			monster_search_points.append(candidate_position)

func _monster_open_neighbor_count(cell: Vector2i) -> int:
	var count = 0
	for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor = cell + direction
		if monster_navigation.is_in_boundsv(neighbor) and not monster_navigation.is_point_solid(neighbor):
			count += 1
	return count

func _update_monster_stuck_and_relocation(dt: float, player, _moved: float, player_distance: float, sees_player: bool) -> void:
	var actual_motion = monster_root.position.distance_to(monster_last_motion_position)
	monster_last_motion_position = monster_root.position
	var actual_speed: float = actual_motion / maxf(dt,0.001)
	if monster_requested_motion > 0.15 and actual_speed < monster_requested_motion * 0.08:
		monster_stuck_timer += dt
	else:
		monster_stuck_timer = max(0.0, monster_stuck_timer - dt * 2.4)
	if monster_stuck_timer > 0.85:
		monster_repath_timer = 0.0
	if not sees_player and player_distance > MONSTER_RELOCATE_DISTANCE:
		monster_far_unseen_timer += dt
	else:
		monster_far_unseen_timer = max(0.0, monster_far_unseen_timer - dt * 2.0)
	var navigation_broken = monster_stuck_timer > 2.2 or monster_path_failure_timer > 2.4
	var director_reposition = monster_far_unseen_timer > 12.0 and monster_unseen_timer > 12.0
	var can_relocate = monster_state in ["patrol", "stalk", "search", "investigate"] and monster_attack_windup <= 0.0
	if not sees_player and can_relocate and (navigation_broken or director_reposition) and monster_relocate_cooldown <= 0.0:
		_try_director_shadow_reposition(player)

func _try_search_active_locker(player, dt: float) -> void:
	if _monster_position_in_warding_light(player.global_position) or darkness_time < DARKNESS_HUNT_DELAY:
		return
	if active_locker.is_empty() or monster_state in ["patrol", "stalk", "hunt_reset", "flee_light"]:
		return
	var locker_node = active_locker.get("node")
	if not is_instance_valid(locker_node):
		return
	if bool(player.flashlight_on):
		monster_locker_suspicion = min(1.0, monster_locker_suspicion + dt * 0.08)
	if monster_root.global_position.distance_to(locker_node.global_position) > 1.8:
		return
	if monster_locker_suspicion < 0.28:
		return
	if not monster_locker_decision_made:
		monster_locker_decision_made = true
		monster_locker_check_timer = lerp(1.55, 0.72, monster_locker_suspicion)
		monster_search_pause = monster_locker_check_timer
		monster_gesture_timer = monster_locker_check_timer
		return
	if monster_locker_check_timer > 0.0:
		return
	var check_roll = fmod(abs(float(noise_event_id * 31 + monster_hunt_reset_count * 17) + monster_search_seed * 7.0), 100.0) / 100.0
	var opens_locker = monster_locker_suspicion >= 0.86 or check_roll < monster_locker_suspicion * 0.58
	if not opens_locker:
		monster_saw_locker_entry = false
		monster_heard_locker_entry = false
		monster_locker_suspicion = 0.0
		monster_locker_decision_made = false
		_begin_monster_search(locker_node.global_position)
		return
	var leave_position: Vector3 = active_locker.get("exit_position", player.global_position)
	player.set_horror_hidden(false)
	player.global_position = leave_position
	active_locker = {}
	monster_saw_locker_entry = false
	monster_heard_locker_entry = false
	monster_locker_suspicion = 0.0
	monster_locker_decision_made = false
	if not _monster_position_in_warding_light(leave_position):
		player.damage(38)
	monster_attack_timer = 1.05
	_play_monster_hunt_cue()
	monster_state = "chase"
	monster_state_timer = 10.0

func _animate_amalgam(dt: float, _move_amount: float) -> void:
	if not is_instance_valid(monster_root) or not is_instance_valid(creature_animation_driver):
		return
	var displacement: Vector3 = monster_root.global_position - creature_visual_last_position
	displacement.y = 0.0
	var speed := displacement.length() / maxf(dt, 0.001)
	if displacement.length() > 2.0:
		speed = 0.0 # A spawn/reentry is not a locomotion stride.
	var turn_speed := angle_difference(creature_visual_last_yaw, monster_root.rotation.y) / maxf(dt, 0.001)
	creature_visual_last_position = monster_root.global_position
	creature_visual_last_yaw = monster_root.rotation.y
	monster_model.rotation = Vector3(0.0, PI, 0.0)
	monster_model.position.y = 0.006 + monster_pounce_visual_arc
	var requested: StringName = &"Idle"
	var tempo := 1.0
	if predator_attack.active:
		requested = &"WindUp" if predator_attack.phase=="Windup" else (&"Attack" if predator_attack.phase=="Strike" else &"Recovery")
	elif creature_beam_hold > 0.0:
		requested = &"Retreat" if speed > 0.08 else &"Blocked"
	elif monster_pounce_timer > 0.0:
		var progress: float = 1.0 - monster_pounce_timer / MONSTER_POUNCE_DURATION
		requested = &"WindUp" if progress < 0.70 else &"Attack"
		tempo = 1.0 if progress < 0.70 else MONSTER_STRIKE_DURATION / (MONSTER_POUNCE_DURATION * 0.30)
	elif monster_strike_timer > 0.0:
		requested = &"Attack"
	elif monster_attack_windup > 0.0 or monster_pounce_windup > 0.0:
		requested = &"WindUp"
		tempo = MONSTER_ATTACK_WINDUP / MONSTER_POUNCE_WINDUP if monster_pounce_windup > 0.0 else 1.0
	elif monster_pounce_recovery_timer > 0.0:
		requested = &"Recovery"
	elif monster_light_stagger_timer > 0.0:
		requested = &"Blocked"
	elif player_in_safe_light and speed < 0.08:
		requested = &"LightStop"
	elif speed < 0.6 and absf(turn_speed) > 0.18:
		requested = &"TurnLeft" if turn_speed > 0.0 else &"TurnRight"
	elif speed > 0.06:
		requested = &"Retreat" if displacement.dot(-monster_root.global_basis.z) < -0.001 else &"Locomotion"
	elif monster_state == "suspicious" or monster_gesture_timer > 0.0:
		requested = &"Alert"
	var intent: StringName = &"Patrol"
	if requested == &"Attack": intent = &"Attack"
	elif requested == &"WindUp": intent = &"AttackWindup"
	elif requested == &"Recovery": intent = &"Recover"
	elif ceiling_escape_active or boundary_watch_active or player_in_safe_light: intent = &"LightBoundary"
	elif creature_light_state != "clear": intent = &"FlashlightStalk"
	elif monster_state == "chase": intent = &"Chase"
	elif monster_state == "flee_light": intent = &"Retreat"
	elif monster_state in ["suspicious", "investigate"]: intent = &"Alert"
	elif monster_state=="search": intent = &"Search"
	var p = flashlight_blocking_player
	if p!=null:
		var gap: float = monster_root.global_position.distance_to(p.global_position)
		creature_animation_driver.target_distance = gap
		creature_animation_driver.target_visible = monster_has_visual
		var head: Vector3 = monster_skeleton.to_global(monster_skeleton.get_bone_global_pose(creature_animation_driver.head_index).origin)
		creature_animation_driver.target_pitch = clampf(-atan2(p.camera_origin().y-head.y,maxf(gap,0.5)),-0.3,0.3)
		if intent==&"Chase" and gap<3.4: intent=&"CloseHunt"
		if intent in [&"Chase",&"CloseHunt"] and creature_dark_approach_time>0: intent=&"Reacquire"
		if intent in [&"Chase",&"CloseHunt"] and creature_notice_timer>0: intent=&"Alert"
	creature_threat_state = String(intent)
	creature_animation_driver.behavior_intent = intent
	creature_animation_driver.attack_kind = predator_attack.kind
	creature_animation_driver.heavy_attack = predator_attack.kind=="Heavy" and predator_attack.active
	creature_animation_driver.advance_visual(dt, requested, speed, monster_head_gaze_offset, turn_speed, tempo)
	if monster_pounce_timer > 0.0 and not predator_attack.active:
		creature_animation_driver.pounce_pose(1.0-monster_pounce_timer/MONSTER_POUNCE_DURATION)
	creature_animation_driver.ground_visual(dt, displacement / maxf(dt,0.001) if speed > 0.0 else Vector3.ZERO, turn_speed, monster_visual_pitch, monster_turn_lean + monster_stride_side_bias * 0.08, monster_predator_crouch)
	creature_beam_hold = maxf(0.0, creature_beam_hold - dt)
	monster_gesture_timer = maxf(0.0, monster_gesture_timer - dt)
	monster_active_animation = String(requested)

func _repath_amalgam(target: Vector3) -> void:
	if monster_navigation == null:
		return
	# Aim for physical melee reach, not the player's/beam emitter's cell centre.
	# A coarse 4 m cell may be blocked by the cone although the rear approach
	# is entirely dark. Keep the same swept collision/light rules for this link.
	if monster_state == "chase" and monster_has_visual and monster_raw_visual_strength > 0.015 and is_instance_valid(flashlight_blocking_player) and not bool(flashlight_blocking_player.horror_hidden) and not _monster_position_in_warding_light(flashlight_blocking_player.global_position):
		var prey: Vector3 = flashlight_blocking_player.global_position
		prey.y = 0.0
		var separation := monster_root.position - prey
		separation.y = 0.0
		if separation.length() > 0.01 and separation.length() < 12.0:
			var contact := prey + separation.normalized() * 1.25
			if _monster_motion_segment_valid(monster_root.position, contact):
				monster_path = [_world_cell(monster_root.position)]
				monster_path_index = monster_path.size()
				monster_path_endpoint = contact
				return
	var from_cell = _nearest_reachable_monster_cell(monster_root.position)
	var target_cell = _nearest_reachable_monster_cell(target)
	monster_path = Array(monster_navigation.get_id_path(from_cell, target_cell, true))
	if monster_path.size() <= 1 and monster_state in ["stalk", "patrol", "search", "investigate"] and (monster_root.position.distance_to(target) < 0.72 or not _monster_motion_segment_valid(monster_root.position,target)):
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var candidate: Vector2i = from_cell + direction * 2
			if not monster_navigation.is_in_boundsv(candidate) or monster_navigation.is_point_solid(candidate):
				continue
			var local_path = monster_navigation.get_id_path(from_cell, candidate, true)
			if local_path.size() > monster_path.size():
				monster_path = Array(local_path)
	monster_path_index = 1 if monster_path.size() > 1 and monster_root.position.distance_to(_cell_world(monster_path[0])) < 0.72 else 0
	monster_path_endpoint = monster_root.position
	if not monster_path.is_empty():
		monster_path_endpoint = _cell_world(monster_path.back())
		if monster_path.back() == target_cell and _monster_motion_segment_valid(monster_path_endpoint,target):
			monster_path_endpoint = target
		# Replanning must not pull the creature back to the same coarse cell on
		# every half-second update. Keep the furthest body-clear waypoint ahead.
		for index in range(mini(monster_path.size()-1,3),-1,-1):
			if _monster_motion_segment_valid(monster_root.position,_cell_world(monster_path[index])):
				monster_path_index = index
				break
		if monster_root.position.distance_squared_to(monster_path_endpoint) <= 144.0 and _monster_motion_segment_valid(monster_root.position,monster_path_endpoint):
			monster_path_index = monster_path.size()

func _nearest_reachable_monster_cell(position: Vector3) -> Vector2i:
	var origin := _world_cell(position)
	var candidates: Array[Vector2i] = []
	for z in range(-2,3):
		for x in range(-2,3):
			var cell := origin + Vector2i(x,z)
			if not monster_navigation.is_in_boundsv(cell) or monster_navigation.is_point_solid(cell):
				continue
			candidates.append(cell)
	candidates.sort_custom(func(a,b): return position.distance_squared_to(_cell_world(a)) < position.distance_squared_to(_cell_world(b)))
	for cell in candidates:
		if _monster_motion_segment_valid(position,_cell_world(cell)):
			return cell
	return _nearest_open_cell(origin)

func _advance_monster_motion(dt: float, player, desired_speed: float) -> float:
	monster_requested_motion = 0.0
	if not is_instance_valid(monster_root):
		return 0.0
	while monster_path_index < monster_path.size() and monster_root.position.distance_to(_cell_world(monster_path[monster_path_index])) < 0.72:
		monster_path_index += 1
	var retreating := creature_light_state in ["retreat","reassess","stalk"] or ceiling_escape_active or boundary_watch_active
	while retreating and not creature_retreat_path.is_empty() and monster_root.position.distance_to(creature_retreat_path[0]) < 0.18:
		creature_retreat_path.pop_front()
	var arrival_distance := 0.08 if monster_state == "chase" else 0.45
	var finished: bool = creature_retreat_path.is_empty() if retreating else (monster_path.is_empty() or (monster_path_index >= monster_path.size() and monster_root.position.distance_to(monster_path_endpoint) < arrival_distance))
	if finished or desired_speed <= 0.01:
		var settle_rate = 24.0 if monster_state == "flee_light" else 8.5
		monster_motion_velocity = monster_motion_velocity.move_toward(Vector3.ZERO, settle_rate * dt)
		monster_turn_lean = move_toward(monster_turn_lean, 0.0, dt * 4.5)
		monster_root.position = _monster_camera_clearance_position(player,dt,monster_root.position)
		return 0.0
	var steering_point = monster_path_endpoint if monster_path_index >= monster_path.size() else _cell_world(monster_path[monster_path_index])
	if retreating: steering_point = creature_retreat_path[0]
	# Look one cell through gentle corners. The path remains authoritative, but
	# the body no longer snaps to every four-metre grid centre.
	if not retreating and monster_path_index + 1 < monster_path.size():
		var lookahead = _cell_world(monster_path[monster_path_index + 1])
		if _monster_motion_segment_valid(monster_root.position, lookahead) and _monster_motion_segment_valid(monster_root.position, steering_point.lerp(lookahead, 0.46)):
			steering_point = steering_point.lerp(lookahead, 0.46)
	var path_delta = steering_point - monster_root.position
	path_delta.y = 0.0
	if path_delta.length_squared() <= 0.0001:
		return 0.0
	var path_direction = path_delta.normalized()
	var desired_direction = path_direction
	var turn_response = 15.0 if monster_state == "flee_light" else (8.2 if monster_state == "chase" else 4.8)
	if monster_steering_direction.length_squared() < 0.001:
		monster_steering_direction = desired_direction
	else:
		monster_steering_direction = monster_steering_direction.lerp(desired_direction, 1.0 - exp(-turn_response * dt)).normalized()
	var body_forward = -monster_root.transform.basis.z
	body_forward.y = 0.0
	body_forward = body_forward.normalized()
	var body_alignment = body_forward.dot(monster_steering_direction)
	# Direction comes from navigation, not a car-like body-forward arc.
	# The planted feet account for the resulting turn/diagonal displacement.
	var turn_progress = smoothstep(-0.10, 0.84, body_alignment)
	var corner_floor = 0.54 if monster_state == "flee_light" else (0.30 if monster_state == "chase" else 0.18)
	var corner_speed = lerp(corner_floor, 1.0, turn_progress)
	var locomotion_direction = monster_steering_direction
	if locomotion_direction.length_squared() < 0.001:
		locomotion_direction = monster_steering_direction
	else:
		locomotion_direction = locomotion_direction.normalized()
	var path_arrival = 1.0
	if monster_path_index + 1 >= monster_path.size() and monster_state not in ["chase", "flee_light"]:
		path_arrival = lerp(0.22, 1.0, smoothstep(0.55, 2.25, path_delta.length()))
	var desired_velocity = locomotion_direction * monster_current_speed * corner_speed * path_arrival
	if is_instance_valid(creature_animation_driver):
		desired_velocity *= lerpf(0.55,1.0,creature_animation_driver.feet.clearance_scale)
	if retreating:
		desired_velocity = locomotion_direction * monster_current_speed
	# Plant and turn through sharp bends rather than carrying lateral momentum
	# while the visual faces another direction.
	if body_alignment < 0.9 and creature_light_state == "clear" and not ceiling_escape_active:
		desired_velocity = Vector3.ZERO
		monster_motion_velocity = monster_motion_velocity.move_toward(Vector3.ZERO, 24.0 * dt)
	var velocity_response = 7.0 if monster_state in ["flee_light","chase"] else 2.45
	var previous_velocity = monster_motion_velocity
	monster_motion_velocity = monster_motion_velocity.lerp(desired_velocity, 1.0 - exp(-velocity_response * dt))
	monster_requested_motion = desired_velocity.length()
	var longitudinal_acceleration = (monster_motion_velocity - previous_velocity).dot(monster_steering_direction) / max(dt, 0.001)
	var pitch_target = clamp(-longitudinal_acceleration * 0.0042, -0.072, 0.060)
	monster_visual_pitch = lerp(monster_visual_pitch, pitch_target, 1.0 - exp(-9.0 * dt))
	var step_vector = monster_motion_velocity * dt
	if monster_state == "chase":
		var player_gap = player.global_position - monster_root.global_position
		player_gap.y = 0.0
		var maximum_step = max(0.0, player_gap.length() - MONSTER_CAMERA_CLEARANCE)
		if step_vector.length() > maximum_step:
			step_vector = step_vector.normalized() * maximum_step
	var next_position = monster_root.position + step_vector
	if not _monster_motion_segment_valid(monster_root.position, next_position):
		# Near walls the weave collapses back into the navigation line instead of
		# clipping or stopping dead.
		monster_steering_direction = path_direction
		monster_motion_velocity = path_direction * min(monster_current_speed, monster_motion_velocity.length())
		step_vector = monster_motion_velocity * dt
		next_position = monster_root.position + step_vector
		if not _monster_motion_segment_valid(monster_root.position, next_position):
			monster_motion_velocity = monster_motion_velocity.move_toward(Vector3.ZERO, 28.0 * dt)
			monster_path.clear()
			monster_repath_timer = 0.0
			return 0.0
	# Navigation and camera separation resolve a single position commit.
	next_position = _monster_camera_clearance_position(player,dt,next_position)
	step_vector = next_position-monster_root.position
	monster_root.position = next_position
	# Turn toward the path rather than residual velocity to avoid corner orbits.
	var target_yaw = atan2(-monster_steering_direction.x, -monster_steering_direction.z)
	if retreating:
		var to_player: Vector3 = player.global_position-monster_root.global_position
		target_yaw = atan2(-to_player.x,-to_player.z)
		if creature_light_state in ["stalk","retreat"] and not ceiling_escape_active:
			var travel_yaw := atan2(-path_direction.x,-path_direction.z)
			var offset := angle_difference(target_yaw,travel_yaw)
			if absf(offset)>2.4: offset=stalk_director.side*0.40
			target_yaw += clampf(offset,-0.40,0.40)*0.65
	var yaw_error = wrapf(target_yaw - monster_root.rotation.y, -PI, PI)
	var maximum_turn_rate = 1.8 if monster_state == "flee_light" else (1.5 if monster_state == "chase" else 1.35)
	var angular_target = clamp(yaw_error * turn_response, -maximum_turn_rate, maximum_turn_rate)
	var angular_response = 7.0 if monster_state == "flee_light" else (4.2 if monster_state == "chase" else 3.0)
	monster_turn_velocity = lerp(monster_turn_velocity, angular_target, 1.0 - exp(-angular_response * dt))
	monster_root.rotation.y += monster_turn_velocity * dt
	monster_turn_lean = move_toward(monster_turn_lean, clamp(monster_turn_velocity / maximum_turn_rate, -1.0, 1.0), dt * (5.5 if monster_state == "flee_light" else 2.7))
	monster_stride_phase += step_vector.length() * (2.8 if monster_state == "flee_light" else 2.1) * monster_stride_cadence
	return step_vector.length() / max(dt, 0.001)

func _monster_motion_position_valid(position: Vector3) -> bool:
	if level_manager.is_blocked_world(position + Vector3.UP * 0.48, MONSTER_BODY_RADIUS):
		return false
	return not _monster_position_in_warding_light(position, MONSTER_BODY_RADIUS) and not _position_in_handheld_light(position, MONSTER_BODY_RADIUS)

func _grid_has_clear_line(from: Vector3, to: Vector3) -> bool:
	# Shared exact prop occlusion prevents sight and melee from skipping a thin
	# tabletop between coarse grid samples. Height remains physically meaningful.
	return _handheld_line_clear(from,to)

func _world_cell(position: Vector3) -> Vector2i:
	return Vector2i(roundi(position.x / TILE), roundi(position.z / TILE))

func _cell_world(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * TILE, 0.0, float(cell.y) * TILE)

func _nearest_open_cell(origin: Vector2i) -> Vector2i:
	if monster_navigation != null and monster_navigation.is_in_boundsv(origin) and not monster_navigation.is_point_solid(origin):
		return origin
	for radius in range(1, 20):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var cell = Vector2i(x, y)
				if monster_navigation.is_in_boundsv(cell) and not monster_navigation.is_point_solid(cell):
					return cell
	return Vector2i(1, 1)

func _make_amalgam_breath_loop() -> AudioStreamWAV:
	const MIX_RATE = 16000
	const DURATION = 2.8
	var sample_count = int(MIX_RATE * DURATION)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time = float(index) / float(MIX_RATE)
		var breath = sin(time * TAU * 41.0) * 0.34 + sin(time * TAU * 62.0) * 0.18
		var throat = sin(time * TAU * (25.0 + sin(time * 1.7) * 4.0)) * 0.24
		var pulse = 0.28 + pow(0.5 + 0.5 * sin(time * TAU / DURATION * 2.0), 2.0) * 0.72
		var grain = sin(time * 1193.0) * sin(time * 173.0) * 0.08
		var value = clamp((breath + throat + grain) * pulse * 0.42, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(value * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

func _make_monster_reentry_scrape() -> AudioStreamWAV:
	const MIX_RATE = 16000
	const DURATION = 0.92
	var sample_count = int(MIX_RATE * DURATION)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time = float(index) / float(MIX_RATE)
		var phase = time / DURATION
		var attack = smoothstep(0.0, 0.08, phase)
		var release = 1.0 - smoothstep(0.56, 1.0, phase)
		var envelope = attack * release
		var metal = sin(time * TAU * (84.0 + sin(time * 11.0) * 19.0)) * 0.30
		var scrape = sin(time * 1763.0 + sin(time * 57.0) * 3.4) * sin(time * 193.0) * 0.25
		var body = sin(time * TAU * 31.0) * (0.18 + 0.12 * sin(time * 7.0))
		var value = clamp((metal + scrape + body) * envelope * 0.58, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(value * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func _make_monster_hunt_inhale() -> AudioStreamWAV:
	const MIX_RATE = 16000
	const DURATION = 0.64
	var sample_count = int(MIX_RATE * DURATION)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time = float(index) / float(MIX_RATE)
		var phase = time / DURATION
		var inhale = smoothstep(0.0, 0.12, phase) * (1.0 - smoothstep(0.62, 1.0, phase))
		var throat = sin(time * TAU * lerp(46.0, 71.0, phase)) * 0.29
		var wet_grain = sin(time * 1789.0 + sin(time * 91.0) * 2.8) * sin(time * 227.0) * 0.15
		var joint_clicks = 0.0
		for click_time in [0.17, 0.31, 0.46]:
			var click_phase = abs(time - click_time)
			if click_phase < 0.018:
				joint_clicks += sin(click_phase * TAU * 1150.0) * (1.0 - click_phase / 0.018) * 0.23
		var value = clamp((throat + wet_grain) * inhale * 0.62 + joint_clicks, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(value * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func _play_monster_hunt_cue() -> void:
	if not is_instance_valid(monster_hunt_audio) or monster_hunt_audio.playing:
		return
	monster_hunt_audio.pitch_scale = randf_range(0.91, 1.06)
	monster_hunt_audio.play()

func _make_monster_light_pain_sound() -> AudioStreamWAV:
	const MIX_RATE = 16000
	const DURATION = 0.46
	var sample_count = int(MIX_RATE * DURATION)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time = float(index) / float(MIX_RATE)
		var phase = time / DURATION
		var envelope = sin(clamp(phase, 0.0, 1.0) * PI) * (1.0 - phase * 0.42)
		var shriek = sin(time * TAU * lerp(310.0, 118.0, phase)) * 0.34
		var throat = sin(time * TAU * (73.0 + sin(time * 34.0) * 18.0)) * 0.38
		var burn_hiss = sin(time * 1987.0) * sin(time * 643.0) * 0.24
		var value = clamp((shriek + throat + burn_hiss) * envelope * 0.72, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(value * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func _collect_fragment(fragment: Dictionary) -> void:
	fragment["collected"] = true
	fragments_collected += 1
	var node: Node3D = fragment["node"]
	var tween = create_tween().bind_node(node).set_parallel(true)
	tween.tween_property(node, "scale", Vector3(2.6, 2.6, 2.6), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", node.position.y + 0.75, 0.22)
	tween.chain().tween_property(node, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(node.queue_free)
	fragment_collected.emit(fragments_collected, FRAGMENT_TOTAL)
	if fragments_collected >= FRAGMENT_TOTAL:
		_unlock_exit()

func _unlock_exit() -> void:
	if is_instance_valid(exit_light):
		exit_light.light_color = Color8(185, 218, 164)
		exit_light.light_energy = 2.8
	if is_instance_valid(exit_panel):
		exit_panel.material_override = _glow_material(Color8(155, 201, 139), 3.0)

func _build_merged_walls(raw: Array) -> void:
	const LIGHTING_CHUNK_CELLS = 4
	var chunk_faces: Dictionary = {}
	for row in raw.size():
		var line = String(raw[row])
		for col in line.length():
			if line.substr(col, 1) != "#":
				continue
			var chunk_key = Vector2i(floori(float(col) / LIGHTING_CHUNK_CELLS), floori(float(row) / LIGHTING_CHUNK_CELLS))
			if not chunk_faces.has(chunk_key):
				chunk_faces[chunk_key] = []
			var faces: Array = chunk_faces[chunk_key]
			var x0 = float(col) * TILE - TILE * 0.5
			var x1 = x0 + TILE
			var z0 = float(row) * TILE - TILE * 0.5
			var z1 = z0 + TILE
			if not _maze_cell_solid(raw, row, col - 1):
				_append_labyrinth_face(faces, [Vector3(x0, 0, z1), Vector3(x0, 0, z0), Vector3(x0, WALL_HEIGHT, z0), Vector3(x0, WALL_HEIGHT, z1), Vector3.LEFT])
			if not _maze_cell_solid(raw, row, col + 1):
				_append_labyrinth_face(faces, [Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x1, WALL_HEIGHT, z1), Vector3(x1, WALL_HEIGHT, z0), Vector3.RIGHT])
			if not _maze_cell_solid(raw, row - 1, col):
				_append_labyrinth_face(faces, [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, WALL_HEIGHT, z0), Vector3(x0, WALL_HEIGHT, z0), Vector3.BACK])
			if not _maze_cell_solid(raw, row + 1, col):
				_append_labyrinth_face(faces, [Vector3(x1, 0, z1), Vector3(x0, 0, z1), Vector3(x0, WALL_HEIGHT, z1), Vector3(x1, WALL_HEIGHT, z1), Vector3.FORWARD])
	for chunk_key in chunk_faces.keys():
		var faces: Array = chunk_faces[chunk_key]
		if faces.is_empty():
			continue
		var builder = SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for face in faces:
			_append_wall_quad(builder, face[0], face[1], face[2], face[3], face[4])
		var walls = MeshInstance3D.new()
		walls.name = "LabyrinthWalls_%02d_%02d" % [chunk_key.x, chunk_key.y]
		walls.mesh = builder.commit()
		walls.material_override = wall_material
		add_child(walls)

func _append_labyrinth_face(faces: Array, face: Array) -> void:
	faces.append(face)

func _maze_cell_solid(raw: Array, row: int, col: int) -> bool:
	if row < 0 or row >= raw.size():
		return false
	var line = String(raw[row])
	return col >= 0 and col < line.length() and line.substr(col, 1) == "#"

func _append_wall_quad(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for vertex in [a, b, c, a, c, d]:
		builder.set_normal(normal)
		builder.add_vertex(vertex)

func _build_corridor_dressing(raw: Array) -> void:
	var metal := _flat_material(Color8(55, 60, 56), 0.78)
	var dark := _flat_material(Color8(24, 27, 25), 0.87)
	var cardboard := _make_concrete_shader(Color(0.31, 0.25, 0.16), 0.25, 0.96)
	var paper := _flat_material(Color8(151, 142, 114), 0.96)
	for row in range(1, raw.size() - 1):
		for col in range(1, String(raw[row]).length() - 1):
			if String(raw[row]).substr(col, 1) == "#":
				continue
			var pos := _cell_world(Vector2i(col, row))
			# Dress the opening service route, never the already authored kitchen.
			if _inside_kitchen_art_zone(pos) or pos.z < 430.0 or pos.x > 184.0:
				continue
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not _maze_cell_solid(raw, row + direction.y, col + direction.x):
					continue
				var bay := Node3D.new()
				bay.name = "ServiceBay_%d_%d_%d_%d" % [col, row, direction.x, direction.y]
				bay.position = pos + Vector3(direction.x, 0, direction.y) * (TILE * 0.5 - 0.015)
				bay.rotation.y = atan2(-float(direction.x), -float(direction.y))
				add_child(bay)
				# Segments join along the wall, with brackets and a low skirting strip.
				_add_box(bay, Vector3(4.0, 0.12, 0.07), Vector3(0, 0.08, 0.035), dark)
				for pipe_y in [3.12, 3.31]:
					var pipe := MeshInstance3D.new()
					var cylinder := CylinderMesh.new()
					cylinder.top_radius = 0.045
					cylinder.bottom_radius = 0.045
					cylinder.height = 4.0
					cylinder.radial_segments = 8
					pipe.mesh = cylinder
					pipe.rotation.z = PI * 0.5
					pipe.position = Vector3(0, pipe_y, 0.14)
					pipe.material_override = metal
					bay.add_child(pipe)
				_add_box(bay, Vector3(0.06, 0.37, 0.21), Vector3(0, 3.22, 0.1), dark)
				if (row + col) % 2 == 0:
					_add_service_bay_prop(bay, absi(col * 13 + row * 7 + direction.x * 3 + direction.y) % 5, metal, dark, cardboard, paper)
				_merge_service_bay_meshes(bay)
				for child in bay.get_children():
					if child is GeometryInstance3D:
						child.visibility_range_end = 44.0
						child.visibility_range_end_margin = 8.0

func _merge_service_bay_meshes(bay: Node3D) -> void:
	# One draw per material/bay instead of separate draws for every shelf screw.
	var builders: Dictionary = {}
	for child in bay.get_children():
		if not child is MeshInstance3D:
			continue
		var material: Material = child.material_override
		if not builders.has(material):
			var builder := SurfaceTool.new()
			builder.begin(Mesh.PRIMITIVE_TRIANGLES)
			builders[material] = builder
		builders[material].append_from(child.mesh, 0, child.transform)
		child.free()
	for material in builders:
		var merged := MeshInstance3D.new()
		merged.mesh = builders[material].commit()
		merged.material_override = material
		bay.add_child(merged)

func _add_service_bay_prop(bay: Node3D, kind: int, metal: Material, dark: Material, cardboard: Material, paper: Material) -> void:
	if kind == 0: # Recessed electrical panel and conduit.
		_add_box(bay, Vector3(0.66, 0.90, 0.14), Vector3(0, 1.95, 0.09), metal)
		_add_box(bay, Vector3(0.025, 0.20, 0.04), Vector3(0.22, 1.92, 0.18), dark)
		_add_box(bay, Vector3(0.035, 0.75, 0.04), Vector3(-0.19, 2.77, 0.035), metal)
		_add_box(bay, Vector3(0.21, 0.21, 0.01), Vector3(0, 2.06, 0.166), cardboard)
	elif kind == 1: # Pinboard with uneven, faded paper notices (no HUD text).
		_add_box(bay, Vector3(1.10, 0.82, 0.06), Vector3(0, 1.92, 0.035), dark)
		_add_box(bay, Vector3(1.01, 0.73, 0.02), Vector3(0, 1.92, 0.075), cardboard)
		for i in 3:
			_add_box(bay, Vector3(0.23, 0.34 + i * 0.04, 0.012), Vector3(-0.32 + i * 0.31, 1.95 - i * 0.05, 0.095), paper)
		_add_box(bay, Vector3(0.80, 0.42, 0.08), Vector3(0, 2.88, 0.04), dark)
		for i in 6:
			_add_box(bay, Vector3(0.72, 0.022, 0.025), Vector3(0, 2.73 + i * 0.057, 0.09), metal)
	else:
		var height := 2.12 if kind != 4 else 0.91
		var width := 0.96 if kind == 2 else 1.22
		if kind == 2: # Old double service cabinet, not an interactive hiding locker.
			_add_box(bay, Vector3(width, height, 0.40), Vector3(0, height * 0.5, 0.21), metal)
			for x in [-0.23, 0.23]:
				_add_box(bay, Vector3(0.445, 1.95, 0.025), Vector3(x, 1.09, 0.425), dark)
				_add_box(bay, Vector3(0.41, 1.92, 0.025), Vector3(x, 1.09, 0.445), metal)
				_add_box(bay, Vector3(0.025, 0.17, 0.025), Vector3(x + 0.13, 1.13, 0.47), dark)
				for i in 3:
					_add_box(bay, Vector3(0.24, 0.022, 0.012), Vector3(x, 1.79 + i * 0.07, 0.463), dark)
		else: # Wall-hugging storage rack / two-tier service trolley.
			for x in [-0.58, 0.58]:
				for z in [0.08, 0.54]:
					_add_box(bay, Vector3(0.045, height, 0.045), Vector3(x, height * 0.5 + 0.06, z), metal)
			for y in ([0.18, 0.86, 1.54] if kind == 3 else [0.17, 0.73]):
				_add_box(bay, Vector3(1.22, 0.045, 0.52), Vector3(0, y, 0.30), metal)
				_add_box(bay, Vector3(0.49, 0.32, 0.39), Vector3(-0.23, y + 0.18, 0.30), cardboard)
				_add_box(bay, Vector3(0.06, 0.012, 0.39), Vector3(-0.23, y + 0.346, 0.30), paper)
			if kind == 4:
				for x in [-0.52, 0.52]:
					_add_box(bay, Vector3(0.12, 0.13, 0.14), Vector3(x, 0.08, 0.40), dark)
		# Keep the central 2.8+ metres open; register rotated bounds correctly.
		var extent := bay.basis.x.abs() * width * 0.5 + bay.basis.z.abs() * 0.30
		level_manager.solid_areas.append({"center": bay.to_global(Vector3(0, height * 0.5, 0.30)), "half": Vector2(extent.x, extent.z), "height": height, "dressing_owner":bay.get_instance_id()})

func _add_corridor_mist_patch(pos: Vector3, color: Color, index: int, opacity: float) -> void:
	var root = Node3D.new()
	root.name = "LocalMist_%02d" % index
	root.position = pos + Vector3(0, 0.88, 0)
	add_child(root)
	var material = _corridor_mist_material(color, opacity)
	for layer in range(2):
		var mist_card = MeshInstance3D.new()
		mist_card.name = "MistLayer_%d" % layer
		var mesh = QuadMesh.new()
		mesh.size = Vector2(7.4 - layer * 0.8, 2.85 + layer * 0.2)
		mist_card.mesh = mesh
		mist_card.position = Vector3((layer - 0.5) * 1.55, (layer - 0.5) * 0.28, (layer - 0.5) * 1.20)
		mist_card.material_override = material
		mist_card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mist_card)

func _corridor_mist_material(color: Color, opacity: float) -> ShaderMaterial:
	var cache_key = "mist_%s_%.3f" % [color.to_html(false), opacity]
	if mist_material_cache.has(cache_key):
		return mist_material_cache[cache_key]
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 mist_color : source_color;
void vertex() { MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]); }
void fragment() {
	vec2 p = UV - vec2(0.5);
	float radius = length(p);
	float soft = exp(-radius * radius * 7.4);
	float drift = 0.72 + 0.18 * sin(UV.x * 13.0 + TIME * 0.10) + 0.10 * sin(UV.y * 21.0 - TIME * 0.07);
	float alpha = mist_color.a * soft * soft * drift * 0.46;
	ALBEDO = mix(vec3(0.020), mist_color.rgb, 0.52);
	EMISSION = mist_color.rgb * 0.12;
	ALPHA = alpha;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("mist_color", Color(color.r, color.g, color.b, opacity))
	mist_material_cache[cache_key] = material
	return material


func _fixture_cell_is_spaced(candidate: Vector2, existing: Array[Vector2], minimum_distance: float) -> bool:
	for cell in existing:
		if candidate.distance_to(cell) < minimum_distance:
			return false
	return true

func _add_ceiling_fixture(pos: Vector3, index: int, dark_metal: Material, pale_light: Material, _red_light: Material, _cyan_light: Material, _amber_light: Material) -> void:
	var fixture := Node3D.new()
	fixture.name = "SafeCeilingFixture_%03d" % index
	var height := WALL_HEIGHT - 0.25
	if task_anchors.has("kitchen"):
		var local := pos - Vector3(task_anchors["kitchen"])
		if absf(local.x) < 2.5 and local.z > 2.3 and local.z < 28.0:
			height = 2.44
	fixture.position = pos + Vector3.UP * height
	add_child(fixture)
	_add_box(fixture, Vector3(1.4, 0.12, 0.30), Vector3.ZERO, dark_metal)
	var tube := _add_box(fixture, Vector3(1.18, 0.025, 0.18), Vector3(0, -0.07, 0), pale_light)
	fixture.set_meta("cycle_tube", tube)
	var light := SpotLight3D.new()
	light.name = "SafeDownlight"
	light.position.y = -0.10
	light.rotation_degrees.x = -90.0
	light.light_color = Color8(222, 209, 169)
	light.light_energy = 24.0
	light.spot_angle = rad_to_deg(atan(3.8 / (height - 0.10)))
	light.spot_range = height + 1.7
	light.spot_attenuation = 0.65
	light.spot_angle_attenuation = 0.65
	light.shadow_enabled = true
	light.shadow_bias = 0.025
	light.shadow_normal_bias = 0.15
	light.distance_fade_enabled = true
	light.distance_fade_begin = 28.0
	light.distance_fade_length = 8.0
	light.distance_fade_shadow = 24.0
	fixture.add_child(light)
	_register_monster_warding_light(fixture.global_position, 1.0, true)
	for ward in monster_warding_lights:
		if Vector3(ward.position).distance_to(pos) < 0.35:
			fixture.set_meta("cycle_ward", ward)
			break
	route_light_positions.append(pos)

func _add_fixture_light_shaft(parent: Node3D, color: Color, opacity: float) -> void:
	# Two nested frustums make the fixture and its floor pool read as one
	# continuous volume instead of two disconnected bright shapes.
	_add_fixture_light_cone(parent, color, opacity * 1.85, 0.08, 1.25)
	_add_fixture_light_cone(parent, color, opacity * 0.72, 0.24, 2.10)

func _add_fixture_light_cone(parent: Node3D, color: Color, opacity: float, top_radius: float, bottom_radius: float) -> void:
	var shaft_height = WALL_HEIGHT - 0.34
	var shaft = MeshInstance3D.new()
	shaft.name = "AtmosphericLightCone"
	var mesh = CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = shaft_height
	mesh.radial_segments = 20
	mesh.rings = 2
	mesh.cap_top = false
	mesh.cap_bottom = false
	shaft.mesh = mesh
	shaft.position = Vector3(0, -0.20 - shaft_height * 0.5, 0)
	shaft.material_override = _fixture_light_shaft_material(color, opacity)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(shaft)

func _add_fixture_floor_pool(parent: Node3D, color: Color, opacity: float) -> void:
	_add_fixture_floor_pool_layer(
		parent,
		"FixtureFloorSpill",
		Vector2(11.5, 9.0),
		-WALL_HEIGHT + 0.26,
		color,
		clamp(opacity * 0.72, 0.32, 0.52),
		1.10
	)
	_add_fixture_floor_pool_layer(
		parent,
		"FixtureFloorCore",
		Vector2(6.4, 5.0),
		-WALL_HEIGHT + 0.275,
		color,
		clamp(opacity * 0.82, 0.38, 0.62),
		1.50
	)

func _add_fixture_floor_pool_layer(parent: Node3D, pool_name: String, pool_size: Vector2, y_offset: float, color: Color, opacity: float, brightness: float) -> void:
	var pool = MeshInstance3D.new()
	pool.name = pool_name
	var mesh = QuadMesh.new()
	mesh.size = pool_size
	pool.mesh = mesh
	pool.position = Vector3(0, y_offset, 0)
	pool.rotation_degrees.x = -90.0
	pool.material_override = _fixture_floor_pool_material(color, opacity, brightness)
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pool)

func _fixture_floor_pool_material(color: Color, opacity: float, brightness: float) -> ShaderMaterial:
	var cache_key = "floor_pool_%s_%.3f_%.3f" % [color.to_html(false), opacity, brightness]
	if fixture_pool_material_cache.has(cache_key):
		return fixture_pool_material_cache[cache_key]
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 pool_color : source_color;
uniform float brightness = 1.0;
void fragment() {
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	vec2 ellipse = centered * vec2(0.68, 1.0);
	float radial = dot(ellipse, ellipse);
	float core = 1.0 - smoothstep(0.0, 0.36, radial);
	float spill = 1.0 - smoothstep(0.10, 1.0, radial);
	float intensity = clamp(spill * 0.72 + core * 0.28, 0.0, 1.0);
	ALBEDO = pool_color.rgb * (0.35 + intensity * 0.25);
	EMISSION = pool_color.rgb * intensity * brightness;
	ALPHA = pool_color.a * intensity;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("pool_color", Color(color.r, color.g, color.b, opacity))
	material.set_shader_parameter("brightness", brightness)
	fixture_pool_material_cache[cache_key] = material
	return material

func _fixture_light_shaft_material(color: Color, opacity: float) -> ShaderMaterial:
	var cache_key = "shaft_%s_%.3f" % [color.to_html(false), opacity]
	if light_shaft_material_cache.has(cache_key):
		return light_shaft_material_cache[cache_key]
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 shaft_color : source_color;
void fragment() {
	float vertical_fade = smoothstep(0.0, 0.07, UV.y) * (1.0 - smoothstep(0.90, 1.0, UV.y));
	float view_edge = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 0.72);
	float volume = mix(0.28, 1.0, view_edge);
	float air = 0.94 + 0.06 * sin(UV.y * 23.0 + TIME * 0.10);
	ALBEDO = shaft_color.rgb * 0.025;
	EMISSION = shaft_color.rgb * (0.18 + volume * 0.46);
	ALPHA = shaft_color.a * vertical_fade * volume * air;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shaft_color", Color(color.r, color.g, color.b, opacity))
	light_shaft_material_cache[cache_key] = material
	return material

func _register_shader_light(position: Vector3, color: Color, strength: float, priority: bool = false, safe_zone: bool = false, flickers: bool = false, flicker_phase: float = 0.0, faulty: bool = false) -> void:
	_register_monster_warding_light(position, strength, safe_zone, flickers, flicker_phase, faulty)
	if shader_light_positions.size() < 32:
		shader_light_positions.append(position)
		shader_light_colors.append(Vector3(color.r, color.g, color.b))
		shader_light_strengths.append(strength)
		return
	if not priority:
		return
	var weakest_index := 0
	var weakest_strength := float(shader_light_strengths[0])
	for light_index in range(1, shader_light_strengths.size()):
		if float(shader_light_strengths[light_index]) < weakest_strength:
			weakest_strength = float(shader_light_strengths[light_index])
			weakest_index = light_index
	shader_light_positions[weakest_index] = position
	shader_light_colors[weakest_index] = Vector3(color.r, color.g, color.b)
	shader_light_strengths[weakest_index] = strength

func _register_monster_warding_light(position: Vector3, strength: float, safe_zone: bool = false, flickers: bool = false, flicker_phase: float = 0.0, faulty: bool = false) -> void:
	ward_spatial_count = -1
	var horizontal_position = Vector3(position.x, 0.0, position.z)
	var radius = SAFE_LIGHT_RADIUS
	for ward in monster_warding_lights:
		var existing: Vector3 = ward["position"]
		if existing.distance_to(horizontal_position) < 0.35:
			ward["radius"] = max(float(ward["radius"]), radius)
			ward["strength"] = max(float(ward.get("strength", 0.0)), strength)
			ward["safe_zone"] = bool(ward.get("safe_zone", false)) or safe_zone
			return
	monster_warding_lights.append({
		"position": horizontal_position,
		"radius": radius,
		"strength": strength,
		"safe_zone": safe_zone,
		"flickers": flickers,
		"phase": flicker_phase,
		"faulty": faulty
	})

func _refresh_cycle_navigation(ward: Dictionary) -> void:
	if monster_navigation == null: return
	var center := _world_cell(ward.position)
	# Only the small footprint changes; never rebuild the full map per frame.
	for z in range(center.y - 2, center.y + 3):
		for x in range(center.x - 2, center.x + 3):
			var cell := Vector2i(x, z)
			if not monster_navigation.is_in_boundsv(cell): continue
			var pos := _cell_world(cell)
			var blocked: bool = level_manager.is_blocked_world(pos + Vector3.UP * 0.48, MONSTER_BODY_RADIUS) or _monster_position_in_warding_light(pos, MONSTER_BODY_RADIUS)
			monster_navigation.set_point_solid(cell, blocked)
			if blocked: monster_open_cells.erase(cell)
			elif not monster_open_cells.has(cell): monster_open_cells.append(cell)
	monster_path.clear()
	monster_repath_timer = 0.0
	monster_static_light_update_timer = 0.0

func _ceiling_escape_segment_allowed(from: Vector3, to: Vector3) -> bool:
	if ward_spatial_count!=monster_warding_lights.size(): _monster_position_in_warding_light(from)
	var nearby := {}
	for z in range(floori((minf(from.z,to.z)-MONSTER_BODY_RADIUS)/8.0),floori((maxf(from.z,to.z)+MONSTER_BODY_RADIUS)/8.0)+1):
		for x in range(floori((minf(from.x,to.x)-MONSTER_BODY_RADIUS)/8.0),floori((maxf(from.x,to.x)+MONSTER_BODY_RADIUS)/8.0)+1):
			for index in ward_spatial_buckets.get(Vector2i(x,z),[]): nearby[index]=true
	for index in nearby:
		var ward: Dictionary = monster_warding_lights[index]
		if not ward.safe_zone or not bool(ward.get("cycle_active", true)): continue
		var radius: float = ward.radius + MONSTER_BODY_RADIUS
		var new_distance := Vector3(to.x, 0, to.z).distance_squared_to(ward.position)
		if new_distance >= radius * radius: continue
		var old_distance := Vector3(from.x, 0, from.z).distance_squared_to(ward.position)
		if new_distance < old_distance - 0.0001:
			return false
	return true

func _hold_ceiling_light_boundary(dt: float, player) -> bool:
	var center := Vector3.INF
	for ward in monster_warding_lights:
		if not ward.has("cycle_active") or not ward.cycle_active: continue
		if monster_root.position.distance_to(ward.position) < float(ward.radius) + MONSTER_BODY_RADIUS + 0.05 and _grid_has_clear_line(monster_root.position + Vector3.UP * 0.5, Vector3(ward.position) + Vector3.UP * 0.5):
			center = ward.position
			break
	if center == Vector3.INF:
		if ceiling_escape_active:
			ceiling_escape_active = false
			creature_retreat_path.clear()
			monster_steering_direction = Vector3.ZERO
			monster_repath_timer = 0.0
		return false
	ceiling_escape_active = true
	predator_attack.cancel(self)
	monster_attack_windup = 0.0
	monster_strike_timer = 0.0
	monster_pounce_windup = 0.0
	monster_pounce_timer = 0.0
	monster_pounce_visual_arc = predator_attack.interrupted_landing
	creature_beam_hold = 0.12
	var best := Vector3.INF
	var score := -INF
	for i in 16:
		var angle := TAU * i / 16.0
		var next := monster_root.position + Vector3(cos(angle), 0, sin(angle)) * 0.55
		if not _monster_motion_segment_valid(monster_root.position, next): continue
		var value := next.distance_to(center)
		if value > score:
			score = value
			best = next
	creature_retreat_path.clear()
	if best != Vector3.INF: creature_retreat_path.append(best)
	monster_current_speed = move_toward(monster_current_speed, 1.4, dt * 3.5)
	var moved := _advance_monster_motion(dt, player, monster_current_speed)
	_animate_amalgam(dt, moved)
	return true

func _ward_light_pulse(ward: Dictionary) -> float:
	if ward.has("cycle_pulse"):
		return float(ward.cycle_pulse)
	if not bool(ward.get("flickers", false)):
		return 1.0
	var phase = float(ward.get("phase", 0.0))
	var pulse = 0.94 + sin(elapsed * 5.1 + phase) * 0.06
	if bool(ward.get("faulty", false)) and fmod(elapsed * 1.7 + phase, 7.0) < 0.24:
		pulse *= 0.08
	return pulse

func _monster_position_in_warding_light(position: Vector3, margin: float = 0.0) -> bool:
	var horizontal_position = Vector3(position.x, 0.0, position.z)
	if ward_spatial_count != monster_warding_lights.size():
		ward_spatial_buckets.clear()
		for index in monster_warding_lights.size():
			var ward: Dictionary = monster_warding_lights[index]
			if not bool(ward.get("safe_zone",false)):
				continue
			var center: Vector3 = ward.position
			var radius: float = ward.radius
			for z in range(floori((center.z-radius)/8.0),floori((center.z+radius)/8.0)+1):
				for x in range(floori((center.x-radius)/8.0),floori((center.x+radius)/8.0)+1):
					var key := Vector2i(x,z)
					if not ward_spatial_buckets.has(key): ward_spatial_buckets[key]=[]
					ward_spatial_buckets[key].append(index)
		ward_spatial_count=monster_warding_lights.size()
	var nearby: Dictionary = {}
	for z in range(floori((position.z-margin)/8.0),floori((position.z+margin)/8.0)+1):
		for x in range(floori((position.x-margin)/8.0),floori((position.x+margin)/8.0)+1):
			for index in ward_spatial_buckets.get(Vector2i(x,z),[]): nearby[index]=true
	for index in nearby:
		var ward: Dictionary = monster_warding_lights[index]
		if not bool(ward.get("cycle_active", true)):
			continue
		if horizontal_position.distance_squared_to(ward.position) <= pow(float(ward.radius)+margin,2) and _grid_has_clear_line(position + Vector3.UP * 0.5, Vector3(ward.position) + Vector3.UP * 0.5):
			return true
	return false

func _sync_fixture_shader_lights() -> void:
	for material in flashlight_reactive_materials:
		if material == null:
			continue
		material.set_shader_parameter("fixture_count", shader_light_positions.size())
		material.set_shader_parameter("fixture_positions", shader_light_positions)
		material.set_shader_parameter("fixture_colors", shader_light_colors)
		material.set_shader_parameter("fixture_strengths", shader_light_strengths)

func _add_pipe_cluster(pos: Vector3, material: Material) -> void:
	var root = Node3D.new()
	root.position = pos + Vector3(0, WALL_HEIGHT - 0.30, 0)
	add_child(root)
	for offset in [-0.20, 0.0, 0.20]:
		var pipe = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.top_radius = 0.045
		mesh.bottom_radius = 0.045
		mesh.height = 3.3
		mesh.radial_segments = 6
		pipe.mesh = mesh
		pipe.rotation_degrees = Vector3(90, 0, 0)
		pipe.position = Vector3(offset, 0, 0)
		pipe.material_override = material
		pipe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(pipe)

func _add_service_marker(pos: Vector3, glow: Material, metal: Material) -> void:
	var root = Node3D.new()
	root.position = pos + Vector3(0, 1.35, -1.78)
	add_child(root)
	_add_box(root, Vector3(0.86, 0.54, 0.05), Vector3.ZERO, metal)
	_add_box(root, Vector3(0.62, 0.07, 0.058), Vector3(0, 0.11, -0.01), glow)
	_add_box(root, Vector3(0.38, 0.045, 0.058), Vector3(-0.12, -0.08, -0.01), glow)

func _add_memory_fragment(pos: Vector3, task_id: String = "") -> void:
	var root = Node3D.new()
	root.name = "MemoryFragment_%d" % (fragments.size() + 1)
	root.position = pos + Vector3(0, 1.05, 0)
	add_child(root)
	var core_material = _make_memory_shader(float(fragments.size()))
	var frame_material = _flat_material(Color8(26, 27, 25), 0.60)
	for i in 3:
		var shard = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.12 + i * 0.04, 0.72 - i * 0.13, 0.10 + i * 0.03)
		shard.mesh = mesh
		shard.position = Vector3((i - 1) * 0.22, (i % 2) * 0.12, 0)
		shard.rotation_degrees = Vector3(i * 13.0, i * 34.0, -12.0 + i * 11.0)
		shard.material_override = core_material
		root.add_child(shard)
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.47
	torus.rings = 16
	torus.ring_segments = 6
	ring.mesh = torus
	ring.material_override = frame_material
	root.add_child(ring)
	var light = OmniLight3D.new()
	light.light_color = Color8(164, 190, 159)
	light.light_energy = 2.3
	light.omni_range = 5.2
	light.omni_attenuation = 1.55
	root.add_child(light)
	fragments.append({"node": root, "base_y": root.position.y, "phase": fragments.size() * 1.9, "collected": false, "task": task_id})

func _build_exit_marker() -> void:
	var root = Node3D.new()
	root.name = "MemoryExit"
	root.position = exit_position
	add_child(root)
	var frame_mat = _flat_material(Color8(19, 20, 19), 0.72)
	for x in [-1.42, 1.42]:
		_add_box(root, Vector3(0.24, 3.2, 0.28), Vector3(x, 1.6, 0), frame_mat)
	_add_box(root, Vector3(3.08, 0.24, 0.28), Vector3(0, 3.08, 0), frame_mat)
	exit_panel = _add_box(root, Vector3(1.65, 0.11, 0.08), Vector3(0, 2.72, -0.18), _glow_material(Color8(126, 30, 25), 2.2))
	exit_light = OmniLight3D.new()
	exit_light.position = Vector3(0, 2.25, 0)
	exit_light.light_color = Color8(145, 36, 29)
	exit_light.light_energy = 1.5
	exit_light.omni_range = 6.4
	exit_light.omni_attenuation = 1.7
	root.add_child(exit_light)
	# The exit marker is not a safe light; its overhead route fixture is.

func _update_lights(dt: float) -> void:
	flicker_light_update_timer -= dt
	if flicker_light_update_timer > 0.0:
		return
	flicker_light_update_timer += FLICKER_LIGHT_UPDATE_INTERVAL
	if flicker_light_update_timer <= 0.0:
		flicker_light_update_timer = FLICKER_LIGHT_UPDATE_INTERVAL
	for item in flicker_lights:
		var light: Light3D = item["light"]
		if not is_instance_valid(light):
			continue
		var pulse = 0.94 + sin(elapsed * 5.1 + float(item["phase"])) * 0.06
		if bool(item["faulty"]) and fmod(elapsed * 1.7 + float(item["phase"]), 7.0) < 0.24:
			pulse *= 0.08
		if is_instance_valid(monster_root) and monster_distress_blend > 0.08:
			var monster_distance = light.global_position.distance_to(monster_root.global_position)
			if monster_distance < 10.0:
				var disturbance = (1.0 - monster_distance / 10.0) * monster_distress_blend
				var nervous_flutter = 0.72 + sin(elapsed * 19.0 + float(item["phase"]) * 1.31) * 0.18
				pulse *= 1.0 - disturbance * nervous_flutter * 0.32
		light.light_energy = float(item["base"]) * pulse

func _update_flashlight_materials(dt: float, player) -> void:
	if player == null:
		return
	flashlight_surface_update_timer -= dt
	if flashlight_surface_update_timer > 0.0:
		return
	flashlight_surface_update_timer += FLASHLIGHT_SURFACE_UPDATE_INTERVAL
	if flashlight_surface_update_timer <= 0.0:
		flashlight_surface_update_timer = FLASHLIGHT_SURFACE_UPDATE_INTERVAL
	var enabled = bool(player.horror_flashlight_mode) and bool(player.flashlight_on)
	# Surface response follows the same physical lens as every SpotLight3D.
	# Using the camera here creates a second floor impact beside the held torch.
	var origin = player.flashlight_beam_origin() if player.has_method("flashlight_beam_origin") else player.camera_origin()
	var direction = player.flashlight_beam_direction().normalized() if player.has_method("flashlight_beam_direction") else player.aim_dir().normalized()
	for material in flashlight_reactive_materials:
		if material == null:
			continue
		material.set_shader_parameter("flashlight_enabled", enabled)
		material.set_shader_parameter("flashlight_origin", origin)
		material.set_shader_parameter("flashlight_direction", direction)

func _add_box(parent: Node3D, box_size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = box_size
	node.mesh = mesh
	node.position = position
	node.material_override = material
	parent.add_child(node)
	return node

func _add_structure_box(parent: Node3D, box_size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	# These are ordinary authored solids registered through the same collision list
	# used by the rest of the level. No grid-cell replacement or kitchen-specific
	# movement exception is involved.
	var node := _add_box(parent, box_size, position, material)
	var center := node.global_position
	level_manager.solid_areas.append({
		"center": center,
		"half": Vector2(box_size.x * 0.5, box_size.z * 0.5),
		"height": box_size.y
	})
	return node

func _flat_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _dim_lit_material(color: Color, roughness: float, _emission_energy: float) -> StandardMaterial3D:
	var material = _flat_material(color, roughness)
	return material

func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material = _flat_material(color, 0.34)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _make_concrete_shader(base_color: Color, grime: float, roughness: float) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;
uniform vec3 base_color = vec3(0.1);
uniform float grime = 0.3;
uniform float roughness_value = 0.9;
uniform float metallic_value = 0.0;
uniform int surface_kind = 0;
uniform float ambient_lift = 0.0;
uniform bool flashlight_enabled = false;
uniform vec3 flashlight_origin = vec3(0.0);
uniform vec3 flashlight_direction = vec3(0.0, 0.0, -1.0);
uniform int fixture_count = 0;
uniform vec3 fixture_positions[32];
uniform vec3 fixture_colors[32];
uniform float fixture_strengths[32];
varying vec3 world_position;
float hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x), mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
float filtered_noise(vec2 p) {
	float footprint = max(length(dFdx(p)), length(dFdy(p)));
	if (footprint >= 1.5) { return 0.5; }
	return mix(noise(p), 0.5, smoothstep(0.5, 1.5, footprint));
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = floor(world_position.xz * 2.1);
	float n = hash(p) * 0.55 + hash(floor(p * 0.23)) * 0.45;
	float stain = smoothstep(0.52, 0.98, n) * grime;
	vec3 surface_color = base_color * (0.78 + n * 0.25 - stain * 0.30);
	if (surface_kind == 1) {
		vec2 wall_uv = vec2(world_position.x + world_position.z, world_position.y);
		float damp = noise(wall_uv * vec2(1.1, 0.6));
		float plaster = filtered_noise(wall_uv * 72.0);
		float streak = noise(wall_uv * vec2(7.0, 0.7)) * noise(wall_uv * 1.8);
		float band = 1.0 - smoothstep(1.19, 1.21, world_position.y);
		surface_color = mix(base_color * vec3(1.08, 1.02, 0.88), vec3(0.13, 0.15, 0.135), band);
		surface_color *= 0.69 + damp * 0.35 + plaster * 0.13;
			surface_color *= 1.0 - smoothstep(0.35, 0.85, streak) * grime * 0.6;
		surface_color *= mix(0.56, 1.0, smoothstep(0.0, 0.32, world_position.y));
	} else if (surface_kind == 2) {
		vec2 tile_uv = world_position.xz / 0.65;
		// Integrate thin grout over a pixel footprint, instead of sampling a
		// subpixel hard line (which became dotted/shimmering diagonal bands).
		vec2 footprint = max(fwidth(tile_uv), vec2(0.0001));
		vec2 hi = tile_uv + vec2(0.014) + footprint * 0.5;
		vec2 lo = tile_uv + vec2(0.014) - footprint * 0.5;
		vec2 integral_hi = floor(hi) * 0.028 + min(fract(hi), vec2(0.028));
		vec2 integral_lo = floor(lo) * 0.028 + min(fract(lo), vec2(0.028));
		vec2 lines = clamp((integral_hi - integral_lo) / footprint, vec2(0.0), vec2(1.0));
		float grout = 1.0 - max(lines.x, lines.y);
		float tile = hash(floor(tile_uv));
		float wear = filtered_noise(world_position.xz * 8.0) * 0.14 + filtered_noise(world_position.xz * 95.0) * 0.07;
		surface_color = base_color * (0.57 + tile * 0.35 + wear);
		surface_color *= mix(0.40, 1.0, grout);
	}
	ALBEDO = surface_color;
	ROUGHNESS = clamp(roughness_value + stain * 0.08, 0.0, 1.0);
	METALLIC = metallic_value;
	SPECULAR = 0.18;
	EMISSION = vec3(0.0);
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Vector3(base_color.r, base_color.g, base_color.b))
	material.set_shader_parameter("grime", grime)
	material.set_shader_parameter("roughness_value", roughness)
	flashlight_reactive_materials.append(material)
	return material

func _make_puddle_shader() -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
void fragment() {
	float ripple = sin((UV.x + UV.y) * 24.0 + TIME * 0.34) * 0.015;
	ALBEDO = vec3(0.025, 0.035, 0.034) + ripple;
	METALLIC = 0.25;
	ROUGHNESS = 0.13;
	ALPHA = 0.72;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	return material

func _make_memory_shader(phase: float) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded;
uniform float phase = 0.0;
void fragment() {
	float scan = smoothstep(0.25, 0.95, sin((UV.y + TIME * 0.08) * 92.0) * 0.5 + 0.5);
	float glitch = step(0.94, fract(sin(floor(TIME * 9.0 + phase) * 71.73) * 4831.21));
	float pulse = 1.25 + sin(TIME * 2.4 + phase) * 0.45 + scan * 0.18 + glitch * 0.55;
	vec3 color = vec3(0.48, 0.72, 0.60);
	ALBEDO = color * (0.82 + scan * 0.18);
	EMISSION = color * pulse;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("phase", phase)
	return material

func _monster_motion_segment_valid(from: Vector3, to: Vector3) -> bool:
	var steps := maxi(1, ceili(from.distance_to(to) / 0.20))
	var previous_depth := _handheld_light_depth(from,MONSTER_BODY_RADIUS) if creature_light_state in ["retreat","stalk"] else 0.0
	var previous := from
	for step in range(1, steps + 1):
		var point := from.lerp(to,float(step)/steps)
		if creature_light_state in ["retreat","stalk"]:
			if level_manager.is_blocked_world(point+Vector3.UP*0.48,MONSTER_BODY_RADIUS) or not _ceiling_escape_segment_allowed(previous, point): return false
			var next_depth := _handheld_light_depth(point,MONSTER_BODY_RADIUS)
			if previous_depth <= 0.0 and next_depth > 0.0: return false
			# A beam swept onto an existing body may deepen geometrically as it
			# backs away along the widening cone. Permit only escape, never advance.
			if next_depth > previous_depth + 0.0001 and point.distance_squared_to(flashlight_blocking_player.global_position) < previous.distance_squared_to(flashlight_blocking_player.global_position): return false
			previous_depth = next_depth
			previous = point
		elif ceiling_escape_active:
			if level_manager.is_blocked_world(point + Vector3.UP * 0.48, MONSTER_BODY_RADIUS) or _position_in_handheld_light(point, MONSTER_BODY_RADIUS): return false
			if not _ceiling_escape_segment_allowed(previous, point): return false
			previous = point
		elif not _monster_motion_position_valid(point): return false
	return true

func _build_safe_light_route(raw: Array) -> void:
	route_light_positions.clear()
	var housing := _flat_material(Color8(22, 23, 21), 0.86)
	var tube := _glow_material(Color8(222, 209, 169), 1.7)
	# Sparse refuges: 24+ metre spacing leaves real dark travel between pools.
	# Do not add an extra lamp merely because a corner hides the previous one.
	var start := _world_cell(level_manager.spawn_pos)
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	# Give the main route's centreline priority over arbitrary wall-edge cells.
	# Remaining branches still receive sparse refuges below.
	for cell in [Vector2i(42,132), Vector2i(36,128), Vector2i(30,128), Vector2i(30,122), Vector2i(24,118), Vector2i(18,118), Vector2i(12,118), Vector2i(10,112)]:
		if not level_manager.is_blocked_world(_cell_world(cell) + Vector3.UP * 0.48, 0.32):
			visited[cell] = true
			queue.append(cell)
	# Authored furniture can divide coarse grid connectivity even where the
	# player can walk around it. Cover every remaining walkable component too.
	for row in raw.size():
		for col in String(raw[row]).length():
			var cell := Vector2i(col, row)
			if visited.has(cell) or String(raw[row]).substr(col, 1) == "#":
				continue
			if level_manager.is_blocked_world(_cell_world(cell) + Vector3.UP * 0.48, 0.32):
				continue
			visited[cell] = true
			queue.append(cell)
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		var position := _cell_world(cell)
		var covered := false
		for ward in monster_warding_lights:
			if bool(ward.get("safe_zone", false)) and position.distance_to(ward["position"]) < 24.0:
				covered = true
				break
		if cell == start or not covered:
			_add_ceiling_fixture(position, route_light_positions.size(), housing, tube, tube, tube, tube)

func _build_battery_pickups(raw: Array) -> void:
	battery_pickups.clear()
	var casing := _flat_material(Color8(168, 144, 81), 0.7)
	var metal := _flat_material(Color8(142, 144, 139), 0.4)
	var marker := ShaderMaterial.new()
	var marker_shader := Shader.new()
	marker_shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_disabled;
varying float marker_distance;
void vertex() {
	marker_distance = distance(MODEL_MATRIX[3].xyz, CAMERA_POSITION_WORLD);
}
void fragment() {
	float nearby = 1.0 - smoothstep(6.0, 15.0, marker_distance);
	ALBEDO = vec3(0.42, 0.33, 0.14);
	ROUGHNESS = 0.82;
	EMISSION = vec3(0.45, 0.36, 0.15) * 0.9 * nearby;
}
"""
	marker.shader = marker_shader
	for light_index in range(3, route_light_positions.size(), maxi(5, ceili(route_light_positions.size() / 10.0))):
		if battery_pickups.size() >= 10:
			break
		var origin := _world_cell(route_light_positions[light_index])
		for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var cell: Vector2i = origin + direction
			if cell.y < 0 or cell.y >= raw.size() or cell.x < 0 or cell.x >= String(raw[cell.y]).length():
				continue
			var position := _cell_world(cell)
			if String(raw[cell.y]).substr(cell.x, 1) == "#" or level_manager.is_blocked_world(position + Vector3.UP * 0.48, 0.4) or _monster_position_in_warding_light(position):
				continue
			var pickup := Node3D.new()
			pickup.name = "FlashlightBattery_%02d" % battery_pickups.size()
			pickup.position = position
			add_child(pickup)
			_add_box(pickup, Vector3(0.32, 0.16, 0.52), Vector3(0, 0.12, 0), casing)
			_add_box(pickup, Vector3(0.22, 0.06, 0.12), Vector3(0, 0.20, -0.18), metal)
			# A narrow wrap is visible from the top and sides, but cannot shine
			# through furniture or create another monster-safe light volume.
			_add_box(pickup, Vector3(0.334, 0.17, 0.048), Vector3(0, 0.12, 0.06), marker).name = "BatteryReflectiveBand"
			# End caps keep the same restrained accent readable along the long axis.
			for end_z in [-0.264, 0.264]:
				_add_box(pickup, Vector3(0.08, 0.12, 0.008), Vector3(0, 0.12, end_z), marker)
			battery_pickups.append(pickup)
			break

func _tick_darkness_and_batteries(dt: float, player) -> void:
	player_in_safe_light = _monster_position_in_warding_light(player.global_position)
	if player_in_safe_light:
		darkness_time = 0.0
	elif not player.horror_cinematic_locked:
		darkness_time = minf(20.0, darkness_time + dt)
	if darkness_time >= DARKNESS_HUNT_DELAY and not bool(player.horror_hidden) and not player.horror_cinematic_locked and is_instance_valid(monster_root):
		monster_awareness = maxf(monster_awareness, minf(1.0, darkness_time / 8.0))
		if monster_state not in ["flee_light", "hunt_reset"] and monster_root.global_position.distance_to(player.global_position) <= MONSTER_SIGHT_RANGE:
			monster_last_known_position = player.global_position
			monster_estimated_player_position = player.global_position
			monster_state = "chase"
	for pickup in battery_pickups:
		if is_instance_valid(pickup) and pickup.visible and pickup.global_position.distance_to(player.global_position) < 1.10:
			if player.collect_horror_battery():
				pickup.hide()
