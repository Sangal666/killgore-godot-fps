extends Node3D
class_name EnemyBase

signal died(enemy)
signal requested_projectile(enemy, direction, speed, damage)
signal requested_bomb(enemy, direction, speed, damage)
signal requested_laser(enemy, direction, damage)
signal phase2_started(enemy)

const QUATERNIUS_ANIMATION_SCENE := "res://assets/quaternius/animations/UAL1_Standard.glb"
const RIGGED_HUMANOID_KEYS := {
	"grunt": {"scale": 1.00, "run": "Jog_Fwd_Loop", "attack": "Punch_Jab", "bulk": 1.00},
	"climber": {"scale": 0.96, "run": "Sprint_Loop", "attack": "Punch_Cross", "bulk": 0.88},
	"tank": {"scale": 1.12, "run": "Walk_Loop", "attack": "Punch_Cross", "bulk": 1.38},
	"brute": {"scale": 1.14, "run": "Jog_Fwd_Loop", "attack": "Punch_Cross", "bulk": 1.25},
	"ranged": {"scale": 0.98, "run": "Jog_Fwd_Loop", "attack": "Pistol_Shoot", "bulk": 0.95},
	"jumper": {"scale": 0.98, "run": "Sprint_Loop", "attack": "Punch_Jab", "bulk": 0.92},
	"wallstalker": {"scale": 0.95, "run": "Sprint_Loop", "attack": "Punch_Cross", "bulk": 0.86},
	"caster": {"scale": 1.00, "run": "Walk_Loop", "attack": "Spell_Simple_Shoot", "bulk": 0.98},
	"spider": {"scale": 0.98, "run": "Sprint_Loop", "attack": "Punch_Cross", "bulk": 0.82},
	"minitank": {"scale": 1.18, "run": "Jog_Fwd_Loop", "attack": "Punch_Cross", "bulk": 1.48},
	"minicaster": {"scale": 1.10, "run": "Walk_Loop", "attack": "Spell_Simple_Shoot", "bulk": 1.10},
	"boss": {"scale": 1.30, "run": "Sprint_Loop", "attack": "Spell_Simple_Shoot", "bulk": 1.92}
}
const RIG_ATTACK_HOLD := 0.42
const RIG_HIT_HOLD := 0.20
const MAX_ACTIVE_RIGGED_HUMANOIDS := 96
const RIG_ANIMATION_ALIASES := {
	"Idle_Loop": "Idle",
	"Walk_Loop": "Walk",
	"Jog_Fwd_Loop": "Jog_Fwd",
	"Sprint_Loop": "Sprint",
	"Jump_Loop": "Jump",
	"Crouch_Fwd_Loop": "Crouch_Fwd",
	"Crouch_Idle_Loop": "Crouch_Idle",
	"Pistol_Idle_Loop": "Pistol_Idle",
	"Push_Loop": "Push",
	"Swim_Fwd_Loop": "Swim_Fwd",
	"Swim_Idle_Loop": "Swim_Idle"
}

static var active_rigged_humanoids = 0
static var rig_scene_cache: PackedScene = null

var stats
var hp = 1
var attack_timer = 0.0
var hit_flash = 0.0
var dead = false
var knockback_velocity = Vector3.ZERO
var jump_timer = 0.0
var jump_cooldown = 0.0
var base_y = 0.0
var shadow: MeshInstance3D
var hp_bar: MeshInstance3D
var asset_factory
var parts: Array = []
var flash_parts: Array = []
var hit_material: StandardMaterial3D
var hit_flash_visible = false
var boss_phase2 = false
var boss_mega_jump_timer = 0.0
var boss_phase_transition_timer = 0.0
var freeze_timer = 0.0
var stun_timer = 0.0
var slow_status_timer = 0.0
var slow_status_multiplier = 1.0
var rig_visual: Node3D
var rig_import_root: Node3D
var rig_skeleton: Skeleton3D
var rig_animation_player: AnimationPlayer
var rig_slot_reserved = false
var rig_current_animation = ""
var rig_last_position = Vector3.ZERO
var rig_attack_timer = 0.0
var rig_hit_timer = 0.0
var rig_hit_animation = "Hit_Chest"
var rig_last_vertical = 0.0
var rig_last_base_y = 0.0
var rig_land_timer = 0.0
var rig_lod_interval = 0.0
var rig_lod_tick = 0.0
var rig_far_paused = false
var death_signal_emitted = false

func configure(data, factory) -> void:
	stats = data
	asset_factory = factory
	hp = stats.hp
	attack_timer = randf_range(0.0, 0.5)
	jump_cooldown = randf_range(0.2, 0.9)
	base_y = global_position.y
	boss_phase2 = false
	boss_mega_jump_timer = randf_range(2.8, 4.8)
	boss_phase_transition_timer = 0.0
	freeze_timer = 0.0
	stun_timer = 0.0
	slow_status_timer = 0.0
	slow_status_multiplier = 1.0
	hit_flash_visible = false
	rig_visual = null
	rig_import_root = null
	rig_skeleton = null
	rig_animation_player = null
	rig_slot_reserved = false
	rig_current_animation = ""
	rig_last_position = global_position
	rig_attack_timer = 0.0
	rig_hit_timer = 0.0
	rig_hit_animation = "Hit_Chest"
	rig_last_vertical = 0.0
	rig_last_base_y = base_y
	rig_land_timer = 0.0
	rig_lod_interval = 0.0
	rig_lod_tick = 0.0
	rig_far_paused = false
	death_signal_emitted = false
	_build_visual()

