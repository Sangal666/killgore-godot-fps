extends Node
class_name WeaponManager

const GameDataScript = preload("res://scripts/core/GameData.gd")
const GameSettingsScript = preload("res://scripts/core/GameSettings.gd")

const IMPORTED_WEAPON_MODELS = {}

signal changed
signal fired(weapon_id)
signal message(text)
signal sound_requested(sfx_name)
signal sound_at_requested(sfx_name, world_position)
signal sound_attached_requested(sfx_name, parent_node, local_position)
signal sound_stop_requested(sfx_name)

var weapons = {}
var player
var level_manager
var current_weapon = "pistol"
var unlocked = {"whip": true, "pistol": true}
var carried_weapons: Array = ["whip", "pistol"]
var max_carried_weapons = 5
var pending_weapon_pickup = ""
var locker_open = false
var current_bomb_type = "frag"
var bomb_types = ["frag", "incendiary", "cryo", "toxic", "shock", "cluster"]
var ammo_reserve = {}
var mag_ammo = {}
var shoot_timer = 0.0
var special_timer = 0.0
var quick_melee_timer = 0.0
var reload_timer = 0.0
var grenade_cooldown = 0.0
var fire_flash_timer = 0.0
var recoil_kick = 0.0
var weapon_sway := Vector3.ZERO
var weapon_physics_offset := Vector3.ZERO
var weapon_physics_velocity := Vector3.ZERO
var weapon_lag := Vector2.ZERO
var weapon_roll = 0.0
var last_player_yaw = 0.0
var last_player_pitch = 0.0
var last_player_horizontal_velocity := Vector3.ZERO
var last_player_vertical_velocity = 0.0
var weapon_accel_memory := Vector3.ZERO
var weapon_vertical_accel_memory = 0.0
var attack_anim_timer = 0.0
var whip_swing_timer = 0.0
var quick_melee_anim_timer = 0.0
var weapon_root: Node3D
var muzzle_marker: Marker3D
var view_weapon_id = ""
var weapon_visual_cache = {}
var weapon_visual_build_root: Node3D
var no_gun_mode = false
var level_weapons_disabled = false
var legacy_weapon_models = false
var revolver_fan_timer = 0.0
var revolver_fan_interval = 0.0
var revolver_fan_rounds = 0
var auto_stabilizer_timer = 0.0
var rail_zoom_sound_timer = 0.0
var flak_overdrive_timer = 0.0
var shotgun_pending_fire = false
var shotgun_pending_timer = 0.0
var shotgun_trigger_delay = 0.20
var developer_mode = false

func configure(weapon_data: Dictionary, player_node, lm) -> void:
	weapons = weapon_data
	player = player_node
	level_manager = lm
	var settings = GameSettingsScript.load_settings()
	no_gun_mode = bool(settings.get("no_gun_mode", false))
	legacy_weapon_models = bool(settings.get("legacy_weapon_models", false))
	developer_mode = bool(settings.get("developer_mode", false))
	current_weapon = "pistol"
	unlocked = {"whip": true, "pistol": true}
	carried_weapons = ["whip", "pistol"]
	pending_weapon_pickup = ""
	locker_open = false
	current_bomb_type = "frag"
	ammo_reserve = _base_ammo_reserve()
	mag_ammo = _empty_mag_state()
	ammo_reserve.bullets = 72
	ammo_reserve.grenades = 2
	mag_ammo.pistol = weapons.pistol.mag_size
	quick_melee_timer = 0.0
	weapon_sway = Vector3(0.36, -0.50, -0.92)
	weapon_physics_offset = Vector3.ZERO
	weapon_physics_velocity = Vector3.ZERO
	weapon_lag = Vector2.ZERO
	weapon_roll = 0.0
	attack_anim_timer = 0.0
	whip_swing_timer = 0.0
	quick_melee_anim_timer = 0.0
	last_player_yaw = player.yaw if player != null else 0.0
	last_player_pitch = player.pitch if player != null else 0.0
	last_player_horizontal_velocity = player.horizontal_velocity if player != null else Vector3.ZERO
	last_player_vertical_velocity = player.vertical_velocity if player != null else 0.0
	weapon_accel_memory = Vector3.ZERO
	weapon_vertical_accel_memory = 0.0
	shotgun_pending_fire = false
	shotgun_pending_timer = 0.0
	_ensure_weapon_view()
	if developer_mode:
		unlock_all_weapons(true)
	else:
		_rebuild_weapon_view()
	if not legacy_weapon_models:
		_prewarm_imported_weapon_views()
	_prewarm_weapon_views(GameDataScript.WEAPON_ORDER)
	changed.emit()

func _base_ammo_reserve() -> Dictionary:
	var out = {}
	for ammo_type in GameDataScript.AMMO_MAX.keys():
		out[ammo_type] = 0
	return out

func _empty_mag_state() -> Dictionary:
	var out = {}
	for id in GameDataScript.WEAPON_ORDER:
		if weapons.has(id):
			var weapon = weapons[id]
			out[id] = 0 if weapon.melee else 0
	return out

func _normalize_weapon_state() -> void:
	for ammo_type in GameDataScript.AMMO_MAX.keys():
		if not ammo_reserve.has(ammo_type):
			ammo_reserve[ammo_type] = 0
	for id in GameDataScript.WEAPON_ORDER:
		if not mag_ammo.has(id):
			mag_ammo[id] = 0
	if carried_weapons.is_empty():
		carried_weapons = ["whip", "pistol"]
	for id in carried_weapons.duplicate():
		if not unlocked.has(id) or not weapons.has(id):
			carried_weapons.erase(id)
	if carried_weapons.is_empty():
		unlocked.pistol = true
		carried_weapons.append("pistol")
	if not carried_weapons.has(current_weapon):
		current_weapon = String(carried_weapons[0])
	while carried_weapons.size() > max_carried_weapons:
		var removed = carried_weapons.pop_back()
		if removed == current_weapon:
			current_weapon = String(carried_weapons[0])

func set_no_gun_mode(enabled: bool) -> void:
	no_gun_mode = enabled
	if is_instance_valid(weapon_root):
		weapon_root.visible = _weapon_view_visible()

func set_level_weapons_disabled(disabled: bool) -> void:
	level_weapons_disabled = disabled
	_cancel_shotgun_pending_fire()
	if is_instance_valid(weapon_root):
		weapon_root.visible = _weapon_view_visible()

func _weapon_view_visible() -> bool:
	return not no_gun_mode and not level_weapons_disabled

func set_legacy_weapon_models(enabled: bool) -> void:
	if legacy_weapon_models == enabled:
		return
	legacy_weapon_models = enabled
	weapon_visual_cache.clear()
	if is_instance_valid(weapon_root):
		for child in weapon_root.get_children():
			if child != muzzle_marker:
				child.queue_free()
	view_weapon_id = ""
	_rebuild_weapon_view()

func set_developer_mode(enabled: bool) -> void:
	var was_enabled = developer_mode
	developer_mode = enabled
	if developer_mode and not was_enabled:
		unlock_all_weapons(true)
	changed.emit()

func tick(dt: float) -> void:
	shoot_timer = max(0.0, shoot_timer - dt)
	special_timer = max(0.0, special_timer - dt)
	revolver_fan_timer = max(0.0, revolver_fan_timer - dt)
	auto_stabilizer_timer = max(0.0, auto_stabilizer_timer - dt)
	rail_zoom_sound_timer = max(0.0, rail_zoom_sound_timer - dt)
	flak_overdrive_timer = max(0.0, flak_overdrive_timer - dt)
	quick_melee_timer = max(0.0, quick_melee_timer - dt)
	fire_flash_timer = max(0.0, fire_flash_timer - dt * 8.0)
	recoil_kick = max(0.0, recoil_kick - dt * 7.5)
	attack_anim_timer = max(0.0, attack_anim_timer - dt)
	whip_swing_timer = max(0.0, whip_swing_timer - dt)
	quick_melee_anim_timer = max(0.0, quick_melee_anim_timer - dt)
	grenade_cooldown = max(0.0, grenade_cooldown - dt)
	_update_weapon_view(dt)
	_tick_shotgun_pending_fire(dt)
	if reload_timer > 0.0:
		reload_timer -= dt
		if reload_timer <= 0.0:
			_finish_reload()
	_tick_revolver_fan_fire(dt)
	if player != null and not player.paused and not level_weapons_disabled:
		if (Input.is_key_pressed(KEY_F) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and current_weapon in ["auto", "plasma", "incinerator", "cryo", "toxic", "shock_flux", "flak", "grenade_launcher"]:
			attack()
		if current_weapon == "seeker" and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_attack_current()
		if current_weapon == "railgun" and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_hold_rail_zoom()
		if current_weapon == "shock_flux" and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_shock_flux_chain()

func attack() -> void:
	if level_weapons_disabled:
		return
	if current_weapon == "shotgun":
		_start_shotgun_pending_fire()
		return
	if current_weapon == "seeker":
		if special_timer > 0.0 or reload_timer > 0.0:
			return
		_seeker_marked_burst()
		return

	_attack_current()

func _start_shotgun_pending_fire() -> void:
	if shotgun_pending_fire:
		return
	if player == null or level_manager == null or not weapons.has("shotgun"):
		return
	if shoot_timer > 0.0 or reload_timer > 0.0:
		return
	if not developer_mode and mag_ammo.shotgun <= 0:
		_attack_current()
		return
	shotgun_pending_fire = true
	shotgun_pending_timer = shotgun_trigger_delay
	if is_instance_valid(muzzle_marker):
		sound_attached_requested.emit("shotgun", muzzle_marker, Vector3.ZERO)
	else:
		sound_at_requested.emit("shotgun", _weapon_muzzle_origin())

func _tick_shotgun_pending_fire(dt: float) -> void:
	if not shotgun_pending_fire:
		return
	var trigger_held = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_F)
	if player == null or player.paused or current_weapon != "shotgun" or not trigger_held:
		_cancel_shotgun_pending_fire()
		return
	shotgun_pending_timer -= dt
	if shotgun_pending_timer <= 0.0:
		shotgun_pending_fire = false
		shotgun_pending_timer = 0.0
		_attack_current()

func _cancel_shotgun_pending_fire() -> void:
	if not shotgun_pending_fire:
		return
	shotgun_pending_fire = false
	shotgun_pending_timer = 0.0
	sound_stop_requested.emit("shotgun")

func _attack_current() -> void:
	if player == null or level_manager == null:
		return
	var weapon = weapons[current_weapon]
	if shoot_timer > 0.0 or reload_timer > 0.0:
		return
	if weapon.melee:
		_melee_attack(weapon)
		return
	var free_shot = developer_mode or (current_weapon == "flak" and flak_overdrive_timer > 0.0)
	if developer_mode and not weapon.melee and mag_ammo[current_weapon] <= 0:
		mag_ammo[current_weapon] = weapon.mag_size
	if not weapon.melee and not free_shot and mag_ammo[current_weapon] <= 0:
		sound_requested.emit("empty")
		start_reload()
		return
	if not weapon.melee and not free_shot:
		mag_ammo[current_weapon] -= 1
	var cooldown_mult = 0.62 if current_weapon == "auto" and auto_stabilizer_timer > 0.0 else 1.0
	if current_weapon == "flak" and flak_overdrive_timer > 0.0:
		cooldown_mult = 0.47
	shoot_timer = weapon.cooldown * cooldown_mult
	fire_flash_timer = 1.0
	recoil_kick = (0.30 if auto_stabilizer_timer > 0.0 else 0.46) if current_weapon == "auto" else (1.16 if current_weapon == "flak" and flak_overdrive_timer > 0.0 else (0.64 if current_weapon == "seeker" else (1.22 if current_weapon == "pistol" else 1.0)))
	attack_anim_timer = max(attack_anim_timer, 0.10 if current_weapon in ["auto", "seeker"] else (0.26 if current_weapon in ["shotgun", "heavy", "railgun"] else 0.16))
	var fire = _fire_solution()
	_spawn_weapon_muzzle_flash(fire, weapon.color)
	if current_weapon == "shotgun":
		_spawn_shotgun_muzzle_bloom(fire, 0.78)
	player.add_shake(0.004 if current_weapon == "auto" else (0.018 if current_weapon == "flak" and flak_overdrive_timer > 0.0 else (0.010 if current_weapon == "seeker" else (0.018 if current_weapon == "pistol" else (0.010 if current_weapon not in ["shotgun", "heavy", "railgun"] else 0.026)))))
	fired.emit(current_weapon)
	var shot_damage = _weapon_damage(current_weapon, weapon)
	if current_weapon == "shock_flux":
		_shock_flux_attack(weapon, fire.origin)
	elif current_weapon == "flak":
		_flak_attack(weapon, fire.origin)
	elif current_weapon == "grenade_launcher":
		_grenade_launcher_fire(weapon, fire)
	elif weapon.projectile_speed > 0.0:
		var explosive_damage = shot_damage if weapon.explosive else 0
		var bounce_count = 3 if current_weapon == "plasma" else (10 if current_weapon == "saw" else 0)
		var projectile_dir = _apply_movement_spread(fire.dir, weapon, 0.55)
		var visual_scale = 1.72 if current_weapon == "heavy" else (1.12 if current_weapon == "grenade_launcher" else (0.72 if current_weapon == "saw" else 1.0))
		var effect = ""
		if current_weapon in ["saw", "cryo", "toxic"]:
			effect = current_weapon
		elif current_weapon == "grenade_launcher":
			effect = "grenade_round"
		level_manager.spawn_player_projectile(fire.origin, projectile_dir, weapon.projectile_speed, shot_damage, weapon.explosive, weapon.explosion_radius, explosive_damage, weapon.color, bounce_count, current_weapon == "plasma", visual_scale, current_weapon == "incinerator" or current_weapon == "toxic", current_weapon == "seeker", effect)
	elif current_weapon == "railgun":
		_rail_attack(weapon, fire.origin)
	else:
		_hitscan_attack(weapon, fire.origin)
	if developer_mode and not weapon.melee:
		mag_ammo[current_weapon] = weapon.mag_size
	elif not weapon.melee and mag_ammo[current_weapon] <= 0 and (current_weapon == "pistol" or ammo_reserve[weapon.ammo_type] > 0):
		start_reload()
	changed.emit()

