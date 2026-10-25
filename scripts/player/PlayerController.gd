extends Node3D
class_name PlayerController

signal shoot_requested
signal special_requested
signal reload_requested
signal grenade_requested
signal interact_requested
signal melee_requested
signal weapon_slot_requested(slot_index)
signal weapon_cycle_requested(direction)
signal hp_changed(hp)
signal dash_changed(cooldown, total)
signal sound_requested(sfx_name)

const BASE_SPEED = 6.4
const PLAYER_RADIUS = 0.34
const PLAYER_HEIGHT = 1.72
const LOOK_SENS = 0.0027
const KEY_LOOK_SPEED = 1.75
const DASH_DISTANCE = 5.2
const DASH_COOLDOWN = 0.85
const SLIDE_COOLDOWN = 0.95
const SLIDE_DURATION = 0.86
const SLIDE_START_SPEED = 16.2
const SLIDE_MIN_SPEED = 8.9
const SLIDE_END_SPEED = 2.7
const SLIDE_STEER_FORCE = 4.6
const SLIDE_FRICTION = 6.1
const SLIDE_WALL_BRAKE = 0.36
const AIR_SLIDE_DURATION = 0.66
const AIR_SLIDE_START_SPEED = 15.2
const AIR_SLIDE_END_SPEED = 2.7
const AIR_SLIDE_STEER_FORCE = 2.75
const AIR_SLIDE_FRICTION = 2.45
const AIR_SLIDE_VERTICAL_DAMP = 0.46
const AIR_SLIDE_GLIDE_LIFT = 1.42
const AIR_SLIDE_AIM_UP_BOOST = 6.35
const AIR_SLIDE_UP_KICK = 1.45
const GROUND_ACCEL = 30.0
const AIR_ACCEL = 5.4
const GROUND_FRICTION = 16.0
const AIR_FRICTION = 3.8
const ICE_GROUND_ACCEL = 10.6
const ICE_STEER_RATE = 2.35
const ICE_IDLE_FRICTION = 1.75
const ICE_INPUT_FRICTION = 0.62
const ICE_MAX_SPEED_MULT = 1.66
const ICE_ALWAYS_GLIDE = 0.26
const ICE_DRIFT_SWING_RATE = 1.35
const ICE_FORWARD_SPEED_CAP = 0.86
const ICE_BACK_SPEED_CAP = 0.70
const ICE_SIDE_SPEED_CAP = 0.76
const ICE_ACCEL_BUILDUP = 0.86
const MOMENTUM_GLIDE_START = 7.3
const MOMENTUM_GLIDE_FRICTION_SCALE = 0.48
const BODY_CROUCH_DROP = 0.44
const GRAVITY = 17.0
const JUMP_SPEED = 8.0
const JUMP_CHARGE_MAX_TIME = 0.82
const JUMP_CHARGE_MAX_SPEED = 23.5
const JUMP_CHARGE_FORWARD_BOOST = 5.8
const JUMP_TAP_CHARGE_THRESHOLD = 0.10
const DOUBLE_JUMP_SPEED = 9.4
const DOUBLE_JUMP_CHARGED_SPEED = 15.8
const DOUBLE_JUMP_CHARGE_FORWARD_BOOST = 3.4
const WALL_JUMP_SPEED = 8.6
const WALL_JUMP_PUSH = 7.2
const GRAPPLE_RANGE = 30.0
const GRAPPLE_PULL_SPEED = 15.8
const GRAPPLE_MAX_TIME = 2.05
const SURFACE_LAUNCH_DECAY = 5.4
const SURFACE_LAUNCH_MAX_UP = 3.6
const SURFACE_LAUNCH_MIN_SPEED = 5.2
const FLOW_SURFACE_SNAP_BASE = 0.48
const FLOW_SURFACE_SNAP_FAST = 1.18
const ARMOR_MAX = 60
const ARMOR_DAMAGE_DRAIN = 1.55
const ARMOR_RECHARGE_DELAY = 1.10
const ARMOR_BREAK_DELAY = 2.25
const ARMOR_RECHARGE_RATE = 38.0
const PASSIVE_HEAL_DELAY = 4.2
const PASSIVE_HEAL_RATE = 0.95
const HORROR_WALK_SPEED = 3.75
const HORROR_SPRINT_SPEED = 7.75
const HORROR_WALK_ACCEL = 7.6
const HORROR_SPRINT_ACCEL = 11.5
const HORROR_BRAKE = 9.2
const HORROR_AIR_ACCEL = 2.2
const HORROR_AIR_BRAKE = 0.9
const HORROR_JUMP_SPEED = 5.35
const HORROR_GRAVITY = 19.5
const HORROR_STAMINA_MAX = 100.0
const HORROR_STAMINA_DRAIN = 25.0
const HORROR_STAMINA_RECOVERY = 19.0
const HORROR_STAMINA_RECOVERY_DELAY = 0.72
const HORROR_FLASHLIGHT_FOCUS_COOL_RATE = 0.085
const HORROR_FLASHLIGHT_OFF_COOL_RATE = 0.24
const HORROR_FLASHLIGHT_MODEL_PATH = "res://assets/props/flashlight/flashlight.glb"
const HORROR_FLASHLIGHT_MODEL_SCALE = 0.0035
const HORROR_FLASHLIGHT_DEVICE_POSITION = Vector3(0.23, -0.285, -0.40)
const HORROR_FLASHLIGHT_DEVICE_ROTATION = Vector3(2.0, 1.50, 0.0)
const HORROR_FLASHLIGHT_VIEWMODEL_LAYER = 1 << 19
const HORROR_FLASHLIGHT_WORLD_LIGHT_MASK = (1 << 19) - 1

var camera: Camera3D
var powerups
var level_manager
var character_name = "KILLGORE"
var developer_mode = false
var hp = 100
var hp_float = 100.0
var armor = ARMOR_MAX
var armor_float = float(ARMOR_MAX)
var armor_recharge_delay = 0.0
var passive_heal_delay = 0.0
var yaw = 0.0
var pitch = 0.0
var target_yaw = 0.0
var target_pitch = 0.0
var vertical_velocity = 0.0
var grounded = true
var dash_cooldown = 0.0
var dash_total = SLIDE_COOLDOWN
var damage_flash = 0.0
var dash_flash = 0.0
var shake_timer = 0.0
var shake_strength = 0.0
var super_jump_cooldown = 0.0
var jumps_left = 1
var jump_charge_active = false
var jump_charge_timer = 0.0
var jump_charge_amount = 0.0
var last_jump_charge_amount = 0.0
var wall_jump_cooldown = 0.0
var wall_push_velocity = Vector3.ZERO
var horizontal_velocity = Vector3.ZERO
var horizontal_speed = 0.0
var slide_active = false
var slide_airborne = false
var slide_hold_locked = false
var slide_timer = 0.0
var slide_velocity = Vector3.ZERO
var slide_intensity = 0.0
var slide_visual_intensity = 0.0
var slide_crouch = 0.0
var air_slide_used = false
var momentum_intensity = 0.0
var grapple_momentum_intensity = 0.0
var surface_slide_factor = 0.0
var body_roll = 0.0
var body_pitch = 0.0
var body_yaw = 0.0
var movement_lean_memory = 0.0
var look_lean_memory = 0.0
var drift_swing_phase = 0.0
var last_lean_yaw = 0.0
var post_slide_lean_timer = 0.0
var landing_kick = 0.0
var wall_impact = 0.0
var air_time = 0.0
var last_floor_y = 0.0
var surface_launch_memory = 0.0
var grapple_active = false
var grapple_point = Vector3.ZERO
var grapple_cooldown = 0.0
var grapple_visual_timer = 0.0
var grapple_timer = 0.0
var last_grapple_velocity = Vector3.ZERO
var grapple_enemy = null
var grapple_enemy_mode = ""
var dodge_immunity_timer = 0.0
var post_slide_super_jump_timer = 0.0
var camera_base_position = Vector3.ZERO
var camera_base_fov = 75.0
var move_intensity = 0.0
var move_forward = 0.0
var move_strafe = 0.0
var camera_bob_time = 0.0
var paused = false
var look_sensitivity_multiplier = 1.0
var shake_scale = 0.68
var slow_timer = 0.0
var slow_multiplier = 1.0
var zoom_timer = 0.0
var zoom_fov_drop = 0.0
var horror_flashlight_mode = false
const HORROR_BATTERY_SECONDS = 100.0
const HORROR_BATTERY_DRAIN_RATE = 1.6
const HORROR_BATTERY_PICKUP_SECONDS = 35.0
var horror_battery_seconds = HORROR_BATTERY_SECONDS
var flashlight_on = false
var flashlight_primary: SpotLight3D
var horror_near_visibility: OmniLight3D
var horror_near_adaptation := 0.0

func _tick_horror_near_visibility(dt: float) -> void:
	if not is_instance_valid(horror_near_visibility):
		if not horror_flashlight_mode:
			return
		horror_near_visibility = OmniLight3D.new()
		horror_near_visibility.name = "HorrorNearVisibility"
		add_child(horror_near_visibility)
		# Player root is at floor height. Waist-level fill reaches nearby floor
		# and obstacle faces instead of grazing the floor from ankle height.
		# Render-only: never registered in the horror ward/flashlight systems.
		horror_near_visibility.position = Vector3(0.0, 0.90, 0.0)
		horror_near_visibility.omni_range = 2.80
		horror_near_visibility.omni_attenuation = 0.45
		horror_near_visibility.light_color = Color8(190, 195, 200)
		horror_near_visibility.light_specular = 0.0
		horror_near_visibility.light_cull_mask = HORROR_FLASHLIGHT_WORLD_LIGHT_MASK
		horror_near_visibility.shadow_enabled = true
		horror_near_visibility.shadow_bias = 0.03
		horror_near_visibility.shadow_normal_bias = 0.10
		horror_near_visibility.light_energy = 0.0
	var wanted := horror_flashlight_mode and not horror_cinematic_locked and not horror_hidden and not developer_mode and (not flashlight_on or horror_battery_seconds <= 0.0)
	horror_near_adaptation = move_toward(horror_near_adaptation, 1.0 if wanted else 0.0, dt * (0.65 if wanted else 5.0))
	if not horror_flashlight_mode or horror_cinematic_locked:
		horror_near_adaptation = 0.0
	horror_near_visibility.light_energy = 1.4 * smoothstep(0.0, 1.0, horror_near_adaptation)
	horror_near_visibility.visible = horror_near_adaptation > 0.001
var flashlight_fill: SpotLight3D
var flashlight_hotspot: SpotLight3D
var flashlight_long_throw: SpotLight3D
var flashlight_camera_throw: SpotLight3D
var flashlight_camera_fill: SpotLight3D
var flashlight_device_root: Node3D
var flashlight_device_model: Node3D
var flashlight_emitter: Marker3D
var flashlight_corridor_lights: Array[OmniLight3D] = []
var flashlight_source_glow: MeshInstance3D
var flashlight_source_neck: MeshInstance3D
var flashlight_source_visual_material: ShaderMaterial
var flashlight_source_light: OmniLight3D
var flashlight_viewmodel_fill: OmniLight3D
var flashlight_volume_root: Node3D
var flashlight_volume_planes: Array[MeshInstance3D] = []
var flashlight_beam_ribbons: Array[MeshInstance3D] = []
var flashlight_beam_slices: Array[MeshInstance3D] = []
var flashlight_volume_material: ShaderMaterial
var flashlight_volume_core_material: ShaderMaterial
var flashlight_ribbon_material: ShaderMaterial
var flashlight_ribbon_core_material: ShaderMaterial
var flashlight_slice_material: ShaderMaterial
var flashlight_slice_core_material: ShaderMaterial
var flashlight_fan_material: ShaderMaterial
var horror_mist_layer: CanvasLayer
var horror_mist_overlay: ColorRect
var flashlight_dust: GPUParticles3D
var flashlight_haze: GPUParticles3D
var flashlight_dust_process: ParticleProcessMaterial
var flashlight_haze_process: ParticleProcessMaterial
var flashlight_volume_length = 18.0
var flashlight_volume_target_length = 18.0
var flashlight_volume_probe_timer = 0.0
var flashlight_time = 0.0
var horror_flashlight_focus_heat = 0.0
var horror_flashlight_strain_timer = 0.0
var horror_flashlight_strain_strength = 0.0
var horror_flashlight_output = 1.0
var horror_sprint_stamina = HORROR_STAMINA_MAX
var horror_sprint_active = false
var horror_sprint_recovery_delay = 0.0
var horror_sprint_exhausted = false
var horror_hidden = false
var horror_hide_position = Vector3.ZERO
var horror_cinematic_locked = false

func _ready() -> void:
	camera = $Camera3D
	camera_base_position = camera.position
	camera_base_fov = camera.fov
	last_lean_yaw = yaw
	powerups = $PowerupManager
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func configure(lm, powerup_data: Dictionary) -> void:
	level_manager = lm
	powerups.configure(powerup_data)

func set_horror_flashlight_mode(enabled: bool) -> void:
	if enabled and not horror_flashlight_mode:
		horror_battery_seconds = HORROR_BATTERY_SECONDS
	horror_flashlight_mode = enabled
	flashlight_on = enabled
	flashlight_volume_probe_timer = 0.0
	flashlight_volume_length = 18.0
	flashlight_volume_target_length = 18.0
	horror_flashlight_focus_heat = 0.0
	horror_flashlight_strain_timer = 0.0
	horror_flashlight_strain_strength = 0.0
	horror_flashlight_output = 1.0
	horror_sprint_stamina = HORROR_STAMINA_MAX
	horror_sprint_active = false
	horror_sprint_recovery_delay = 0.0
	horror_sprint_exhausted = false
	if enabled:
		# Enter the horror chapter without carrying combat momentum or traversal
		# state into its deliberately grounded movement profile.
		horizontal_velocity = Vector3.ZERO
		wall_push_velocity = Vector3.ZERO
		slide_active = false
		slide_velocity = Vector3.ZERO
		slide_intensity = 0.0
		slide_visual_intensity = 0.0
		slide_crouch = 0.0
		momentum_intensity = 0.0
		grapple_momentum_intensity = 0.0
		if grapple_active:
			_cancel_grapple(false)
		jump_charge_active = false
		jump_charge_timer = 0.0
		jump_charge_amount = 0.0
	else:
		horror_hidden = false
		horror_cinematic_locked = false
	_ensure_horror_flashlight()
	_update_horror_flashlight_visibility()
	_tick_horror_near_visibility(0.0)

func _toggle_horror_flashlight() -> void:
	flashlight_on = not flashlight_on and horror_battery_seconds > 0.0
	# Never reveal a stale, long beam for a frame after toggling back on. The
	# next physics tick samples the current wall and expands from a safe length.
	if flashlight_on:
		flashlight_volume_probe_timer = 0.0
		flashlight_volume_length = minf(flashlight_volume_length, 10.0)
		flashlight_volume_target_length = flashlight_volume_length
	_update_horror_flashlight_visibility()

func set_horror_hidden(enabled: bool, hide_position: Vector3 = Vector3.ZERO, hide_yaw: float = 0.0) -> void:
	horror_hidden = enabled
	if enabled:
		horror_hide_position = hide_position
		global_position = hide_position
		yaw = hide_yaw
		target_yaw = hide_yaw
		horizontal_velocity = Vector3.ZERO
		vertical_velocity = 0.0
		grounded = true
		horror_sprint_active = false
		jump_charge_active = false
		slide_active = false
		if grapple_active:
			_cancel_grapple(false)


func set_horror_cinematic_lock(enabled: bool) -> void:
	horror_cinematic_locked = enabled
	if not enabled:
		return
	horizontal_velocity = Vector3.ZERO
	horizontal_speed = 0.0
	vertical_velocity = 0.0
	horror_sprint_active = false
	jump_charge_active = false
	slide_active = false
	if grapple_active:
		_cancel_grapple(false)

func horror_stamina_ratio() -> float:
	return clamp(horror_sprint_stamina / HORROR_STAMINA_MAX, 0.0, 1.0)

func horror_battery_ratio() -> float:
	return clampf(horror_battery_seconds / HORROR_BATTERY_SECONDS, 0.0, 1.0)

func collect_horror_battery() -> bool:
	if not horror_flashlight_mode or horror_battery_seconds >= HORROR_BATTERY_SECONDS:
		return false
	horror_battery_seconds = minf(HORROR_BATTERY_SECONDS, horror_battery_seconds + HORROR_BATTERY_PICKUP_SECONDS)
	return true

func horror_flashlight_heat_ratio() -> float:
	return clamp(horror_flashlight_focus_heat, 0.0, 1.0)

func horror_flashlight_focus_ratio() -> float:
	return horror_flashlight_output

func stress_horror_flashlight(strength: float, dt: float) -> void:
	if not horror_flashlight_mode or not flashlight_on:
		return
	var focused_strength = clamp(strength, 0.0, 1.0)
	horror_flashlight_focus_heat = min(1.0, horror_flashlight_focus_heat + dt * lerp(0.055, 0.19, focused_strength))
	horror_flashlight_strain_timer = 0.72
	horror_flashlight_strain_strength = max(horror_flashlight_strain_strength, focused_strength)