func _build_visual() -> void:
	parts.clear()
	flash_parts.clear()
	hit_material = asset_factory.make_flat_material(Color.WHITE)
	var body_mat = asset_factory.make_enemy_material(stats.sprite_key, stats.color, stats.accent)
	var dark_mat = asset_factory.make_enemy_material(stats.sprite_key, stats.color.darkened(0.34), stats.accent, true)
	var accent_mat = asset_factory.make_glow_material(stats.accent, 0.95)
	var tooth_mat = asset_factory.make_flat_material(Color8(236, 230, 196))
	if _try_build_animated_humanoid_visual(body_mat, dark_mat, accent_mat, tooth_mat):
		_build_shadow_and_hp_bar()
		return
	_add_capsule(Vector3(0, stats.height * 0.48, 0), stats.width * 0.34, stats.height * 0.76, body_mat)
	_add_sphere(Vector3(0, stats.height * 0.88, -0.03), stats.width * 0.25, body_mat)
	_add_eye_pair(stats.width, stats.height, accent_mat)
	match stats.sprite_key:
		"grunt":
			_add_horns(stats.width, stats.height, dark_mat, 0.42)
			_add_box(Vector3(0, stats.height * 0.35, -0.23), Vector3(stats.width * 0.55, 0.12, 0.12), dark_mat)
		"climber":
			_add_spikes(stats.width, stats.height, dark_mat)
			_add_box(Vector3(-stats.width * 0.42, stats.height * 0.46, -0.05), Vector3(0.16, 0.66, 0.16), dark_mat, Vector3(0, 0, -26))
			_add_box(Vector3(stats.width * 0.42, stats.height * 0.46, -0.05), Vector3(0.16, 0.66, 0.16), dark_mat, Vector3(0, 0, 26))
			_add_cylinder(Vector3(-stats.width * 0.54, stats.height * 0.75, -0.12), 0.0, 0.07, 0.24, accent_mat, Vector3(90, 0, -25))
			_add_cylinder(Vector3(stats.width * 0.54, stats.height * 0.75, -0.12), 0.0, 0.07, 0.24, accent_mat, Vector3(90, 0, 25))
		"tank":
			_add_box(Vector3(-stats.width * 0.43, stats.height * 0.58, 0), Vector3(0.48, 0.34, 0.52), dark_mat)
			_add_box(Vector3(stats.width * 0.43, stats.height * 0.58, 0), Vector3(0.48, 0.34, 0.52), dark_mat)
			_add_box(Vector3(0, stats.height * 0.32, -0.18), Vector3(stats.width * 0.92, 0.22, 0.14), body_mat)
		"brute":
			_add_box(Vector3(0, stats.height * 0.34, -0.28), Vector3(stats.width * 0.72, 0.24, 0.2), dark_mat)
			for i in 4:
				_add_tooth(Vector3(-0.24 + i * 0.16, stats.height * 0.26, -0.42), tooth_mat)
			_add_box(Vector3(-stats.width * 0.52, stats.height * 0.48, 0), Vector3(0.18, 0.56, 0.18), body_mat)
			_add_box(Vector3(stats.width * 0.52, stats.height * 0.48, 0), Vector3(0.18, 0.56, 0.18), body_mat)
		"ranged":
			_add_sphere(Vector3(-stats.width * 0.48, stats.height * 0.52, -0.05), 0.14, accent_mat)
			_add_sphere(Vector3(stats.width * 0.48, stats.height * 0.52, -0.05), 0.14, accent_mat)
			_add_sphere(Vector3(0, stats.height * 0.38, -0.3), 0.18, accent_mat)
		"flyer":
			_add_wings(stats.width, stats.height, dark_mat, accent_mat)
			_add_sphere(Vector3(0, stats.height * 0.54, -0.28), 0.16, accent_mat)
			_add_box(Vector3(0, stats.height * 0.20, 0.0), Vector3(stats.width * 0.34, 0.18, 0.48), dark_mat)
		"skyrazor":
			_add_wings(stats.width, stats.height, dark_mat, accent_mat)
			_add_spikes(stats.width, stats.height, dark_mat)
			_add_cylinder(Vector3(0, stats.height * 0.52, -0.36), 0.0, stats.width * 0.09, 0.42, accent_mat, Vector3(90, 0, 0))
			_add_box(Vector3(0, stats.height * 0.24, 0.08), Vector3(stats.width * 0.26, 0.12, 0.62), dark_mat)
		"bomber":
			_add_wings(stats.width, stats.height, dark_mat, accent_mat)
			_add_box(Vector3(0, stats.height * 0.38, -0.10), Vector3(stats.width * 0.75, 0.22, 0.52), dark_mat)
			_add_sphere(Vector3(0, stats.height * 0.34, -0.42), stats.width * 0.18, accent_mat)
			_add_sphere(Vector3(-stats.width * 0.36, stats.height * 0.48, -0.20), stats.width * 0.12, accent_mat)
			_add_sphere(Vector3(stats.width * 0.36, stats.height * 0.48, -0.20), stats.width * 0.12, accent_mat)
		"wallstalker":
			_add_spikes(stats.width, stats.height, dark_mat)
			_add_box(Vector3(-stats.width * 0.52, stats.height * 0.44, -0.02), Vector3(0.13, 0.80, 0.13), dark_mat, Vector3(0, 0, -34))
			_add_box(Vector3(stats.width * 0.52, stats.height * 0.44, -0.02), Vector3(0.13, 0.80, 0.13), dark_mat, Vector3(0, 0, 34))
			_add_cylinder(Vector3(-stats.width * 0.64, stats.height * 0.82, -0.12), 0.0, 0.06, 0.32, accent_mat, Vector3(90, 0, -32))
			_add_cylinder(Vector3(stats.width * 0.64, stats.height * 0.82, -0.12), 0.0, 0.06, 0.32, accent_mat, Vector3(90, 0, 32))
		"caster":
			_add_sphere(Vector3(-stats.width * 0.54, stats.height * 0.56, -0.10), 0.15, accent_mat)
			_add_sphere(Vector3(stats.width * 0.54, stats.height * 0.56, -0.10), 0.15, accent_mat)
			_add_sphere(Vector3(0, stats.height * 0.42, -0.34), 0.20, accent_mat)
			_add_horns(stats.width, stats.height, dark_mat, 0.36)
			_add_box(Vector3(0, stats.height * 0.26, 0.04), Vector3(stats.width * 0.28, 0.60, 0.18), dark_mat)
		"apex":
			_add_wings(stats.width, stats.height, dark_mat, accent_mat)
			_add_horns(stats.width, stats.height, dark_mat, 0.48)
			_add_sphere(Vector3(0, stats.height * 0.56, -0.34), 0.20, accent_mat)
			_add_cylinder(Vector3(0, stats.height * 0.50, -0.58), 0.0, stats.width * 0.07, 0.62, accent_mat, Vector3(90, 0, 0))
			_add_box(Vector3(-stats.width * 0.48, stats.height * 0.38, 0.08), Vector3(0.10, 0.54, 0.16), dark_mat, Vector3(0, 0, -18))
			_add_box(Vector3(stats.width * 0.48, stats.height * 0.38, 0.08), Vector3(0.10, 0.54, 0.16), dark_mat, Vector3(0, 0, 18))
		"minitank":
			_add_box(Vector3(-stats.width * 0.46, stats.height * 0.58, 0), Vector3(0.58, 0.42, 0.64), dark_mat)
			_add_box(Vector3(stats.width * 0.46, stats.height * 0.58, 0), Vector3(0.58, 0.42, 0.64), dark_mat)
			_add_horns(stats.width, stats.height, dark_mat, 0.64)
			_add_box(Vector3(0, stats.height * 0.38, -0.34), Vector3(stats.width * 0.82, 0.30, 0.26), dark_mat)
			_add_sphere(Vector3(0, stats.height * 0.54, -0.50), 0.20, accent_mat)
		"minicaster":
			_add_horns(stats.width, stats.height, dark_mat, 0.54)
			_add_sphere(Vector3(0, stats.height * 0.46, -0.34), 0.24, accent_mat)
			_add_sphere(Vector3(-stats.width * 0.58, stats.height * 0.60, -0.18), 0.18, accent_mat)
			_add_sphere(Vector3(stats.width * 0.58, stats.height * 0.60, -0.18), 0.18, accent_mat)
			_add_box(Vector3(0, stats.height * 0.23, 0.04), Vector3(stats.width * 0.32, 0.82, 0.22), dark_mat)
			_add_cylinder(Vector3(0, stats.height * 0.68, -0.54), 0.0, stats.width * 0.08, 0.48, accent_mat, Vector3(90, 0, 0))
		"miniflyer":
			_add_wings(stats.width, stats.height, dark_mat, accent_mat)
			_add_spikes(stats.width, stats.height, dark_mat)
			_add_horns(stats.width, stats.height, dark_mat, 0.42)
			_add_box(Vector3(0, stats.height * 0.34, -0.18), Vector3(stats.width * 0.62, 0.18, 0.54), dark_mat)
			_add_sphere(Vector3(0, stats.height * 0.50, -0.44), 0.18, accent_mat)
		"minibomber":
			_add_wings(stats.width, stats.height, dark_mat, accent_mat)
			_add_box(Vector3(0, stats.height * 0.40, -0.08), Vector3(stats.width * 0.82, 0.26, 0.64), dark_mat)
			_add_horns(stats.width, stats.height, dark_mat, 0.52)
			_add_sphere(Vector3(0, stats.height * 0.42, -0.48), 0.24, accent_mat)
			_add_sphere(Vector3(-stats.width * 0.42, stats.height * 0.35, -0.30), 0.14, accent_mat)
			_add_sphere(Vector3(stats.width * 0.42, stats.height * 0.35, -0.30), 0.14, accent_mat)
			_add_cylinder(Vector3(0, stats.height * 0.28, -0.62), 0.0, stats.width * 0.10, 0.50, accent_mat, Vector3(90, 0, 0))
		"spider":
			_add_box(Vector3(0, stats.height * 0.40, -0.06), Vector3(stats.width * 0.86, 0.34, stats.width * 0.72), dark_mat)
			_add_sphere(Vector3(0, stats.height * 0.52, -0.32), stats.width * 0.30, body_mat)
			_add_sphere(Vector3(0, stats.height * 0.48, -0.56), stats.width * 0.14, accent_mat)
			for side in [-1.0, 1.0]:
				for i in 4:
					var z = -0.34 + i * 0.22
					var tilt = -34.0 + i * 18.0
					_add_box(Vector3(side * stats.width * (0.48 + i * 0.03), stats.height * 0.30, z), Vector3(0.10, 0.72, 0.12), dark_mat, Vector3(0, tilt, side * 52.0))
				_add_box(Vector3(side * stats.width * 0.78, stats.height * 0.66, -0.10), Vector3(0.12, 1.05, 0.14), accent_mat, Vector3(0, 0, side * 62.0))
				_add_box(Vector3(side * stats.width * 0.96, stats.height * 0.26, -0.26), Vector3(0.11, 0.92, 0.13), dark_mat, Vector3(0, 0, side * -54.0))
			_add_spikes(stats.width, stats.height, dark_mat)
		"jumper":
			_add_horns(stats.width, stats.height, dark_mat, 0.58)
			_add_box(Vector3(-stats.width * 0.38, stats.height * 0.20, 0.08), Vector3(0.20, 0.72, 0.20), dark_mat, Vector3(18, 0, -18))
			_add_box(Vector3(stats.width * 0.38, stats.height * 0.20, 0.08), Vector3(0.20, 0.72, 0.20), dark_mat, Vector3(18, 0, 18))
			_add_box(Vector3(-stats.width * 0.55, 0.18, -0.12), Vector3(0.46, 0.16, 0.24), dark_mat)
			_add_box(Vector3(stats.width * 0.55, 0.18, -0.12), Vector3(0.46, 0.16, 0.24), dark_mat)
		"boss":
			_add_horns(stats.width, stats.height, dark_mat, 0.96)
			_add_box(Vector3(0, stats.height * 0.34, -0.5), Vector3(stats.width * 0.78, 0.34, 0.24), dark_mat)
			_add_sphere(Vector3(0, stats.height * 0.50, -0.58), 0.28, accent_mat)
			for i in 5:
				_add_tooth(Vector3(-0.38 + i * 0.19, stats.height * 0.23, -0.64), tooth_mat)
	_build_shadow_and_hp_bar()