func special_attack() -> void:
	if level_weapons_disabled or player == null or level_manager == null or player.paused:
		return
	if current_weapon == "seeker":
		_attack_current()
		return
	if special_timer > 0.0 or reload_timer > 0.0:
		return
	match current_weapon:
		"whip":
			_whip_special()
		"pistol":
			_revolver_fan_fire()
		"shotgun":
			_shotgun_alt_blast()
		"auto":
			_auto_overdrive()
		"plasma":
			_plasma_triad()
		"grenade_launcher":
			_grenade_launcher_cluster_round()
		"heavy":
			_heavy_cluster_rocket()
		"railgun":
			_rail_zoom()
		"incinerator":
			_incinerator_flame_wave()
		"saw":
			_saw_fan()
		"cryo":
			_cryo_burst()
		"toxic":
			_toxic_pool()
		"shock_flux":
			_shock_flux_chain()
		"flak":
			_flak_burst()
		"seeker":
			_seeker_marked_burst()
		_:
			attack()

func _spend_rounds(rounds: int) -> int:
	var weapon = weapons[current_weapon]
	if weapon.melee:
		return 0
	if developer_mode:
		mag_ammo[current_weapon] = max(mag_ammo[current_weapon], weapon.mag_size)
		return rounds
	if mag_ammo[current_weapon] <= 0:
		sound_requested.emit("empty")
		start_reload()
		return 0
	var spent = min(rounds, mag_ammo[current_weapon])
	mag_ammo[current_weapon] -= spent
	if mag_ammo[current_weapon] <= 0 and (current_weapon == "pistol" or ammo_reserve[weapon.ammo_type] > 0):
		start_reload()
	return spent

func _whip_special() -> void:
	var weapon = weapons.whip
	special_timer = 1.05
	shoot_timer = max(shoot_timer, 0.55)
	whip_swing_timer = 0.62
	recoil_kick = max(recoil_kick, 1.10)
	_spawn_whip_swing_visual()
	var hits = level_manager.find_enemies_in_cone(player.global_position, player.aim_dir(), weapon.melee_range + 1.9, 0.42) if level_manager.has_method("find_enemies_in_cone") else []
	for hit in hits:
		if is_instance_valid(hit) and not hit.dead:
			level_manager.damage_enemy(hit, int(ceil(weapon.damage * 1.55)), player.global_position)
			level_manager.spawn_impact_fx(hit.global_position + Vector3(0, hit.stats.height * 0.55, 0), weapon.color.lightened(0.25))
	player.add_shake(0.024)
	sound_requested.emit("whip")
	changed.emit()

func _revolver_fan_fire() -> void:
	if mag_ammo.pistol <= 0:
		sound_requested.emit("empty")
		start_reload()
		return
	revolver_fan_rounds = mag_ammo.pistol
	revolver_fan_timer = 0.01
	revolver_fan_interval = 0.082
	special_timer = 0.35 + revolver_fan_rounds * revolver_fan_interval
	shoot_timer = max(shoot_timer, special_timer)
	changed.emit()

func _tick_revolver_fan_fire(dt: float) -> void:
	if revolver_fan_rounds <= 0:
		return
	if player == null or player.paused or current_weapon != "pistol":
		revolver_fan_rounds = 0
		return
	revolver_fan_timer -= dt
	while revolver_fan_rounds > 0 and revolver_fan_timer <= 0.0:
		var spent = _spend_rounds(1)
		if spent <= 0:
			revolver_fan_rounds = 0
			return
		var weapon = weapons.pistol
		var fire = _fire_solution()
		_hitscan_attack(weapon, fire.origin)
		_spawn_weapon_muzzle_flash(fire, weapon.color.lightened(0.2))
		recoil_kick = max(recoil_kick, 1.22)
		attack_anim_timer = max(attack_anim_timer, 0.16)
		player.add_shake(0.018)
		sound_requested.emit("pistol")
		fired.emit(current_weapon)
		revolver_fan_rounds -= 1
		revolver_fan_timer += revolver_fan_interval
		changed.emit()

func _shotgun_alt_blast() -> void:
	var rounds = _spend_rounds(2)
	if rounds <= 0:
		return
	special_timer = 0.95
	shoot_timer = max(shoot_timer, 0.58)
	var weapon = weapons.shotgun
	var fire = _fire_solution()
	for i in rounds + 1:
		_hitscan_attack(weapon, fire.origin)
	_spawn_weapon_muzzle_flash(fire, weapon.color.lightened(0.22))
	_spawn_shotgun_muzzle_bloom(fire, 1.45)
	recoil_kick = max(recoil_kick, 1.45)
	player.add_shake(0.038)
	sound_requested.emit("shotgun")
	fired.emit(current_weapon)
	changed.emit()

func _spawn_shotgun_muzzle_bloom(fire: Dictionary, intensity: float) -> void:
	if level_manager == null:
		return
	var smoke_amount = max(1, int(round(9.0 * intensity)))
	if level_manager.has_method("spawn_shotgun_muzzle_smoke"):
		level_manager.spawn_shotgun_muzzle_smoke(fire.origin, fire.dir, smoke_amount, intensity)
	var grit_count = max(1, int(round(3.0 * intensity)))
	if level_manager.has_method("_vfx_count"):
		grit_count = level_manager._vfx_count(grit_count)
	for i in grit_count:
		var warm = Color8(116, 88, 58) if i % 2 == 0 else Color8(70, 66, 58)
		level_manager.spawn_impact_fx(
			fire.origin + fire.dir * randf_range(0.55, 1.25 + intensity * 0.24) + Vector3(randf_range(-0.12, 0.12), randf_range(-0.05, 0.13), randf_range(-0.12, 0.12)),
			warm
		)

func _auto_overdrive() -> void:
	auto_stabilizer_timer = 3.2
	special_timer = 1.0
	recoil_kick = max(recoil_kick, 0.34)
	player.add_shake(0.012)
	sound_requested.emit("pickup")
	changed.emit()

func _plasma_triad() -> void:
	var rounds = _spend_rounds(6)
	if rounds <= 0:
		return
	special_timer = 0.36
	shoot_timer = max(shoot_timer, 0.22)
	var weapon = weapons.plasma
	var fire = _fire_solution()
	for angle in [-0.12, 0.0, 0.12]:
		var dir = _apply_movement_spread(fire.dir.rotated(Vector3.UP, angle), weapon, 0.38)
		level_manager.spawn_player_projectile(fire.origin, dir, weapon.projectile_speed * 1.34, int(ceil(weapon.damage * 1.2)), false, 0.0, 0, weapon.color.lightened(0.16), 3, true, 1.05)
	_spawn_weapon_muzzle_flash(fire, weapon.color)
	recoil_kick = max(recoil_kick, 0.82)
	sound_requested.emit("plasma")
	fired.emit(current_weapon)
	changed.emit()

func _heavy_cluster_rocket() -> void:
	var weapon = weapons.heavy
	var rounds = weapon.mag_size if developer_mode else int(mag_ammo.heavy)
	rounds = max(1, rounds)
	rounds = _spend_rounds(rounds)
	if rounds <= 0:
		return
	special_timer = 1.65
	shoot_timer = max(shoot_timer, 1.22)
	var fire = _fire_solution()
	var radius = weapon.explosion_radius * clamp(1.15 + float(rounds) * 0.34, 1.65, 2.65)
	var dmg = int(ceil(float(weapon.damage) * (1.35 + float(rounds) * 0.55)))
	level_manager.spawn_player_projectile(fire.origin, _apply_movement_spread(fire.dir, weapon, 0.30), weapon.projectile_speed * 1.22, dmg, true, radius, dmg, weapon.color.lightened(0.16), 0, false, 2.55, true, false, "inferno")
	_spawn_weapon_muzzle_flash(fire, weapon.color)
	recoil_kick = max(recoil_kick, 1.50 + float(rounds) * 0.08)
	player.add_shake(0.052 + float(rounds) * 0.010)
	sound_requested.emit("heavy")
	fired.emit(current_weapon)
	changed.emit()

func _grenade_launcher_cluster_round() -> void:
	var rounds = _spend_rounds(2)
	if rounds <= 0:
		return
	special_timer = 0.92
	shoot_timer = max(shoot_timer, 0.54)
	var weapon = weapons.grenade_launcher
	var fire = _fire_solution(42.0)
	var throw_dir = (_apply_movement_spread(fire.dir, weapon, 0.42) + Vector3.UP * 0.11).normalized()
	level_manager.spawn_grenade(fire.origin, throw_dir * 17.5, "cluster", false, 0.88)
	_spawn_weapon_muzzle_flash(fire, weapon.color)
	recoil_kick = max(recoil_kick, 1.12)
	player.add_shake(0.030)
	sound_requested.emit("grenade_launcher")
	fired.emit(current_weapon)
	changed.emit()

func _grenade_launcher_fire(weapon, fire: Dictionary) -> void:
	var throw_dir = (_apply_movement_spread(fire.dir, weapon, 0.36) + Vector3.UP * 0.10).normalized()
	level_manager.spawn_grenade(fire.origin, throw_dir * 18.5, "frag", false, 0.95)

func _saw_fan() -> void:
	var rounds = _spend_rounds(3)
	if rounds <= 0:
		return
	special_timer = 0.72
	shoot_timer = max(shoot_timer, 0.42)
	var weapon = weapons.saw
	var fire = _fire_solution()
	for i in rounds:
		var angle = deg_to_rad(-7.0 + i * 7.0)
		var dir = _apply_movement_spread(fire.dir.rotated(Vector3.UP, angle), weapon, 0.28)
		level_manager.spawn_player_projectile(fire.origin, dir, weapon.projectile_speed * 1.08, weapon.damage, false, 0.0, 0, weapon.color.lightened(0.14), 12, false, 0.72, false, false, "saw")
	_spawn_weapon_muzzle_flash(fire, weapon.color)
	recoil_kick = max(recoil_kick, 0.92)
	sound_requested.emit("auto")
	fired.emit(current_weapon)
	changed.emit()

func _cryo_burst() -> void:
	var rounds = _spend_rounds(5)
	if rounds <= 0:
		return
	special_timer = 0.68
	shoot_timer = max(shoot_timer, 0.38)
	var weapon = weapons.cryo
	var fire = _fire_solution()
	for i in 5:
		var dir = _apply_movement_spread(fire.dir.rotated(Vector3.UP, deg_to_rad(-8 + i * 4)), weapon, 0.42)
		level_manager.spawn_player_projectile(fire.origin, dir, weapon.projectile_speed * 0.95, weapon.damage, false, 0.0, 0, weapon.color.lightened(0.12), 0, false, 0.88, false, false, "cryo")
	_spawn_weapon_muzzle_flash(fire, weapon.color)
	recoil_kick = max(recoil_kick, 0.72)
	sound_requested.emit("plasma")
	fired.emit(current_weapon)
	changed.emit()

func _bow_power_shot() -> void:
	var rounds = _spend_rounds(1)
	if rounds <= 0:
		return
	special_timer = 0.82
	shoot_timer = max(shoot_timer, 0.62)
	var weapon = weapons.bow
	var fire = _fire_solution(88.0)
	var dir = _apply_movement_spread(player.aim_dir(), weapon, 0.12)
	var origin = player.camera_origin()
	var end = origin + dir * 96.0
	var wall = level_manager.wall_hit_along_segment(origin, end, 0.08)
	var max_dist = origin.distance_to(wall.position) if wall.hit else 96.0
	var hits = level_manager.find_enemies_in_ray(origin, dir, max_dist)
	var pierce = 0
	for hit in hits:
		var e = hit.enemy
		if is_instance_valid(e) and not e.dead:
			var dmg = int(ceil(float(weapon.damage) * 1.8 * (_headshot_multiplier("bow", e) if hit.headshot else 1.0)))
			if hit.headshot:
				level_manager.damage_enemy_headshot(e, dmg, player.global_position)
			else:
				level_manager.damage_enemy(e, dmg, player.global_position)
			pierce += 1
			if pierce >= 2:
				break
	level_manager.spawn_tracer(fire.origin, wall.position if wall.hit else origin + dir * 36.0, weapon.color.lightened(0.18))
	recoil_kick = max(recoil_kick, 0.86)
	sound_requested.emit("pistol")
	fired.emit(current_weapon)
	changed.emit()