func _ensure_horror_flashlight() -> void:
	if camera == null:
		return
	_ensure_flashlight_device()
	var light_parent: Node3D = flashlight_emitter if is_instance_valid(flashlight_emitter) else camera
	if not is_instance_valid(flashlight_primary):
		flashlight_primary = SpotLight3D.new()
		flashlight_primary.name = "HorrorFlashlightBeam"
		flashlight_primary.position = Vector3.ZERO
		flashlight_primary.rotation_degrees = Vector3.ZERO
		flashlight_primary.light_color = Color8(238, 232, 205)
		flashlight_primary.light_energy = 5.20
		flashlight_primary.light_specular = 0.72
		flashlight_primary.spot_range = 20.0
		flashlight_primary.spot_angle = 32.0
		flashlight_primary.spot_angle_attenuation = 2.0
		flashlight_primary.spot_attenuation = 0.85
		flashlight_primary.shadow_enabled = true
		# Compatibility shadow-map self-intersection caused diagonal bands on
		# corridor props/walls, especially at grazing flashlight angles.
		flashlight_primary.shadow_bias = 0.15
		flashlight_primary.shadow_normal_bias = 1.5
		# Closed corridor solids cast from their back faces: unlike a larger
		# bias alone this avoids distance-dependent self-shadow stripes.
		flashlight_primary.shadow_reverse_cull_face = true
		flashlight_primary.light_cull_mask = HORROR_FLASHLIGHT_WORLD_LIGHT_MASK
		light_parent.add_child(flashlight_primary)
	# The flashlight uses one world-light cone. Stacking short-range fill,
	# hotspot and long-throw SpotLights creates several independently ending
	# pools on the floor even when all of them share the physical lens.
	# Do not place proxy lamps down the corridor. Their overlapping pools create
	# visible rings on the floor instead of one continuous beam from the lens.
	_ensure_flashlight_volume()
	_ensure_horror_screen_mist()

func _ensure_flashlight_corridor_lights(light_parent: Node3D) -> void:
	if not flashlight_corridor_lights.is_empty():
		return
	# Three broad, shadowless pools fake the indirect light that Compatibility
	# cannot bounce from the flashlight hit surface. Keeping the pool count fixed
	# avoids adding more dynamic lights to the horror level.
	var distances = [2.4, 8.0, 15.0]
	var ranges = [5.6, 6.2, 4.4]
	var energies = [0.56, 0.22, 0.08]
	var colors = [
		Color8(214, 211, 190),
		Color8(232, 222, 190),
		Color8(255, 229, 180)
	]
	for index in distances.size():
		var corridor_light = OmniLight3D.new()
		corridor_light.name = "HorrorFlashlightCorridorPool%d" % (index + 1)
		corridor_light.position = Vector3(0.0, -0.18 - float(index) * 0.12, -float(distances[index]))
		corridor_light.light_color = colors[index]
		corridor_light.light_energy = float(energies[index])
		corridor_light.light_specular = 0.10
		corridor_light.omni_range = float(ranges[index])
		corridor_light.omni_attenuation = 1.02 + float(index) * 0.05
		corridor_light.shadow_enabled = false
		corridor_light.light_cull_mask = HORROR_FLASHLIGHT_WORLD_LIGHT_MASK
		light_parent.add_child(corridor_light)
		flashlight_corridor_lights.append(corridor_light)

func _ensure_horror_screen_mist() -> void:
	if is_instance_valid(horror_mist_layer):
		return
	horror_mist_layer = CanvasLayer.new()
	horror_mist_layer.name = "HorrorAtmosphericMist"
	horror_mist_layer.layer = 1
	add_child(horror_mist_layer)
	horror_mist_overlay = ColorRect.new()
	horror_mist_overlay.name = "MovingMistVeil"
	horror_mist_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	horror_mist_layer.add_child(horror_mist_overlay)
	horror_mist_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mist_shader = Shader.new()
	mist_shader.code = """
shader_type canvas_item;
render_mode blend_mix;
float fog_noise(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
	vec2 uv = UV;
	vec2 drift = vec2(TIME * 0.006, -TIME * 0.003);
	vec2 cell = floor((uv + drift) * vec2(13.0, 8.0));
	float broad = fog_noise(cell) * 0.55 + fog_noise(floor(cell * 0.43 + 9.0)) * 0.45;
	float lower_air = smoothstep(0.0, 0.72, 1.0 - uv.y);
	float center = 1.0 - smoothstep(0.42, 0.82, length(uv - vec2(0.5)));
	float horizon = exp(-pow((uv.y - 0.51) * 4.6, 2.0));
	float alpha = (0.004 + broad * 0.010 + horizon * 0.007) * (0.70 + lower_air * 0.30) * (0.72 + center * 0.28);
	COLOR = vec4(vec3(0.34, 0.35, 0.33), alpha);
}
"""
	var mist_material = ShaderMaterial.new()
	mist_material.shader = mist_shader
	horror_mist_overlay.material = mist_material

func _ensure_flashlight_device() -> void:
	if camera == null or is_instance_valid(flashlight_device_root):
		return
	flashlight_device_root = Node3D.new()
	flashlight_device_root.name = "HorrorFlashlightDevice"
	flashlight_device_root.position = HORROR_FLASHLIGHT_DEVICE_POSITION
	# The hand-held lamp converges on the crosshair instead of projecting a
	# camera-centred light. This makes the beam visibly travel from the lens.
	flashlight_device_root.rotation_degrees = HORROR_FLASHLIGHT_DEVICE_ROTATION
	camera.add_child(flashlight_device_root)

	var packed_model = load(HORROR_FLASHLIGHT_MODEL_PATH)
	if packed_model is PackedScene:
		var model_instance = packed_model.instantiate()
		if model_instance is Node3D:
			flashlight_device_model = model_instance as Node3D
			flashlight_device_model.name = "FlashlightModel"
			# The authored GLB is 98 units long, lies on +X/-X and has its wide
			# reflector at +X. Scale it to a 34 cm hand torch and rotate +X onto
			# the beam's -Z so the reflector points away from the player.
			flashlight_device_model.scale = Vector3.ONE * HORROR_FLASHLIGHT_MODEL_SCALE
			flashlight_device_model.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			flashlight_device_model.position = Vector3(0.0, -0.062, 0.0)
			_prepare_flashlight_device_model(flashlight_device_model)
			flashlight_device_root.add_child(flashlight_device_model)
	if not is_instance_valid(flashlight_device_model):
		# Preserve a visible, functional fallback if the external scene is ever
		# missing from a build rather than silently losing the physical emitter.
		_build_procedural_flashlight_fallback()

	flashlight_emitter = Marker3D.new()
	flashlight_emitter.name = "FlashlightEmitter"
	flashlight_emitter.position = Vector3(0, 0, -0.184)
	flashlight_device_root.add_child(flashlight_emitter)
	flashlight_source_light = OmniLight3D.new()
	flashlight_source_light.name = "FlashlightLensSpill"
	flashlight_source_light.position = Vector3(0, 0, -0.028)
	flashlight_source_light.light_color = Color8(255, 236, 184)
	flashlight_source_light.light_energy = 0.08
	flashlight_source_light.omni_range = 0.28
	flashlight_source_light.omni_attenuation = 2.65
	flashlight_source_light.light_specular = 0.48
	flashlight_source_light.shadow_enabled = false
	# This tiny lamp only gives the held prop a readable front rim. World beam
	# lights explicitly exclude this layer, preventing the model from lighting
	# itself when their invisible proxy lights move down a long corridor.
	flashlight_source_light.light_cull_mask = HORROR_FLASHLIGHT_VIEWMODEL_LAYER
	flashlight_emitter.add_child(flashlight_source_light)
	_ensure_flashlight_source_visual()
	flashlight_viewmodel_fill = OmniLight3D.new()
	flashlight_viewmodel_fill.name = "FlashlightControlledBodyFill"
	flashlight_viewmodel_fill.position = Vector3(0.02, 0.08, -0.18)
	flashlight_viewmodel_fill.light_color = Color8(196, 185, 156)
	flashlight_viewmodel_fill.light_energy = 0.21
	flashlight_viewmodel_fill.omni_range = 0.92
	flashlight_viewmodel_fill.omni_attenuation = 2.10
	flashlight_viewmodel_fill.light_specular = 0.34
	flashlight_viewmodel_fill.shadow_enabled = false
	flashlight_viewmodel_fill.light_cull_mask = HORROR_FLASHLIGHT_VIEWMODEL_LAYER
	camera.add_child(flashlight_viewmodel_fill)

func _ensure_flashlight_source_visual() -> void:
	if not is_instance_valid(flashlight_emitter) or is_instance_valid(flashlight_source_glow):
		return
	# The imported GLB is a single mesh and has no independently addressable
	# lens material. Add a tiny optical source at the actual emitter so the eye
	# can trace the illumination back to the held flashlight.
	flashlight_source_visual_material = ShaderMaterial.new()
	var source_shader = Shader.new()
	source_shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float source_intensity = 1.0;
void fragment() {
	float facing = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float edge_glint = pow(1.0 - facing, 2.2);
	float glass_depth = mix(0.28, 0.72, pow(facing, 0.55));
	vec3 warm_source = vec3(1.0, 0.91, 0.66);
	ALBEDO = mix(vec3(0.055, 0.050, 0.038), warm_source * 0.34, glass_depth);
	EMISSION = warm_source * (0.62 * glass_depth + 1.15 * edge_glint) * source_intensity;
	ALPHA = clamp((0.42 * glass_depth + 0.18 * edge_glint) * source_intensity, 0.0, 0.82);
}
"""
	flashlight_source_visual_material.shader = source_shader
	flashlight_source_visual_material.render_priority = 96
	flashlight_source_glow = MeshInstance3D.new()
	flashlight_source_glow.name = "FlashlightPhysicalLensGlow"
	var glow_mesh = CylinderMesh.new()
	glow_mesh.top_radius = 0.057
	glow_mesh.bottom_radius = 0.057
	glow_mesh.height = 0.010
	glow_mesh.radial_segments = 32
	flashlight_source_glow.mesh = glow_mesh
	flashlight_source_glow.position = Vector3(0.0, 0.0, -0.016)
	flashlight_source_glow.rotation_degrees.x = 90.0
	flashlight_source_glow.material_override = flashlight_source_visual_material
	flashlight_source_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flashlight_source_glow.layers = HORROR_FLASHLIGHT_VIEWMODEL_LAYER
	flashlight_emitter.add_child(flashlight_source_glow)

	# A short, faint neck gives the source continuity in mist. It is unshaded
	# geometry, so it cannot create another light pool on floors or walls.
	var neck_shader = Shader.new()
	neck_shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float source_intensity = 1.0;
void fragment() {
	float start_fade = smoothstep(0.0, 0.055, UV.y);
	float end_fade = 1.0 - smoothstep(0.30, 1.0, UV.y);
	float grazing = pow(1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 1.45);
	float broken_air = 0.76 + 0.12 * sin(UV.y * 37.0 + TIME * 0.7);
	broken_air += 0.08 * sin(UV.x * 21.0 - UV.y * 61.0 - TIME * 0.4);
	vec3 warm_air = vec3(0.91, 0.87, 0.68);
	float air_density = (0.016 + grazing * 0.040) * start_fade * end_fade * clamp(broken_air, 0.48, 1.0) * source_intensity;
	ALBEDO = warm_air * 0.025;
	EMISSION = warm_air * 0.24 * source_intensity;
	ALPHA = air_density;
}
"""
	var neck_material = ShaderMaterial.new()
	neck_material.shader = neck_shader
	neck_material.render_priority = 88
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var segments = 48
	var neck_length = 3.05
	var neck_radius = 0.30
	for index in range(segments):
		var angle_a = TAU * float(index) / float(segments)
		var angle_b = TAU * float(index + 1) / float(segments)
		vertices.append(Vector3(0.0, 0.0, -0.012))
		vertices.append(Vector3(cos(angle_a) * neck_radius, sin(angle_a) * neck_radius, -neck_length))
		vertices.append(Vector3(cos(angle_b) * neck_radius, sin(angle_b) * neck_radius, -neck_length))
		uvs.append(Vector2((float(index) + 0.5) / float(segments), 0.0))
		uvs.append(Vector2(float(index) / float(segments), 1.0))
		uvs.append(Vector2(float(index + 1) / float(segments), 1.0))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var neck_mesh = ArrayMesh.new()
	neck_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	flashlight_source_neck = MeshInstance3D.new()
	flashlight_source_neck.name = "FlashlightSourceNeck"
	flashlight_source_neck.mesh = neck_mesh
	flashlight_source_neck.material_override = neck_material
	flashlight_source_neck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flashlight_source_neck.layers = HORROR_FLASHLIGHT_VIEWMODEL_LAYER
	flashlight_source_neck.set_meta("source_material", neck_material)
	flashlight_emitter.add_child(flashlight_source_neck)