func _exit_tree() -> void:
	if rig_slot_reserved:
		active_rigged_humanoids = max(0, active_rigged_humanoids - 1)
		rig_slot_reserved = false

func tick(dt: float, player, level_manager) -> void:
	if dead:
		return
	attack_timer = max(0.0, attack_timer - dt)
	rig_attack_timer = max(0.0, rig_attack_timer - dt)
	rig_hit_timer = max(0.0, rig_hit_timer - dt)
	hit_flash = max(0.0, hit_flash - dt * 6.0)
	freeze_timer = max(0.0, freeze_timer - dt)
	stun_timer = max(0.0, stun_timer - dt)
	slow_status_timer = max(0.0, slow_status_timer - dt)
	boss_phase_transition_timer = max(0.0, boss_phase_transition_timer - dt)
	if slow_status_timer <= 0.0:
		slow_status_multiplier = 1.0
	_update_rig_lod(player)
	_apply_hit_flash()
	if boss_phase_transition_timer > 0.0:
		hit_flash = max(hit_flash, 0.65)
		var pulse = 1.18 + sin(Time.get_ticks_msec() * 0.010) * 0.08
		scale = Vector3(pulse, pulse, pulse)
		_update_rig_animation(dt, Vector3.ZERO, 0.0)
		return
	if freeze_timer > 0.0 or stun_timer > 0.0:
		if freeze_timer > 0.0:
			hit_flash = max(hit_flash, 0.22)
		_update_rig_animation(dt, Vector3.ZERO, 0.0)
		return
	var speed_mult = 1.0
	var cooldown_mult = 1.0
	var damage_mult = 1.0
	var projectile_speed_mult = 1.0
	var projectile_count_bonus = 0
	var spread_bonus = 0.0
	var player_momentum = clamp(float(player.horizontal_speed) / 14.0, 0.0, 1.0) if player != null else 0.0
	var level_pressure = clamp(float(level_manager.level_index) / 8.0, 0.0, 1.0) if level_manager != null else 0.0
	if not stats.boss:
		if _is_miniboss():
			speed_mult *= 1.14
			cooldown_mult *= 0.82
			damage_mult *= 1.10
			projectile_speed_mult *= 1.10
			speed_mult *= 1.30 + level_pressure * 0.38
			cooldown_mult *= 0.90 - level_pressure * 0.17
			speed_mult *= 1.0 + player_momentum * (0.44 if stats.flying or stats.climbing else 0.32)
		cooldown_mult *= 1.0 - player_momentum * (0.22 if stats.ranged else 0.14)
	if stats.boss:
		if not boss_phase2 and hp <= int(stats.hp * 0.66):
			boss_phase2 = true
			boss_phase_transition_timer = 7.0
			hit_flash = 1.0
			scale = Vector3(1.18, 1.18, 1.18)
			phase2_started.emit(self)
			_update_rig_animation(dt, Vector3.ZERO, 0.0)
			return
		if boss_phase2:
			speed_mult = 2.26
			cooldown_mult = 0.30
			damage_mult = 2.20
			projectile_speed_mult = 1.66
			projectile_count_bonus = 5
			spread_bonus = 0.28
		else:
			speed_mult = 1.66
			cooldown_mult = 0.54
			damage_mult = 1.38
			projectile_speed_mult = 1.30
			projectile_count_bonus = 2
			spread_bonus = 0.10
	if slow_status_timer > 0.0:
		speed_mult *= slow_status_multiplier
		cooldown_mult *= 1.0 + (1.0 - slow_status_multiplier) * 0.55
	var floor_y = level_manager.floor_height_at(global_position)
	var uses_flight = stats.flying or (stats.boss and boss_phase2)
	if not uses_flight and jump_timer <= 0.0:
		base_y = move_toward(base_y, floor_y, (4.2 if stats.climbing else 18.0) * dt)
	var target = player
	var target_height = 1.6
	if level_manager != null and level_manager.has_method("best_turret_target_for_enemy"):
		var turret = level_manager.best_turret_target_for_enemy(global_position, player.global_position)
		if turret != null:
			target = turret
			target_height = 0.72
	var target_pos = target.global_position + Vector3(0, target_height * 0.52, 0)
	var to_player = target_pos - (global_position + Vector3(0, stats.height * 0.42, 0))
	var dist = to_player.length()
	if dist <= 0.001:
		return
	var dir = to_player.normalized()
	var desired = Vector3.ZERO
	var vertical = 0.0
	if String(stats.id) == "EX":
		desired = dir
		var mine_old = global_position
		global_position += desired.normalized() * stats.speed * speed_mult * dt
		if level_manager.is_enemy_blocked_world(global_position, 0.38 * stats.width, mine_old.y, stats.flying, stats.climbing):
			global_position = mine_old
		global_position.y = base_y
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
		_update_rig_animation(dt, desired, vertical)
		return
	if stats.boss:
		boss_mega_jump_timer = max(0.0, boss_mega_jump_timer - dt)
	if knockback_velocity.length() > 0.02:
		var before_knock = global_position
		global_position += knockback_velocity * dt
		if level_manager.is_enemy_blocked_world(global_position, 0.38 * stats.width, before_knock.y, stats.flying, stats.climbing):
			global_position = before_knock
			knockback_velocity *= -0.22
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 12.0 * dt)
	if stats.jumping:
		jump_timer = max(0.0, jump_timer - dt)
		jump_cooldown = max(0.0, jump_cooldown - dt)
		if stats.boss and boss_mega_jump_timer <= 0.0 and jump_timer <= 0.0 and dist > 11.0:
			jump_timer = max(stats.jump_duration, 0.62)
			jump_cooldown = max(jump_cooldown, stats.jump_cooldown)
			boss_mega_jump_timer = randf_range(6.5, 9.0)
		if jump_timer <= 0.0 and jump_cooldown <= 0.0 and dist > 2.2 and dist < (24.0 if stats.boss else 18.5):
			jump_timer = stats.jump_duration
			jump_cooldown = stats.jump_cooldown
		if jump_timer > 0.0:
			var jump_duration_ref = max(0.01, 0.62 if stats.boss and dist > 11.0 else stats.jump_duration)
			var progress = 1.0 - jump_timer / jump_duration_ref
			var mega = stats.boss and dist > 11.0
			vertical = sin(progress * PI) * stats.jump_height * (1.45 if mega else 1.0)
			desired = dir * (3.10 if mega else (1.95 if stats.boss else 1.75))
	if uses_flight:
		desired = dir
		if dist < stats.ideal_range - 1.2:
			desired = -dir
		elif dist < stats.ideal_range + 1.5:
			desired = Vector3(sin(Time.get_ticks_msec() * 0.002 + global_position.x), 0, cos(Time.get_ticks_msec() * 0.002 + global_position.z)) * 0.7
		var fly_height = 4.4 if stats.boss and boss_phase2 else (9.4 if stats.sprite_key == "apex" else (6.2 if stats.sprite_key == "minibomber" else (5.4 if stats.sprite_key == "miniflyer" else (4.2 if stats.sprite_key == "bomber" else 2.35))))
		vertical = floor_y + fly_height + sin(Time.get_ticks_msec() * 0.004 + global_position.x) * 0.42 - base_y
		if stats.boss and boss_phase2 and dist >= stats.attack_range and attack_timer <= 0.0:
			_trigger_rig_attack()
			requested_laser.emit(self, dir, int(stats.damage * damage_mult * 1.08))
			if randf() < 0.50:
				requested_bomb.emit(self, (dir + Vector3.UP * 0.10).normalized(), stats.projectile_speed * 0.82, int(stats.damage * damage_mult * 0.82))
			attack_timer = stats.cooldown * cooldown_mult * 1.30
		if dist < stats.attack_range and attack_timer <= 0.0:
			if stats.boss and boss_phase2 and dist > stats.ideal_range + 4.0:
				_trigger_rig_attack()
				requested_laser.emit(self, dir, int(stats.damage * damage_mult * 1.15))
				if randf() < 0.70:
					requested_bomb.emit(self, (dir + Vector3.UP * 0.12).normalized(), stats.projectile_speed * 0.86, int(stats.damage * damage_mult * 0.92))
				attack_timer = stats.cooldown * cooldown_mult * 1.18
				return
			var count = stats.projectile_count + projectile_count_bonus
			var start = -(stats.projectile_spread + spread_bonus) * float(count - 1) * 0.5
			_trigger_rig_attack()
			for i in count:
				var shot_dir = dir.rotated(Vector3.UP, start + (stats.projectile_spread + spread_bonus) * i)
				requested_projectile.emit(self, shot_dir, stats.projectile_speed * projectile_speed_mult, int(stats.damage * damage_mult))
			if stats.boss and randf() < (0.52 if boss_phase2 else 0.28):
				requested_bomb.emit(self, (dir + Vector3.UP * 0.16).normalized(), stats.projectile_speed * 0.76, int(stats.damage * damage_mult * 0.88))
			attack_timer = stats.cooldown * cooldown_mult
	elif stats.ranged:
		if dist > stats.ideal_range + 1.2:
			desired = dir
		elif dist < stats.ideal_range - 1.0:
			desired = -dir
		else:
			desired = Vector3(sin(Time.get_ticks_msec() * 0.001 + global_position.x), 0, cos(Time.get_ticks_msec() * 0.001 + global_position.z)) * 0.25
		if stats.sprite_key == "spider":
			var side = Vector3(-dir.z, 0, dir.x).normalized()
			desired = (side * sin(Time.get_ticks_msec() * 0.0035 + global_position.x) + dir * 0.18).normalized()
			if dist < stats.ideal_range - 1.0:
				desired = (desired - dir * 0.85).normalized()
		if dist < stats.attack_range and attack_timer <= 0.0:
			var count = stats.projectile_count + projectile_count_bonus
			var spread = stats.projectile_spread + spread_bonus
			var start = -spread * float(count - 1) * 0.5
			_trigger_rig_attack()
			for i in count:
				var shot_dir = dir.rotated(Vector3.UP, start + spread * i)
				requested_projectile.emit(self, shot_dir, stats.projectile_speed * projectile_speed_mult, int(stats.damage * damage_mult))
			attack_timer = stats.cooldown * cooldown_mult
	else:
		if desired == Vector3.ZERO and dist > stats.attack_range * 0.85:
			desired = dir
		elif dist <= stats.attack_range and attack_timer <= 0.0:
			_trigger_rig_attack()
			if target != player and target.has_method("damage"):
				target.damage(int(stats.damage * damage_mult), global_position)
			else:
				player.damage(int(stats.damage * damage_mult))
			attack_timer = stats.cooldown * cooldown_mult
	if desired.length() > 0.0:
		var old = global_position
		global_position += desired.normalized() * stats.speed * speed_mult * dt
		if level_manager.is_enemy_blocked_world(global_position, 0.38 * stats.width, old.y, stats.flying, stats.climbing):
			global_position = old
			if stats.climbing:
				var climb_boost = 2.45 if stats.sprite_key == "spider" else 1.55
				base_y = min(level_manager.wall_top_height(), base_y + stats.speed * speed_mult * climb_boost * dt)
			elif stats.climbing:
				var next_floor = level_manager.floor_height_at(global_position)
				if next_floor > base_y + 0.15:
					base_y = move_toward(base_y, next_floor, max(0.22, stats.speed * 0.18 * dt))
				elif stats.sprite_key == "spider" and dist > 4.0 and floori(float(Time.get_ticks_msec()) / 900.0) % 5 == 0:
					base_y = move_toward(base_y, min(level_manager.wall_top_height(), floor_y + 3.2), stats.speed * 0.52 * dt)
	global_position.y = base_y + vertical
	if shadow != null:
		shadow.scale = Vector3(1.0 - vertical * 0.22, 1.0, 0.55 - vertical * 0.12)
	look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
	_update_rig_animation(dt, desired, vertical)