func _shock_flux_chain() -> void:
	if player == null or level_manager == null or player.paused:
		return
	if special_timer > 0.0 or reload_timer > 0.0:
		return
	special_timer = 0.075
	shoot_timer = max(shoot_timer, 0.050)
	var weapon = weapons.shock_flux
	var fire = _fire_solution(42.0)
	var origin = player.camera_origin()
	var dir = _apply_movement_spread(player.aim_dir(), weapon, 0.16)
	var end = origin + dir.normalized() * 42.0
	var wall = level_manager.wall_hit_along_segment(origin, end, 0.08)
	var max_dist = origin.distance_to(wall.position) if wall.hit else 42.0
	var hit_info = level_manager.enemy_hit_info_in_ray(origin, dir.normalized(), max_dist)
	var arc_end = wall.position if wall.hit else end
	if hit_info.has("enemy"):
		arc_end = hit_info.position
		_shock_flux_hit_chain(fire.origin, hit_info.position, hit_info.enemy, weapon, true)
	_spawn_weapon_muzzle_flash(fire, weapon.color.lightened(0.22))
	_spawn_lightning_layers(fire.origin, arc_end, weapon.color.lightened(0.24), 4, 4)
	recoil_kick = max(recoil_kick, 0.56)
	player.add_shake(0.020)
	sound_requested.emit("shock_flux")
	fired.emit(current_weapon)
	changed.emit()

func _flak_burst() -> void:
	if current_weapon != "flak":
		return
	flak_overdrive_timer = 3.0
	special_timer = 3.0
	shoot_timer = min(shoot_timer, 0.04)
	recoil_kick = max(recoil_kick, 1.05)
	player.add_shake(0.030)
	sound_requested.emit("flak")
	changed.emit()

func _toxic_pool() -> void:
	var rounds = _spend_rounds(18)
	if rounds <= 0:
		return
	special_timer = 0.72
	shoot_timer = max(shoot_timer, 0.34)
	var weapon = weapons.toxic
	var fire = _fire_solution(30.0)
	level_manager.spawn_player_projectile(fire.origin, _apply_movement_spread(fire.dir, weapon, 0.56), weapon.projectile_speed * 0.86, weapon.damage, false, 0.0, 0, weapon.color.lightened(0.18), 1, false, 1.12, true, false, "toxic_pool")
	_spawn_weapon_muzzle_flash(fire, weapon.color)
	recoil_kick = max(recoil_kick, 0.82)
	sound_requested.emit("incinerator")
	fired.emit(current_weapon)
	changed.emit()

func _rail_zoom() -> void:
	special_timer = 0.08
	_hold_rail_zoom()

func _hold_rail_zoom() -> void:
	if player.has_method("start_zoom"):
		player.start_zoom(0.22, 42.0)

func _incinerator_flame_wave() -> void:
	var rounds = _spend_rounds(14)
	if rounds <= 0:
		return
	special_timer = 0.75
	shoot_timer = max(shoot_timer, 0.34)
	var weapon = weapons.incinerator
	var fire = _fire_solution(24.0)
	for i in 5:
		var dir = _apply_movement_spread(fire.dir.rotated(Vector3.UP, deg_to_rad(-10 + i * 5)), weapon, 0.75)
		level_manager.spawn_player_projectile(fire.origin, dir, weapon.projectile_speed * 0.86, weapon.damage, false, 0.0, 0, weapon.color, 0, false, 0.92, true)
	_spawn_weapon_muzzle_flash(fire, weapon.color)
	recoil_kick = max(recoil_kick, 0.96)
	sound_requested.emit("incinerator")
	fired.emit(current_weapon)
	changed.emit()

func _seeker_marked_burst() -> void:
	var rounds = _spend_rounds(6)
	if rounds <= 0:
		return
	special_timer = 0.54
	shoot_timer = max(shoot_timer, 0.26)
	var weapon = weapons.seeker
	var burst_damage = weapon.damage + (5 if developer_mode else 1)
	var fire = _fire_solution()
	for i in rounds:
		var dir = _apply_movement_spread(fire.dir.rotated(Vector3.UP, deg_to_rad(randf_range(-3.5, 3.5))), weapon, 0.20)
		level_manager.spawn_player_projectile(fire.origin, dir, weapon.projectile_speed * 1.42, burst_damage, false, 0.0, 0, weapon.color.lightened(0.2), 0, false, 0.92, false, true)
	_spawn_weapon_muzzle_flash(fire, weapon.color)
	recoil_kick = max(recoil_kick, 0.88)
	sound_requested.emit("auto")
	fired.emit(current_weapon)
	changed.emit()

func quick_melee() -> void:
	if level_weapons_disabled or player == null or level_manager == null or player.paused or quick_melee_timer > 0.0:
		return
	quick_melee_timer = 0.34
	fire_flash_timer = max(fire_flash_timer, 0.55)
	recoil_kick = max(recoil_kick, 0.45)
	quick_melee_anim_timer = 0.34
	_spawn_quick_melee_visual()
	var mult = player.powerups.melee_multiplier("quick_melee")
	var melee_range = 2.35
	var hit = level_manager.find_enemy_in_cone(player.global_position, player.aim_dir(), melee_range, 0.68)
	if hit != null:
		level_manager.damage_enemy(hit, max(1, int(2 * mult)), player.global_position)
		level_manager.spawn_impact_fx(hit.global_position + Vector3(0, hit.stats.height * 0.52, 0), Color8(255, 196, 112))
		if player.powerups.is_active("berserk"):
			player.heal(2, 125)
	player.add_shake(0.012)
	sound_requested.emit("melee")

func _melee_attack(weapon) -> void:
	shoot_timer = weapon.cooldown
	fire_flash_timer = 1.0
	recoil_kick = 1.0
	attack_anim_timer = max(attack_anim_timer, 0.18)
	if current_weapon == "whip":
		whip_swing_timer = 0.46
		attack_anim_timer = max(attack_anim_timer, 0.28)
		_spawn_whip_swing_visual()
		sound_requested.emit("whip")
	fired.emit(current_weapon)
	var mult = player.powerups.melee_multiplier(current_weapon)
	var hits = level_manager.find_enemies_in_cone(player.global_position, player.aim_dir(), weapon.melee_range, 0.18) if level_manager.has_method("find_enemies_in_cone") else []
	if hits.is_empty():
		var single_hit = level_manager.find_enemy_in_cone(player.global_position, player.aim_dir(), weapon.melee_range, 0.74)
		if single_hit != null:
			hits.append(single_hit)
	for hit in hits:
		if hit == null or not is_instance_valid(hit) or hit.dead:
			continue
		level_manager.damage_enemy(hit, max(1, int(weapon.damage * mult)), player.global_position)
		level_manager.spawn_impact_fx(hit.global_position + Vector3(0, hit.stats.height * 0.54, 0), weapon.color.lightened(0.22))
	if not hits.is_empty() and player.powerups.is_active("berserk"):
		player.heal(2, 125)
	changed.emit()

func _shock_flux_attack(weapon, muzzle_origin: Vector3) -> void:
	var origin = player.camera_origin()
	var dir = _apply_movement_spread(player.aim_dir(), weapon, 0.20)
	var end = origin + dir.normalized() * 22.0
	var wall = level_manager.wall_hit_along_segment(origin, end, 0.08)
	var max_dist = origin.distance_to(wall.position) if wall.hit else 22.0
	var hit_info = level_manager.enemy_hit_info_in_ray(origin, dir.normalized(), max_dist)
	var arc_end = wall.position if wall.hit else end
	if hit_info.has("enemy"):
		var hit = hit_info.enemy
		arc_end = hit_info.position
		_shock_flux_hit_chain(muzzle_origin, hit_info.position, hit, weapon, false)
	_spawn_lightning_layers(muzzle_origin, arc_end, weapon.color.lightened(0.18), 2, 2)

func _shock_flux_hit_chain(start_pos: Vector3, first_hit_pos: Vector3, first_enemy, weapon, boosted: bool = false) -> void:
	if first_enemy == null or not is_instance_valid(first_enemy) or first_enemy.dead:
		return
	var chain_limit = 5 if boosted else 3
	var damage_scale = 4.5 if boosted else 1.0
	var radius = 11.0 if boosted else 7.5
	var current_enemy = first_enemy
	var current_pos = first_hit_pos
	var excluded = []
	for i in chain_limit:
		if current_enemy == null or not is_instance_valid(current_enemy) or current_enemy.dead:
			break
		var falloff = pow(0.65, float(i))
		var dmg = max(1, int(ceil(float(weapon.damage) * damage_scale * falloff)))
		level_manager.damage_enemy(current_enemy, dmg, player.global_position)
		var stun_time = (0.18 if boosted else 0.11) * max(0.35, falloff)
		if randf() < (0.34 if boosted else 0.18):
			level_manager.apply_enemy_status(current_enemy, "stun", 0.0, stun_time)
		var hit_center = current_enemy.global_position + Vector3(0, current_enemy.stats.height * 0.52, 0)
		var from_pos = start_pos if i == 0 else current_pos
		_spawn_lightning_layers(from_pos, hit_center, weapon.color.lightened(0.18 + min(0.20, falloff * 0.16)), 3 if boosted else 2, 2 if boosted else 1)
		excluded.append(current_enemy)
		current_pos = hit_center
		current_enemy = _nearest_shock_chain_enemy(hit_center, excluded, radius)

func _nearest_shock_chain_enemy(from_pos: Vector3, excluded: Array, radius: float):
	var best = null
	var best_dist = radius
	if level_manager == null:
		return null
	for enemy in level_manager.enemies:
		if not is_instance_valid(enemy) or enemy.dead or excluded.has(enemy):
			continue
		var dist = from_pos.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best

func _spawn_lightning_layers(from_pos: Vector3, to_pos: Vector3, color: Color, layers: int, branches: int) -> void:
	if level_manager == null:
		return
	if level_manager.has_method("spawn_lightning_arc"):
		for i in layers:
			var tint = color.lightened(0.08 * float(i))
			level_manager.spawn_lightning_arc(from_pos, to_pos, tint, branches)
	else:
		level_manager.spawn_tracer(from_pos, to_pos, color)

func _flak_attack(weapon, muzzle_origin: Vector3, burst_scale: float = 1.0) -> void:
	var origin = player.camera_origin()
	var dir = _apply_movement_spread(player.aim_dir(), weapon, 0.34)
	var end = origin + dir.normalized() * 26.0
	var wall = level_manager.wall_hit_along_segment(origin, end, 0.08)
	var burst_pos = wall.position if wall.hit else origin + dir.normalized() * 18.0
	var nearest = level_manager.enemy_hit_info_in_ray(origin, dir.normalized(), wall.position.distance_to(origin) if wall.hit else 26.0)
	if nearest.has("enemy"):
		burst_pos = nearest.position
	level_manager.spawn_impact_fx(burst_pos, weapon.color.lightened(0.15))
	level_manager.explode(burst_pos, 1.55 * burst_scale, max(2, int(ceil(float(weapon.damage) * 0.72 * burst_scale))), 0.07, 0.52)
	for i in 8:
		var yaw = deg_to_rad(randf_range(-13.0, 13.0))
		var pitch = deg_to_rad(randf_range(-5.0, 5.0))
		var pellet_dir = dir.rotated(Vector3.UP, yaw).rotated(player.global_transform.basis.x.normalized(), pitch).normalized()
		var p_end = burst_pos + pellet_dir * randf_range(5.0, 8.5)
		level_manager.spawn_tracer(muzzle_origin if i < 4 else burst_pos, p_end, weapon.color.lightened(randf_range(0.0, 0.24)))
		var hit = level_manager.find_enemy_along_segment(burst_pos, p_end, 0.30)
		if hit != null and is_instance_valid(hit) and not hit.dead:
			level_manager.damage_enemy(hit, max(1, int(ceil(float(weapon.damage) * 0.42 * burst_scale))), burst_pos)