func _prepare_flashlight_device_model(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mesh_instance.layers = HORROR_FLASHLIGHT_VIEWMODEL_LAYER
		# The source material is fully metallic. In the first-person view that
		# turns small proxy-light changes into white contour lines, even in a dark
		# room. Keep its texture, but give the prop a broader, dirtier response.
		if mesh_instance.mesh != null:
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				var source_material = mesh_instance.get_active_material(surface_index)
				if source_material is BaseMaterial3D:
					var view_material = source_material.duplicate() as BaseMaterial3D
					view_material.metallic = minf(view_material.metallic, 0.18)
					view_material.roughness = maxf(view_material.roughness, 0.74)
					view_material.emission_enabled = false
					mesh_instance.set_surface_override_material(surface_index, view_material)
	if node is CollisionObject3D:
		(node as CollisionObject3D).collision_layer = 0
		(node as CollisionObject3D).collision_mask = 0
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	for child in node.get_children():
		_prepare_flashlight_device_model(child)

func _build_procedural_flashlight_fallback() -> void:
	var body_material = _flashlight_device_material(Color8(30, 32, 30), 0.82)
	var rim_material = _flashlight_device_material(Color8(87, 82, 68), 0.52)
	var lens_material = _flashlight_device_material(Color8(255, 239, 188), 0.20, true, 3.8)
	_add_flashlight_device_box(Vector3(0.105, 0.105, 0.27), Vector3(0, 0, 0.09), Vector3.ZERO, body_material)
	_add_flashlight_device_box(Vector3(0.072, 0.17, 0.075), Vector3(0, -0.105, 0.105), Vector3(-12, 0, 0), body_material)
	_add_flashlight_device_cylinder(0.082, 0.105, Vector3(0, 0, -0.075), rim_material)
	_add_flashlight_device_cylinder(0.066, 0.026, Vector3(0, 0, -0.137), body_material)
	flashlight_source_glow = _add_flashlight_device_cylinder(0.050, 0.006, Vector3(0, 0, -0.174), lens_material)

func _add_flashlight_device_box(box_size: Vector3, local_position: Vector3, rotation: Vector3, material: Material) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = box_size
	var part = MeshInstance3D.new()
	part.mesh = mesh
	part.position = local_position
	part.rotation_degrees = rotation
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.layers = HORROR_FLASHLIGHT_VIEWMODEL_LAYER
	flashlight_device_root.add_child(part)
	return part

func _add_flashlight_device_cylinder(radius: float, height: float, local_position: Vector3, material: Material) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var part = MeshInstance3D.new()
	part.mesh = mesh
	part.position = local_position
	part.rotation_degrees.x = 90.0
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.layers = HORROR_FLASHLIGHT_VIEWMODEL_LAYER
	flashlight_device_root.add_child(part)
	return part

func _flashlight_device_material(color: Color, roughness: float, glow: bool = false, glow_energy: float = 1.0) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.38 if not glow else 0.0
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow_energy
	return material

func _ensure_flashlight_volume() -> void:
	if camera == null or is_instance_valid(flashlight_volume_root):
		return
	flashlight_volume_root = Node3D.new()
	flashlight_volume_root.name = "HorrorFlashlightVisibleBeam"
	flashlight_volume_root.position = Vector3.ZERO
	flashlight_volume_root.rotation_degrees = Vector3.ZERO
	var volume_parent: Node3D = flashlight_emitter if is_instance_valid(flashlight_emitter) else camera
	volume_parent.add_child(flashlight_volume_root)
	# Depth-clipped air replaces the old ribbons and overlapping mist cards.
	_ensure_flashlight_air_volume()
	_ensure_flashlight_dust()
	_ensure_flashlight_haze()

func _ensure_flashlight_air_volume() -> void:
	# Integrate illuminated air, not the faces of a transparent cone. Scene depth
	# stops the shaft at walls/props; the lens remains the only source of light.
	# Godot 4.6.2 GLES3 can inherit opaque GL_ONE additive blending for the
	# first transparent additive draw after multiple shadowed lights. Alpha
	# caps then do nothing. MIX forces the correct alpha blend state, retaining
	# the same ray-marched shaft without white fullscreen proxy-box faces.
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, cull_front, depth_draw_never, depth_test_disabled, shadows_disabled;
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec3 lens_position;
uniform vec3 lens_direction = vec3(0.0, 0.0, -1.0);
uniform float beam_intensity = 1.0;
uniform float beam_length = 20.0;
uniform float time_offset = 0.0;
varying vec3 world_vertex;
void vertex() { world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	vec3 ray = normalize(world_vertex - eye);
	float depth = texture(scene_depth, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 scene = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	// Sky/far-plane depth can reconstruct with w ~= 0 in Compatibility.
	// Never let an invalid depth propagate into additive alpha.
	float end = beam_length + 1.0;
	if (abs(scene.w) > 0.00001) {
		end = min(length(scene.xyz / scene.w), end);
	}
	float start = max(0.0, dot(lens_position - eye, ray));
	float travel = max(0.0, end - start);
	float density = 0.0;
	for (int i = 0; i < 32; i++) {
		float u0 = float(i) / 32.0;
		float u1 = float(i + 1) / 32.0;
		float stride = travel * (u1 * u1 - u0 * u0);
		float sample_distance = start + travel * (u0 * u0 + u1 * u1) * 0.5;
		vec3 p = eye + ray * sample_distance - lens_position;
		float along = dot(p, lens_direction);
		float radius = length(p - lens_direction * along);
		float cone_radius = 0.055 + max(along, 0.0) * 0.055;
		float radial = 1.0 - smoothstep(0.05, 1.0, radius / cone_radius);
		float ends = smoothstep(0.0, 0.12, along) * (1.0 - smoothstep(beam_length * 0.75, beam_length, along));
		density += radial * radial * ends * exp(-max(along, 0.0) * 0.22) / (1.0 + max(along, 0.0) * 0.8) * stride;
	}
	ALBEDO = vec3(0.86, 0.83, 0.67);
	EMISSION = vec3(0.0);
	float air_alpha = (1.0 - exp(-density * 0.9)) * clamp(beam_intensity, 0.0, 1.0);
	ALPHA = clamp(air_alpha, 0.0, 0.18);
}
"""
	flashlight_volume_material = ShaderMaterial.new()
	flashlight_volume_material.shader = shader
	var volume := MeshInstance3D.new()
	volume.name = "DepthClippedFlashlightAir"
	var box := BoxMesh.new()
	# The widest lit radius is 0.055 + 20 * 0.055 = 1.155 m.
	# Rasterize only its conservative bounds, not a 16 m fullscreen box.
	# Same 32 samples, depth clipping and density; no quality reduction.
	box.size = Vector3(2.44, 2.44, 20.0)
	volume.mesh = box
	volume.position.z = -10.0
	volume.material_override = flashlight_volume_material
	volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flashlight_volume_root.add_child(volume)

func _ensure_flashlight_beam_ribbons() -> void:
	if camera == null or flashlight_beam_ribbons.size() > 0 or not is_instance_valid(flashlight_device_root) or not is_instance_valid(flashlight_emitter):
		return
	flashlight_ribbon_material = _make_flashlight_ribbon_material(Color(0.95, 0.92, 0.78, 0.12))
	_add_flashlight_beam_ribbon("FlashlightAirBeam", 0.012, 0.62, flashlight_ribbon_material)
	flashlight_ribbon_core_material = _make_flashlight_ribbon_material(Color(1.0, 0.96, 0.84, 0.16))
	_add_flashlight_beam_ribbon("FlashlightLongRangeCore", 0.008, 0.20, flashlight_ribbon_core_material)

func _ensure_flashlight_beam_slices() -> void:
	if camera == null or not flashlight_beam_slices.is_empty():
		return
	var slice_material = _make_flashlight_beam_slice_material(Color(0.91, 0.91, 0.82, 0.024))
	var depths = [0.025, 0.045, 0.070, 0.100, 0.140, 0.190, 0.250, 0.320, 0.400, 0.490, 0.580, 0.670, 0.750, 0.820, 0.880, 0.930]
	for index in range(depths.size()):
		var slice = MeshInstance3D.new()
		slice.name = "FlashlightMistSlice_%02d" % index
		var mesh = QuadMesh.new()
		mesh.size = Vector2.ONE
		slice.mesh = mesh
		slice.material_override = slice_material
		slice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		slice.set_meta("beam_depth", float(depths[index]))
		camera.add_child(slice)
		flashlight_beam_slices.append(slice)

func _make_flashlight_beam_slice_material(color: Color) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 mist_color : source_color;
uniform float time_offset = 0.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float radius = length(vec2(p.x, p.y * 1.18));
	float body = 1.0 - smoothstep(0.14, 1.0, radius);
	float feather = body * body * (3.0 - 2.0 * body);
	float air = 0.84 + 0.08 * sin(UV.x * 19.0 + time_offset);
	air += 0.06 * sin(UV.y * 31.0 - time_offset * 0.63);
	ALBEDO = mist_color.rgb * 0.10;
	EMISSION = mist_color.rgb * 0.72;
	ALPHA = mist_color.a * feather * clamp(air, 0.62, 1.0);
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.render_priority = 23
	material.set_shader_parameter("mist_color", color)
	return material

func _update_flashlight_beam_slices(beam_length: float) -> void:
	if not is_instance_valid(flashlight_device_root) or not is_instance_valid(flashlight_emitter):
		return
	# Slices face the camera for soft blending, but their centres follow the
	# physical lens axis. Keeping the old target at camera centre left a detached
	# oval floating above the downward-aimed flashlight pool.
	var lens_global = flashlight_emitter.global_position
	var beam_direction = -flashlight_emitter.global_transform.basis.z.normalized()
	var lens_position = camera.to_local(lens_global)
	var beam_target = camera.to_local(lens_global + beam_direction * max(1.0, beam_length))
	var length_scale = clamp(beam_length / 12.0, 0.24, 1.0)
	var corridor_radius = 2.45 + beam_length * 0.060
	# Sixteen layers are useful down a long corridor but become pure overdraw
	# when compressed into the first couple of metres. Thin them near walls.
	var slice_stride = 3 if beam_length < 3.2 else (2 if beam_length < 6.5 else 1)
	for slice_index in range(flashlight_beam_slices.size()):
		var slice = flashlight_beam_slices[slice_index]
		if not is_instance_valid(slice):
			continue
		slice.visible = horror_flashlight_mode and flashlight_on and (
			slice_stride == 1
			or slice_index % slice_stride == 0
			or slice_index == flashlight_beam_slices.size() - 1
		)
		var depth = float(slice.get_meta("beam_depth", 0.5))
		slice.position = lens_position.lerp(beam_target, depth)
		var radius = (0.035 + depth * corridor_radius) * length_scale
		slice.scale = Vector3(radius * 2.0, radius * 1.34, 1.0)

func _add_flashlight_beam_ribbon(ribbon_name: String, near_width: float, far_width: float, material: Material) -> void:
	var near_center = flashlight_device_root.transform * flashlight_emitter.position
	var far_center = Vector3(0.0, -0.015, -8.5)
	var projected = Vector2(far_center.x - near_center.x, far_center.y - near_center.y)
	var perpendicular_2d = Vector2(1, 0)
	if projected.length_squared() > 0.000001:
		perpendicular_2d = Vector2(-projected.y, projected.x).normalized()
	var perpendicular = Vector3(perpendicular_2d.x, perpendicular_2d.y, 0)
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		near_center - perpendicular * near_width,
		near_center + perpendicular * near_width,
		far_center - perpendicular * far_width,
		far_center + perpendicular * far_width
	])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0)
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 1, 3, 2])
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var ribbon = MeshInstance3D.new()
	ribbon.name = ribbon_name
	ribbon.mesh = mesh
	ribbon.material_override = material
	ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ribbon.set_meta("near_width", near_width)
	ribbon.set_meta("far_width", far_width)
	camera.add_child(ribbon)
	flashlight_beam_ribbons.append(ribbon)

func _update_flashlight_beam_ribbons(beam_length: float) -> void:
	if not is_instance_valid(flashlight_device_root) or not is_instance_valid(flashlight_emitter):
		return
	var lens_global = flashlight_emitter.global_position
	var beam_direction = -flashlight_emitter.global_transform.basis.z.normalized()
	var near_center = camera.to_local(lens_global)
	var far_center = camera.to_local(lens_global + beam_direction * max(1.0, beam_length))
	var projected = Vector2(far_center.x - near_center.x, far_center.y - near_center.y)
	var perpendicular_2d = Vector2(1, 0)
	if projected.length_squared() > 0.000001:
		perpendicular_2d = Vector2(-projected.y, projected.x).normalized()
	var perpendicular = Vector3(perpendicular_2d.x, perpendicular_2d.y, 0)
	for ribbon in flashlight_beam_ribbons:
		if not is_instance_valid(ribbon) or not ribbon.mesh is ArrayMesh:
			continue
		var near_width = float(ribbon.get_meta("near_width", 0.026))
		var far_width = float(ribbon.get_meta("far_width", 0.62)) * clamp(beam_length / 8.5, 0.01, 2.4)
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
			near_center - perpendicular * near_width,
			near_center + perpendicular * near_width,
			far_center - perpendicular * far_width,
			far_center + perpendicular * far_width
		])
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0)
		])
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 1, 3, 2])
		var mesh = ribbon.mesh as ArrayMesh
		mesh.clear_surfaces()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func _make_flashlight_ribbon_material(color: Color) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 beam_color : source_color;
uniform float beam_intensity = 1.0;
uniform float time_offset = 0.0;
void fragment() {
	float horizontal = abs(UV.x - 0.5) * 2.0;
	float across = exp(-horizontal * horizontal * 4.6) * (1.0 - smoothstep(0.55, 1.0, horizontal));
	float core = exp(-horizontal * horizontal * 15.0);
	float source = smoothstep(0.0, 0.035, UV.y);
	float distance_fade = 1.0 - smoothstep(0.45, 1.0, UV.y);
	float mist = 0.78 + 0.12 * sin(UV.y * 19.0 + time_offset);
	mist += 0.08 * sin(UV.y * 53.0 - UV.x * 13.0 - time_offset * 0.47);
	mist = clamp(mist, 0.48, 1.0);
	float opacity = beam_color.a * (across * 0.72 + core * 0.28) * source * distance_fade * mist * beam_intensity;
	ALBEDO = beam_color.rgb;
	EMISSION = beam_color.rgb * (0.64 + core * 0.32);
	ALPHA = opacity;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.render_priority = 24
	material.set_shader_parameter("beam_color", color)
	return material

func _add_flashlight_fan_plane(angle: float, material: Material) -> void:
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-0.001, 0.0, -0.008), Vector3(0.001, 0.0, -0.008),
		Vector3(-0.205, 0.0, -1.0), Vector3(0.205, 0.0, -1.0)
	])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0)
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 1, 3, 2])
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var fan = MeshInstance3D.new()
	fan.name = "BeamFan_%03d" % int(angle)
	fan.mesh = mesh
	fan.rotation_degrees.z = angle
	fan.material_override = material
	fan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fan.set_meta("flashlight_volume_kind", "fan")
	flashlight_volume_root.add_child(fan)
	flashlight_volume_planes.append(fan)

func _add_flashlight_cone_shell(radius: float, material: Material, shell_name: String) -> void:
	var shell = MeshInstance3D.new()
	shell.name = shell_name
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var segments = 24
	for index in range(segments):
		var angle_a = TAU * float(index) / float(segments)
		var angle_b = TAU * float(index + 1) / float(segments)
		vertices.append(Vector3(0, 0, -0.006))
		vertices.append(Vector3(cos(angle_a) * radius, sin(angle_a) * radius, -1.0))
		vertices.append(Vector3(cos(angle_b) * radius, sin(angle_b) * radius, -1.0))
		uvs.append(Vector2((float(index) + 0.5) / float(segments), 0.0))
		uvs.append(Vector2(float(index) / float(segments), 1.0))
		uvs.append(Vector2(float(index + 1) / float(segments), 1.0))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var cone = ArrayMesh.new()
	cone.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	shell.mesh = cone
	shell.material_override = material
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.set_meta("flashlight_volume_kind", "cone")
	flashlight_volume_root.add_child(shell)
	flashlight_volume_planes.append(shell)

func _add_flashlight_mist_slice(depth: float, radius: float, material: Material, prefix: String) -> void:
	var slice = MeshInstance3D.new()
	slice.name = "%s_%02d" % [prefix, flashlight_volume_planes.size()]
	var mesh = QuadMesh.new()
	mesh.size = Vector2(radius * 2.0, radius * 2.0)
	slice.mesh = mesh
	slice.position.z = -depth
	slice.material_override = material
	slice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	slice.set_meta("flashlight_volume_kind", "slice")
	slice.set_meta("flashlight_volume_depth", depth)
	flashlight_volume_root.add_child(slice)
	flashlight_volume_planes.append(slice)

func _make_flashlight_volume_material(color: Color, intensity: float) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 beam_color : source_color;
uniform float beam_intensity = 1.0;
uniform float time_offset = 0.0;
void fragment() {
	float source_fade = smoothstep(0.0, 0.09, UV.y);
	float end_fade = 1.0 - smoothstep(0.68, 1.0, UV.y);
	float broken_density = 0.64 + 0.20 * sin(UV.y * 31.0 + UV.x * 9.0 + time_offset);
	broken_density += 0.16 * sin(UV.y * 83.0 - UV.x * 17.0 - time_offset * 0.37);
	float edge_variation = 0.82 + 0.18 * sin(UV.x * 6.28318 + time_offset * 0.21);
	float opacity = beam_color.a * source_fade * end_fade * broken_density * edge_variation;
	ALBEDO = beam_color.rgb * 0.10;
	EMISSION = beam_color.rgb * beam_intensity * 0.58;
	ALPHA = opacity;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.render_priority = 84
	material.set_shader_parameter("beam_color", color)
	material.set_shader_parameter("beam_intensity", intensity)
	return material

func _make_flashlight_slice_material(color: Color) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 mist_color : source_color;
uniform float time_offset = 0.0;
uniform float beam_intensity = 1.0;
void fragment() {
	vec2 p = UV - vec2(0.5);
	float radial = 1.0 - smoothstep(0.04, 0.50, length(p));
	float center_soften = smoothstep(0.0, 0.08, length(p)) * 0.18 + 0.82;
	float drifting = 0.78 + 0.14 * sin(UV.x * 15.0 + time_offset);
	drifting += 0.08 * sin(UV.y * 27.0 - time_offset * 0.73);
	float opacity = mist_color.a * radial * radial * center_soften * drifting * beam_intensity;
	ALBEDO = mist_color.rgb * 0.08;
	EMISSION = mist_color.rgb * 1.10;
	ALPHA = opacity;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("mist_color", color)
	return material

func _make_flashlight_fan_material(color: Color) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 beam_color : source_color;
uniform float time_offset = 0.0;
uniform float beam_intensity = 1.0;
void fragment() {
	float edge = 1.0 - smoothstep(0.10, 0.50, abs(UV.x - 0.5));
	float source_fade = smoothstep(0.0, 0.018, UV.y);
	float end_fade = 1.0 - smoothstep(0.78, 1.0, UV.y);
	float grain = 0.82 + 0.10 * sin(UV.y * 47.0 + time_offset);
	grain += 0.08 * sin(UV.y * 103.0 - UV.x * 11.0 - time_offset * 0.47);
	float opacity = beam_color.a * edge * edge * source_fade * end_fade * grain * beam_intensity;
	ALBEDO = beam_color.rgb * 0.46;
	EMISSION = beam_color.rgb * 0.28;
	ALPHA = opacity;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("beam_color", color)
	return material

func _ensure_flashlight_dust() -> void:
	if not is_instance_valid(flashlight_volume_root) or is_instance_valid(flashlight_dust):
		return
	flashlight_dust = GPUParticles3D.new()
	flashlight_dust.name = "FlashlightDustMotes"
	flashlight_dust.amount = 16
	flashlight_dust.lifetime = 8.6
	flashlight_dust.preprocess = 8.6
	flashlight_dust.randomness = 1.0
	# Particles keep their world position after spawning instead of rotating with
	# the flashlight, so turning the beam reveals existing dust in the room.
	flashlight_dust.local_coords = false
	flashlight_dust.visibility_aabb = AABB(Vector3(-12.0, -7.0, -24.0), Vector3(24.0, 14.0, 48.0))
	flashlight_dust.position = Vector3(0, 0, -3.0)
	flashlight_dust_process = ParticleProcessMaterial.new()
	flashlight_dust_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	flashlight_dust_process.emission_box_extents = Vector3(0.58, 0.40, 3.2)
	flashlight_dust_process.direction = Vector3(0.12, 0.72, 0.08)
	flashlight_dust_process.spread = 180.0
	flashlight_dust_process.initial_velocity_min = 0.008
	flashlight_dust_process.initial_velocity_max = 0.075
	flashlight_dust_process.gravity = Vector3(0, 0.002, 0)
	flashlight_dust_process.scale_min = 0.22
	flashlight_dust_process.scale_max = 1.24
	flashlight_dust_process.angle_min = -180.0
	flashlight_dust_process.angle_max = 180.0
	flashlight_dust_process.angular_velocity_min = -16.0
	flashlight_dust_process.angular_velocity_max = 16.0
	var dust_mesh = QuadMesh.new()
	dust_mesh.size = Vector2(0.026, 0.026)
	var dust_material = ShaderMaterial.new()
	var dust_shader = Shader.new()
	dust_shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
varying float particle_eye_depth;
void vertex() {
	particle_eye_depth = -(VIEW_MATRIX * MODEL_MATRIX[3]).z;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float circle = 1.0 - smoothstep(0.28, 0.50, length(UV - vec2(0.5)));
	ALBEDO = vec3(0.92, 0.86, 0.67);
	EMISSION = vec3(0.44, 0.39, 0.27) * circle;
	ALPHA = circle * 0.24 * smoothstep(0.25, 0.8, particle_eye_depth);
}
"""
	dust_material.shader = dust_shader
	dust_mesh.material = dust_material
	flashlight_dust.process_material = flashlight_dust_process
	flashlight_dust.draw_pass_1 = dust_mesh
	flashlight_volume_root.add_child(flashlight_dust)

func _ensure_flashlight_haze() -> void:
	if not is_instance_valid(flashlight_volume_root) or is_instance_valid(flashlight_haze):
		return
	flashlight_haze = GPUParticles3D.new()
	flashlight_haze.name = "FlashlightIlluminatedMist"
	flashlight_haze.amount = 18
	flashlight_haze.lifetime = 11.0
	flashlight_haze.preprocess = 11.0
	flashlight_haze.randomness = 1.0
	flashlight_haze.local_coords = false
	flashlight_haze.visibility_aabb = AABB(Vector3(-14.0, -8.0, -28.0), Vector3(28.0, 16.0, 56.0))
	flashlight_haze.position = Vector3(0, 0, -8.0)
	flashlight_haze_process = ParticleProcessMaterial.new()
	flashlight_haze_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	flashlight_haze_process.emission_box_extents = Vector3(0.66, 0.44, 8.0)
	flashlight_haze_process.direction = Vector3(-0.08, 0.58, 0.12)
	flashlight_haze_process.spread = 180.0
	flashlight_haze_process.initial_velocity_min = 0.002
	flashlight_haze_process.initial_velocity_max = 0.022
	flashlight_haze_process.gravity = Vector3(0, 0.001, 0)
	flashlight_haze_process.scale_min = 0.64
	flashlight_haze_process.scale_max = 2.75
	flashlight_haze_process.angle_min = -180.0
	flashlight_haze_process.angle_max = 180.0
	flashlight_haze_process.angular_velocity_min = -4.0
	flashlight_haze_process.angular_velocity_max = 4.0
	var haze_mesh = QuadMesh.new()
	haze_mesh.size = Vector2(1.28, 0.74)
	var haze_material = ShaderMaterial.new()
	var haze_shader = Shader.new()
	haze_shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
varying float particle_eye_depth;
void vertex() {
	particle_eye_depth = -(VIEW_MATRIX * MODEL_MATRIX[3]).z;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = UV - vec2(0.5);
	float radius = length(p);
	float soft_cloud = exp(-radius * radius * 12.0);
	float broken_edge = 0.70 + 0.18 * sin((UV.x * 1.7 + UV.y * 2.1) * 6.28318);
	broken_edge += 0.12 * sin((UV.x * 3.4 - UV.y * 1.3) * 6.28318);
	float density = soft_cloud * soft_cloud * clamp(broken_edge, 0.1, 1.0);
	vec3 warm_haze = vec3(0.86, 0.83, 0.69);
	ALBEDO = warm_haze * 0.10;
	EMISSION = warm_haze * 0.36;
	// World-space mist must dissolve before the player walks through its quad.
	ALPHA = density * 0.125 * smoothstep(0.8, 2.0, particle_eye_depth);
}
"""
	haze_material.shader = haze_shader
	haze_mesh.material = haze_material
	flashlight_haze.process_material = flashlight_haze_process
	flashlight_haze.draw_pass_1 = haze_mesh
	flashlight_volume_root.add_child(flashlight_haze)

func _update_horror_flashlight_visibility() -> void:
	if is_instance_valid(horror_mist_layer):
		horror_mist_layer.visible = false
	if is_instance_valid(flashlight_primary):
		flashlight_primary.visible = horror_flashlight_mode and flashlight_on
	if is_instance_valid(flashlight_hotspot):
		flashlight_hotspot.visible = false
	if is_instance_valid(flashlight_long_throw):
		flashlight_long_throw.visible = false
	if is_instance_valid(flashlight_camera_throw):
		# Compatibility with an already-running scene created by an older build.
		# New scenes no longer instantiate this second, camera-centred light.
		flashlight_camera_throw.visible = false
	if is_instance_valid(flashlight_camera_fill):
		flashlight_camera_fill.visible = false
	if is_instance_valid(flashlight_fill):
		flashlight_fill.visible = false
	for corridor_light in flashlight_corridor_lights:
		if is_instance_valid(corridor_light):
			corridor_light.visible = horror_flashlight_mode and flashlight_on
	if is_instance_valid(flashlight_volume_root):
		flashlight_volume_root.visible = horror_flashlight_mode and flashlight_on
	for ribbon in flashlight_beam_ribbons:
		if is_instance_valid(ribbon):
			ribbon.visible = horror_flashlight_mode and flashlight_on
	for slice in flashlight_beam_slices:
		if is_instance_valid(slice):
			slice.visible = horror_flashlight_mode and flashlight_on
	if is_instance_valid(flashlight_device_root):
		flashlight_device_root.visible = horror_flashlight_mode
	if is_instance_valid(flashlight_source_glow):
		flashlight_source_glow.visible = horror_flashlight_mode and flashlight_on
	if is_instance_valid(flashlight_source_neck):
		flashlight_source_neck.visible = horror_flashlight_mode and flashlight_on
	if is_instance_valid(flashlight_source_light):
		flashlight_source_light.visible = horror_flashlight_mode and flashlight_on
	if is_instance_valid(flashlight_viewmodel_fill):
		flashlight_viewmodel_fill.visible = horror_flashlight_mode
		flashlight_viewmodel_fill.light_energy = 0.21 if flashlight_on else 0.018
	if is_instance_valid(flashlight_dust):
		flashlight_dust.emitting = horror_flashlight_mode
	if is_instance_valid(flashlight_haze):
		flashlight_haze.emitting = horror_flashlight_mode

func _tick_horror_flashlight(dt: float) -> void:
	if not horror_flashlight_mode:
		return
	if paused:
		return
	if flashlight_on:
		horror_battery_seconds = maxf(0.0, horror_battery_seconds - dt * HORROR_BATTERY_DRAIN_RATE)
		if horror_battery_seconds <= 0.0:
			flashlight_on = false
			_update_horror_flashlight_visibility()
	_tick_horror_near_visibility(dt)
	flashlight_time += dt
	horror_flashlight_strain_timer = max(0.0, horror_flashlight_strain_timer - dt)
	if not flashlight_on:
		horror_flashlight_focus_heat = max(0.0, horror_flashlight_focus_heat - HORROR_FLASHLIGHT_OFF_COOL_RATE * dt)
	elif horror_flashlight_strain_timer <= 0.0:
		horror_flashlight_focus_heat = move_toward(horror_flashlight_focus_heat, 0.08, HORROR_FLASHLIGHT_FOCUS_COOL_RATE * dt)
	horror_flashlight_strain_strength = move_toward(horror_flashlight_strain_strength, 0.0, dt * 1.6)
	var heat_curve = smoothstep(0.48, 1.0, horror_flashlight_focus_heat)
	var stressed_flutter = max(0.0, sin(flashlight_time * 23.0) * sin(flashlight_time * 7.7)) * heat_curve
	horror_flashlight_output = clamp(1.0 - heat_curve * 0.34 - stressed_flutter * 0.12, 0.52, 1.0)
	# The last two battery units fade smoothly before dark adaptation starts.
	horror_flashlight_output *= smoothstep(0.0, 2.0, horror_battery_seconds)
	_update_horror_flashlight_device_motion(dt, heat_curve)
	if is_instance_valid(flashlight_primary) and flashlight_on:
		var movement_flutter = clamp(horizontal_speed / 18.0, 0.0, 1.0) * 0.025
		# A healthy flashlight is steady; rapid idle flutter strobed every prop.
		var electrical_flutter = (sin(flashlight_time * 17.0) * 0.035 + sin(flashlight_time * 41.0) * 0.018) * heat_curve
		var energy_scale = (1.0 - movement_flutter + electrical_flutter) * horror_flashlight_output
		flashlight_primary.light_energy = 12.0 * energy_scale
		if is_instance_valid(flashlight_hotspot):
			flashlight_hotspot.visible = false
		if is_instance_valid(flashlight_fill):
			flashlight_fill.visible = false
		if is_instance_valid(flashlight_camera_fill):
			flashlight_camera_fill.visible = false
		if is_instance_valid(flashlight_source_light):
			flashlight_source_light.light_energy = 0.08 * (1.0 + electrical_flutter * 0.05) * horror_flashlight_output
		if flashlight_source_visual_material != null:
			flashlight_source_visual_material.set_shader_parameter("source_intensity", horror_flashlight_output * (1.0 + electrical_flutter * 0.18))
		if is_instance_valid(flashlight_source_neck):
			var neck_material = flashlight_source_neck.get_meta("source_material", null) as ShaderMaterial
			if neck_material != null:
				neck_material.set_shader_parameter("source_intensity", horror_flashlight_output * (1.0 + electrical_flutter * 0.12))
		if is_instance_valid(flashlight_viewmodel_fill):
			flashlight_viewmodel_fill.light_energy = 0.21 * (1.0 + electrical_flutter * 0.04) * horror_flashlight_output
		_update_flashlight_volume(dt, electrical_flutter)

func _update_horror_flashlight_device_motion(dt: float, heat_curve: float) -> void:
	if not is_instance_valid(flashlight_device_root):
		return
	var motion = clamp(horizontal_speed / HORROR_SPRINT_SPEED, 0.0, 1.0)
	var sprint = 1.0 if horror_sprint_active else 0.0
	var pace = lerp(5.2, 8.6, sprint)
	var phase = flashlight_time * pace
	var side_sway = sin(phase) * motion
	var vertical_sway = abs(cos(phase)) * motion
	var strain = horror_flashlight_strain_strength * heat_curve
	var tremor_x = sin(flashlight_time * 27.0) * strain
	var tremor_y = sin(flashlight_time * 35.0 + 1.4) * strain
	var target_position = HORROR_FLASHLIGHT_DEVICE_POSITION + Vector3(
		side_sway * lerp(0.004, 0.010, sprint) + tremor_x * 0.0018,
		-vertical_sway * lerp(0.003, 0.009, sprint) + tremor_y * 0.0015,
		vertical_sway * 0.004
	)
	var target_rotation = HORROR_FLASHLIGHT_DEVICE_ROTATION + Vector3(
		-vertical_sway * lerp(0.28, 0.72, sprint) + tremor_y * 0.20,
		side_sway * lerp(0.42, 1.05, sprint) + tremor_x * 0.18,
		-side_sway * lerp(0.62, 1.42, sprint)
	)
	var response = 1.0 - exp(-lerp(8.5, 12.0, sprint) * dt)
	flashlight_device_root.position = flashlight_device_root.position.lerp(target_position, response)
	flashlight_device_root.rotation_degrees = flashlight_device_root.rotation_degrees.lerp(target_rotation, response)

func _update_flashlight_volume(dt: float, electrical_flutter: float) -> void:
	if not is_instance_valid(flashlight_volume_root):
		return
	flashlight_volume_probe_timer -= dt
	if flashlight_volume_probe_timer <= 0.0:
		flashlight_volume_probe_timer = 0.045
		flashlight_volume_target_length = 20.0
		if level_manager != null and level_manager.has_method("wall_hit_along_segment") and is_instance_valid(camera):
			# Probe down the player's actual aim rather than the animated prop. A
			# hand-sway offset near a door frame must not make the beam latch onto a
			# side wall while the crosshair still has a clear corridor ahead.
			var direction = -camera.global_transform.basis.z.normalized()
			var origin = camera.global_position + direction * 0.10
			var hit = level_manager.wall_hit_along_segment(origin, origin + direction * 20.0, 0.035)
			if bool(hit.get("hit", false)):
				flashlight_volume_target_length = clamp(origin.distance_to(hit.get("position", origin + direction * 20.0)) - 0.16, 0.55, 20.0)
	# Retraction is intentionally faster than extension. Occlusion therefore
	# wins immediately, while a newly revealed long corridor opens smoothly.
	var length_response = 36.0 if flashlight_volume_target_length < flashlight_volume_length else 11.0
	flashlight_volume_length = lerp(flashlight_volume_length, flashlight_volume_target_length, clamp(dt * length_response, 0.0, 1.0))
	if is_instance_valid(flashlight_long_throw):
		flashlight_long_throw.visible = false
	if is_instance_valid(flashlight_camera_throw):
		flashlight_camera_throw.visible = false
	_update_flashlight_corridor_lights(electrical_flutter)
	var visible_beam_length = min(flashlight_volume_length, 19.0)
	# The held model moves every frame, so its camera-space air layers must do
	# the same even though the more expensive wall probe is rate-limited.
	_update_flashlight_beam_ribbons(visible_beam_length)
	_update_flashlight_beam_slices(visible_beam_length)
	var particle_length = max(0.65, min(flashlight_volume_length - 0.20, 11.0))
	var half_particle_length = particle_length * 0.5
	var distance_ratio = clamp(particle_length / 18.0, 0.12, 1.85)
	if is_instance_valid(flashlight_dust):
		flashlight_dust.position.z = -half_particle_length
	if flashlight_dust_process != null:
		flashlight_dust_process.emission_box_extents = Vector3(0.18 + distance_ratio * 0.44, 0.13 + distance_ratio * 0.30, half_particle_length)
	if is_instance_valid(flashlight_haze):
		flashlight_haze.position.z = -half_particle_length
	if flashlight_haze_process != null:
		flashlight_haze_process.emission_box_extents = Vector3(0.16 + distance_ratio * 0.40, 0.11 + distance_ratio * 0.27, half_particle_length)
	for plane in flashlight_volume_planes:
		if not is_instance_valid(plane):
			continue
		var volume_kind = String(plane.get_meta("flashlight_volume_kind", "cone"))
		if volume_kind == "slice":
			var normalized_depth = float(plane.get_meta("flashlight_volume_depth", 0.5))
			plane.position.z = -visible_beam_length * normalized_depth
			plane.scale = Vector3(visible_beam_length, visible_beam_length, 1.0)
		elif volume_kind == "fan":
			plane.position = Vector3.ZERO
			plane.scale = Vector3(visible_beam_length, visible_beam_length, visible_beam_length)
		else:
			# The cone mesh already runs from the lens at z=0 to z=-1.
			# Translating it by half its length detached the visible shaft from
			# the physical flashlight and made illumination appear at the wall.
			plane.position = Vector3.ZERO
			plane.scale = Vector3(visible_beam_length, visible_beam_length, visible_beam_length)
	if flashlight_volume_material != null:
		flashlight_volume_material.set_shader_parameter("lens_position", flashlight_emitter.global_position)
		flashlight_volume_material.set_shader_parameter("lens_direction", -flashlight_emitter.global_basis.z.normalized())
		flashlight_volume_material.set_shader_parameter("beam_length", 20.0)
		flashlight_volume_material.set_shader_parameter("time_offset", flashlight_time * 0.42)
		flashlight_volume_material.set_shader_parameter("beam_intensity", horror_flashlight_output * (1.0 + electrical_flutter * 0.8))
	if flashlight_volume_core_material != null:
		flashlight_volume_core_material.set_shader_parameter("time_offset", flashlight_time * 0.57 + 2.1)
		flashlight_volume_core_material.set_shader_parameter("beam_intensity", horror_flashlight_output * (1.0 + electrical_flutter * 0.9))
	if flashlight_slice_material != null:
		flashlight_slice_material.set_shader_parameter("time_offset", flashlight_time * 0.31)
		flashlight_slice_material.set_shader_parameter("beam_intensity", horror_flashlight_output * (1.0 + electrical_flutter * 0.32))
	if flashlight_slice_core_material != null:
		flashlight_slice_core_material.set_shader_parameter("time_offset", flashlight_time * 0.43 + 1.7)
		flashlight_slice_core_material.set_shader_parameter("beam_intensity", horror_flashlight_output * (1.0 + electrical_flutter * 0.38))
	if flashlight_fan_material != null:
		flashlight_fan_material.set_shader_parameter("time_offset", flashlight_time * 0.27 + 0.8)
		flashlight_fan_material.set_shader_parameter("beam_intensity", horror_flashlight_output * (1.0 + electrical_flutter * 0.55))
	if flashlight_ribbon_material != null:
		flashlight_ribbon_material.set_shader_parameter("time_offset", flashlight_time * 0.24)
	if not flashlight_beam_slices.is_empty():
		var slice_material = flashlight_beam_slices[0].material_override as ShaderMaterial
		if slice_material != null:
			slice_material.set_shader_parameter("time_offset", flashlight_time * 0.18)
		if flashlight_ribbon_material != null:
			flashlight_ribbon_material.set_shader_parameter("beam_intensity", horror_flashlight_output * (1.0 + electrical_flutter * 0.60))
	if flashlight_ribbon_core_material != null:
		flashlight_ribbon_core_material.set_shader_parameter("time_offset", flashlight_time * 0.31 + 1.4)
		var corridor_boost = lerp(0.92, 1.08, clamp((visible_beam_length - 12.0) / 14.0, 0.0, 1.0))
		flashlight_ribbon_core_material.set_shader_parameter("beam_intensity", horror_flashlight_output * (corridor_boost + electrical_flutter * 0.48))

func _update_flashlight_corridor_lights(electrical_flutter: float) -> void:
	# Legacy compatibility helpers are intentionally disabled. Surface shaders
	# now provide the reflected response, while these Omni lights read as two
	# separate circles marching ahead of the player.
	for corridor_light in flashlight_corridor_lights:
		if is_instance_valid(corridor_light):
			corridor_light.visible = false
	return
	if flashlight_corridor_lights.is_empty():
		return
	var usable_length = max(1.0, flashlight_volume_length - 0.65)
	var desired_distances = [
		min(2.4, usable_length * 0.44),
		min(usable_length, clampf(usable_length * 0.38, 3.1, 10.5)),
		min(usable_length, 18.0)
	]
	var base_ranges = [5.6, 6.2, 4.4]
	var base_energies = [0.56, 0.22, 0.08]
	for index in flashlight_corridor_lights.size():
		var corridor_light = flashlight_corridor_lights[index]
		if not is_instance_valid(corridor_light):
			continue
		var desired_distance = float(desired_distances[index])
		var distance_strength = clampf(flashlight_volume_length / (7.0 + float(index) * 4.0), 0.38, 1.0)
		corridor_light.position = Vector3(0.0, -0.18 - float(index) * 0.12, -desired_distance)
		var available_space = max(1.45, usable_length - desired_distance + 1.10)
		corridor_light.omni_range = minf(
			float(base_ranges[index]) * lerp(0.72, 1.0, distance_strength),
			available_space
		)
		corridor_light.light_energy = float(base_energies[index]) * distance_strength * (1.0 + electrical_flutter * 0.24) * horror_flashlight_output
		var minimum_length = float([1.2, 4.2, 2.0][index])
		corridor_light.visible = horror_flashlight_mode and flashlight_on and flashlight_volume_length > minimum_length

func reset_spawn(spawn: Vector3) -> void:
	global_position = spawn
	if level_manager != null:
		global_position.y = level_manager.floor_height_at(global_position)
	hp = 100
	hp_float = 100.0
	armor = ARMOR_MAX
	armor_float = float(ARMOR_MAX)
	armor_recharge_delay = 0.0
	passive_heal_delay = 0.0
	dodge_immunity_timer = 0.0
	post_slide_super_jump_timer = 0.0
	yaw = 0.0
	pitch = 0.0
	target_yaw = 0.0
	target_pitch = 0.0
	vertical_velocity = 0.0
	grounded = true
	dash_cooldown = 0.0
	dash_total = SLIDE_COOLDOWN
	damage_flash = 0.0
	dash_flash = 0.0
	shake_timer = 0.0
	shake_strength = 0.0
	super_jump_cooldown = 0.0
	jumps_left = 1
	jump_charge_active = false
	jump_charge_timer = 0.0
	jump_charge_amount = 0.0
	last_jump_charge_amount = 0.0
	wall_jump_cooldown = 0.0
	wall_push_velocity = Vector3.ZERO
	horizontal_velocity = Vector3.ZERO
	horizontal_speed = 0.0
	slide_active = false
	slide_airborne = false
	slide_hold_locked = false
	slide_timer = 0.0
	slide_velocity = Vector3.ZERO
	slide_intensity = 0.0
	slide_visual_intensity = 0.0
	slide_crouch = 0.0
	air_slide_used = false
	momentum_intensity = 0.0
	grapple_momentum_intensity = 0.0
	surface_slide_factor = 0.0
	body_roll = 0.0
	body_pitch = 0.0
	body_yaw = 0.0
	movement_lean_memory = 0.0
	look_lean_memory = 0.0
	drift_swing_phase = 0.0
	last_lean_yaw = yaw
	post_slide_lean_timer = 0.0
	landing_kick = 0.0
	wall_impact = 0.0
	air_time = 0.0
	last_floor_y = global_position.y
	surface_launch_memory = 0.0
	grapple_active = false
	grapple_cooldown = 0.0
	grapple_visual_timer = 0.0
	grapple_timer = 0.0
	last_grapple_velocity = Vector3.ZERO
	grapple_enemy = null
	grapple_enemy_mode = ""
	horror_sprint_stamina = HORROR_STAMINA_MAX
	horror_sprint_active = false
	horror_sprint_recovery_delay = 0.0
	horror_sprint_exhausted = false
	horror_hidden = false
	horror_cinematic_locked = false
	move_intensity = 0.0
	move_forward = 0.0
	move_strafe = 0.0
	camera_bob_time = 0.0
	if camera != null:
		camera.position = camera_base_position
	hp_changed.emit(hp)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and not paused and not horror_cinematic_locked:
		target_yaw -= event.relative.x * LOOK_SENS * look_sensitivity_multiplier
		target_pitch = clamp(target_pitch - event.relative.y * LOOK_SENS * look_sensitivity_multiplier, deg_to_rad(-78), deg_to_rad(78))
	if event is InputEventMouseButton and event.pressed and not paused:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not horror_flashlight_mode:
				shoot_requested.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not horror_flashlight_mode:
				special_requested.emit()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if not horror_flashlight_mode:
				grenade_requested.emit()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if not horror_flashlight_mode:
				weapon_cycle_requested.emit(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if not horror_flashlight_mode:
				weapon_cycle_requested.emit(-1)
	if event is InputEventKey and not event.pressed and not event.echo and not paused:
		if event.keycode == KEY_SPACE and jump_charge_active and not horror_flashlight_mode:
			_release_jump_charge()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			paused = not paused
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED)
		elif paused and event.keycode == KEY_Q:
			get_tree().quit()
		elif not paused:
			if horror_cinematic_locked:
				return
			if horror_hidden:
				if event.keycode == KEY_E:
					interact_requested.emit()
				elif event.keycode == KEY_F:
					_toggle_horror_flashlight()
				return
			if event.keycode == KEY_SPACE:
				if horror_flashlight_mode:
					_horror_jump()
					return
				if grapple_active:
					_cancel_grapple(true)
					return
				if grounded:
					_start_jump_charge()
				else:
					_jump()
			elif event.keycode == KEY_F:
				if horror_flashlight_mode:
					_toggle_horror_flashlight()
				else:
					shoot_requested.emit()
			elif event.keycode == KEY_V:
				if not horror_flashlight_mode:
					melee_requested.emit()
			elif event.keycode == KEY_R:
				if not horror_flashlight_mode:
					reload_requested.emit()
			elif event.keycode == KEY_G:
				if not horror_flashlight_mode:
					grenade_requested.emit()
			elif event.keycode == KEY_Q:
				if not horror_flashlight_mode:
					if grapple_active:
						_cancel_grapple(true)
					else:
						_start_grapple()
			elif event.keycode == KEY_E:
				interact_requested.emit()
			elif event.keycode == KEY_SHIFT:
				if not horror_flashlight_mode:
					_start_slide()
			elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
				if not horror_flashlight_mode:
					weapon_slot_requested.emit(event.keycode - KEY_1)

func tick(dt: float) -> void:
	if paused:
		return
	_tick_horror_flashlight(dt)
	powerups.tick(dt)
	_tick_survivability(dt)
	dash_cooldown = max(0.0, dash_cooldown - dt)
	damage_flash = max(0.0, damage_flash - dt * 3.2)
	dash_flash = max(0.0, dash_flash - dt * 5.0)
	shake_timer = max(0.0, shake_timer - dt)
	super_jump_cooldown = max(0.0, super_jump_cooldown - dt)
	wall_jump_cooldown = max(0.0, wall_jump_cooldown - dt)
	grapple_cooldown = max(0.0, grapple_cooldown - dt)
	grapple_visual_timer = max(0.0, grapple_visual_timer - dt)
	dodge_immunity_timer = max(0.0, dodge_immunity_timer - dt)
	post_slide_super_jump_timer = max(0.0, post_slide_super_jump_timer - dt)
	slow_timer = max(0.0, slow_timer - dt)
	zoom_timer = max(0.0, zoom_timer - dt)
	landing_kick = max(0.0, landing_kick - dt * 5.5)
	wall_push_velocity = wall_push_velocity.move_toward(Vector3.ZERO, 12.0 * dt)
	_tick_horror_sprint(dt)
	if not horror_flashlight_mode:
		_update_jump_charge(dt)
		_update_slide_hold_input()
	if Input.is_key_pressed(KEY_LEFT) and not horror_cinematic_locked:
		target_yaw += KEY_LOOK_SPEED * dt
	if Input.is_key_pressed(KEY_RIGHT) and not horror_cinematic_locked:
		target_yaw -= KEY_LOOK_SPEED * dt
	if Input.is_key_pressed(KEY_UP) and not horror_cinematic_locked:
		target_pitch = clamp(target_pitch + KEY_LOOK_SPEED * dt, deg_to_rad(-78), deg_to_rad(78))
	if Input.is_key_pressed(KEY_DOWN) and not horror_cinematic_locked:
		target_pitch = clamp(target_pitch - KEY_LOOK_SPEED * dt, deg_to_rad(-78), deg_to_rad(78))
	# Horror look remains slightly weighty, but must settle with the mouse instead
	# of continuing to rotate after a quick turn.
	var look_response_base := 0.00030 if horror_flashlight_mode else 0.0008
	var look_response := 1.0 - pow(look_response_base, dt)
	yaw = lerp_angle(yaw, target_yaw, look_response)
	pitch = lerp(pitch, target_pitch, look_response)
	rotation.y = yaw
	if horror_cinematic_locked:
		horizontal_velocity = Vector3.ZERO
		horizontal_speed = 0.0
		vertical_velocity = 0.0
		grounded = true
		_update_body_physics(dt)
		_update_camera_motion(dt)
		return
	if horror_hidden:
		global_position = horror_hide_position
		horizontal_velocity = Vector3.ZERO
		vertical_velocity = 0.0
		grounded = true
		_update_body_physics(dt)
		_update_camera_motion(dt)
		return
	if not horror_flashlight_mode:
		_apply_grapple(dt)
	_handle_movement(dt)
	_apply_vertical(dt)
	_resolve_solid_embed()
	_update_body_physics(dt)
	_update_camera_motion(dt)
	dash_changed.emit(dash_cooldown, dash_total)

func _handle_movement(dt: float) -> void:
	if horror_flashlight_mode:
		_handle_horror_movement(dt)
	elif _uses_continuous_slide_movement():
		_handle_ice_movement(dt)
	else:
		_handle_classic_movement(dt)

func _handle_horror_movement(dt: float) -> void:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var move := _movement_input_dir(forward, right)
	var target_velocity := Vector3.ZERO
	if move.length() > 0.0:
		# Retreating and pure strafing are intentionally slower than committing
		# forward. Sprint remains a stamina-governed escape tool, not arena skating.
		var backward_amount := maxf(0.0, -move_forward)
		var strafe_amount := absf(move_strafe) * (1.0 - maxf(0.0, move_forward) * 0.28)
		var directional_scale: float = lerp(1.0, 0.76, backward_amount)
		directional_scale *= lerp(1.0, 0.86, strafe_amount)
		var target_speed := HORROR_SPRINT_SPEED if horror_sprint_active else HORROR_WALK_SPEED
		target_speed *= directional_scale
		if slow_timer > 0.0:
			target_speed *= slow_multiplier
		target_velocity = move * target_speed
	var acceleration := HORROR_SPRINT_ACCEL if horror_sprint_active else HORROR_WALK_ACCEL
	if not grounded:
		acceleration = HORROR_AIR_ACCEL
	if move.length() > 0.0:
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * dt)
	else:
		var brake := HORROR_BRAKE if grounded else HORROR_AIR_BRAKE
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, brake * dt)
	var speed_cap := HORROR_SPRINT_SPEED if horror_sprint_active else HORROR_WALK_SPEED
	if horizontal_velocity.length() > speed_cap:
		horizontal_velocity = horizontal_velocity.limit_length(speed_cap)
	_move_horizontal_velocity(dt)

func _uses_continuous_slide_movement() -> bool:
	return level_manager != null and int(level_manager.level_index) == 11

func _handle_classic_movement(dt: float) -> void:
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var move = _movement_input_dir(forward, right)
	if slide_active:
		_apply_slide(dt, move)
		horizontal_speed = horizontal_velocity.length()
		return
	var target_velocity = Vector3.ZERO
	var speed_mult = powerups.speed_multiplier() * (slow_multiplier if slow_timer > 0.0 else 1.0)
	var base_speed = (HORROR_SPRINT_SPEED if horror_sprint_active else HORROR_WALK_SPEED) if horror_flashlight_mode else BASE_SPEED
	if move.length() > 0.0:
		target_velocity = move.normalized() * base_speed * speed_mult
	var accel = (36.0 if horror_sprint_active else 25.0) if horror_flashlight_mode and grounded else (GROUND_ACCEL if grounded else AIR_ACCEL)
	var friction = GROUND_FRICTION if grounded else AIR_FRICTION
	var speed = horizontal_velocity.length()
	var glide = _momentum_glide_factor(speed)
	if move.length() > 0.0:
		if grounded and speed > base_speed * speed_mult * 1.08:
			var preserved_speed = lerp(speed, base_speed * speed_mult, clamp(dt * (1.45 - surface_slide_factor * 0.55), 0.0, 0.22))
			var guided_velocity = move.normalized() * preserved_speed
			horizontal_velocity = horizontal_velocity.lerp(guided_velocity, clamp(dt * accel * 0.070, 0.0, 0.22))
			horizontal_velocity = horizontal_velocity.move_toward(target_velocity, friction * (0.18 + 0.22 * (1.0 - surface_slide_factor)) * dt)
		else:
			horizontal_velocity = horizontal_velocity.move_toward(target_velocity, accel * dt)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, friction * (1.0 - glide) * dt)
	_move_horizontal_velocity(dt)

func _move_horizontal_velocity(dt: float) -> void:
	var final_velocity = horizontal_velocity + wall_push_velocity
	if final_velocity.length() > 0.02:
		var moved = _try_move(final_velocity * dt)
		if not moved:
			var normal = level_manager.wall_contact_normal(global_position, PLAYER_RADIUS + 0.12) if level_manager != null else Vector3.ZERO
			if normal.length() > 0.0:
				horizontal_velocity = horizontal_velocity.slide(normal).limit_length(max(0.0, horizontal_velocity.length() * 0.62))
			else:
				horizontal_velocity *= 0.32
			wall_impact = max(wall_impact, 0.42)
	horizontal_speed = horizontal_velocity.length()

func _handle_ice_movement(dt: float) -> void:
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var move = _movement_input_dir(forward, right)
	if slide_active:
		_apply_slide(dt, move)
		horizontal_speed = horizontal_velocity.length()
		return
	var speed_mult = powerups.speed_multiplier() * (slow_multiplier if slow_timer > 0.0 else 1.0)
	var speed = horizontal_velocity.length()
	var glide = _momentum_glide_factor(speed)
	var accel = (ICE_GROUND_ACCEL if grounded else AIR_ACCEL) * speed_mult
	var max_speed = BASE_SPEED * speed_mult * (ICE_MAX_SPEED_MULT if grounded else 1.18)
	max_speed *= 1.0 + surface_slide_factor * 0.18 + clamp(grapple_momentum_intensity, 0.0, 1.0) * 0.10
	var surface_flow = _surface_flow_velocity()
	if surface_flow.length() > 0.01:
		max_speed += surface_flow.length() * 0.82
	if move.length() > 0.0:
		var desired_dir = move.normalized()
		var forward_drive = max(0.0, desired_dir.dot(forward))
		var back_drive = max(0.0, -desired_dir.dot(forward))
		var strafe_drive = abs(desired_dir.dot(right))
		var forward_accel_scale = lerp(1.0, 0.68, forward_drive * (1.0 - strafe_drive * 0.35))
		var directional_accel_scale = ICE_ACCEL_BUILDUP
		directional_accel_scale *= lerp(1.0, 0.76, forward_drive)
		directional_accel_scale *= lerp(1.0, 0.64, back_drive)
		directional_accel_scale *= lerp(1.0, 0.72, strafe_drive)
		var directional_speed_cap = 1.0
		directional_speed_cap *= lerp(1.0, ICE_FORWARD_SPEED_CAP, forward_drive * (1.0 - strafe_drive * 0.45))
		directional_speed_cap *= lerp(1.0, ICE_BACK_SPEED_CAP, back_drive)
		directional_speed_cap *= lerp(1.0, ICE_SIDE_SPEED_CAP, strafe_drive)
		if grounded:
			var current_speed = horizontal_velocity.length()
			if current_speed > 0.25:
				var guided_dir = horizontal_velocity.normalized().lerp(desired_dir, clamp(dt * ICE_STEER_RATE, 0.0, 0.26)).normalized()
				horizontal_velocity = guided_dir * current_speed
			horizontal_velocity += desired_dir * accel * forward_accel_scale * directional_accel_scale * dt
			var drag = ICE_INPUT_FRICTION * lerp(1.0, 0.48, surface_slide_factor) * dt
			horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, drag)
		else:
			horizontal_velocity += desired_dir * accel * lerp(1.0, 0.78, forward_drive) * directional_accel_scale * dt
		max_speed *= directional_speed_cap
	else:
		var friction = (ICE_IDLE_FRICTION if grounded else AIR_FRICTION)
		friction *= max(0.12, 1.0 - glide)
		friction *= lerp(1.0, 0.42, surface_slide_factor)
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, friction * dt)
	if surface_flow.length() > 0.01 and grounded:
		var flow_dir = surface_flow.normalized()
		var aligned = clamp(horizontal_velocity.dot(flow_dir) / max(1.0, max_speed), -1.0, 1.0)
		var flow_gain = lerp(1.0, 0.42, max(0.0, aligned))
		horizontal_velocity += surface_flow * flow_gain * dt
		slide_visual_intensity = max(slide_visual_intensity, 0.32)
	if horizontal_velocity.length() > max_speed:
		var trim_rate = 1.65 if grounded else 2.35
		var trimmed_speed = lerp(horizontal_velocity.length(), max_speed, clamp(dt * trim_rate, 0.0, 0.20))
		horizontal_velocity = horizontal_velocity.normalized() * trimmed_speed
	_move_horizontal_velocity(dt)

func _surface_flow_velocity() -> Vector3:
	if level_manager == null or not level_manager.has_method("surface_flow_at"):
		return Vector3.ZERO
	return level_manager.surface_flow_at(global_position)

func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = min(slow_multiplier if slow_timer > 0.0 else 1.0, clamp(multiplier, 0.25, 1.0))
	slow_timer = max(slow_timer, duration)
	add_shake(0.018)

func start_zoom(duration: float = 1.1, fov_drop: float = 24.0) -> void:
	zoom_timer = max(zoom_timer, duration)
	zoom_fov_drop = fov_drop

func _update_slide_hold_input() -> void:
	if horror_flashlight_mode:
		return
	var shift_held = Input.is_key_pressed(KEY_SHIFT)
	if not shift_held:
		slide_hold_locked = false
		if slide_active and slide_airborne:
			_end_slide(0.82)
		return
	if not slide_active and not slide_hold_locked and dash_cooldown <= 0.0:
		_start_slide()

func _momentum_glide_factor(speed: float) -> float:
	if not grounded:
		return 0.0
	var over_speed = clamp((speed - MOMENTUM_GLIDE_START) / 7.5, 0.0, 1.0)
	var surface = clamp(surface_slide_factor, 0.0, 1.0)
	var base_glide = ICE_ALWAYS_GLIDE if _uses_continuous_slide_movement() and speed > 0.35 else 0.0
	return clamp(base_glide + over_speed * MOMENTUM_GLIDE_FRICTION_SCALE + surface * 0.36, 0.0, 0.86)

func _movement_input_dir(forward: Vector3, right: Vector3) -> Vector3:
	var move = Vector3.ZERO
	move_forward = 0.0
	move_strafe = 0.0
	if Input.is_key_pressed(KEY_W):
		move += forward
		move_forward += 1.0
	if Input.is_key_pressed(KEY_S):
		move -= forward
		move_forward -= 1.0
	if Input.is_key_pressed(KEY_D):
		move += right
		move_strafe += 1.0
	if Input.is_key_pressed(KEY_A):
		move -= right
		move_strafe -= 1.0
	move_intensity = clamp(move.length(), 0.0, 1.0)
	return move.normalized() if move.length() > 0.0 else Vector3.ZERO

func _start_slide() -> void:
	if dash_cooldown > 0.0 or slide_active:
		return
	var starting_airborne = not grounded
	if starting_airborne and air_slide_used:
		return
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var move = _movement_input_dir(forward, right)
	var direction = move
	var move_wants_backward = move.length() > 0.0 and move.normalized().dot(forward) < -0.22
	var aim = aim_dir()
	var aim_flat = Vector3(aim.x, 0.0, aim.z)
	if direction.length() <= 0.0 and horizontal_velocity.length() > 1.2:
		direction = horizontal_velocity.normalized()
	if direction.length() <= 0.0 and last_grapple_velocity.length() > 1.2:
		direction = Vector3(last_grapple_velocity.x, 0, last_grapple_velocity.z).normalized()
	if direction.length() <= 0.0:
		direction = forward
	elif move_wants_backward and horizontal_velocity.length() > 1.2:
		direction = (direction.normalized() * 0.92 + horizontal_velocity.normalized() * 0.12).normalized()
	elif horizontal_velocity.length() > 1.2:
		direction = (direction.normalized() * 0.62 + horizontal_velocity.normalized() * 0.50).normalized()
	if starting_airborne and aim_flat.length() > 0.05 and not move_wants_backward:
		direction = (direction.normalized() * 0.42 + aim_flat.normalized() * 0.88).normalized()
	var grapple_h = Vector3(last_grapple_velocity.x, 0, last_grapple_velocity.z)
	var inherited = min(horizontal_velocity.length() * 0.72 + grapple_h.length() * (0.18 if starting_airborne else 0.08), 7.6 if starting_airborne else 6.6)
	var base_speed = AIR_SLIDE_START_SPEED if starting_airborne else SLIDE_START_SPEED
	var speed = max(SLIDE_MIN_SPEED, base_speed + inherited) * powerups.speed_multiplier()
	var forward_slide_start = max(0.0, direction.normalized().dot(forward)) if direction.length() > 0.0 else 0.0
	speed *= lerp(1.0, 0.84, forward_slide_start)
	if starting_airborne and grapple_active:
		_cancel_grapple(true)
	slide_active = true
	slide_hold_locked = true
	slide_airborne = starting_airborne
	slide_timer = AIR_SLIDE_DURATION if starting_airborne else SLIDE_DURATION
	slide_velocity = direction.normalized() * speed
	horizontal_velocity = slide_velocity
	slide_intensity = 1.0
	slide_visual_intensity = 1.0
	slide_crouch = max(slide_crouch, 0.30 if starting_airborne else 1.05)
	body_pitch = max(body_pitch, 0.035 if starting_airborne else 0.075)
	if starting_airborne:
		air_slide_used = true
		var aim_lift = max(0.0, aim.y) * AIR_SLIDE_AIM_UP_BOOST
		vertical_velocity = max(vertical_velocity * AIR_SLIDE_VERTICAL_DAMP, -2.15)
		vertical_velocity = max(vertical_velocity, AIR_SLIDE_UP_KICK + aim_lift)
		grapple_momentum_intensity = max(grapple_momentum_intensity, 0.48)
	dash_total = SLIDE_COOLDOWN * powerups.dash_multiplier()
	dash_cooldown = dash_total
	dash_flash = 0.85
	dodge_immunity_timer = max(dodge_immunity_timer, 1.20 if starting_airborne else 1.45)
	add_shake(0.035 if starting_airborne else 0.030)
	sound_requested.emit("glide" if starting_airborne else "slide")

func _apply_slide(dt: float, move: Vector3) -> void:
	slide_timer = max(0.0, slide_timer - dt)
	var shift_held = Input.is_key_pressed(KEY_SHIFT)
	if move.length() > 0.0 and slide_velocity.length() > 0.1:
		var steer_force = AIR_SLIDE_STEER_FORCE if slide_airborne else SLIDE_STEER_FORCE
		var steer = clamp(dt * (steer_force - surface_slide_factor * 1.25), 0.0, 0.20)
		if move.normalized().dot(slide_velocity.normalized()) < -0.12:
			steer = max(steer, 0.26 if slide_airborne else 0.30)
		slide_velocity = slide_velocity.lerp(move.normalized() * slide_velocity.length(), steer)
	var moved = _try_move(slide_velocity * dt)
	if not moved:
		var normal = level_manager.wall_contact_normal(global_position, PLAYER_RADIUS + 0.14) if level_manager != null else Vector3.ZERO
		if normal.length() > 0.0:
			slide_velocity = slide_velocity.slide(normal) * SLIDE_WALL_BRAKE
		else:
			slide_velocity *= SLIDE_WALL_BRAKE
		slide_timer = min(slide_timer, 0.16)
		wall_impact = max(wall_impact, 0.72)
	if slide_airborne:
		var air_phase = clamp(slide_timer / max(0.01, AIR_SLIDE_DURATION), 0.0, 1.0)
		vertical_velocity = max(vertical_velocity, lerp(-5.2, -2.25, air_phase))
		if air_phase > 0.18 and vertical_velocity < 1.2:
			vertical_velocity += AIR_SLIDE_GLIDE_LIFT * air_phase * dt
	var friction_base = AIR_SLIDE_FRICTION if slide_airborne else SLIDE_FRICTION
	if shift_held and slide_airborne:
		friction_base *= 0.74
	var friction = friction_base * lerp(1.0, 0.56, surface_slide_factor)
	slide_velocity = slide_velocity.move_toward(Vector3.ZERO, friction * dt)
	var surface_flow = _surface_flow_velocity()
	if surface_flow.length() > 0.01 and not slide_airborne:
		slide_velocity += surface_flow * dt
	horizontal_velocity = slide_velocity
	var duration = AIR_SLIDE_DURATION if slide_airborne else SLIDE_DURATION
	var start_speed = AIR_SLIDE_START_SPEED if slide_airborne else SLIDE_START_SPEED
	var speed_ratio = clamp(slide_velocity.length() / max(0.01, start_speed), 0.0, 1.0)
	var hold_floor = 0.54 if slide_airborne and shift_held and slide_velocity.length() > AIR_SLIDE_END_SPEED else 0.0
	slide_intensity = clamp(max(slide_timer / duration, speed_ratio * 0.86, hold_floor), 0.0, 1.0)
	var should_end = slide_velocity.length() < (AIR_SLIDE_END_SPEED if slide_airborne else SLIDE_END_SPEED)
	should_end = should_end or (slide_airborne and not shift_held) or (not slide_airborne and slide_timer <= 0.0 and slide_velocity.length() < SLIDE_MIN_SPEED)
	if should_end:
		var retain = 0.70 if slide_airborne else lerp(0.68, 0.86, surface_slide_factor)
		_end_slide(retain)

func _end_slide(retain: float = 0.76) -> void:
	if not slide_active:
		return
	var was_airborne_slide = slide_airborne
	var right = global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var slide_side = slide_velocity.normalized().dot(right) if slide_velocity.length() > 0.1 and right.length() > 0.0 else 0.0
	slide_active = false
	horizontal_velocity = slide_velocity * retain
	post_slide_super_jump_timer = max(post_slide_super_jump_timer, 1.35)
	if not was_airborne_slide:
		var lean_boost = clamp(slide_side * clamp(slide_velocity.length() / SLIDE_START_SPEED, 0.0, 1.0), -1.0, 1.0)
		movement_lean_memory = clamp(movement_lean_memory * 0.45 + lean_boost * 0.90, -1.0, 1.0)
		post_slide_lean_timer = max(post_slide_lean_timer, 0.85 + clamp(slide_velocity.length() / SLIDE_START_SPEED, 0.0, 1.0) * 0.65)
	slide_velocity = Vector3.ZERO
	slide_intensity = 0.0
	slide_airborne = false

func _do_dash_legacy() -> void:
	if dash_cooldown > 0.0:
		return
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var move = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move += forward
	if Input.is_key_pressed(KEY_S):
		move -= forward
	if Input.is_key_pressed(KEY_D):
		move += right
	if Input.is_key_pressed(KEY_A):
		move -= right
	if move.length() <= 0.0:
		move = forward
	else:
		move = move.normalized()
	var remaining = DASH_DISTANCE
	while remaining > 0.0:
		var step = min(0.45, remaining)
		var before = global_position
		_try_move(move * step)
		if before.distance_to(global_position) < 0.01:
			break
		remaining -= step
	dash_total = DASH_COOLDOWN * powerups.dash_multiplier()
	dash_cooldown = dash_total
	dash_flash = 1.0

func _try_move(delta: Vector3) -> bool:
	if level_manager == null:
		global_position += delta
		return delta.length() > 0.0
	var moved = false
	var next_x = global_position + Vector3(delta.x, 0, 0)
	if not _player_sweep_blocked(global_position, next_x) and not level_manager.is_blocked_world(next_x, PLAYER_RADIUS) and _can_enter_floor(next_x):
		global_position.x = next_x.x
		moved = moved or abs(delta.x) > 0.001
	var next_z = global_position + Vector3(0, 0, delta.z)
	if not _player_sweep_blocked(global_position, next_z) and not level_manager.is_blocked_world(next_z, PLAYER_RADIUS) and _can_enter_floor(next_z):
		global_position.z = next_z.z
		moved = moved or abs(delta.z) > 0.001
	return moved

func _player_sweep_blocked(from_pos: Vector3, to_pos: Vector3) -> bool:
	if level_manager != null and level_manager.has_method("player_sweep_blocked"):
		return level_manager.player_sweep_blocked(from_pos, to_pos, PLAYER_RADIUS)
	return false

func _can_enter_floor(pos: Vector3) -> bool:
	if level_manager == null:
		return true
	var target_floor = level_manager.floor_height_at(pos)
	if grounded and target_floor - global_position.y > 0.28:
		return false
	return true

func _jump() -> void:
	if grounded:
		var from_slide = slide_active
		if slide_active:
			slide_active = false
			horizontal_velocity = slide_velocity * 0.94
			slide_velocity = Vector3.ZERO
			slide_intensity = 0.0
			slide_airborne = false
		var boosted_from_slide = from_slide or post_slide_super_jump_timer > 0.0
		vertical_velocity = JUMP_CHARGE_MAX_SPEED if boosted_from_slide else JUMP_SPEED
		grounded = false
		jumps_left = 1
		if boosted_from_slide and horizontal_velocity.length() > 0.1:
			horizontal_velocity += horizontal_velocity.normalized() * (JUMP_CHARGE_FORWARD_BOOST * 0.88)
			dash_flash = 0.60
			last_jump_charge_amount = 1.0
			post_slide_super_jump_timer = 0.0
			add_shake(0.030)
		elif from_slide:
			add_shake(0.020)
		sound_requested.emit("jump")
		return
	var wall_normal = level_manager.wall_contact_normal(global_position, PLAYER_RADIUS + 0.16) if level_manager != null else Vector3.ZERO
	if wall_normal.length() > 0.0 and wall_jump_cooldown <= 0.0:
		vertical_velocity = WALL_JUMP_SPEED
		wall_push_velocity = wall_normal.normalized() * WALL_JUMP_PUSH
		wall_jump_cooldown = 0.18
		jumps_left = 1
		dash_flash = 0.65
		add_shake(0.025)
		sound_requested.emit("jump")
		return
	if jumps_left > 0:
		var charge = clamp(last_jump_charge_amount, 0.0, 1.0)
		vertical_velocity = lerp(DOUBLE_JUMP_SPEED, DOUBLE_JUMP_CHARGED_SPEED, charge)
		var forward = -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		if horizontal_velocity.length() > 0.2:
			horizontal_velocity += horizontal_velocity.normalized() * (DOUBLE_JUMP_CHARGE_FORWARD_BOOST * charge)
		else:
			horizontal_velocity += forward * (DOUBLE_JUMP_CHARGE_FORWARD_BOOST * charge)
		last_jump_charge_amount = 0.0
		jumps_left -= 1
		dash_flash = 0.45
		add_shake(0.018 + charge * 0.026)
		sound_requested.emit("jump")

func _horror_jump() -> void:
	if horror_hidden or not grounded:
		return
	vertical_velocity = HORROR_JUMP_SPEED
	grounded = false
	jumps_left = 0
	jump_charge_active = false
	jump_charge_timer = 0.0
	jump_charge_amount = 0.0
	last_jump_charge_amount = 0.0
	landing_kick = max(landing_kick, 0.10)
	add_shake(0.010)
	sound_requested.emit("jump")

func _tick_horror_sprint(dt: float) -> void:
	if not horror_flashlight_mode:
		horror_sprint_active = false
		return
	if horror_hidden:
		horror_sprint_active = false
		return
	horror_sprint_recovery_delay = max(0.0, horror_sprint_recovery_delay - dt)
	var has_move_input = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D)
	var wants_sprint = Input.is_key_pressed(KEY_SHIFT) and has_move_input and grounded
	if horror_sprint_exhausted and horror_sprint_stamina >= 24.0:
		horror_sprint_exhausted = false
	if wants_sprint and not horror_sprint_exhausted and horror_sprint_stamina > 0.5:
		horror_sprint_active = true
		horror_sprint_stamina = max(0.0, horror_sprint_stamina - HORROR_STAMINA_DRAIN * dt)
		horror_sprint_recovery_delay = HORROR_STAMINA_RECOVERY_DELAY
		if horror_sprint_stamina <= 0.5:
			horror_sprint_active = false
			horror_sprint_exhausted = true
	else:
		horror_sprint_active = false
		if horror_sprint_recovery_delay <= 0.0:
			horror_sprint_stamina = min(HORROR_STAMINA_MAX, horror_sprint_stamina + HORROR_STAMINA_RECOVERY * dt)

func _start_jump_charge() -> void:
	if jump_charge_active or not grounded:
		return
	jump_charge_active = true
	jump_charge_timer = 0.0
	jump_charge_amount = 0.0

func _update_jump_charge(dt: float) -> void:
	if not jump_charge_active:
		jump_charge_amount = move_toward(jump_charge_amount, 0.0, dt * 3.2)
		return
	if not grounded or not Input.is_key_pressed(KEY_SPACE):
		_release_jump_charge()
		return
	jump_charge_timer = min(JUMP_CHARGE_MAX_TIME, jump_charge_timer + dt)
	jump_charge_amount = clamp(jump_charge_timer / JUMP_CHARGE_MAX_TIME, 0.0, 1.0)
	if jump_charge_timer > JUMP_TAP_CHARGE_THRESHOLD:
		slide_crouch = max(slide_crouch, 0.22 + jump_charge_amount * 0.24)
	if jump_charge_timer >= JUMP_CHARGE_MAX_TIME:
		jump_charge_amount = 1.0

func _release_jump_charge() -> void:
	if not jump_charge_active:
		return
	var amount = jump_charge_amount
	if amount < JUMP_TAP_CHARGE_THRESHOLD / JUMP_CHARGE_MAX_TIME:
		amount = 0.0
	last_jump_charge_amount = amount
	jump_charge_active = false
	jump_charge_timer = 0.0
	jump_charge_amount = 0.0
	if not grounded:
		return
	var forward = -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var charged_speed = lerp(JUMP_SPEED, JUMP_CHARGE_MAX_SPEED, amount)
	vertical_velocity = charged_speed
	grounded = false
	jumps_left = 1
	if horizontal_velocity.length() > 0.2:
		horizontal_velocity += horizontal_velocity.normalized() * (JUMP_CHARGE_FORWARD_BOOST * amount)
	elif move_forward > 0.0:
		horizontal_velocity += forward * (JUMP_CHARGE_FORWARD_BOOST * amount)
	dash_flash = max(dash_flash, 0.32 + amount * 0.45)
	add_shake(0.012 + amount * 0.030)
	sound_requested.emit("jump")

func _start_grapple() -> void:
	if level_manager == null or grapple_cooldown > 0.0:
		return
	var origin = camera_origin()
	var dir = aim_dir()
	var hit = level_manager.wall_hit_along_segment(origin, origin + dir * GRAPPLE_RANGE, 0.08)
	var enemy_info = level_manager.grapple_enemy_hit_info(origin, dir, GRAPPLE_RANGE, 1.25) if level_manager.has_method("grapple_enemy_hit_info") else (level_manager.enemy_hit_info_in_ray(origin, dir, GRAPPLE_RANGE) if level_manager.has_method("enemy_hit_info_in_ray") else {})
	var surface_dist = origin.distance_to(hit.position) if hit.hit else GRAPPLE_RANGE + 1.0
	grapple_enemy = null
	grapple_enemy_mode = ""
	if enemy_info.has("enemy") and float(enemy_info.distance) <= surface_dist + 1.6:
		grapple_enemy = enemy_info.enemy
		grapple_enemy_mode = "heavy" if (grapple_enemy.stats.boss or level_manager.is_miniboss_enemy(grapple_enemy)) else "enemy"
		grapple_point = grapple_enemy.global_position + Vector3(0, grapple_enemy.stats.height * 0.55, 0)
	else:
		if not hit.hit:
			return
		if origin.distance_to(hit.position) < 2.2:
			return
		grapple_point = hit.get("safe_position", hit.position)
	grapple_active = true
	grapple_cooldown = 0.28
	grapple_visual_timer = 0.0
	grapple_timer = GRAPPLE_MAX_TIME
	last_grapple_velocity = Vector3.ZERO
	grounded = false
	dash_flash = 0.65
	add_shake(0.018)
	sound_requested.emit("grapple")
	level_manager.spawn_grapple_cable(camera_origin(), grapple_point)

func _apply_grapple(dt: float) -> void:
	if not grapple_active:
		return
	grapple_timer -= dt
	if grapple_enemy != null:
		if not is_instance_valid(grapple_enemy) or grapple_enemy.dead:
			_cancel_grapple(false)
			return
		grapple_point = grapple_enemy.global_position + Vector3(0, grapple_enemy.stats.height * 0.55, 0)
	var origin = global_position + Vector3(0, 1.0, 0)
	var to_hook = grapple_point - origin
	var dist = to_hook.length()
	var min_detach_dist = 0.45 if grapple_enemy != null else 1.35
	if dist < min_detach_dist or Input.is_key_pressed(KEY_S) or grapple_timer <= 0.0:
		_cancel_grapple(true)
		return
	var pull = to_hook.normalized()
	var pull_speed = GRAPPLE_PULL_SPEED
	var move_player = true
	if grapple_enemy != null and grapple_enemy_mode == "enemy":
		var enemy_floor = level_manager.floor_height_at(grapple_enemy.global_position)
		var enemy_airborne = grapple_enemy.global_position.y > enemy_floor + 1.1 or bool(grapple_enemy.stats.flying)
		if enemy_airborne:
			pull_speed *= 1.05
		else:
			move_player = false
			pull_speed *= 0.24
			var enemy_pull = (origin - grapple_enemy.global_position).normalized()
			if grapple_enemy.has_method("apply_impulse"):
				grapple_enemy.apply_impulse(enemy_pull * (2.0 + dt * 18.0))
			last_grapple_velocity = Vector3.ZERO
			grapple_momentum_intensity = max(grapple_momentum_intensity, 0.24)
	elif grapple_enemy != null and grapple_enemy.has_method("apply_impulse"):
		grapple_enemy.apply_impulse((-pull) * 0.75)
	if move_player:
		last_grapple_velocity = pull * pull_speed
		_try_move(Vector3(last_grapple_velocity.x, 0, last_grapple_velocity.z) * dt)
		var grapple_h = Vector3(last_grapple_velocity.x, 0, last_grapple_velocity.z)
		if grapple_h.length() > 0.01:
			horizontal_velocity = horizontal_velocity.lerp(grapple_h * 0.78, clamp(dt * 4.8, 0.0, 0.46))
			grapple_momentum_intensity = max(grapple_momentum_intensity, clamp(grapple_h.length() / GRAPPLE_PULL_SPEED, 0.0, 1.0))
		vertical_velocity = max(vertical_velocity, pull.y * 10.5 + 2.2)
		grounded = false
	if grapple_visual_timer <= 0.0:
		grapple_visual_timer = 0.055
		level_manager.spawn_grapple_cable(camera_origin(), grapple_point)

func _cancel_grapple(keep_momentum: bool) -> void:
	var carry_velocity = last_grapple_velocity
	if grapple_enemy != null and is_instance_valid(grapple_enemy):
		if keep_momentum and grapple_enemy.has_method("apply_impulse"):
			var throw_dir = (aim_dir() + Vector3.UP * 0.18).normalized()
			var throw_power = 17.0 if grapple_enemy_mode == "enemy" else 8.5
			grapple_enemy.apply_impulse(throw_dir * throw_power)
			if grapple_enemy.has_method("apply_stun"):
				grapple_enemy.apply_stun(0.42 if grapple_enemy_mode == "enemy" else 0.22)
		grapple_enemy = null
		grapple_enemy_mode = ""
	grapple_active = false
	grapple_timer = 0.0
	if carry_velocity.length() > 0.01:
		_carry_grapple_release_momentum(carry_velocity, 1.0 if keep_momentum else 0.66)
	_refresh_slide_after_grapple()

func _carry_grapple_release_momentum(carry_velocity: Vector3, strength: float) -> void:
	var grapple_h = Vector3(carry_velocity.x, 0.0, carry_velocity.z)
	if grapple_h.length() > 0.01:
		var retain = clamp(0.58 + strength * 0.28, 0.0, 0.92)
		horizontal_velocity = horizontal_velocity.lerp(grapple_h * (0.88 * strength), retain)
		wall_push_velocity += grapple_h * (0.18 * strength)
	if carry_velocity.y > 0.01:
		vertical_velocity = max(vertical_velocity, min(carry_velocity.y * (0.70 * strength), 7.2))
	elif carry_velocity.y < -0.01:
		vertical_velocity = min(vertical_velocity, carry_velocity.y * (0.45 * strength))
	grapple_momentum_intensity = max(grapple_momentum_intensity, clamp(carry_velocity.length() / GRAPPLE_PULL_SPEED, 0.0, 1.0))
	slide_visual_intensity = max(slide_visual_intensity, 0.24 * strength)
	body_pitch = max(body_pitch, 0.024 * strength)

func _refresh_slide_after_grapple() -> void:
	dash_total = SLIDE_COOLDOWN * powerups.dash_multiplier()
	dash_cooldown = 0.0
	air_slide_used = false
	dash_flash = max(dash_flash, 0.72)

func _apply_vertical(dt: float) -> void:
	if level_manager == null:
		return
	if horror_hidden:
		vertical_velocity = 0.0
		grounded = true
		return
	var floor_y = level_manager.floor_height_at(global_position)
	var was_grounded = grounded
	var floor_delta = floor_y - last_floor_y
	if not horror_flashlight_mode and was_grounded and floor_delta > 0.025 and horizontal_velocity.length() >= SURFACE_LAUNCH_MIN_SPEED:
		var rise_speed = floor_delta / max(dt, 0.001)
		var launch_from_slope = rise_speed * 0.24 + horizontal_velocity.length() * 0.045
		surface_launch_memory = max(surface_launch_memory, clamp(launch_from_slope, 0.0, SURFACE_LAUNCH_MAX_UP))
	surface_launch_memory = max(0.0, surface_launch_memory - SURFACE_LAUNCH_DECAY * dt)
	var fall_speed = max(0.0, -vertical_velocity)
	vertical_velocity -= (HORROR_GRAVITY if horror_flashlight_mode else GRAVITY) * dt
	global_position.y += vertical_velocity * dt
	if level_manager.has_method("ceiling_height_at"):
		var ceiling_y = float(level_manager.ceiling_height_at(global_position, PLAYER_RADIUS))
		if ceiling_y < INF and global_position.y + PLAYER_HEIGHT > ceiling_y:
			global_position.y = ceiling_y - PLAYER_HEIGHT - 0.025
			vertical_velocity = min(vertical_velocity, 0.0)
			if grapple_active and grapple_point.y >= ceiling_y - 0.08:
				last_grapple_velocity.y = min(last_grapple_velocity.y, 0.0)
				_cancel_grapple(false)
	if global_position.y <= floor_y:
		global_position.y = floor_y
		if not was_grounded and fall_speed > 4.2:
			landing_kick = clamp(fall_speed / 32.0, 0.05, 0.30)
			var speed_preserve = 1.0 - landing_kick * lerp(0.52, 0.22, clamp(horizontal_velocity.length() / 13.0, 0.0, 1.0))
			horizontal_velocity *= clamp(speed_preserve, 0.76, 1.0)
			if not horror_flashlight_mode and horizontal_velocity.length() > 7.0:
				horizontal_velocity += horizontal_velocity.normalized() * min(0.95, landing_kick * 2.0)
			add_shake(0.014 + landing_kick * 0.15)
			sound_requested.emit("land_hard" if fall_speed > 12.0 else "land")
		vertical_velocity = 0.0
		grounded = true
		if slide_active and slide_airborne and horizontal_velocity.length() > 4.0:
			slide_airborne = false
			slide_timer = max(slide_timer, 0.20)
			slide_velocity = horizontal_velocity * 0.92
			slide_crouch = max(slide_crouch, 1.02)
		air_time = 0.0
		air_slide_used = false
		last_jump_charge_amount = 0.0
		jumps_left = 1
	elif _should_snap_to_flow_surface(floor_y, was_grounded):
		global_position.y = floor_y
		vertical_velocity = 0.0
		grounded = true
		air_time = 0.0
		air_slide_used = false
		last_jump_charge_amount = 0.0
		jumps_left = 1
	else:
		if was_grounded and not horror_flashlight_mode:
			_apply_surface_departure_carry(floor_y)
		grounded = false
		air_time += dt
	last_floor_y = floor_y

func _should_snap_to_flow_surface(floor_y: float, was_grounded: bool) -> bool:
	if not was_grounded:
		return false
	var surface_flow = _surface_flow_velocity()
	if surface_flow.length() <= 0.01:
		return false
	if vertical_velocity > 0.15:
		return false
	var floor_gap = global_position.y - floor_y
	if floor_gap <= 0.0:
		return false
	var speed_factor = clamp(horizontal_velocity.length() / 18.0, 0.0, 1.0)
	var snap_limit = lerp(FLOW_SURFACE_SNAP_BASE, FLOW_SURFACE_SNAP_FAST, speed_factor)
	return floor_gap <= snap_limit

func _apply_surface_departure_carry(floor_y: float) -> void:
	if _surface_flow_velocity().length() > 0.01 and grounded:
		return
	var speed = horizontal_velocity.length()
	if speed < 1.2:
		return
	var ledge_drop = clamp(global_position.y - floor_y, 0.0, 3.5)
	if surface_launch_memory > 0.04 and speed >= SURFACE_LAUNCH_MIN_SPEED:
		var launch_up = min(SURFACE_LAUNCH_MAX_UP, surface_launch_memory + clamp((speed - SURFACE_LAUNCH_MIN_SPEED) * 0.10, 0.0, 1.05))
		vertical_velocity = max(vertical_velocity, launch_up)
		horizontal_velocity += horizontal_velocity.normalized() * min(0.85, speed * 0.035)
		body_pitch = max(body_pitch, 0.035)
		slide_visual_intensity = max(slide_visual_intensity, 0.28)
	elif ledge_drop > 0.10:
		horizontal_velocity += horizontal_velocity.normalized() * min(0.38, speed * 0.018)
		body_pitch = max(body_pitch, 0.018)

func _resolve_solid_embed() -> void:
	if level_manager == null or not level_manager.has_method("push_out_of_solid"):
		return
	var fixed = level_manager.push_out_of_solid(global_position, PLAYER_RADIUS)
	if fixed.distance_to(global_position) > 0.001:
		global_position = fixed
		horizontal_velocity *= 0.78
		wall_impact = max(wall_impact, 0.45)

func _update_body_physics(dt: float) -> void:
	if horror_flashlight_mode:
		_update_horror_body_physics(dt)
	elif _uses_continuous_slide_movement():
		_update_ice_body_physics(dt)
	else:
		_update_classic_body_physics(dt)

func _update_horror_body_physics(dt: float) -> void:
	# Horror locomotion has no combat glide, crouch pumping, grapple lean or
	# momentum carry. Only a restrained weight shift follows the actual velocity.
	surface_slide_factor = 0.0
	horizontal_speed = horizontal_velocity.length()
	var pace: float = clamp(horizontal_speed / HORROR_SPRINT_SPEED, 0.0, 1.0)
	momentum_intensity = move_toward(momentum_intensity, pace, dt * 3.0)
	grapple_momentum_intensity = 0.0
	slide_intensity = 0.0
	slide_visual_intensity = move_toward(slide_visual_intensity, 0.0, dt * 8.0)
	slide_crouch = move_toward(slide_crouch, 0.0, dt * 8.0)
	wall_impact = max(0.0, wall_impact - dt * 4.0)
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var side_ratio: float = clamp(horizontal_velocity.dot(right) / HORROR_SPRINT_SPEED, -1.0, 1.0)
	var forward_ratio: float = clamp(horizontal_velocity.dot(forward) / HORROR_SPRINT_SPEED, -1.0, 1.0)
	var target_roll: float = -side_ratio * 0.018
	var target_pitch: float = -forward_ratio * 0.010 + clamp(-vertical_velocity / 34.0, -0.025, 0.030) + landing_kick * 0.055
	body_roll = lerp(body_roll, target_roll, clamp(dt * 4.2, 0.0, 1.0))
	body_pitch = lerp(body_pitch, target_pitch, clamp(dt * 3.8, 0.0, 1.0))
	body_yaw = lerp(body_yaw, -side_ratio * 0.008, clamp(dt * 3.5, 0.0, 1.0))
	movement_lean_memory = move_toward(movement_lean_memory, 0.0, dt * 4.0)
	look_lean_memory = move_toward(look_lean_memory, 0.0, dt * 4.0)

func _update_classic_body_physics(dt: float) -> void:
	surface_slide_factor = level_manager.surface_slide_factor_at(global_position) if level_manager != null and level_manager.has_method("surface_slide_factor_at") else 0.0
	horizontal_speed = horizontal_velocity.length()
	var grapple_target = clamp(last_grapple_velocity.length() / max(0.01, GRAPPLE_PULL_SPEED), 0.0, 1.0) if grapple_active else 0.0
	grapple_momentum_intensity = move_toward(grapple_momentum_intensity, grapple_target, dt * (9.0 if grapple_active else 2.9))
	var vertical_momentum = clamp(abs(vertical_velocity) / 24.0, 0.0, 0.46)
	momentum_intensity = max(clamp(horizontal_speed / 14.0, 0.0, 1.0), grapple_momentum_intensity * 0.88, vertical_momentum)
	var slide_target = slide_intensity if slide_active else 0.0
	slide_visual_intensity = move_toward(slide_visual_intensity, slide_target, dt * (8.5 if slide_active else 4.3))
	var crouch_target = 0.0
	if slide_active:
		crouch_target = 0.34 if slide_airborne else 1.18
	elif jump_charge_active:
		crouch_target = max(crouch_target, 0.28 + jump_charge_amount * 0.55)
	elif grounded and horizontal_speed > MOMENTUM_GLIDE_START:
		crouch_target = clamp((horizontal_speed - MOMENTUM_GLIDE_START) / 9.0, 0.0, 0.28) * (0.45 + surface_slide_factor)
	slide_crouch = move_toward(slide_crouch, crouch_target, dt * (10.5 if crouch_target > slide_crouch else 5.8))
	wall_impact = max(0.0, wall_impact - dt * 4.8)
	movement_lean_memory = move_toward(movement_lean_memory, 0.0, dt * 3.2)
	look_lean_memory = move_toward(look_lean_memory, 0.0, dt * 3.2)
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var side_speed = horizontal_velocity.dot(right)
	var forward_speed = horizontal_velocity.dot(forward)
	var grapple_side = last_grapple_velocity.dot(right) / GRAPPLE_PULL_SPEED if grapple_active else 0.0
	var grapple_forward = last_grapple_velocity.dot(forward) / GRAPPLE_PULL_SPEED if grapple_active else 0.0
	var grapple_up = last_grapple_velocity.y / GRAPPLE_PULL_SPEED if grapple_active else 0.0
	var side_ratio = clamp(side_speed / 12.0, -1.0, 1.0)
	var forward_ratio = clamp(forward_speed / 12.0, -1.0, 1.0)
	var slide_side = 0.0
	if slide_active and slide_velocity.length() > 0.1:
		slide_side = slide_velocity.normalized().dot(right)
	var slide_roll_strength = 0.105 if slide_airborne else 0.165
	var slide_pitch_strength = 0.065 if slide_airborne else 0.115
	var target_roll = -side_ratio * (0.050 + momentum_intensity * 0.032) - slide_side * slide_visual_intensity * slide_roll_strength - grapple_side * grapple_momentum_intensity * 0.070
	target_roll += sin(camera_bob_time * 0.70) * momentum_intensity * 0.014
	var body_target_pitch = -forward_ratio * 0.018 + slide_visual_intensity * slide_pitch_strength + clamp(-vertical_velocity / 26.0, -0.045, 0.052) + landing_kick * 0.10
	body_target_pitch += grapple_forward * grapple_momentum_intensity * 0.038 - grapple_up * grapple_momentum_intensity * 0.030
	if not grounded:
		body_target_pitch += clamp(air_time * 0.030, 0.0, 0.055)
	body_roll = lerp(body_roll, target_roll, clamp(dt * 8.2, 0.0, 1.0))
	body_pitch = lerp(body_pitch, body_target_pitch, clamp(dt * 7.4, 0.0, 1.0))
	body_yaw = lerp(body_yaw, -side_ratio * (0.018 + slide_visual_intensity * 0.024) - grapple_side * grapple_momentum_intensity * 0.020, clamp(dt * 6.8, 0.0, 1.0))

func _update_ice_body_physics(dt: float) -> void:
	surface_slide_factor = level_manager.surface_slide_factor_at(global_position) if level_manager != null and level_manager.has_method("surface_slide_factor_at") else 0.0
	horizontal_speed = horizontal_velocity.length()
	var yaw_delta = wrapf(yaw - last_lean_yaw, -PI, PI)
	last_lean_yaw = yaw
	var look_turn_speed = yaw_delta / max(0.001, dt)
	var look_target = clamp(-look_turn_speed * 0.18, -1.0, 1.0)
	if abs(look_target) > 0.035:
		look_lean_memory = lerp(look_lean_memory, look_target, clamp(dt * 5.0, 0.0, 1.0))
	else:
		look_lean_memory = move_toward(look_lean_memory, 0.0, dt * 0.42)
	var grapple_target = clamp(last_grapple_velocity.length() / max(0.01, GRAPPLE_PULL_SPEED), 0.0, 1.0) if grapple_active else 0.0
	grapple_momentum_intensity = move_toward(grapple_momentum_intensity, grapple_target, dt * (9.0 if grapple_active else 2.9))
	var vertical_momentum = clamp(abs(vertical_velocity) / 24.0, 0.0, 0.46)
	momentum_intensity = max(clamp(horizontal_speed / 12.5, 0.0, 1.0), grapple_momentum_intensity * 0.88, vertical_momentum)
	var slide_target = slide_intensity if slide_active else 0.0
	slide_visual_intensity = move_toward(slide_visual_intensity, slide_target, dt * (8.5 if slide_active else 4.3))
	var crouch_target = 0.0
	if slide_active:
		crouch_target = 0.34 if slide_airborne else 1.18
	elif jump_charge_active:
		crouch_target = max(crouch_target, 0.28 + jump_charge_amount * 0.55)
	elif grounded and horizontal_speed > MOMENTUM_GLIDE_START:
		crouch_target = clamp((horizontal_speed - MOMENTUM_GLIDE_START) / 9.0, 0.0, 0.28) * (0.45 + surface_slide_factor)
	slide_crouch = move_toward(slide_crouch, crouch_target, dt * (10.5 if crouch_target > slide_crouch else 5.8))
	wall_impact = max(0.0, wall_impact - dt * 4.8)
	post_slide_lean_timer = max(0.0, post_slide_lean_timer - dt)
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var side_speed = horizontal_velocity.dot(right)
	var forward_speed = horizontal_velocity.dot(forward)
	var grapple_side = last_grapple_velocity.dot(right) / GRAPPLE_PULL_SPEED if grapple_active else 0.0
	var grapple_forward = last_grapple_velocity.dot(forward) / GRAPPLE_PULL_SPEED if grapple_active else 0.0
	var grapple_up = last_grapple_velocity.y / GRAPPLE_PULL_SPEED if grapple_active else 0.0
	var side_ratio = clamp(side_speed / 12.0, -1.0, 1.0)
	var forward_ratio = clamp(forward_speed / 12.0, -1.0, 1.0)
	var lean_target = side_ratio
	if abs(move_strafe) > 0.05:
		lean_target = clamp(lean_target * 0.78 + float(move_strafe) * 0.72, -1.0, 1.0)
	elif horizontal_speed < 0.45:
		lean_target = movement_lean_memory * 0.86 + look_lean_memory * 0.18
	else:
		lean_target = clamp(lean_target + movement_lean_memory * 0.58, -1.0, 1.0)
	var lean_decay_rate = 0.08 if horizontal_speed > 0.9 else 0.18
	if post_slide_lean_timer > 0.0:
		lean_decay_rate = 0.04
	var lean_attack_rate = 3.8 if abs(lean_target) > abs(movement_lean_memory) else lean_decay_rate
	movement_lean_memory = lerp(movement_lean_memory, lean_target, clamp(dt * lean_attack_rate, 0.0, 1.0))
	drift_swing_phase += dt * (ICE_DRIFT_SWING_RATE + horizontal_speed * 0.21 + slide_visual_intensity * 1.6)
	var drift_amount = clamp(horizontal_speed / 9.5, 0.0, 1.0) * (0.45 + clamp(abs(movement_lean_memory), 0.0, 1.0) * 0.55)
	var slide_side = 0.0
	var slide_forward = 0.0
	if slide_active and slide_velocity.length() > 0.1:
		slide_side = slide_velocity.normalized().dot(right)
		slide_forward = slide_velocity.normalized().dot(forward)
	var slide_roll_strength = 0.105 if slide_airborne else 0.165
	var slide_pitch_strength = 0.065 if slide_airborne else 0.115
	var target_roll = -side_ratio * (0.070 + momentum_intensity * 0.050) - slide_side * slide_visual_intensity * slide_roll_strength - grapple_side * grapple_momentum_intensity * 0.070
	target_roll += -movement_lean_memory * (0.115 + momentum_intensity * 0.060) + look_lean_memory * 0.050
	target_roll += look_lean_memory * slide_visual_intensity * clamp(abs(slide_forward), 0.0, 1.0) * 0.060
	target_roll += sin(drift_swing_phase) * drift_amount * 0.034
	target_roll += sin(camera_bob_time * 0.70) * momentum_intensity * 0.018
	var body_target_pitch = -forward_ratio * 0.018 + slide_visual_intensity * slide_pitch_strength + clamp(-vertical_velocity / 26.0, -0.045, 0.052) + landing_kick * 0.10
	body_target_pitch += grapple_forward * grapple_momentum_intensity * 0.038 - grapple_up * grapple_momentum_intensity * 0.030
	body_target_pitch += momentum_intensity * 0.010 + abs(movement_lean_memory) * 0.010
	body_target_pitch += max(0.0, slide_forward) * slide_visual_intensity * (0.070 if slide_airborne else 0.165)
	if not grounded:
		body_target_pitch += clamp(air_time * 0.030, 0.0, 0.055)
	body_roll = lerp(body_roll, target_roll, clamp(dt * 6.8, 0.0, 1.0))
	body_pitch = lerp(body_pitch, body_target_pitch, clamp(dt * 6.4, 0.0, 1.0))
	var yaw_swing = sin(drift_swing_phase * 0.76) * drift_amount * 0.018
	body_yaw = lerp(body_yaw, -side_ratio * (0.020 + slide_visual_intensity * 0.026) - movement_lean_memory * 0.020 + look_lean_memory * 0.016 - grapple_side * grapple_momentum_intensity * 0.020 + yaw_swing, clamp(dt * 5.8, 0.0, 1.0))

func _update_camera_motion(dt: float) -> void:
	if horror_flashlight_mode:
		_update_horror_camera_motion(dt)
	elif _uses_continuous_slide_movement():
		_update_ice_camera_motion(dt)
	else:
		_update_classic_camera_motion(dt)

func _update_horror_camera_motion(dt: float) -> void:
	var speed_ratio: float = clamp(horizontal_speed / HORROR_SPRINT_SPEED, 0.0, 1.0)
	var walk_ratio: float = clamp(horizontal_speed / HORROR_WALK_SPEED, 0.0, 1.0)
	var sprint_weight: float = clamp((horizontal_speed - HORROR_WALK_SPEED) / maxf(0.01, HORROR_SPRINT_SPEED - HORROR_WALK_SPEED), 0.0, 1.0)
	if horizontal_speed > 0.08 and grounded:
		camera_bob_time += dt * lerp(4.35, 6.65, sprint_weight)
	var bob_x: float = sin(camera_bob_time) * lerp(0.018, 0.032, sprint_weight) * walk_ratio
	var bob_y: float = -abs(cos(camera_bob_time)) * lerp(0.023, 0.043, sprint_weight) * walk_ratio
	var step_roll: float = sin(camera_bob_time) * lerp(0.0035, 0.0060, sprint_weight) * walk_ratio
	var step_pitch: float = cos(camera_bob_time * 2.0) * lerp(0.0018, 0.0032, sprint_weight) * walk_ratio
	var breathing: float = sin(Time.get_ticks_msec() * 0.00155) * (0.0025 + sprint_weight * 0.0035)
	var air_dip: float = clamp(-vertical_velocity / 34.0, -0.055, 0.065)
	var shake_amp: float = shake_strength * (shake_timer / 0.22) if shake_timer > 0.0 else 0.0
	var shake_x: float = sin(Time.get_ticks_msec() * 0.073) * shake_amp * 0.14
	var shake_y: float = cos(Time.get_ticks_msec() * 0.089) * shake_amp * 0.07
	var shake_roll: float = sin(Time.get_ticks_msec() * 0.11) * shake_amp
	var target_position: Vector3 = camera_base_position + Vector3(
		bob_x + shake_x + body_yaw * 0.10,
		bob_y + breathing + air_dip + shake_y - landing_kick * 0.12 - wall_impact * 0.015,
		0.0
	)
	# Returning through a spring-like interpolation keeps individual footfalls
	# weighty without the rapid arena-camera oscillation used by combat stages.
	camera.position = camera.position.lerp(target_position, clamp(dt * 9.0, 0.0, 1.0))
	camera.rotation.x = pitch + body_pitch + step_pitch - move_forward * 0.004 * speed_ratio + landing_kick * 0.035
	camera.rotation.y = body_yaw
	camera.rotation.z = body_roll + step_roll - move_strafe * 0.010 * speed_ratio + shake_roll
	var fov_boost: float = sprint_weight * 1.35
	var zoom_drop: float = zoom_fov_drop if zoom_timer > 0.0 else 0.0
	camera.fov = lerp(camera.fov, camera_base_fov + fov_boost - zoom_drop, clamp(dt * 4.0, 0.0, 1.0))

func _update_classic_camera_motion(dt: float) -> void:
	var momentum_factor = momentum_intensity
	var speed_factor = max(move_intensity, momentum_factor * 0.82) if grounded else max(move_intensity * 0.35, momentum_factor * 0.42)
	camera_bob_time += dt * (6.8 + speed_factor * 7.4 + slide_visual_intensity * 3.2)
	var bob_x = sin(camera_bob_time) * (0.032 + momentum_factor * 0.035) * speed_factor
	var bob_y = abs(cos(camera_bob_time * 1.72)) * (0.040 + momentum_factor * 0.040) * speed_factor
	var air_dip = clamp(-vertical_velocity / 25.0, -0.10, 0.12)
	var grapple_lean = 0.035 if grapple_active else 0.0
	var slide_dir = slide_velocity.normalized() if slide_velocity.length() > 0.05 else Vector3.ZERO
	var right = global_transform.basis.x.normalized()
	var slide_side = slide_dir.dot(right)
	var slide_drop = -BODY_CROUCH_DROP * slide_crouch * (0.58 if slide_airborne else 1.0)
	var slide_forward = (-0.055 if slide_airborne else -0.13) * slide_visual_intensity
	var momentum_sink = -0.040 * momentum_factor * surface_slide_factor
	var shake_amp = shake_strength * (shake_timer / 0.22) if shake_timer > 0.0 else 0.0
	var shake_x = sin(Time.get_ticks_msec() * 0.073) * shake_amp * 0.18
	var shake_y = cos(Time.get_ticks_msec() * 0.089) * shake_amp * 0.08
	var shake_roll = sin(Time.get_ticks_msec() * 0.11) * shake_amp
	camera.position = camera_base_position + Vector3(bob_x + shake_x + slide_side * 0.055 * slide_visual_intensity + body_yaw * 0.18, bob_y + air_dip + shake_y + slide_drop + momentum_sink - landing_kick * 0.24 - wall_impact * 0.025, slide_forward)
	camera.rotation.x = pitch + body_pitch + (-move_forward * 0.011 * speed_factor) + clamp(-vertical_velocity * 0.0025, -0.038, 0.038) + landing_kick * 0.072 + slide_visual_intensity * (0.018 if slide_airborne else 0.035)
	camera.rotation.y = body_yaw
	camera.rotation.z = body_roll + (-move_strafe * 0.034 * speed_factor) + grapple_lean + shake_roll - slide_side * (0.046 if slide_airborne else 0.072) * slide_visual_intensity + sin(camera_bob_time * 0.7) * momentum_factor * 0.014
	var fov_boost = clamp(horizontal_speed / 18.0, 0.0, 1.0) * 5.0
	fov_boost += slide_visual_intensity * (4.2 if slide_airborne else 6.6)
	fov_boost += grapple_momentum_intensity * 4.8
	fov_boost += clamp(max(0.0, vertical_velocity) / 20.0, 0.0, 1.0) * 2.2
	var zoom_drop = zoom_fov_drop if zoom_timer > 0.0 else 0.0
	camera.fov = lerp(camera.fov, camera_base_fov + fov_boost - zoom_drop, clamp(dt * (10.0 if zoom_timer > 0.0 else 7.0), 0.0, 1.0))

func _update_ice_camera_motion(dt: float) -> void:
	var momentum_factor = momentum_intensity
	var speed_factor = max(move_intensity * 0.28, momentum_factor * 0.94) if grounded else max(move_intensity * 0.20, momentum_factor * 0.50)
	camera_bob_time += dt * (2.4 + speed_factor * 3.8 + slide_visual_intensity * 1.8)
	var bob_x = (sin(camera_bob_time) * 0.55 + movement_lean_memory * 0.90) * (0.030 + momentum_factor * 0.072) * speed_factor
	var bob_y = sin(camera_bob_time * 0.63) * (0.014 + momentum_factor * 0.026) * speed_factor
	var air_dip = clamp(-vertical_velocity / 25.0, -0.10, 0.12)
	var grapple_lean = 0.035 if grapple_active else 0.0
	var slide_dir = slide_velocity.normalized() if slide_velocity.length() > 0.05 else Vector3.ZERO
	var right = global_transform.basis.x.normalized()
	var slide_side = slide_dir.dot(right)
	var forward = -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var slide_forward = clamp(slide_dir.dot(forward), -1.0, 1.0) if slide_dir.length() > 0.0 and forward.length() > 0.0 else 0.0
	var slide_drop = -BODY_CROUCH_DROP * slide_crouch * (0.58 if slide_airborne else 1.0)
	var slide_camera_forward = (-0.055 if slide_airborne else -0.13) * slide_visual_intensity
	slide_camera_forward += -max(0.0, slide_forward) * slide_visual_intensity * 0.090
	var momentum_sink = -0.040 * momentum_factor * surface_slide_factor
	var shake_amp = shake_strength * (shake_timer / 0.22) if shake_timer > 0.0 else 0.0
	var shake_x = sin(Time.get_ticks_msec() * 0.073) * shake_amp * 0.18
	var shake_y = cos(Time.get_ticks_msec() * 0.089) * shake_amp * 0.08
	var shake_roll = sin(Time.get_ticks_msec() * 0.11) * shake_amp
	camera.position = camera_base_position + Vector3(bob_x + shake_x + slide_side * 0.055 * slide_visual_intensity + body_yaw * 0.18 + look_lean_memory * max(0.0, slide_forward) * slide_visual_intensity * 0.030, bob_y + air_dip + shake_y + slide_drop + momentum_sink - landing_kick * 0.24 - wall_impact * 0.025, slide_camera_forward)
	camera.rotation.x = pitch + body_pitch + (-move_forward * 0.011 * speed_factor) + clamp(-vertical_velocity * 0.0025, -0.038, 0.038) + landing_kick * 0.072 + slide_visual_intensity * (0.018 if slide_airborne else 0.035) + max(0.0, slide_forward) * slide_visual_intensity * 0.055
	camera.rotation.y = body_yaw
	camera.rotation.z = body_roll + (-movement_lean_memory * 0.070 - move_strafe * 0.012 * speed_factor) + grapple_lean + shake_roll - slide_side * (0.046 if slide_airborne else 0.072) * slide_visual_intensity + look_lean_memory * max(0.0, slide_forward) * slide_visual_intensity * 0.046 + sin(camera_bob_time * 0.44) * momentum_factor * 0.018
	var fov_boost = clamp(horizontal_speed / 18.0, 0.0, 1.0) * 5.0
	fov_boost += slide_visual_intensity * (4.2 if slide_airborne else 6.6)
	fov_boost += grapple_momentum_intensity * 4.8
	fov_boost += clamp(max(0.0, vertical_velocity) / 20.0, 0.0, 1.0) * 2.2
	var zoom_drop = zoom_fov_drop if zoom_timer > 0.0 else 0.0
	camera.fov = lerp(camera.fov, camera_base_fov + fov_boost - zoom_drop, clamp(dt * (10.0 if zoom_timer > 0.0 else 7.0), 0.0, 1.0))

func damage(amount: int) -> void:
	if developer_mode:
		damage_flash = max(damage_flash, 0.18)
		add_shake(0.006)
		hp = max(1, hp)
		hp_float = max(1.0, hp_float)
		hp_changed.emit(hp)
		return
	if dodge_immunity_timer > 0.0:
		damage_flash = max(damage_flash, 0.12)
		dash_flash = max(dash_flash, 0.25)
		return
	amount = powerups.damage_after_shield(amount)
	var incoming = float(amount)
	if armor_float > 0.1:
		var armor_budget = armor_float / ARMOR_DAMAGE_DRAIN
		var absorbed_damage = min(incoming, armor_budget)
		armor_float = max(0.0, armor_float - absorbed_damage * ARMOR_DAMAGE_DRAIN)
		armor = int(round(armor_float))
		incoming -= absorbed_damage
		armor_recharge_delay = ARMOR_BREAK_DELAY if armor_float <= 0.1 else ARMOR_RECHARGE_DELAY
	hp_float = max(0.0, hp_float - incoming)
	hp = int(ceil(hp_float))
	passive_heal_delay = PASSIVE_HEAL_DELAY
	damage_flash = 1.0
	add_shake(0.035 + amount * 0.003)
	sound_requested.emit("player_damage")
	hp_changed.emit(hp)

func heal(amount: int, cap: int = 100) -> void:
	hp = min(cap, hp + amount)
	hp_float = float(hp)
	hp_changed.emit(hp)

func _tick_survivability(dt: float) -> void:
	if hp <= 0:
		return
	armor_recharge_delay = max(0.0, armor_recharge_delay - dt)
	passive_heal_delay = max(0.0, passive_heal_delay - dt)
	if passive_heal_delay <= 0.0 and hp_float < 100.0:
		hp_float = min(100.0, hp_float + PASSIVE_HEAL_RATE * dt)
		var new_hp = int(floor(hp_float))
		if new_hp != hp:
			hp = new_hp
			hp_changed.emit(hp)
	if armor_recharge_delay <= 0.0 and armor_float < float(ARMOR_MAX):
		armor_float = min(float(ARMOR_MAX), armor_float + ARMOR_RECHARGE_RATE * dt)
		armor = int(round(armor_float))

func camera_origin() -> Vector3:
	return camera.global_position

func aim_dir() -> Vector3:
	return -camera.global_transform.basis.z.normalized()

func flashlight_beam_origin() -> Vector3:
	if is_instance_valid(flashlight_emitter):
		return flashlight_emitter.global_position
	return camera_origin()

func flashlight_beam_direction() -> Vector3:
	if is_instance_valid(flashlight_emitter):
		return -flashlight_emitter.global_transform.basis.z.normalized()
	return aim_dir()

func add_shake(amount: float) -> void:
	shake_timer = 0.22
	shake_strength = min(0.09, max(shake_strength, amount * shake_scale))

func set_mouse_sensitivity(value: float) -> void:
	look_sensitivity_multiplier = clamp(value, 0.35, 2.2)

func set_screen_shake(value: float) -> void:
	shake_scale = clamp(value, 0.0, 1.0)

func set_developer_mode(enabled: bool) -> void:
	developer_mode = enabled
	if developer_mode:
		hp = 100
		hp_float = 100.0
		armor = ARMOR_MAX
		armor_float = float(ARMOR_MAX)
		hp_changed.emit(hp)