func take_damage(amount: int, source: Vector3, headshot := false) -> void:
	if dead or boss_phase_transition_timer > 0.0:
		return
	hp -= amount
	hit_flash = 1.0
	rig_hit_timer = RIG_HIT_HOLD
	rig_hit_animation = "Hit_Head" if headshot else "Hit_Chest"
	hp_bar.visible = true
	hp_bar.scale.x = max(0.05, float(hp) / float(stats.hp))
	var push = global_position - source
	push.y = 0
	if push.length() > 0.01:
		apply_impulse(push.normalized() * 2.8)
	if hp <= 0:
		die()

func apply_impulse(impulse: Vector3) -> void:
	impulse.y = 0.0
	var resist = 1.0
	if stats.boss:
		resist = 0.16
	elif _is_miniboss():
		resist = 0.48
	knockback_velocity += impulse * resist

func apply_slow(multiplier: float, duration: float) -> void:
	var resist = 0.72 if stats.boss else (0.82 if _is_miniboss() else 1.0)
	var adjusted = lerp(1.0, clamp(multiplier, 0.28, 1.0), resist)
	slow_status_multiplier = min(slow_status_multiplier, adjusted)
	slow_status_timer = max(slow_status_timer, duration * resist)
	hit_flash = max(hit_flash, 0.38)