func _hitscan_attack(weapon, muzzle_origin: Vector3) -> void:
	for i in weapon.shots:
		var dir = player.aim_dir()
		var spread = weapon.spread_degrees + _movement_spread_bonus(current_weapon)
		dir = dir.rotated(Vector3.UP, deg_to_rad(randf_range(-spread, spread)))
		dir = dir.rotated(player.global_transform.basis.x.normalized(), deg_to_rad(randf_range(-spread * 0.35, spread * 0.35)))
		var origin = player.camera_origin()
		var weapon_range = 999.0 if current_weapon in ["auto", "marksman"] else 44.0
		var end = origin + dir.normalized() * weapon_range
		var wall = level_manager.wall_hit_along_segment(origin, end, 0.08)
		var max_dist = origin.distance_to(wall.position) if wall.hit else weapon_range
		var hit_info = level_manager.enemy_hit_info_in_ray(origin, dir.normalized(), max_dist)
		if hit_info.has("enemy"):
			var hit = hit_info.enemy
			var head_mult = _headshot_multiplier(current_weapon, hit)
			var final_damage = weapon.damage * _distance_damage_multiplier(current_weapon, hit_info.distance) * (head_mult if hit_info.headshot else 1.0)
			var hit_pos = hit_info.position
			if hit_info.headshot:
				level_manager.damage_enemy_headshot(hit, int(ceil(final_damage)), player.global_position)
			else:
				level_manager.damage_enemy(hit, int(ceil(final_damage)), player.global_position)
			level_manager.spawn_tracer(muzzle_origin, hit_pos, weapon.color)
		elif wall.hit:
			if not _is_high_rate_hitscan_weapon(current_weapon):
				level_manager.spawn_impact_fx(wall.position, weapon.color.darkened(0.2))
			level_manager.spawn_tracer(muzzle_origin, wall.position, weapon.color)
		else:
			var miss_pos = origin + dir.normalized() * min(weapon_range, 44.0)
			if not _is_high_rate_hitscan_weapon(current_weapon):
				level_manager.spawn_impact_fx(miss_pos, weapon.color.darkened(0.2))
			level_manager.spawn_tracer(muzzle_origin, miss_pos, weapon.color)

func _is_high_rate_hitscan_weapon(id: String) -> bool:
	return id in ["auto", "shock_flux"]

func _rail_attack(weapon, muzzle_origin: Vector3) -> void:
	var dir = _apply_movement_spread(player.aim_dir(), weapon, 0.35)
	var origin = player.camera_origin()
	var end = origin + dir.normalized() * 999.0
	var wall = level_manager.wall_hit_along_segment(origin, end, 0.08)
	var max_dist = origin.distance_to(wall.position) if wall.hit else 999.0
	var hits = level_manager.find_enemies_in_ray(origin, dir.normalized(), max_dist)
	var trail_end = wall.position if wall.hit else end
	for hit in hits:
		var e = hit.enemy
		if is_instance_valid(e) and not e.dead:
			var final_damage = weapon.damage * (_headshot_multiplier(current_weapon, e) if hit.headshot else 1.0)
			if hit.headshot:
				level_manager.damage_enemy_headshot(e, int(ceil(final_damage)), player.global_position)
			else:
				level_manager.damage_enemy(e, int(ceil(final_damage)), player.global_position)
				level_manager.spawn_impact_fx(hit.position, weapon.color.lightened(0.2))
	level_manager.spawn_rail_trail(muzzle_origin, trail_end, weapon.color)
	if wall.hit:
		level_manager.spawn_impact_fx(wall.position, weapon.color.darkened(0.1))

func _bow_attack(weapon, muzzle_origin: Vector3) -> void:
	var dir = _apply_movement_spread(player.aim_dir(), weapon, 0.22)
	var origin = player.camera_origin()
	var end = origin + dir.normalized() * 72.0
	var wall = level_manager.wall_hit_along_segment(origin, end, 0.08)
	var max_dist = origin.distance_to(wall.position) if wall.hit else 72.0
	var hit_info = level_manager.enemy_hit_info_in_ray(origin, dir.normalized(), max_dist)
	if hit_info.has("enemy"):
		var hit = hit_info.enemy
		var final_damage = weapon.damage * (_headshot_multiplier(current_weapon, hit) if hit_info.headshot else 1.0)
		if hit_info.headshot:
			level_manager.damage_enemy_headshot(hit, int(ceil(final_damage)), player.global_position)
		else:
			level_manager.damage_enemy(hit, int(ceil(final_damage)), player.global_position)
			level_manager.spawn_impact_fx(hit_info.position, weapon.color)
		level_manager.spawn_tracer(muzzle_origin, hit_info.position, weapon.color)
	elif wall.hit:
		level_manager.spawn_impact_fx(wall.position, weapon.color)
		level_manager.spawn_tracer(muzzle_origin, wall.position, weapon.color)
	else:
		level_manager.spawn_tracer(muzzle_origin, origin + dir.normalized() * 30.0, weapon.color)

func throw_grenade() -> void:
	if level_weapons_disabled:
		return
	if grenade_cooldown > 0.0:
		return
	if ammo_reserve.grenades <= 0:
		message.emit("NO GRENADES")
		return
	if not developer_mode:
		ammo_reserve.grenades -= 1
	grenade_cooldown = 0.46
	var throw_origin = _weapon_muzzle_origin()
	var target = _crosshair_target(34.0)
	var throw_dir = (target - throw_origin).normalized()
	if throw_dir.length() <= 0.01:
		throw_dir = player.aim_dir()
	level_manager.spawn_grenade(throw_origin, (throw_dir + Vector3.UP * 0.18).normalized() * 14.0, current_bomb_type)
	changed.emit()

func cycle_bomb_type(direction: int = 1) -> void:
	var idx = bomb_types.find(current_bomb_type)
	if idx < 0:
		idx = 0
	idx = posmod(idx + direction, bomb_types.size())
	current_bomb_type = String(bomb_types[idx])
	message.emit("%s BOMB" % current_bomb_type.to_upper())
	changed.emit()

func set_bomb_type(kind: String) -> void:
	if not bomb_types.has(kind):
		return
	current_bomb_type = kind
	changed.emit()

func start_reload() -> void:
	var weapon = weapons[current_weapon]
	if weapon.melee:
		return
	if developer_mode:
		mag_ammo[current_weapon] = weapon.mag_size
		reload_timer = 0.0
		changed.emit()
		return
	var ammo_type = weapon.ammo_type
	if reload_timer > 0.0 or mag_ammo[current_weapon] >= weapon.mag_size:
		return
	if current_weapon != "pistol" and ammo_reserve[ammo_type] <= 0:
		message.emit("NO AMMO")
		return
	reload_timer = weapon.reload_time
	changed.emit()

func _finish_reload() -> void:
	var weapon = weapons[current_weapon]
	if current_weapon == "pistol":
		mag_ammo[current_weapon] = weapon.mag_size
		reload_timer = 0.0
		changed.emit()
		return
	var ammo_type = weapon.ammo_type
	var needed = weapon.mag_size - mag_ammo[current_weapon]
	var loaded = min(needed, ammo_reserve[ammo_type])
	mag_ammo[current_weapon] += loaded
	ammo_reserve[ammo_type] -= loaded
	reload_timer = 0.0
	changed.emit()

func select_slot(index: int) -> void:
	if index < 0 or index >= carried_weapons.size():
		return
	equip(String(carried_weapons[index]))

func cycle_weapon(direction: int) -> void:
	if direction == 0:
		return
	var order = carried_weapons
	if order.is_empty():
		return
	var current_index = order.find(current_weapon)
	if current_index < 0:
		current_index = 0
	for step in range(1, order.size() + 1):
		var idx = posmod(current_index + step * direction, order.size())
		var id = order[idx]
		if unlocked.has(id):
			equip(id)
			return

func equip(id: String) -> void:
	if unlocked.has(id) and carried_weapons.has(id):
		current_weapon = id
		_rebuild_weapon_view()
		changed.emit()

func pickup_weapon(id: String) -> String:
	var weapon = weapons[id]
	var first_time = not unlocked.has(id)
	unlocked[id] = true
	var added_to_loadout = false
	if not carried_weapons.has(id):
		if carried_weapons.size() >= max_carried_weapons:
			_open_replacement_prompt(id)
			return "CHOOSE LOADOUT SLOT"
		carried_weapons.append(id)
		added_to_loadout = true
	var added = 0
	if weapon.ammo_type != "":
		added = add_ammo(weapon.ammo_type, weapon.pickup_ammo)
		if mag_ammo[id] == 0:
			var load_now = min(weapon.mag_size, ammo_reserve[weapon.ammo_type])
			mag_ammo[id] = load_now
			ammo_reserve[weapon.ammo_type] -= load_now
	if first_time or added_to_loadout:
		current_weapon = id
		_rebuild_weapon_view()
		changed.emit()
		return "%s PICKED UP" % weapon.display_name
	changed.emit()
	if weapon.ammo_type != "":
		return "%s AMMO +%d" % [weapon.display_name, added]
	return "%s ALREADY UNLOCKED" % weapon.display_name

func can_take_weapon_pickup(id: String) -> Dictionary:
	var weapon = weapons[id]
	if not unlocked.has(id) or not carried_weapons.has(id):
		if carried_weapons.size() >= max_carried_weapons:
			_open_replacement_prompt(id)
			return {"take": false, "message": "CHOOSE LOADOUT SLOT"}
		return {"take": true, "message": ""}
	if weapon.melee:
		return {"take": false, "message": "%s ALREADY UNLOCKED" % weapon.display_name}
	if mag_ammo[id] >= weapon.mag_size:
		return {"take": false, "message": "%s MAG FULL" % weapon.display_name}
	if weapon.ammo_type != "" and ammo_reserve[weapon.ammo_type] >= GameDataScript.AMMO_MAX[weapon.ammo_type]:
		return {"take": false, "message": "%s AMMO FULL" % weapon.display_name}
	return {"take": true, "message": ""}

func add_ammo(ammo_type: String, amount: int) -> int:
	var before = ammo_reserve[ammo_type]
	ammo_reserve[ammo_type] = min(GameDataScript.AMMO_MAX[ammo_type], before + amount)
	changed.emit()
	return ammo_reserve[ammo_type] - before

func add_general_ammo() -> int:
	var total = 0
	var amounts = {"bullets": 86, "shells": 18, "cells": 84, "rockets": 4, "grenades": 6, "blades": 8, "chem": 64}
	for ammo_type in amounts.keys():
		total += add_ammo(ammo_type, amounts[ammo_type])
	return total

func snapshot_state() -> Dictionary:
	_normalize_weapon_state()
	return {
		"current_weapon": current_weapon,
		"unlocked": unlocked.duplicate(true),
		"carried_weapons": carried_weapons.duplicate(true),
		"ammo_reserve": ammo_reserve.duplicate(true),
		"mag_ammo": mag_ammo.duplicate(true),
		"current_bomb_type": current_bomb_type
	}