func apply_freeze(duration: float) -> void:
	var resist = 0.28 if stats.boss else (0.48 if _is_miniboss() else 1.0)
	freeze_timer = max(freeze_timer, duration * resist)
	hit_flash = 1.0

func apply_stun(duration: float) -> void:
	var resist = 0.24 if stats.boss else (0.46 if _is_miniboss() else 1.0)
	stun_timer = max(stun_timer, duration * resist)
	hit_flash = max(hit_flash, 0.75)

func die() -> void:
	dead = true
	if stats.boss:
		if hp_bar != null:
			hp_bar.visible = false
		var death_tween = create_tween()
		death_tween.set_parallel(true)
		death_tween.tween_property(self, "scale", Vector3(1.55, 0.78, 1.55), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		death_tween.tween_property(self, "rotation_degrees:y", rotation_degrees.y + 34.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		death_tween.chain().tween_callback(_emit_died_once)
		death_tween.tween_callback(func():
			visible = false
			queue_free()
		)
		return
	visible = false
	_emit_died_once()
	var tween = create_tween()
	tween.tween_interval(0.18)
	tween.tween_callback(queue_free)

func _emit_died_once() -> void:
	if death_signal_emitted:
		return
	death_signal_emitted = true
	died.emit(self)

func _apply_hit_flash() -> void:
	if flash_parts.is_empty():
		return
	var should_flash = hit_flash > 0.0
	if should_flash == hit_flash_visible:
		return
	hit_flash_visible = should_flash
	for part in flash_parts:
		if not is_instance_valid(part.node):
			continue
		part.node.material_override = hit_material if should_flash else part.mat

func _build_shadow_and_hp_bar() -> void:
	shadow = MeshInstance3D.new()
	var shadow_mesh = CylinderMesh.new()
	shadow_mesh.top_radius = stats.width * 0.42
	shadow_mesh.bottom_radius = stats.width * 0.42
	shadow_mesh.height = 0.02
	shadow.mesh = shadow_mesh
	shadow.position.y = 0.02
	shadow.scale.z = 0.55
	var shadow_mat = StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.38)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.material_override = shadow_mat
	add_child(shadow)
	hp_bar = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(stats.width, 0.055, 0.04)
	hp_bar.mesh = mesh
	hp_bar.position = Vector3(0, stats.height + 0.32, -0.04)
	hp_bar.material_override = asset_factory.make_flat_material(Color8(255, 82, 64) if _is_miniboss() else Color8(210, 50, 55))
	hp_bar.visible = _is_miniboss()
	add_child(hp_bar)

func _try_build_animated_humanoid_visual(body_mat: Material, dark_mat: Material, accent_mat: Material, tooth_mat: Material) -> bool:
	if not RIGGED_HUMANOID_KEYS.has(String(stats.sprite_key)):
		return false
	if not ResourceLoader.exists(QUATERNIUS_ANIMATION_SCENE):
		return false
	var priority_rig = stats.boss or _is_miniboss()
	if not priority_rig and active_rigged_humanoids >= MAX_ACTIVE_RIGGED_HUMANOIDS:
		return false
	active_rigged_humanoids += 1
	rig_slot_reserved = true
	var scene = _rig_scene()
	if scene == null or not scene is PackedScene:
		_release_rig_slot()
		return false
	var imported = scene.instantiate()
	if not imported is Node3D:
		imported.queue_free()
		_release_rig_slot()
		return false
	rig_visual = Node3D.new()
	rig_visual.name = "QuaterniusHumanoidVisual"
	rig_visual.rotation_degrees.y = 180.0
	add_child(rig_visual)
	rig_visual.add_child(imported)
	rig_import_root = imported
	var rig_body_mat = asset_factory.make_enemy_material(stats.sprite_key, stats.color.darkened(0.28), stats.accent, true)
	_prepare_rig_visual(imported, rig_body_mat)
	_normalize_rig_visual(imported)
	rig_animation_player = _find_animation_player(imported)
	rig_skeleton = _find_skeleton(imported)
	if rig_animation_player == null or rig_skeleton == null:
		rig_visual.queue_free()
		rig_visual = null
		rig_import_root = null
		rig_skeleton = null
		_release_rig_slot()
		return false
	_prepare_rig_animations()
	_add_rig_identity_details(body_mat, dark_mat, accent_mat, tooth_mat)
	_play_rig_animation("Idle_Loop", true, 1.0)
	return true

func _rig_scene() -> PackedScene:
	if rig_scene_cache != null:
		return rig_scene_cache
	var loaded = load(QUATERNIUS_ANIMATION_SCENE)
	if loaded is PackedScene:
		rig_scene_cache = loaded
	return rig_scene_cache

func _release_rig_slot() -> void:
	if not rig_slot_reserved:
		return
	active_rigged_humanoids = max(0, active_rigged_humanoids - 1)
	rig_slot_reserved = false

func _prepare_rig_visual(root: Node, body_mat: Material) -> void:
	for node in _walk_visual_nodes(root):
		if node is MeshInstance3D:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.material_override = body_mat
			flash_parts.append({"node": node, "mat": body_mat})
		if node is CollisionObject3D:
			node.collision_layer = 0
			node.collision_mask = 0
		if node is CollisionShape3D:
			node.disabled = true
		if node is Camera3D or node is Light3D:
			node.visible = false

func _normalize_rig_visual(root: Node3D) -> void:
	var bounds = _visual_bounds(root)
	if bounds.size == Vector3.ZERO or bounds.size.y <= 0.001:
		return
	var profile = RIGGED_HUMANOID_KEYS[String(stats.sprite_key)]
	var target_height = stats.height * float(profile.get("scale", 1.0))
	var scale_ratio = target_height / bounds.size.y
	var center = bounds.position + bounds.size * 0.5
	root.scale *= scale_ratio
	root.position -= Vector3(center.x, bounds.position.y, center.z) * scale_ratio

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var found = _find_animation_player(child)
		if found != null:
			return found
	return null

func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root
	for child in root.get_children():
		var found = _find_skeleton(child)
		if found != null:
			return found
	return null

func _prepare_rig_animations() -> void:
	if rig_animation_player == null:
		return
	for anim_name in rig_animation_player.get_animation_list():
		var anim = rig_animation_player.get_animation(anim_name)
		if anim != null and _is_looping_rig_animation(String(anim_name)):
			anim.loop_mode = Animation.LOOP_LINEAR

func _is_looping_rig_animation(anim_name: String) -> bool:
	return anim_name in [
		"Idle",
		"Walk",
		"Jog_Fwd",
		"Sprint",
		"Jump",
		"Crouch_Fwd",
		"Crouch_Idle",
		"Pistol_Idle",
		"Push",
		"Swim_Fwd",
		"Swim_Idle"
	] or anim_name.ends_with("_Loop")

func _add_rig_identity_details(body_mat: Material, dark_mat: Material, accent_mat: Material, tooth_mat: Material) -> void:
	var profile = RIGGED_HUMANOID_KEYS.get(String(stats.sprite_key), {})
	var bulk = float(profile.get("bulk", 1.0))
	var armor_mat = asset_factory.make_enemy_material(stats.sprite_key, stats.color.lightened(0.08), stats.accent)
	var black_mat = asset_factory.make_enemy_material(stats.sprite_key, stats.color.darkened(0.58), stats.accent, true)
	_add_bone_box("spine_03", Vector3(0.0, 0.020, -0.055), Vector3(stats.width * 0.54 * bulk, stats.height * 0.16, 0.14), armor_mat)
	_add_bone_box("spine_02", Vector3(0.0, 0.000, -0.075), Vector3(stats.width * 0.36 * bulk, stats.height * 0.09, 0.055), accent_mat)
	_add_bone_box("spine_01", Vector3(0.0, -0.020, -0.045), Vector3(stats.width * 0.42 * bulk, stats.height * 0.10, 0.12), black_mat)
	_add_bone_sphere("Head", Vector3(0.0, 0.020, -0.020), stats.width * 0.18, armor_mat)
	_add_bone_box("Head", Vector3(0.0, 0.000, -stats.width * 0.15), Vector3(stats.width * 0.32, 0.040, 0.040), accent_mat)
	_add_bone_sphere("Head", Vector3(-stats.width * 0.10, 0.015, -stats.width * 0.20), max(0.035, stats.width * 0.035), accent_mat)
	_add_bone_sphere("Head", Vector3(stats.width * 0.10, 0.015, -stats.width * 0.20), max(0.035, stats.width * 0.035), accent_mat)
	_add_bone_box("upperarm_l", Vector3(0.0, 0.050, 0.0), Vector3(stats.width * 0.13, stats.height * 0.15, 0.13), dark_mat, Vector3(0, 0, -6))
	_add_bone_box("upperarm_r", Vector3(0.0, 0.050, 0.0), Vector3(stats.width * 0.13, stats.height * 0.15, 0.13), dark_mat, Vector3(0, 0, 6))
	match stats.sprite_key:
		"grunt":
			_add_rig_horns(dark_mat, 0.32)
			_add_bone_box("pelvis", Vector3(0.0, -0.02, -0.05), Vector3(stats.width * 0.42, 0.12, 0.12), black_mat)
		"climber", "wallstalker":
			_add_rig_spikes(dark_mat)
			_add_bone_cylinder("hand_l", Vector3(0.0, 0.02, -0.08), 0.0, 0.045, 0.28, accent_mat, Vector3(90, 0, -22))
			_add_bone_cylinder("hand_r", Vector3(0.0, 0.02, -0.08), 0.0, 0.045, 0.28, accent_mat, Vector3(90, 0, 22))
			_add_bone_box("calf_l", Vector3(0.0, 0.03, 0.0), Vector3(0.10, 0.34, 0.10), dark_mat, Vector3(8, 0, -10))
			_add_bone_box("calf_r", Vector3(0.0, 0.03, 0.0), Vector3(0.10, 0.34, 0.10), dark_mat, Vector3(8, 0, 10))
		"tank", "minitank":
			_add_bone_box("upperarm_l", Vector3(0.0, 0.07, 0.0), Vector3(0.34, 0.24, 0.32), dark_mat)
			_add_bone_box("upperarm_r", Vector3(0.0, 0.07, 0.0), Vector3(0.34, 0.24, 0.32), dark_mat)
			_add_rig_horns(dark_mat, 0.42)
			_add_bone_box("pelvis", Vector3(0.0, -0.03, -0.07), Vector3(stats.width * 0.62, 0.18, 0.13), body_mat)
		"brute":
			_add_rig_horns(dark_mat, 0.46)
			_add_bone_box("pelvis", Vector3(0.0, -0.03, -0.08), Vector3(stats.width * 0.58, 0.20, 0.14), black_mat)
			for i in 4:
				_add_bone_cylinder("Head", Vector3(-0.15 + i * 0.10, -0.10, -0.18), 0.0, 0.030, 0.13, tooth_mat, Vector3(90, 0, 0))
		"ranged":
			_add_bone_sphere("hand_l", Vector3(0.0, 0.02, -0.04), 0.08, accent_mat)
			_add_bone_sphere("hand_r", Vector3(0.0, 0.02, -0.04), 0.08, accent_mat)
			_add_bone_cylinder("hand_r", Vector3(0.0, 0.00, -0.18), 0.035, 0.060, 0.36, black_mat, Vector3(90, 0, 0))
			_add_bone_sphere("hand_r", Vector3(0.0, 0.00, -0.38), 0.045, accent_mat)
		"caster", "minicaster":
			_add_rig_horns(dark_mat, 0.36)
			_add_bone_sphere("spine_01", Vector3(0.0, -0.05, -0.16), 0.13, accent_mat)
			_add_bone_sphere("hand_l", Vector3(0.0, 0.02, -0.06), 0.10, accent_mat)
			_add_bone_sphere("hand_r", Vector3(0.0, 0.02, -0.06), 0.10, accent_mat)
		"jumper":
			_add_rig_horns(dark_mat, 0.38)
			_add_bone_box("thigh_l", Vector3(0.0, 0.03, 0.02), Vector3(0.14, 0.34, 0.14), dark_mat, Vector3(10, 0, -10))
			_add_bone_box("thigh_r", Vector3(0.0, 0.03, 0.02), Vector3(0.14, 0.34, 0.14), dark_mat, Vector3(10, 0, 10))
			_add_bone_box("calf_l", Vector3(0.0, 0.03, 0.0), Vector3(0.12, 0.32, 0.12), black_mat, Vector3(10, 0, -8))
			_add_bone_box("calf_r", Vector3(0.0, 0.03, 0.0), Vector3(0.12, 0.32, 0.12), black_mat, Vector3(10, 0, 8))
		"spider":
			_add_rig_spikes(dark_mat)
			_add_bone_sphere("spine_02", Vector3(0.0, -0.03, -0.15), stats.width * 0.18, accent_mat)
			_add_bone_box("spine_03", Vector3(0.0, 0.02, -0.09), Vector3(stats.width * 0.72, stats.height * 0.12, 0.14), black_mat)
			_add_bone_box("pelvis", Vector3(0.0, -0.04, -0.08), Vector3(stats.width * 0.62, 0.16, 0.18), dark_mat)
			for side in [-1.0, 1.0]:
				var side_bone = "upperarm_l" if side < 0.0 else "upperarm_r"
				var thigh_bone = "thigh_l" if side < 0.0 else "thigh_r"
				var calf_bone = "calf_l" if side < 0.0 else "calf_r"
				_add_bone_box(side_bone, Vector3(side * 0.06, 0.06, -0.04), Vector3(0.08, 0.46, 0.10), black_mat, Vector3(0, 0, side * 48.0))
				_add_bone_box(thigh_bone, Vector3(side * 0.04, 0.06, -0.02), Vector3(0.09, 0.42, 0.10), dark_mat, Vector3(0, 0, side * 38.0))
				_add_bone_box(calf_bone, Vector3(side * 0.04, 0.03, -0.02), Vector3(0.08, 0.36, 0.09), black_mat, Vector3(0, 0, side * -28.0))
				_add_bone_cylinder("hand_l" if side < 0.0 else "hand_r", Vector3(0.0, 0.01, -0.07), 0.0, 0.040, 0.24, accent_mat, Vector3(90, 0, side * 20.0))
		"boss":
			_add_rig_horns(dark_mat, 0.52)
			_add_bone_box("spine_03", Vector3(0.0, 0.04, -0.09), Vector3(stats.width * 0.68, stats.height * 0.20, 0.18), body_mat)
			_add_bone_box("spine_02", Vector3(0.0, -0.01, -0.12), Vector3(stats.width * 0.48, stats.height * 0.10, 0.09), accent_mat)
			_add_bone_box("upperarm_l", Vector3(0.0, 0.08, 0.0), Vector3(0.44, 0.32, 0.44), dark_mat)
			_add_bone_box("upperarm_r", Vector3(0.0, 0.08, 0.0), Vector3(0.44, 0.32, 0.44), dark_mat)
			_add_bone_sphere("hand_l", Vector3(0.0, 0.02, -0.10), 0.18, accent_mat)
			_add_bone_sphere("hand_r", Vector3(0.0, 0.02, -0.10), 0.18, accent_mat)
			_add_bone_box("pelvis", Vector3(0.0, -0.04, -0.10), Vector3(stats.width * 0.62, 0.24, 0.18), black_mat)
			for i in 5:
				_add_bone_cylinder("Head", Vector3(-0.18 + i * 0.09, -0.10, -0.18), 0.0, 0.026, 0.11, tooth_mat, Vector3(90, 0, 0))

func _update_rig_animation(dt: float, desired: Vector3, vertical: float) -> void:
	if rig_animation_player == null:
		return
	var urgent = rig_hit_timer > 0.0 or rig_attack_timer > 0.0 or rig_land_timer > 0.0
	if rig_far_paused and not urgent:
		rig_animation_player.speed_scale = 0.0
		rig_last_position = global_position
		rig_last_base_y = base_y
		rig_last_vertical = vertical
		return
	if rig_lod_interval > 0.0 and not urgent:
		rig_lod_tick -= dt
		if rig_lod_tick > 0.0:
			return
		rig_lod_tick = rig_lod_interval
	var flat_delta = Vector3(global_position.x - rig_last_position.x, 0.0, global_position.z - rig_last_position.z)
	var move_speed = flat_delta.length() / max(0.001, dt)
	rig_last_position = global_position
	var climb_speed = abs(base_y - rig_last_base_y) / max(0.001, dt)
	rig_last_base_y = base_y
	if rig_last_vertical > 0.20 and vertical <= 0.04:
		rig_land_timer = 0.18
	rig_last_vertical = vertical
	rig_land_timer = max(0.0, rig_land_timer - dt)
	var anim = "Idle_Loop"
	var speed_scale = 1.0
	var moving_ranged_attack = stats.ranged and rig_attack_timer > 0.0 and move_speed > 0.22
	if rig_hit_timer > 0.0:
		anim = rig_hit_animation
	elif rig_attack_timer > 0.0 and not moving_ranged_attack:
		anim = _rig_attack_animation()
	elif rig_land_timer > 0.0:
		anim = "Jump_Land"
	elif stats.jumping and jump_timer > stats.jump_duration * 0.72:
		anim = "Jump_Start"
	elif stats.jumping and (jump_timer > 0.0 or vertical > 0.08):
		anim = "Jump_Loop"
	elif stats.climbing and climb_speed > 0.18 and move_speed > 0.10:
		anim = "Sprint_Loop"
		speed_scale = clamp(move_speed / max(0.1, stats.speed), 0.80, 1.75)
	elif move_speed > stats.speed * 1.10 or desired.length() > 0.8:
		anim = _rig_run_animation(move_speed)
		speed_scale = clamp(move_speed / max(0.1, stats.speed), 0.72, 1.65)
	elif move_speed > 0.16:
		anim = "Walk_Loop"
		speed_scale = clamp(move_speed / 2.2, 0.65, 1.18)
	_play_rig_animation(anim, false, speed_scale)

func _update_rig_lod(player) -> void:
	if rig_animation_player == null:
		return
	if player == null or stats.boss or _is_miniboss():
		rig_lod_interval = 0.0
		rig_far_paused = false
		return
	var dist_sq = global_position.distance_squared_to(player.global_position)
	if dist_sq > 48.0 * 48.0:
		rig_lod_interval = 0.34
		rig_far_paused = true
	elif dist_sq > 34.0 * 34.0:
		rig_lod_interval = 0.18
		rig_far_paused = false
	elif dist_sq > 20.0 * 20.0:
		rig_lod_interval = 0.08
		rig_far_paused = false
	else:
		rig_lod_interval = 0.0
		rig_far_paused = false

func _rig_attack_animation() -> String:
	var profile = RIGGED_HUMANOID_KEYS.get(String(stats.sprite_key), {})
	return String(profile.get("attack", "Punch_Jab"))

func _rig_run_animation(move_speed: float) -> String:
	var profile = RIGGED_HUMANOID_KEYS.get(String(stats.sprite_key), {})
	if move_speed > stats.speed * 1.35:
		return "Sprint_Loop"
	return String(profile.get("run", "Jog_Fwd_Loop"))

func _trigger_rig_attack() -> void:
	rig_attack_timer = RIG_ATTACK_HOLD

func _play_rig_animation(anim_name: String, force := false, speed_scale := 1.0) -> void:
	anim_name = _resolve_rig_animation(anim_name)
	if rig_animation_player == null or not rig_animation_player.has_animation(anim_name):
		if anim_name == "Jump_Land" and rig_animation_player != null and rig_animation_player.has_animation("Jump"):
			anim_name = "Jump"
		else:
			return
	if rig_animation_player == null or not rig_animation_player.has_animation(anim_name):
		return
	rig_animation_player.speed_scale = speed_scale
	if force or rig_current_animation != anim_name or not rig_animation_player.is_playing():
		rig_current_animation = anim_name
		rig_animation_player.play(anim_name, 0.10)

func _resolve_rig_animation(anim_name: String) -> String:
	if rig_animation_player != null and rig_animation_player.has_animation(anim_name):
		return anim_name
	if RIG_ANIMATION_ALIASES.has(anim_name):
		var alias = String(RIG_ANIMATION_ALIASES[anim_name])
		if rig_animation_player == null or rig_animation_player.has_animation(alias):
			return alias
	return anim_name

func _walk_visual_nodes(root: Node) -> Array:
	var out = [root]
	for child in root.get_children():
		out.append_array(_walk_visual_nodes(child))
	return out

func _visual_bounds(root: Node3D) -> AABB:
	var found = false
	var bounds = AABB()
	var root_inv = root.global_transform.affine_inverse()
	for node in _walk_visual_nodes(root):
		if not node is MeshInstance3D:
			continue
		var mesh_node: MeshInstance3D = node
		var local_aabb = mesh_node.get_aabb()
		if local_aabb.size == Vector3.ZERO:
			continue
		for corner in _aabb_corners(local_aabb):
			var point = root_inv * mesh_node.to_global(corner)
			if not found:
				bounds = AABB(point, Vector3.ZERO)
				found = true
			else:
				bounds = bounds.expand(point)
	return bounds if found else AABB()

func _aabb_corners(box: AABB) -> Array:
	var p = box.position
	var s = box.size
	return [
		p,
		p + Vector3(s.x, 0, 0),
		p + Vector3(0, s.y, 0),
		p + Vector3(0, 0, s.z),
		p + Vector3(s.x, s.y, 0),
		p + Vector3(s.x, 0, s.z),
		p + Vector3(0, s.y, s.z),
		p + s
	]

func _add_bone_box(bone_name: String, pos: Vector3, mesh_size: Vector3, mat: Material, rot := Vector3.ZERO) -> void:
	var mesh = BoxMesh.new()
	mesh.size = mesh_size
	_add_bone_mesh(bone_name, mesh, pos, mat, rot)

func _add_bone_sphere(bone_name: String, pos: Vector3, radius: float, mat: Material) -> void:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	_add_bone_mesh(bone_name, mesh, pos, mat)

func _add_bone_cylinder(bone_name: String, pos: Vector3, top: float, bottom: float, height: float, mat: Material, rot := Vector3.ZERO) -> void:
	var mesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 6
	_add_bone_mesh(bone_name, mesh, pos, mat, rot)

func _add_bone_mesh(bone_name: String, mesh: Mesh, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	if rig_skeleton == null or rig_skeleton.find_bone(bone_name) < 0:
		return _add_rig_mesh(mesh, pos, mat, rot)
	var attach = BoneAttachment3D.new()
	attach.name = "KillgoreArmor_%s" % bone_name
	attach.bone_name = bone_name
	rig_skeleton.add_child(attach)
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	attach.add_child(node)
	parts.append({"node": node, "mat": mat, "bone": bone_name})
	flash_parts.append({"node": node, "mat": mat})
	return node

func _add_rig_box(pos: Vector3, mesh_size: Vector3, mat: Material, rot := Vector3.ZERO) -> void:
	var mesh = BoxMesh.new()
	mesh.size = mesh_size
	_add_rig_mesh(mesh, pos, mat, rot)

func _add_rig_sphere(pos: Vector3, radius: float, mat: Material) -> void:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	_add_rig_mesh(mesh, pos, mat)

func _add_rig_cylinder(pos: Vector3, top: float, bottom: float, height: float, mat: Material, rot := Vector3.ZERO) -> void:
	var mesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 6
	_add_rig_mesh(mesh, pos, mat, rot)

func _add_rig_mesh(mesh: Mesh, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var parent = rig_visual if is_instance_valid(rig_visual) else self
	parent.add_child(node)
	parts.append({"node": node, "mat": mat})
	flash_parts.append({"node": node, "mat": mat})
	return node

func _add_rig_horns(mat: Material, horn_height: float) -> void:
	_add_bone_cylinder("Head", Vector3(-stats.width * 0.13, 0.14, 0.0), 0.01, stats.width * 0.055, horn_height * 0.78, mat, Vector3(30, 0, -18))
	_add_bone_cylinder("Head", Vector3(stats.width * 0.13, 0.14, 0.0), 0.01, stats.width * 0.055, horn_height * 0.78, mat, Vector3(30, 0, 18))

func _add_rig_spikes(mat: Material) -> void:
	for i in 5:
		_add_bone_cylinder("Head", Vector3(-stats.width * 0.20 + i * stats.width * 0.10, 0.12, 0.02), 0.0, stats.width * 0.034, 0.24, mat, Vector3(0, 0, -8 + i * 4))

func _add_capsule(pos: Vector3, radius: float, height: float, mat: Material) -> void:
	var mesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = max(height, radius * 2.2)
	mesh.radial_segments = 7
	mesh.rings = 3
	_add_mesh(mesh, pos, mat)

func _add_sphere(pos: Vector3, radius: float, mat: Material) -> void:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	_add_mesh(mesh, pos, mat)

func _add_box(pos: Vector3, size: Vector3, mat: Material, rot := Vector3.ZERO) -> void:
	var mesh = BoxMesh.new()
	mesh.size = size
	_add_mesh(mesh, pos, mat, rot)

func _add_cylinder(pos: Vector3, top: float, bottom: float, height: float, mat: Material, rot := Vector3.ZERO) -> void:
	var mesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 6
	_add_mesh(mesh, pos, mat, rot)

func _add_mesh(mesh: Mesh, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = mat
	add_child(node)
	parts.append({"node": node, "mat": mat})
	flash_parts.append({"node": node, "mat": mat})
	return node

func _add_eye_pair(width: float, height: float, mat: Material) -> void:
	_add_sphere(Vector3(-width * 0.12, height * 0.93, -width * 0.22), max(0.045, width * 0.045), mat)
	_add_sphere(Vector3(width * 0.12, height * 0.93, -width * 0.22), max(0.045, width * 0.045), mat)

func _add_horns(width: float, height: float, mat: Material, horn_height: float) -> void:
	_add_cylinder(Vector3(-width * 0.19, height * 1.08, 0), 0.01, width * 0.065, horn_height, mat, Vector3(30, 0, -18))
	_add_cylinder(Vector3(width * 0.19, height * 1.08, 0), 0.01, width * 0.065, horn_height, mat, Vector3(30, 0, 18))

func _add_spikes(width: float, height: float, mat: Material) -> void:
	for i in 5:
		_add_cylinder(Vector3(-width * 0.32 + i * width * 0.16, height * 1.02, 0.0), 0.0, width * 0.045, 0.36, mat, Vector3(0, 0, -8 + i * 4))

func _add_wings(width: float, height: float, mat: Material, glow_mat: Material) -> void:
	_add_box(Vector3(-width * 0.62, height * 0.58, 0.08), Vector3(width * 0.70, 0.08, 0.34), mat, Vector3(0, 0, -24))
	_add_box(Vector3(width * 0.62, height * 0.58, 0.08), Vector3(width * 0.70, 0.08, 0.34), mat, Vector3(0, 0, 24))
	_add_box(Vector3(-width * 0.86, height * 0.43, 0.1), Vector3(width * 0.44, 0.06, 0.28), glow_mat, Vector3(0, 0, -38))
	_add_box(Vector3(width * 0.86, height * 0.43, 0.1), Vector3(width * 0.44, 0.06, 0.28), glow_mat, Vector3(0, 0, 38))

func _add_tooth(pos: Vector3, mat: Material) -> void:
	_add_cylinder(pos, 0.0, 0.045, 0.18, mat, Vector3(90, 0, 0))

func _is_miniboss() -> bool:
	return String(stats.id) in ["0", "6", "7", "8", "9"]