func restore_state(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	current_weapon = String(snapshot.get("current_weapon", current_weapon))
	unlocked = snapshot.get("unlocked", unlocked).duplicate(true)
	carried_weapons = snapshot.get("carried_weapons", carried_weapons).duplicate(true)
	ammo_reserve = snapshot.get("ammo_reserve", ammo_reserve).duplicate(true)
	mag_ammo = snapshot.get("mag_ammo", mag_ammo).duplicate(true)
	current_bomb_type = String(snapshot.get("current_bomb_type", current_bomb_type))
	_normalize_weapon_state()
	reload_timer = 0.0
	shoot_timer = 0.0
	_rebuild_weapon_view()
	changed.emit()

func unlock_all_weapons(fill_ammo := true) -> void:
	var previous = current_weapon
	for id in GameDataScript.WEAPON_ORDER:
		unlocked[id] = true
	carried_weapons.clear()
	for id in GameDataScript.WEAPON_ORDER:
		if carried_weapons.size() >= max_carried_weapons:
			break
		carried_weapons.append(id)
	if unlocked.has(previous):
		if not carried_weapons.has(previous):
			if carried_weapons.size() >= max_carried_weapons:
				carried_weapons[carried_weapons.size() - 1] = previous
			else:
				carried_weapons.append(previous)
		current_weapon = previous
	if fill_ammo:
		ammo_reserve = {"bullets": 300, "shells": 68, "cells": 280, "rockets": 26, "grenades": 12, "blades": 32, "chem": 190}
		if developer_mode:
			ammo_reserve = {}
			for ammo_type in GameDataScript.AMMO_MAX.keys():
				ammo_reserve[ammo_type] = GameDataScript.AMMO_MAX[ammo_type]
		for id in GameDataScript.WEAPON_ORDER:
			var weapon = weapons[id]
			mag_ammo[id] = weapon.mag_size if not weapon.melee else 0
	_normalize_weapon_state()
	reload_timer = 0.0
	shoot_timer = 0.0
	_rebuild_weapon_view()
	changed.emit()

func _open_replacement_prompt(id: String) -> void:
	pending_weapon_pickup = id
	locker_open = false
	if player != null:
		player.paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	changed.emit()

func replace_carried_weapon(old_id: String, new_id: String = "") -> void:
	if new_id == "":
		new_id = pending_weapon_pickup
	if new_id == "" or not weapons.has(new_id):
		return
	var idx = carried_weapons.find(old_id)
	if idx < 0:
		return
	unlocked[new_id] = true
	carried_weapons[idx] = new_id
	var weapon = weapons[new_id]
	if weapon.ammo_type != "" and mag_ammo[new_id] == 0:
		var load_now = min(weapon.mag_size, ammo_reserve.get(weapon.ammo_type, 0))
		mag_ammo[new_id] = load_now
		ammo_reserve[weapon.ammo_type] = max(0, ammo_reserve.get(weapon.ammo_type, 0) - load_now)
	current_weapon = new_id
	pending_weapon_pickup = ""
	locker_open = false
	if level_manager != null and level_manager.has_method("consume_pending_weapon_pickup"):
		level_manager.consume_pending_weapon_pickup(new_id)
	if player != null:
		player.paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_rebuild_weapon_view()
	changed.emit()

func open_weapon_locker() -> void:
	locker_open = true
	pending_weapon_pickup = ""
	if player != null:
		player.paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	changed.emit()

func close_loadout_overlay() -> void:
	pending_weapon_pickup = ""
	locker_open = false
	if player != null:
		player.paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	changed.emit()

func toggle_locker_weapon(id: String) -> void:
	if not unlocked.has(id) or not weapons.has(id):
		return
	if carried_weapons.has(id):
		if carried_weapons.size() <= 1:
			return
		carried_weapons.erase(id)
		if current_weapon == id:
			current_weapon = String(carried_weapons[0])
			_rebuild_weapon_view()
	else:
		if carried_weapons.size() < max_carried_weapons:
			carried_weapons.append(id)
			current_weapon = id
			_rebuild_weapon_view()
		else:
			message.emit("REMOVE A WEAPON FIRST")
	changed.emit()

func set_carried_loadout(list: Array) -> void:
	var next = []
	for id in list:
		var wid = String(id)
		if unlocked.has(wid) and weapons.has(wid) and not next.has(wid):
			next.append(wid)
		if next.size() >= max_carried_weapons:
			break
	if not next.is_empty():
		carried_weapons = next
		if not carried_weapons.has(current_weapon):
			current_weapon = String(carried_weapons[0])
		_rebuild_weapon_view()
	changed.emit()

func state() -> Dictionary:
	var weapon = weapons[current_weapon]
	var ammo_text = "INF"
	if not weapon.melee:
		ammo_text = "INF" if developer_mode else ("RELOADING" if reload_timer > 0.0 else ("%d/INF" % mag_ammo[current_weapon] if current_weapon == "pistol" else "%d/%d" % [mag_ammo[current_weapon], ammo_reserve[weapon.ammo_type]]))
	return {
		"weapon": weapon,
		"weapon_id": current_weapon,
		"ammo_text": ammo_text,
		"grenades": ammo_reserve.grenades,
		"unlocked": unlocked,
		"carried_weapons": carried_weapons,
		"pending_weapon_pickup": pending_weapon_pickup,
			"locker_open": locker_open,
			"bomb_type": current_bomb_type,
			"bomb_label": current_bomb_type.to_upper(),
			"bomb_types": bomb_types,
			"reload_timer": reload_timer
		}

func _spawn_weapon_muzzle_flash(fire: Dictionary, color: Color, weapon_id: String = "") -> void:
	var id = current_weapon if weapon_id == "" else weapon_id
	if is_instance_valid(weapon_root) and is_instance_valid(muzzle_marker):
		level_manager.spawn_muzzle_flash(fire.origin, fire.dir, color, id, weapon_root, muzzle_marker.position)
	else:
		level_manager.spawn_muzzle_flash(fire.origin, fire.dir, color, id)

func _fire_solution(max_dist: float = 48.0) -> Dictionary:
	var origin = _weapon_muzzle_origin()
	var target = _crosshair_target(max_dist)
	var dir = target - origin
	if dir.length() <= 0.01:
		dir = player.aim_dir()
	return {"origin": origin, "target": target, "dir": dir.normalized()}

func _crosshair_target(max_dist: float = 48.0) -> Vector3:
	var origin = player.camera_origin()
	var dir = player.aim_dir()
	var end = origin + dir * max_dist
	var wall = level_manager.wall_hit_along_segment(origin, end, 0.08)
	var limit = origin.distance_to(wall.position) if wall.hit else max_dist
	var hit = level_manager.find_enemy_in_ray(origin, dir, limit)
	if hit != null:
		return hit.global_position + Vector3(0, hit.stats.height * 0.55, 0)
	return wall.position if wall.hit else end

func _movement_spread_bonus(id: String) -> float:
	if player == null:
		return 0.0
	var momentum = max(clamp(float(player.horizontal_speed) / 14.0, 0.0, 1.0), clamp(float(player.momentum_intensity), 0.0, 1.0))
	var slide = max(clamp(float(player.slide_intensity), 0.0, 1.0), clamp(float(player.slide_visual_intensity), 0.0, 1.0))
	var air_slide = slide if bool(player.slide_airborne) else 0.0
	var ground_slide = slide if not bool(player.slide_airborne) else 0.0
	var grapple = clamp(float(player.grapple_momentum_intensity), 0.0, 1.0)
	var landing = clamp(float(player.landing_kick) * 3.0, 0.0, 1.0)
	var air = 0.34 if not player.grounded else 0.0
	var surface = clamp(float(player.surface_slide_factor), 0.0, 1.0)
	var base = momentum * 0.58 + ground_slide * 1.08 + air_slide * 0.76 + grapple * 0.42 + landing * 0.34 + air * 0.22 + surface * momentum * 0.24
	base = min(base, 3.2)
	if id == "railgun" and float(player.zoom_timer) > 0.0:
		return base * 0.08
	match id:
		"shotgun":
			return base * 0.95
		"auto", "seeker", "incinerator", "flak", "grenade_launcher":
			if id == "auto" and auto_stabilizer_timer > 0.0:
				return base * 0.20
			return base * 0.58
		"saw", "toxic":
			return base * 0.62
		"cryo", "shock_flux":
			return base * 0.42
		"marksman":
			return base * 0.18
		"pistol", "heavy":
			return base * 0.45
		"railgun", "plasma":
			return base * 0.24
		_:
			return base * 0.34

func _distance_damage_multiplier(id: String, distance: float) -> float:
	if id != "shotgun":
		return 1.0
	var close = 1.0 - clamp((distance - 2.0) / 13.0, 0.0, 1.0)
	return lerp(0.58, 6.25, close * close)

func _headshot_multiplier(id: String, enemy) -> float:
	var mult = 2.15
	match id:
		"pistol":
			mult = 3.15
		"railgun":
			mult = 3.60
		"marksman":
			mult = 4.15
		"shotgun":
			mult = 1.55
		"auto", "seeker":
			mult = 2.05
		"saw":
			mult = 1.65
		"plasma", "incinerator", "cryo", "toxic":
			mult = 1.72
	if enemy != null and enemy.stats != null:
		if enemy.stats.boss:
			mult *= 0.58
		elif level_manager != null and level_manager.has_method("is_miniboss_enemy") and level_manager.is_miniboss_enemy(enemy):
			mult *= 0.74
	return mult

func _weapon_damage(id: String, weapon) -> int:
	if id == "seeker":
		return int(weapon.damage) + (3 if developer_mode else 0)
	return int(weapon.damage)

func _apply_movement_spread(dir: Vector3, _weapon, spread_scale: float = 1.0) -> Vector3:
	var spread = _movement_spread_bonus(current_weapon) * spread_scale
	if spread <= 0.01:
		return dir.normalized()
	var out = dir.normalized()
	out = out.rotated(Vector3.UP, deg_to_rad(randf_range(-spread, spread)))
	out = out.rotated(player.global_transform.basis.x.normalized(), deg_to_rad(randf_range(-spread * 0.38, spread * 0.38)))
	return out.normalized()

func _weapon_muzzle_origin() -> Vector3:
	if is_instance_valid(muzzle_marker):
		var marker_pos = muzzle_marker.global_position
		if level_manager != null and level_manager.is_blocked_world(marker_pos, 0.08):
			return player.camera_origin() + player.aim_dir() * 0.42
		return marker_pos
	if player == null or player.camera == null:
		return Vector3.ZERO
	var basis = player.camera.global_transform.basis
	var pos = player.camera_origin() + basis.x.normalized() * 0.24 - basis.y.normalized() * 0.24 + player.aim_dir() * 0.78
	if level_manager != null and level_manager.is_blocked_world(pos, 0.08):
		return player.camera_origin() + player.aim_dir() * 0.42
	return pos

func _ensure_weapon_view() -> void:
	if player == null or player.camera == null:
		return
	if is_instance_valid(weapon_root):
		return
	weapon_root = Node3D.new()
	weapon_root.name = "KillgoreWeaponView3D"
	player.camera.add_child(weapon_root)

func _update_weapon_view(dt: float) -> void:
	if not is_instance_valid(weapon_root):
		_ensure_weapon_view()
		return
	if view_weapon_id != current_weapon:
		_rebuild_weapon_view()
	if player == null:
		return
	weapon_root.visible = _weapon_view_visible()
	var t = Time.get_ticks_msec() * 0.001
	var response = _weapon_motion_response(current_weapon)
	var look_delta = Vector2(wrapf(player.yaw - last_player_yaw, -PI, PI), player.pitch - last_player_pitch)
	last_player_yaw = player.yaw
	last_player_pitch = player.pitch
	weapon_lag = weapon_lag.lerp(Vector2(clamp(-look_delta.x * 2.2, -0.08, 0.08), clamp(look_delta.y * 2.0, -0.08, 0.08)), clamp(dt * 10.0, 0.0, 1.0))
	var slide = max(clamp(float(player.slide_intensity), 0.0, 1.0), clamp(float(player.slide_visual_intensity), 0.0, 1.0))
	var air_slide = slide if bool(player.slide_airborne) else 0.0
	var ground_slide = slide if not bool(player.slide_airborne) else 0.0
	var crouch = clamp(float(player.slide_crouch), 0.0, 1.35)
	var momentum = max(clamp(float(player.horizontal_speed) / 13.5, 0.0, 1.0), clamp(float(player.momentum_intensity), 0.0, 1.0))
	var grapple = clamp(float(player.grapple_momentum_intensity), 0.0, 1.0)
	var surface = clamp(float(player.surface_slide_factor), 0.0, 1.0)
	var landing = clamp(float(player.landing_kick) * 2.6, 0.0, 1.0)
	var right = player.global_transform.basis.x.normalized()
	var forward = -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var velocity = player.horizontal_velocity
	var safe_dt = max(dt, 0.001)
	var raw_horizontal_accel = (velocity - last_player_horizontal_velocity) / safe_dt
	var raw_vertical_accel = (float(player.vertical_velocity) - last_player_vertical_velocity) / safe_dt
	last_player_horizontal_velocity = velocity
	last_player_vertical_velocity = float(player.vertical_velocity)
	weapon_accel_memory = weapon_accel_memory.lerp(raw_horizontal_accel.limit_length(30.0), clamp(dt * 4.2, 0.0, 1.0))
	weapon_vertical_accel_memory = lerp(weapon_vertical_accel_memory, clamp(raw_vertical_accel, -34.0, 34.0), clamp(dt * 4.0, 0.0, 1.0))
	var side_ratio = clamp(velocity.dot(right) / 12.0, -1.0, 1.0)
	var forward_ratio = clamp(velocity.dot(forward) / 12.0, -1.0, 1.0)
	var accel_side = clamp(weapon_accel_memory.dot(right) / 20.0, -1.0, 1.0)
	var accel_forward = clamp(weapon_accel_memory.dot(forward) / 20.0, -1.0, 1.0)
	var accel_vertical = clamp(weapon_vertical_accel_memory / 30.0, -1.0, 1.0)
	var grapple_velocity = player.last_grapple_velocity
	var grapple_side = clamp(grapple_velocity.dot(right) / 14.5, -1.0, 1.0)
	var grapple_forward = clamp(grapple_velocity.dot(forward) / 14.5, -1.0, 1.0)
	var grapple_up = clamp(grapple_velocity.y / 14.5, -1.0, 1.0)
	var forward_slide = max(0.0, forward_ratio) * ground_slide
	var persistent_lean = clamp(float(player.movement_lean_memory), -1.0, 1.0)
	var move_intensity = max(clamp(float(player.move_intensity), 0.0, 1.0) * 0.18, momentum)
	var drift_speed = lerp(1.15, 3.55, momentum) + slide * 1.65 + surface * 0.80
	var drift_amount = lerp(0.035, 0.165, momentum) * (1.0 + slide * 0.95 + grapple * 0.55)
	var skate_sway = Vector3(
		(sin(t * drift_speed) * 0.45 + persistent_lean * 0.95 + side_ratio * 0.35) * drift_amount,
		cos(t * drift_speed * 0.73) * drift_amount * 0.22,
		sin(t * drift_speed * 0.43) * drift_amount * 0.30
	)
	var legacy_walk_bob = _legacy_walk_bob(t, response, clamp(float(player.move_intensity), 0.0, 1.0)) * 0.055
	var vertical = clamp(float(player.vertical_velocity) / 18.0, -1.0, 1.0)
	var jump_drop = Vector3(0.0, -vertical * 0.245 - accel_vertical * 0.070, vertical * 0.095)
	if not player.grounded:
		jump_drop += Vector3(0.0, -0.030 + abs(vertical) * 0.018, 0.024)
	jump_drop += Vector3(0.0, -landing * 0.055 - crouch * 0.060, landing * 0.038)
	var fire_phase = clamp(attack_anim_timer / 0.26, 0.0, 1.0)
	var recoil = Vector3(0.0, -0.024 * recoil_kick - 0.018 * fire_phase, 0.125 * recoil_kick + 0.045 * fire_phase)
	var melee_phase = clamp(quick_melee_anim_timer / 0.34, 0.0, 1.0)
	var melee_push = Vector3(-0.070 * sin(melee_phase * PI), 0.018 * sin(melee_phase * PI), -0.145 * sin(melee_phase * PI))
	var whip_phase = clamp(whip_swing_timer / 0.46, 0.0, 1.0)
	var whip_pull = Vector3(-0.075 * sin(whip_phase * PI), 0.040 * sin(whip_phase * PI), -0.085 * sin(whip_phase * PI))
	var grapple_pull = Vector3(0.035, -0.020, 0.025) * (0.35 + grapple * 0.90) if player.grapple_active or grapple > 0.05 else Vector3.ZERO
	var slide_pull = Vector3(0.180, -0.275, 0.150) * ground_slide + Vector3(0.120, -0.130, 0.085) * air_slide + Vector3(0.050, -0.035, 0.022) * momentum
	slide_pull += Vector3(-0.055, 0.060, -0.030) * forward_slide
	var grapple_inertia = Vector3(grapple_side * 0.060, -abs(grapple_up) * 0.040, -grapple_forward * 0.052 + grapple_up * 0.020) * grapple
	var inertia_target = Vector3(
		-persistent_lean * 0.310 - side_ratio * 0.230 - accel_side * 0.155 + grapple_side * grapple * 0.100,
		-vertical * 0.205 - accel_vertical * 0.090 - crouch * 0.070 + landing * 0.095,
		forward_ratio * 0.125 - accel_forward * 0.105 + surface * momentum * 0.055 - grapple_forward * grapple * 0.095
	)
	inertia_target = inertia_target.limit_length(0.78)
	var spring = lerp(7.2, 12.5, response)
	var damping = lerp(6.8, 10.5, response)
	weapon_physics_velocity += (inertia_target - weapon_physics_offset) * spring * dt
	weapon_physics_velocity = weapon_physics_velocity.move_toward(Vector3.ZERO, damping * dt)
	weapon_physics_offset = (weapon_physics_offset + weapon_physics_velocity * dt).limit_length(0.82)
	var inertia_pull = weapon_physics_offset + grapple_inertia
	var target_pos = Vector3(0.36, -0.50, -0.92) + _weapon_hand_offset(current_weapon)
	target_pos += skate_sway + legacy_walk_bob + recoil + jump_drop + melee_push + whip_pull + grapple_pull + slide_pull + inertia_pull
	target_pos += Vector3(weapon_lag.x, weapon_lag.y, 0.0)
	var smooth = clamp(dt * lerp(3.8, 6.4, response), 0.0, 1.0)
	weapon_sway = weapon_sway.lerp(target_pos, smooth)
	var target_roll = weapon_lag.x * 38.0
	if player.grapple_active:
		target_roll += 4.0
	target_roll += ground_slide * lerp(24.0, 16.0, forward_slide) + air_slide * 13.0 + momentum * 5.0 + grapple * 7.4 + persistent_lean * 17.5 + side_ratio * 12.0 + accel_side * 5.6 + grapple_side * 6.0 + rad_to_deg(float(player.body_roll)) * 0.62
	target_roll += sin(t * drift_speed * 0.58) * move_intensity * lerp(1.2, 3.4, response)
	weapon_roll = lerp(weapon_roll, target_roll, clamp(dt * 5.8, 0.0, 1.0))
	var pitch = -5.0 - recoil_kick * lerp(3.0, 5.6, response) + weapon_lag.y * 42.0 + vertical * 7.8 + accel_vertical * 3.4 + ground_slide * lerp(13.5, 8.8, forward_slide) + air_slide * 5.8 + landing * 5.4 + grapple_forward * grapple * 4.2 - grapple_up * grapple * 3.6 + rad_to_deg(float(player.body_pitch)) * 0.52
	var yaw = 4.5 + weapon_lag.x * 58.0 - ground_slide * 6.2 - air_slide * 3.1 + persistent_lean * 13.0 + side_ratio * 9.8 + accel_side * 4.8 + accel_forward * 2.0 + grapple_side * grapple * 6.8 + rad_to_deg(float(player.body_yaw)) * 0.94
	if quick_melee_anim_timer > 0.0:
		pitch -= sin(melee_phase * PI) * 8.0
		yaw -= sin(melee_phase * PI) * 7.5
	if whip_swing_timer > 0.0:
		pitch -= sin(whip_phase * PI) * 7.0
		yaw -= sin(whip_phase * PI) * 15.0
		weapon_roll -= sin(whip_phase * PI) * 18.0
	weapon_root.position = weapon_sway
	weapon_root.rotation_degrees = Vector3(pitch, yaw, weapon_roll)

func _legacy_walk_bob(t: float, response: float, input_amount: float) -> Vector3:
	var bob_speed = lerp(5.4, 8.8, response)
	var bob_amount = lerp(0.010, 0.035, response) * input_amount
	return Vector3(
		sin(t * bob_speed) * bob_amount,
		abs(sin(t * bob_speed * 0.5)) * bob_amount * 0.70,
		sin(t * bob_speed * 0.42) * bob_amount * 0.30
	)

func _rebuild_weapon_view() -> void:
	_ensure_weapon_view()
	if not is_instance_valid(weapon_root):
		return
	_ensure_muzzle_marker()
	_hide_cached_weapon_views_and_clear_temp()
	weapon_root.visible = _weapon_view_visible()
	view_weapon_id = current_weapon
	if _show_cached_weapon_view(current_weapon):
		return
	var visual_root = Node3D.new()
	visual_root.name = "WeaponView_%s" % current_weapon
	visual_root.set_meta("weapon_view_id", current_weapon)
	weapon_root.add_child(visual_root)
	weapon_visual_build_root = visual_root
	if not legacy_weapon_models and _try_add_imported_weapon_view(current_weapon):
		_finish_weapon_visual_cache(current_weapon, visual_root)
		return
	var accent = _weapon_accent(current_weapon)
	var armor = Color8(226, 222, 205)
	var armor_shadow = Color8(150, 150, 136)
	var metal = Color8(38, 42, 43)
	var dark = Color8(16, 19, 20)
	var yellow = Color8(236, 178, 34)
	if current_weapon == "whip":
		_add_sci_body(Vector3(0.28, 0.18, 0.42), Vector3(0.16, -0.08, -0.34), armor, metal, accent)
		_add_box(Vector3(0.16, 0.34, 0.16), Vector3(0.22, -0.28, -0.18), Vector3(-14, 0, 0), dark)
		_add_cylinder(0.055, 0.70, Vector3(0.04, 0.05, -0.58), Vector3(62, 0, 70), yellow)
		for i in 10:
			var p = float(i) / 9.0
			var pos = Vector3(0.02 - p * 0.88, 0.08 + sin(p * PI) * 0.30, -0.58 - p * 0.38)
			_add_box(Vector3(0.09, 0.07, 0.10), pos, Vector3(0, 28, i * 17), dark)
			_add_sphere(0.026, pos + Vector3(0, 0.035, 0), yellow if i % 2 == 0 else accent, true)
		_add_box(Vector3(0.20, 0.10, 0.20), Vector3(-0.94, 0.12, -0.92), Vector3(0, 45, 0), armor)
		_add_box(Vector3(0.08, 0.34, 0.08), Vector3(-1.02, 0.12, -0.92), Vector3(0, 0, 28), yellow, true)
		_add_box(Vector3(0.08, 0.34, 0.08), Vector3(-0.86, 0.12, -0.92), Vector3(0, 0, -28), yellow, true)
		muzzle_marker.position = Vector3(-0.94, 0.12, -0.92)
	elif current_weapon == "shotgun":
		_add_sci_body(Vector3(0.54, 0.28, 0.90), Vector3(0.02, -0.02, -0.48), armor, metal, accent)
		_add_cylinder(0.16, 0.34, Vector3(0.00, 0.08, -1.02), Vector3(90, 0, 0), dark)
		_add_cylinder(0.11, 0.40, Vector3(0.00, 0.08, -1.08), Vector3(90, 0, 0), yellow, true)
		_add_box(Vector3(0.42, 0.08, 0.70), Vector3(0.00, 0.25, -0.54), Vector3.ZERO, yellow, true)
		_add_box(Vector3(0.18, 0.42, 0.20), Vector3(0.16, -0.34, -0.15), Vector3(-18, 0, 0), dark)
		_add_box(Vector3(0.34, 0.18, 0.30), Vector3(0.04, 0.14, -0.02), Vector3.ZERO, armor_shadow)
		_add_sight(Vector3(0.0, 0.34, -0.36), accent)
		muzzle_marker.position = Vector3(0.0, 0.08, -1.28)
	elif current_weapon in ["auto", "seeker"]:
		_add_sci_body(Vector3(0.42, 0.24, 1.02), Vector3(0.04, 0.00, -0.58), armor, metal, accent)
		_add_cylinder(0.065, 0.70, Vector3(0.04, 0.12, -1.08), Vector3(90, 0, 0), dark)
		_add_cylinder(0.045, 0.36, Vector3(0.04, 0.12, -1.40), Vector3(90, 0, 0), metal)
		_add_box(Vector3(0.20, 0.46, 0.20), Vector3(0.02, -0.34, -0.34), Vector3(-8, 0, 0), dark)
		_add_box(Vector3(0.38, 0.08, 0.66), Vector3(0.04, 0.22, -0.64), Vector3.ZERO, accent, true)
		if current_weapon == "seeker":
			_add_sphere(0.13, Vector3(0.04, 0.14, -1.02), accent, true)
			_add_box(Vector3(0.24, 0.08, 0.32), Vector3(-0.18, 0.08, -0.82), Vector3(0, 16, 0), accent, true)
			_add_box(Vector3(0.24, 0.08, 0.32), Vector3(0.26, 0.08, -0.82), Vector3(0, -16, 0), accent, true)
		_add_sight(Vector3(0.04, 0.34, -0.38), accent)
		_add_box(Vector3(0.32, 0.10, 0.40), Vector3(0.04, -0.17, -0.70), Vector3.ZERO, dark)
		muzzle_marker.position = Vector3(0.04, 0.12, -1.58)
	elif current_weapon == "marksman":
		accent = Color8(166, 116, 72)
		var wood = Color8(132, 82, 48)
		_add_box(Vector3(0.24, 0.16, 1.24), Vector3(0.03, -0.04, -0.72), Vector3.ZERO, wood)
		_add_box(Vector3(0.20, 0.12, 0.72), Vector3(0.03, 0.12, -0.62), Vector3.ZERO, metal)
		_add_box(Vector3(0.16, 0.16, 0.46), Vector3(0.05, -0.20, -0.20), Vector3(-12, 0, 0), wood)
		_add_box(Vector3(0.16, 0.34, 0.16), Vector3(0.06, -0.33, -0.52), Vector3(-4, 0, 0), dark)
		_add_cylinder(0.040, 1.02, Vector3(0.03, 0.15, -1.18), Vector3(90, 0, 0), dark)
		_add_cylinder(0.030, 0.34, Vector3(0.03, 0.15, -1.78), Vector3(90, 0, 0), metal)
		_add_sight(Vector3(0.03, 0.31, -0.70), Color8(230, 210, 160))
		muzzle_marker.position = Vector3(0.03, 0.15, -1.98)
	elif current_weapon == "grenade_launcher":
		accent = Color8(255, 188, 74)
		_add_sci_body(Vector3(0.62, 0.34, 0.76), Vector3(0.02, -0.04, -0.44), armor, metal, accent)
		_add_cylinder(0.21, 0.36, Vector3(0.02, 0.10, -0.94), Vector3(90, 0, 0), dark)
		_add_cylinder(0.13, 0.24, Vector3(0.02, 0.10, -1.12), Vector3(90, 0, 0), accent, true)
		_add_cylinder(0.14, 0.34, Vector3(-0.20, -0.16, -0.42), Vector3(0, 0, 90), accent)
		_add_box(Vector3(0.22, 0.40, 0.22), Vector3(0.12, -0.34, -0.20), Vector3(-12, 0, 0), dark)
		_add_box(Vector3(0.46, 0.10, 0.28), Vector3(0.02, 0.26, -0.42), Vector3.ZERO, armor_shadow)
		muzzle_marker.position = Vector3(0.02, 0.10, -1.34)
	elif current_weapon == "saw":
		accent = Color8(224, 226, 212)
		_add_sci_body(Vector3(0.48, 0.22, 0.76), Vector3(0.02, -0.02, -0.48), armor, metal, accent)
		_add_cylinder(0.22, 0.10, Vector3(0.02, 0.12, -1.02), Vector3(90, 0, 0), accent, true)
		_add_cylinder(0.28, 0.045, Vector3(0.02, 0.12, -1.06), Vector3(90, 0, 0), dark)
		for i in 8:
			var a = TAU * float(i) / 8.0
			_add_box(Vector3(0.08, 0.035, 0.22), Vector3(cos(a) * 0.22, 0.12 + sin(a) * 0.22, -1.06), Vector3(0, 0, rad_to_deg(a)), accent, true)
		_add_box(Vector3(0.18, 0.36, 0.20), Vector3(0.12, -0.28, -0.20), Vector3(-12, 0, 0), dark)
		muzzle_marker.position = Vector3(0.02, 0.12, -1.32)
	elif current_weapon == "cryo":
		accent = Color8(118, 226, 255)
		_add_sci_body(Vector3(0.50, 0.26, 0.82), Vector3(0.02, -0.02, -0.48), armor, metal, accent)
		_add_sphere(0.16, Vector3(0.02, 0.12, -0.88), accent, true)
		_add_cylinder(0.08, 0.72, Vector3(-0.20, 0.08, -0.62), Vector3(90, 0, 0), accent, true)
		_add_cylinder(0.08, 0.72, Vector3(0.24, 0.08, -0.62), Vector3(90, 0, 0), accent.lightened(0.16), true)
		_add_cylinder(0.10, 0.28, Vector3(0.02, 0.11, -1.10), Vector3(90, 0, 0), dark)
		muzzle_marker.position = Vector3(0.02, 0.11, -1.28)
	elif current_weapon == "shock_flux":
		accent = Color8(176, 116, 255)
		_add_sci_body(Vector3(0.44, 0.24, 0.78), Vector3(0.02, -0.03, -0.48), armor, metal, accent)
		for x in [-0.18, 0.18]:
			_add_cylinder(0.055, 0.92, Vector3(x, 0.11, -0.68), Vector3(90, 0, 0), accent, true)
			_add_box(Vector3(0.08, 0.10, 0.88), Vector3(x, 0.11, -0.68), Vector3.ZERO, dark)
		_add_sphere(0.15, Vector3(0.02, 0.14, -0.98), accent.lightened(0.20), true)
		_add_box(Vector3(0.18, 0.36, 0.20), Vector3(0.12, -0.29, -0.20), Vector3(-10, 0, 0), dark)
		muzzle_marker.position = Vector3(0.02, 0.13, -1.28)
	elif current_weapon == "bow":
		accent = Color8(198, 154, 92)
		_add_box(Vector3(0.14, 0.24, 0.92), Vector3(0.02, -0.02, -0.62), Vector3.ZERO, dark)
		_add_box(Vector3(0.08, 1.18, 0.08), Vector3(-0.28, 0.18, -0.78), Vector3(0, 0, -24), accent)
		_add_box(Vector3(0.08, 1.18, 0.08), Vector3(0.32, 0.18, -0.78), Vector3(0, 0, 24), accent)
		_add_box(Vector3(0.64, 0.030, 0.04), Vector3(0.02, 0.56, -0.78), Vector3.ZERO, armor, false)
		_add_box(Vector3(0.64, 0.030, 0.04), Vector3(0.02, -0.18, -0.78), Vector3.ZERO, armor, false)
		_add_cylinder(0.030, 1.34, Vector3(0.02, 0.16, -1.12), Vector3(90, 0, 0), accent.lightened(0.16), true)
		_add_sight(Vector3(0.02, 0.36, -0.46), accent)
		muzzle_marker.position = Vector3(0.02, 0.16, -1.58)
	elif current_weapon == "toxic":
		accent = Color8(128, 255, 82)
		_add_sci_body(Vector3(0.54, 0.28, 0.70), Vector3(0.02, -0.03, -0.42), armor, metal, accent)
		_add_sphere(0.16, Vector3(0.25, 0.14, -0.48), accent, true)
		_add_sphere(0.12, Vector3(-0.22, 0.14, -0.48), accent.darkened(0.18), true)
		_add_cylinder(0.12, 0.38, Vector3(0.02, 0.08, -0.92), Vector3(90, 0, 0), accent, true)
		_add_box(Vector3(0.44, 0.10, 0.30), Vector3(0.02, -0.18, -0.42), Vector3.ZERO, Color8(86, 126, 50))
		muzzle_marker.position = Vector3(0.02, 0.08, -1.18)
	elif current_weapon == "plasma":
		accent = Color8(72, 255, 96)
		_add_sci_body(Vector3(0.56, 0.30, 0.82), Vector3(0.02, -0.02, -0.48), armor, metal, accent)
		_add_cylinder(0.18, 0.26, Vector3(0.02, 0.08, -0.98), Vector3(90, 0, 0), dark)
		_add_sphere(0.14, Vector3(0.02, 0.08, -1.12), accent, true)
		for x in [-0.22, 0.22]:
			_add_cylinder(0.07, 0.60, Vector3(x, 0.07, -0.62), Vector3(90, 0, 0), accent, true)
			_add_box(Vector3(0.10, 0.14, 0.68), Vector3(x, 0.07, -0.62), Vector3.ZERO, dark)
		_add_box(Vector3(0.20, 0.36, 0.20), Vector3(0.10, -0.30, -0.20), Vector3(-10, 0, 0), dark)
		_add_sight(Vector3(0.02, 0.35, -0.28), accent)
		muzzle_marker.position = Vector3(0.02, 0.08, -1.22)
	elif current_weapon == "flak":
		accent = Color8(255, 132, 82)
		_add_sci_body(Vector3(0.52, 0.30, 0.58), Vector3(0.04, -0.06, -0.34), armor_shadow, metal, accent)
		for x in [-0.16, 0.16]:
			for y in [0.06, 0.22]:
				_add_cylinder(0.038, 1.04, Vector3(x, y, -0.90), Vector3(90, 0, 0), dark)
				_add_cylinder(0.026, 0.16, Vector3(x, y, -1.48), Vector3(90, 0, 0), accent, true)
		_add_box(Vector3(0.48, 0.18, 0.24), Vector3(0.04, 0.14, -0.74), Vector3.ZERO, Color8(28, 31, 32))
		_add_box(Vector3(0.56, 0.08, 0.20), Vector3(0.04, 0.36, -0.48), Vector3.ZERO, armor)
		_add_box(Vector3(0.16, 0.42, 0.22), Vector3(0.16, -0.34, -0.16), Vector3(-14, 0, 0), dark)
		_add_box(Vector3(0.08, 0.36, 0.68), Vector3(-0.22, -0.18, -0.54), Vector3(0, 0, -18), metal)
		_add_box(Vector3(0.08, 0.36, 0.68), Vector3(0.30, -0.18, -0.54), Vector3(0, 0, 18), metal)
		_add_sight(Vector3(0.04, 0.42, -0.46), accent)
		muzzle_marker.position = Vector3(0.04, 0.14, -1.56)
	elif current_weapon == "heavy":
		_add_sci_body(Vector3(0.66, 0.34, 0.94), Vector3(0.02, -0.03, -0.48), armor, metal, yellow)
		_add_cylinder(0.22, 0.48, Vector3(0.02, 0.09, -1.02), Vector3(90, 0, 0), dark)
		_add_cylinder(0.15, 0.50, Vector3(0.02, 0.09, -1.12), Vector3(90, 0, 0), yellow, true)
		_add_box(Vector3(0.52, 0.13, 0.40), Vector3(0.02, 0.30, -0.44), Vector3.ZERO, armor_shadow)
		_add_cylinder(0.14, 0.34, Vector3(0.18, -0.20, -0.46), Vector3(0, 0, 90), yellow)
		_add_box(Vector3(0.22, 0.38, 0.22), Vector3(0.12, -0.34, -0.20), Vector3(-12, 0, 0), dark)
		muzzle_marker.position = Vector3(0.02, 0.09, -1.42)
	elif current_weapon == "railgun":
		accent = Color8(178, 72, 255)
		_add_sci_body(Vector3(0.36, 0.20, 1.20), Vector3(0.02, 0.03, -0.72), armor, metal, accent)
		_add_box(Vector3(0.12, 0.10, 1.38), Vector3(-0.19, 0.14, -0.80), Vector3.ZERO, dark)
		_add_box(Vector3(0.12, 0.10, 1.38), Vector3(0.23, 0.14, -0.80), Vector3.ZERO, dark)
		_add_box(Vector3(0.07, 0.07, 1.38), Vector3(-0.19, 0.20, -0.80), Vector3.ZERO, accent, true)
		_add_box(Vector3(0.07, 0.07, 1.38), Vector3(0.23, 0.20, -0.80), Vector3.ZERO, accent, true)
		_add_cylinder(0.11, 0.20, Vector3(0.02, 0.16, -1.50), Vector3(90, 0, 0), accent, true)
		_add_box(Vector3(0.17, 0.34, 0.20), Vector3(0.08, -0.27, -0.28), Vector3(-10, 0, 0), dark)
		muzzle_marker.position = Vector3(0.02, 0.16, -1.62)
	elif current_weapon == "incinerator":
		accent = Color8(255, 142, 42)
		_add_sci_body(Vector3(0.58, 0.30, 0.74), Vector3(0.02, -0.03, -0.42), armor, metal, accent)
		_add_cylinder(0.17, 0.34, Vector3(0.02, 0.08, -0.94), Vector3(90, 0, 0), dark)
		_add_cylinder(0.10, 0.52, Vector3(0.02, 0.08, -1.04), Vector3(90, 0, 0), accent, true)
		_add_sphere(0.14, Vector3(0.24, 0.16, -0.58), Color8(255, 190, 62), true)
		_add_box(Vector3(0.34, 0.12, 0.42), Vector3(-0.10, -0.18, -0.48), Vector3.ZERO, yellow)
		_add_box(Vector3(0.18, 0.34, 0.20), Vector3(0.08, -0.30, -0.20), Vector3(-12, 0, 0), dark)
		muzzle_marker.position = Vector3(0.02, 0.08, -1.30)
	else:
		_add_sci_body(Vector3(0.40, 0.24, 0.62), Vector3(0.06, -0.02, -0.38), armor, metal, accent)
		_add_cylinder(0.08, 0.56, Vector3(0.06, 0.11, -0.82), Vector3(90, 0, 0), dark)
		_add_cylinder(0.06, 0.20, Vector3(0.06, 0.11, -1.12), Vector3(90, 0, 0), accent, true)
		_add_box(Vector3(0.15, 0.34, 0.18), Vector3(0.12, -0.28, -0.18), Vector3(-12, 0, 0), dark)
		_add_box(Vector3(0.34, 0.05, 0.34), Vector3(0.06, 0.17, -0.46), Vector3.ZERO, Color8(70, 220, 240), true)
		_add_sight(Vector3(0.06, 0.30, -0.30), Color8(70, 220, 240))
		muzzle_marker.position = Vector3(0.06, 0.11, -1.22)
	_finish_weapon_visual_cache(current_weapon, visual_root)

func _ensure_muzzle_marker() -> void:
	if is_instance_valid(muzzle_marker):
		return
	muzzle_marker = Marker3D.new()
	muzzle_marker.name = "Muzzle"
	weapon_root.add_child(muzzle_marker)

func _hide_cached_weapon_views_and_clear_temp() -> void:
	for child in weapon_root.get_children():
		if child == muzzle_marker:
			continue
		if child.has_meta("weapon_view_id"):
			child.visible = false
		else:
			child.queue_free()

func _show_cached_weapon_view(id: String) -> bool:
	if not weapon_visual_cache.has(id):
		return false
	var visual = weapon_visual_cache[id]
	if not is_instance_valid(visual):
		weapon_visual_cache.erase(id)
		return false
	visual.visible = true
	if IMPORTED_WEAPON_MODELS.has(id):
		muzzle_marker.position = IMPORTED_WEAPON_MODELS[id].muzzle
		visual.set_meta("muzzle_position", muzzle_marker.position)
	else:
		muzzle_marker.position = visual.get_meta("muzzle_position", muzzle_marker.position)
	return true

func _finish_weapon_visual_cache(id: String, visual_root: Node3D) -> void:
	weapon_visual_build_root = null
	visual_root.set_meta("muzzle_position", muzzle_marker.position)
	weapon_visual_cache[id] = visual_root

func _weapon_visual_parent() -> Node3D:
	if is_instance_valid(weapon_visual_build_root):
		return weapon_visual_build_root
	return weapon_root

func _prewarm_imported_weapon_views() -> void:
	if legacy_weapon_models:
		return
	var original_weapon = current_weapon
	for id in IMPORTED_WEAPON_MODELS.keys():
		if weapon_visual_cache.has(id) and is_instance_valid(weapon_visual_cache[id]):
			continue
		current_weapon = id
		_rebuild_weapon_view()
	current_weapon = original_weapon
	view_weapon_id = ""
	_rebuild_weapon_view()

func _prewarm_weapon_views(ids: Array) -> void:
	var original_weapon = current_weapon
	for id_value in ids:
		var id = String(id_value)
		if not weapons.has(id):
			continue
		if weapon_visual_cache.has(id) and is_instance_valid(weapon_visual_cache[id]):
			continue
		current_weapon = id
		_rebuild_weapon_view()
	current_weapon = original_weapon
	view_weapon_id = ""
	_rebuild_weapon_view()

func _try_add_imported_weapon_view(id: String) -> bool:
	if legacy_weapon_models:
		return false
	if not IMPORTED_WEAPON_MODELS.has(id):
		return false
	var profile = IMPORTED_WEAPON_MODELS[id]
	var path = String(profile.path)
	if not ResourceLoader.exists(path):
		return false
	var scene = load(path)
	if scene == null or not scene is PackedScene:
		return false
	var imported = scene.instantiate()
	if not imported is Node3D:
		imported.queue_free()
		return false
	var holder = Node3D.new()
	holder.name = "ImportedWeapon_%s" % id
	holder.position = profile.pos
	holder.rotation_degrees = profile.rot
	_weapon_visual_parent().add_child(holder)
	holder.add_child(imported)
	_prepare_imported_weapon_node(imported)
	_normalize_imported_weapon(imported, float(profile.size))
	muzzle_marker.position = profile.muzzle
	return true

func _prepare_imported_weapon_node(root: Node) -> void:
	for node in _walk_imported_weapon_nodes(root):
		if node is MeshInstance3D:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if node is CollisionObject3D:
			node.collision_layer = 0
			node.collision_mask = 0
		if node is CollisionShape3D:
			node.disabled = true
		if node is Light3D:
			node.visible = false
		if node is Camera3D:
			node.current = false

func _walk_imported_weapon_nodes(root: Node) -> Array:
	var out = [root]
	for child in root.get_children():
		out.append_array(_walk_imported_weapon_nodes(child))
	return out

func _normalize_imported_weapon(root: Node3D, target_size: float) -> void:
	var bounds = _imported_weapon_bounds(root)
	if bounds.size == Vector3.ZERO:
		return
	var longest = max(bounds.size.x, max(bounds.size.y, bounds.size.z))
	if longest <= 0.001:
		return
	var scale_ratio = target_size / longest
	var center = bounds.position + bounds.size * 0.5
	root.scale *= scale_ratio
	root.position -= center * scale_ratio

func _imported_weapon_bounds(root: Node3D) -> AABB:
	var found = false
	var bounds = AABB()
	var root_inv = root.global_transform.affine_inverse()
	for node in _walk_imported_weapon_nodes(root):
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

func _weapon_hand_offset(id: String) -> Vector3:
	match id:
		"shotgun":
			return Vector3(0.035, -0.020, -0.045)
		"heavy":
			return Vector3(0.045, -0.035, -0.060)
		"railgun":
			return Vector3(0.020, 0.012, -0.080)
		"plasma":
			return Vector3(0.030, -0.010, -0.030)
		"auto":
			return Vector3(0.025, -0.005, -0.055)
		"marksman":
			return Vector3(0.018, 0.002, -0.078)
		"seeker":
			return Vector3(0.030, -0.008, -0.062)
		"incinerator":
			return Vector3(0.042, -0.018, -0.035)
		"saw":
			return Vector3(0.030, -0.010, -0.050)
		"cryo":
			return Vector3(0.032, -0.012, -0.038)
		"bow":
			return Vector3(0.020, 0.020, -0.070)
		"toxic":
			return Vector3(0.042, -0.020, -0.030)
		"whip":
			return Vector3(0.040, 0.000, 0.000)
		_:
			return Vector3.ZERO

func _weapon_motion_response(id: String) -> float:
	match id:
		"shotgun":
			return 0.48
		"heavy":
			return 0.34
		"railgun", "plasma":
			return 0.54
		"auto", "seeker":
			return 0.86
		"marksman":
			return 0.50
		"saw", "toxic":
			return 0.74
		"cryo":
			return 0.62
		"bow":
			return 0.42
		"incinerator":
			return 0.58
		"whip":
			return 0.96
		_:
			return 0.78

func _spawn_whip_swing_visual() -> void:
	if not is_instance_valid(weapon_root):
		return
	var points = [
		Vector3(0.58, -0.04, -0.44),
		Vector3(0.24, 0.30, -0.74),
		Vector3(-0.24, 0.28, -1.10),
		Vector3(-0.82, -0.12, -1.38),
		Vector3(-1.22, 0.12, -1.18)
	]
	var hot = Color8(255, 164, 44)
	var ember = Color8(255, 74, 32)
	var core = Color8(220, 255, 255)
	var cyan = Color8(92, 238, 255)
	for i in range(points.size() - 1):
		_add_temp_segment(points[i], points[i + 1], 0.034 + i * 0.006, hot if i % 2 == 0 else ember, 0.30)
		_add_temp_sphere(0.034, points[i + 1], hot.lightened(0.10) if i % 2 == 0 else ember.lightened(0.18), 0.28)
	var angle_jitter = randf_range(-18.0, 18.0)
	for band in range(12):
		var p = float(band) / 11.0
		var width = 1.72 - p * 0.52
		var pos = Vector3(0.72 - p * 2.10, 0.36 - sin(p * PI) * 0.46 + randf_range(-0.025, 0.025), -0.66 - p * 0.76)
		var rot = Vector3(-8 - p * 10.0 + randf_range(-4.0, 4.0), -34 - p * 54.0 + angle_jitter, -46 + p * 96.0 + randf_range(-7.0, 7.0))
		var color = core if band in [2, 3, 4] else (cyan if band % 2 == 0 else hot)
		_add_temp_box(Vector3(width, 0.024, 0.060), pos, rot, color, true, 0.42)
		_add_temp_box(Vector3(width * 0.70, 0.016, 0.046), pos + Vector3(0.02, -0.036, -0.014), rot + Vector3(0, 4, -9), ember if band % 2 == 0 else hot, true, 0.36)
	_add_temp_box(Vector3(0.14, 0.10, 0.24), points[points.size() - 1], Vector3(0, 48, 28), Color8(245, 220, 116), true, 0.30)

func _spawn_quick_melee_visual() -> void:
	if not is_instance_valid(weapon_root):
		return
	var fist = Node3D.new()
	fist.name = "QuickMeleeVisual"
	weapon_root.add_child(fist)
	fist.position = Vector3(0.24, -0.22, -0.44)
	var armor = Color8(226, 222, 205)
	var metal = Color8(32, 36, 38)
	var glow = Color8(80, 220, 240)
	_add_temp_box_to(fist, Vector3(0.16, 0.22, 0.28), Vector3(0.0, 0.0, -0.18), Vector3(-8, 0, 6), metal, false, 0.26)
	_add_temp_box_to(fist, Vector3(0.24, 0.17, 0.18), Vector3(-0.02, 0.04, -0.38), Vector3(-4, 0, -8), armor, false, 0.26)
	_add_temp_box_to(fist, Vector3(0.050, 0.030, 0.050), Vector3(-0.12, 0.13, -0.47), Vector3.ZERO, glow, true, 0.26)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fist, "position", Vector3(0.02, -0.10, -0.98), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(fist, "rotation_degrees", Vector3(-16, -20, -10), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(fist, "position", Vector3(0.36, -0.35, -0.42), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(fist.queue_free)

func _add_temp_segment(from: Vector3, to: Vector3, thickness: float, color: Color, lifetime: float) -> void:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(thickness, thickness, max(0.01, from.distance_to(to)))
	var part = _add_temp_mesh(mesh, (from + to) * 0.5, Vector3.ZERO, color, true, lifetime)
	part.look_at(weapon_root.to_global(to), Vector3.UP)

func _add_temp_sphere(radius: float, pos: Vector3, color: Color, lifetime: float) -> void:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	_add_temp_mesh(mesh, pos, Vector3.ZERO, color, true, lifetime)

func _add_temp_box(size: Vector3, pos: Vector3, rot_deg: Vector3, color: Color, glow: bool, lifetime: float) -> void:
	var mesh = BoxMesh.new()
	mesh.size = size
	_add_temp_mesh(mesh, pos, rot_deg, color, glow, lifetime)

func _add_temp_box_to(parent: Node3D, size: Vector3, pos: Vector3, rot_deg: Vector3, color: Color, glow: bool, lifetime: float) -> void:
	var mesh = BoxMesh.new()
	mesh.size = size
	var part = MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.rotation_degrees = rot_deg
	part.material_override = _temp_material(color, glow)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	var tween = create_tween()
	tween.tween_interval(lifetime)
	tween.tween_callback(part.queue_free)

func _add_temp_mesh(mesh: Mesh, pos: Vector3, rot_deg: Vector3, color: Color, glow: bool, lifetime: float) -> MeshInstance3D:
	var part = MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.rotation_degrees = rot_deg
	part.material_override = _temp_material(color, glow)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.scale = Vector3(0.60, 0.60, 0.60)
	weapon_root.add_child(part)
	var tween = create_tween()
	tween.tween_property(part, "scale", Vector3.ONE, min(0.045, lifetime * 0.35)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(max(0.01, lifetime - 0.09))
	tween.tween_property(part, "scale", Vector3(0.05, 0.05, 0.05), 0.055).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(part.queue_free)
	return part

func _temp_material(color: Color, glow: bool) -> Material:
	if level_manager != null and level_manager.asset_factory != null:
		return level_manager.asset_factory.make_glow_material(color, 1.08) if glow else level_manager.asset_factory.make_flat_material(color)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.1
	return mat

func _weapon_muzzle_position(id: String) -> Vector3:
	match id:
		"railgun":
			return Vector3(-0.38, 0.02, -0.20)
		"shotgun":
			return Vector3(-0.36, -0.01, -0.20)
		"heavy":
			return Vector3(-0.37, -0.01, -0.20)
		"plasma":
			return Vector3(-0.34, -0.01, -0.20)
		"auto":
			return Vector3(-0.36, -0.01, -0.20)
		"seeker":
			return Vector3(-0.36, -0.01, -0.20)
		"incinerator":
			return Vector3(-0.34, -0.01, -0.20)
		"whip":
			return Vector3(-0.34, -0.01, -0.20)
		_:
			return Vector3(-0.26, -0.01, -0.20)

func _weapon_accent(id: String) -> Color:
	match id:
		"plasma":
			return Color8(72, 255, 96)
		"seeker":
			return Color8(72, 255, 150)
		"railgun":
			return Color8(178, 72, 255)
		"saw":
			return Color8(224, 226, 212)
		"cryo":
			return Color8(118, 226, 255)
		"marksman":
			return Color8(198, 154, 92)
		"toxic":
			return Color8(128, 255, 82)
		"heavy", "shotgun", "incinerator", "whip":
			return Color8(236, 178, 34)
		_:
			return Color8(72, 220, 240)

func _add_sci_body(size: Vector3, pos: Vector3, armor: Color, metal: Color, accent: Color) -> void:
	_add_box(size, pos, Vector3.ZERO, metal)
	_add_box(Vector3(size.x * 0.80, size.y * 0.45, size.z * 0.72), pos + Vector3(0, size.y * 0.38, -size.z * 0.03), Vector3.ZERO, armor)
	_add_box(Vector3(size.x * 0.96, size.y * 0.18, size.z * 0.36), pos + Vector3(0, -size.y * 0.12, -size.z * 0.10), Vector3.ZERO, Color8(28, 31, 32))
	for x in [-1.0, 1.0]:
		_add_box(Vector3(0.045, size.y * 0.42, size.z * 0.20), pos + Vector3(x * size.x * 0.48, size.y * 0.10, -size.z * 0.18), Vector3.ZERO, armor.darkened(0.08))
		_add_box(Vector3(0.026, size.y * 0.18, size.z * 0.36), pos + Vector3(x * size.x * 0.52, size.y * 0.15, -size.z * 0.02), Vector3.ZERO, accent, true)
	for i in 4:
		var z = pos.z - size.z * 0.35 + float(i) * size.z * 0.23
		_add_box(Vector3(0.055, 0.025, 0.045), pos + Vector3(-size.x * 0.22 + i * size.x * 0.14, size.y * 0.62, z), Vector3.ZERO, accent if i % 2 == 0 else Color8(52, 56, 58), i % 2 == 0)

func _add_sight(pos: Vector3, accent: Color) -> void:
	_add_box(Vector3(0.20, 0.10, 0.20), pos, Vector3.ZERO, Color8(30, 34, 36))
	_add_box(Vector3(0.12, 0.035, 0.12), pos + Vector3(0, 0.07, 0), Vector3.ZERO, accent, true)

func _add_box(size: Vector3, pos: Vector3, rot_deg: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	return _add_mesh(mesh, pos, rot_deg, color, glow)

func _add_cylinder(radius: float, height: float, pos: Vector3, rot_deg: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return _add_mesh(mesh, pos, rot_deg, color, glow)

func _add_sphere(radius: float, pos: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return _add_mesh(mesh, pos, Vector3.ZERO, color, glow)

func _add_mesh(mesh: Mesh, pos: Vector3, rot_deg: Vector3, color: Color, glow: bool) -> MeshInstance3D:
	var part = MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.rotation_degrees = rot_deg
	var factory = level_manager.asset_factory
	part.material_override = factory.make_glow_material(color, 0.96) if glow else factory.make_flat_material(color)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_weapon_visual_parent().add_child(part)
	return part
