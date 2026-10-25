extends Node3D

const AssetFactoryScript = preload("res://scripts/core/AssetFactory.gd")
const GameDataScript = preload("res://scripts/core/GameData.gd")
const LevelManagerScript = preload("res://scripts/world/LevelManager.gd")
const WeaponManagerScript = preload("res://scripts/weapons/WeaponManager.gd")
const AudioManagerScript = preload("res://scripts/core/AudioManager.gd")
const GameSettingsScript = preload("res://scripts/core/GameSettings.gd")
const SolitudeManagerScript = preload("res://scripts/narrative/SolitudeManager.gd")

var asset_factory
var player
var level_manager
var weapon_manager
var hud
var transition
var audio_manager
var sol_manager
var level_index = 0
var settings := {}
var level_entry_weapon_state := {}
var sol_choice_triggered_from_proximity = false
var world_environment: Environment
var world_sun: DirectionalLight3D
var developer_night_vision: Environment
var developer_previous_camera_environment: Environment

func _sync_developer_night_vision() -> void:
	if player == null or not is_instance_valid(player.camera):
		return
	var enabled: bool = player.developer_mode and GameDataScript.is_horror_sequence_level(level_index)
	if enabled and developer_night_vision == null:
		developer_previous_camera_environment = player.camera.environment
		developer_night_vision = world_environment.duplicate() as Environment
		# Camera-only visibility aid: no Light3D, beam, battery or AI changes.
		developer_night_vision.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		developer_night_vision.ambient_light_color = Color(0.48, 0.85, 0.56)
		developer_night_vision.ambient_light_energy = 1.0
		developer_night_vision.adjustment_contrast = 1.02
		developer_night_vision.adjustment_brightness = 1.0
		developer_night_vision.adjustment_saturation = 0.65
		player.camera.environment = developer_night_vision
	elif not enabled and developer_night_vision != null:
		player.camera.environment = developer_previous_camera_environment
		developer_night_vision = null
		developer_previous_camera_environment = null

func _ready() -> void:
	if get_tree().has_meta("killgore_random_seed"):
		seed(int(get_tree().get_meta("killgore_random_seed")))
		get_tree().remove_meta("killgore_random_seed")
	else:
		randomize()
	asset_factory = AssetFactoryScript.new()
	settings = GameSettingsScript.load_settings()
	GameSettingsScript.apply_video(settings)
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	audio_manager.set_master_volume(float(settings.get("master_volume", 0.82)))
	audio_manager.set_sfx_volume(float(settings.get("sfx_volume", 0.78)))
	audio_manager.set_music_volume(float(settings.get("music_volume", 0.80)))
	_setup_environment()
	_setup_game_nodes()
	var start_level = int(get_tree().get_meta("killgore_start_level", 0))
	var level_select_start = bool(get_tree().get_meta("killgore_level_select", false))
	get_tree().remove_meta("killgore_start_level")
	get_tree().remove_meta("killgore_level_select")
	_load_level(start_level, false, true, level_select_start)

func _setup_environment() -> void:
	var env_node = WorldEnvironment.new()
	world_environment = Environment.new()
	world_environment.background_mode = Environment.BG_COLOR
	world_environment.background_color = Color8(32, 36, 44)
	world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_environment.ambient_light_color = Color8(126, 122, 116)
	world_environment.ambient_light_energy = 0.62
	env_node.environment = world_environment
	add_child(env_node)
	world_sun = DirectionalLight3D.new()
	world_sun.rotation_degrees = Vector3(-54, 34, 0)
	world_sun.light_energy = 1.25
	add_child(world_sun)

func _apply_level_environment(index: int) -> void:
	if world_environment == null or world_sun == null:
		return
	# Preserve shadow detail at the flashlight's grazing/distant surfaces.
	# Scope the higher depth precision to horror, leaving combat unchanged.
	get_viewport().positional_shadow_atlas_16_bits = not GameDataScript.is_horror_sequence_level(index)
	if GameDataScript.is_horror_sequence_level(index):
		world_environment.background_color = Color8(4, 5, 5)
		world_environment.ambient_light_color = Color8(101, 103, 94)
		world_environment.ambient_light_energy = 0.0
		# Darkness comes from the absence of practical lights, without a fog veil.
		world_environment.fog_enabled = false
		world_environment.fog_light_color = Color8(45, 55, 50)
		world_environment.fog_light_energy = 0.38
		world_environment.fog_density = 0.044
		world_environment.fog_height = 1.12
		world_environment.fog_height_density = 0.018
		world_environment.fog_sky_affect = 0.0
		world_environment.adjustment_enabled = true
		world_environment.adjustment_brightness = 0.98
		world_environment.adjustment_contrast = 1.14
		world_environment.adjustment_saturation = 0.76
		world_sun.light_color = Color8(90, 91, 82)
		world_sun.light_energy = 0.0
		return
	if GameDataScript.is_trench_map_level(index):
		world_environment.background_color = Color8(10, 12, 13)
		world_environment.ambient_light_color = Color8(112, 116, 109)
		world_environment.ambient_light_energy = 0.56
		world_environment.fog_enabled = true
		world_environment.fog_light_color = Color8(36, 42, 41)
		world_environment.fog_light_energy = 0.42
		world_environment.fog_density = 0.0048
		world_environment.fog_height = 1.4
		world_environment.fog_height_density = 0.026
		world_environment.fog_sky_affect = 0.18
		world_environment.adjustment_enabled = true
		world_environment.adjustment_brightness = 1.06
		world_environment.adjustment_contrast = 1.07
		world_environment.adjustment_saturation = 0.82
		world_sun.light_color = Color8(176, 171, 151)
		world_sun.light_energy = 0.72
		return
	var profile_index = index
	if index >= GameDataScript.LEVELS.size() - 1:
		profile_index = 12
	var profiles = {
		0: [Color8(26, 30, 31), Color8(135, 137, 129), Color8(177, 176, 158), Color8(72, 119, 116), 0.0016, 0.68, 0.86],
		1: [Color8(24, 23, 22), Color8(126, 118, 102), Color8(181, 164, 132), Color8(94, 77, 55), 0.0022, 0.62, 0.82],
		2: [Color8(19, 25, 26), Color8(105, 120, 116), Color8(135, 162, 157), Color8(48, 87, 85), 0.0028, 0.57, 0.80],
		3: [Color8(29, 27, 23), Color8(139, 130, 107), Color8(193, 176, 137), Color8(105, 91, 67), 0.0030, 0.60, 0.80],
		4: [Color8(20, 19, 19), Color8(105, 96, 86), Color8(161, 139, 111), Color8(74, 54, 47), 0.0036, 0.53, 0.76],
		5: [Color8(21, 25, 22), Color8(111, 119, 102), Color8(151, 158, 130), Color8(61, 78, 61), 0.0034, 0.55, 0.77],
		6: [Color8(17, 19, 19), Color8(108, 110, 104), Color8(164, 155, 130), Color8(50, 57, 56), 0.0040, 0.52, 0.75],
		7: [Color8(18, 23, 27), Color8(99, 111, 116), Color8(131, 153, 158), Color8(42, 62, 69), 0.0038, 0.54, 0.76],
		8: [Color8(22, 19, 19), Color8(112, 103, 98), Color8(163, 142, 127), Color8(70, 49, 47), 0.0042, 0.51, 0.72],
		9: [Color8(23, 22, 20), Color8(120, 113, 99), Color8(177, 157, 124), Color8(82, 66, 48), 0.0035, 0.56, 0.78],
		11: [Color8(17, 20, 21), Color8(112, 116, 112), Color8(155, 157, 146), Color8(47, 57, 57), 0.0026, 0.58, 0.78],
		12: [Color8(10, 10, 11), Color8(82, 76, 69), Color8(147, 121, 86), Color8(49, 34, 31), 0.0048, 0.46, 0.68]
	}
	var profile = profiles.get(profile_index, profiles[6])
	world_environment.background_color = profile[0]
	world_environment.ambient_light_color = profile[1]
	world_environment.ambient_light_energy = profile[5]
	world_environment.fog_enabled = true
	world_environment.fog_light_color = profile[3]
	world_environment.fog_light_energy = 0.34
	world_environment.fog_density = profile[4]
	world_environment.fog_height = 1.2
	world_environment.fog_height_density = 0.018
	world_environment.fog_sky_affect = 0.14
	world_environment.adjustment_enabled = true
	world_environment.adjustment_brightness = 1.04
	world_environment.adjustment_contrast = 1.08
	world_environment.adjustment_saturation = profile[6]
	world_sun.light_color = profile[2]
	world_sun.light_energy = 0.84 if profile_index != 12 else 0.62

func _setup_game_nodes() -> void:
	player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(player)
	level_manager = LevelManagerScript.new()
	add_child(level_manager)
	level_manager.configure(asset_factory, player, GameDataScript.make_enemy_data(), GameDataScript.make_themes())
	player.configure(level_manager, GameDataScript.make_powerup_data())
	player.set_mouse_sensitivity(float(settings.get("mouse_sensitivity", 1.0)))
	player.set_screen_shake(float(settings.get("screen_shake", 0.68)))
	weapon_manager = WeaponManagerScript.new()
	add_child(weapon_manager)
	weapon_manager.configure(GameDataScript.make_weapon_data(), player, level_manager)
	level_manager.set_weapon_manager(weapon_manager)
	sol_manager = SolitudeManagerScript.new()
	add_child(sol_manager)
	hud = preload("res://scenes/ui/HUD.tscn").instantiate()
	add_child(hud)
	hud.configure(player, weapon_manager, level_manager, asset_factory, audio_manager, sol_manager)
	transition = preload("res://scenes/ui/Transition.tscn").instantiate()
	add_child(transition)

	player.shoot_requested.connect(weapon_manager.attack)
	player.special_requested.connect(weapon_manager.special_attack)
	player.melee_requested.connect(weapon_manager.quick_melee)
	player.reload_requested.connect(weapon_manager.start_reload)
	player.grenade_requested.connect(weapon_manager.throw_grenade)
	player.interact_requested.connect(level_manager.use)
	player.weapon_slot_requested.connect(weapon_manager.select_slot)
	level_manager.pickup_collected.connect(_on_pickup_collected)
	level_manager.message.connect(_show_message)
	level_manager.level_completed.connect(_next_level)
	level_manager.boss_hp_changed.connect(hud.set_boss)
	level_manager.sound_requested.connect(_on_level_sound)
	level_manager.sound_loop_at_requested.connect(_on_level_sound_loop_at)
	level_manager.sound_loop_stop_requested.connect(_on_level_sound_loop_stop)
	weapon_manager.message.connect(_show_message)
	weapon_manager.changed.connect(hud.queue_redraw)
	weapon_manager.fired.connect(_on_weapon_fired)
	weapon_manager.sound_requested.connect(_on_level_sound)
	weapon_manager.sound_at_requested.connect(_on_level_sound_at)
	weapon_manager.sound_attached_requested.connect(_on_level_sound_attached)
	weapon_manager.sound_stop_requested.connect(_on_level_sound_stop)
	sol_manager.changed.connect(hud.queue_redraw)
	sol_manager.choice_finished.connect(_on_sol_choice_finished)
	sol_manager.continue_requested.connect(_on_sol_continue_requested)
	player.hp_changed.connect(_on_player_hp_changed)
	player.dash_changed.connect(_on_player_dash)
	player.weapon_cycle_requested.connect(weapon_manager.cycle_weapon)
	player.sound_requested.connect(_on_level_sound)

func _physics_process(delta: float) -> void:
	_sync_developer_night_vision()
	var dt = min(delta, 0.05)
	if sol_manager != null:
		sol_manager.tick(dt)
	player.tick(dt)
	if level_manager != null:
		level_manager.set_spider_seek_loop_paused(player.paused)
		level_manager.set_algore_audio_paused(player.paused)
	if player.paused:
		return
	weapon_manager.tick(dt)
	_check_sol_exit_proximity()
	if player.paused:
		return
	level_manager.tick(dt)
	if player.hp <= 0:
		_show_message("YOU DIED")
		_respawn_current_level()

func _on_weapon_fired(weapon_id: String) -> void:
	if weapon_id == "shotgun":
		return
	var sfx = weapon_id
	if weapon_id == "whip":
		sfx = "whip"
	audio_manager.play(sfx, 0.08)

func _on_level_sound_stop(sfx: String) -> void:
	audio_manager.stop(sfx)

func _on_level_sound_loop_at(sfx: String, loop_id: String, world_position: Vector3, volume_db_offset: float) -> void:
	audio_manager.play_loop_at(sfx, loop_id, world_position, volume_db_offset)

func _on_level_sound_loop_stop(loop_id: String) -> void:
	audio_manager.stop_loop(loop_id)

func _on_player_hp_changed(hp: int) -> void:
	if hp <= 0:
		audio_manager.play("explosion", 0.0)

func _on_player_dash(_cd: float, _total: float) -> void:
	if _cd > 0 and abs(_cd - _total) < 0.01:
		audio_manager.play("slide", 0.06)

func _on_level_sound(sfx: String) -> void:
	audio_manager.play(sfx, 0.08)

func _on_level_sound_at(sfx: String, world_position: Vector3) -> void:
	audio_manager.play_at(sfx, world_position, 0.08)

func _on_level_sound_attached(sfx: String, parent_node: Node3D, local_position: Vector3) -> void:
	audio_manager.play_attached(sfx, parent_node, local_position, 0.08)

func _load_level(index: int, keep_state: bool, record_entry_state: bool = true, force_all_weapons: bool = false) -> void:
	level_index = clamp(index, 0, GameDataScript.LEVELS.size() - 1)
	_apply_level_environment(level_index)
	sol_choice_triggered_from_proximity = false
	var developer_mode = bool(settings.get("developer_mode", false))
	if level_manager.has_method("set_developer_mode"):
		level_manager.set_developer_mode(developer_mode)
	var spawn = level_manager.load_level(level_index)
	if not keep_state:
		player.reset_spawn(spawn)
		weapon_manager.configure(GameDataScript.make_weapon_data(), player, level_manager)
	else:
		player.global_position = spawn
		player.global_position.y = level_manager.floor_height_at(spawn)
		player.vertical_velocity = 0.0
		player.grounded = true
	player.target_yaw = 0.0
	player.target_pitch = 0.0
	player.yaw = 0.0
	player.pitch = 0.0
	if GameDataScript.is_trench_map_level(level_index):
		player.target_yaw = PI
		player.yaw = PI
	_apply_developer_mode(developer_mode)
	if (developer_mode and not keep_state) or level_index == GameDataScript.LEVELS.size() - 1 or force_all_weapons:
		weapon_manager.unlock_all_weapons(true)
	var horror_level = GameDataScript.is_horror_sequence_level(level_index)
	player.set_horror_flashlight_mode(horror_level)
	weapon_manager.set_level_weapons_disabled(horror_level)
	if record_entry_state:
		level_entry_weapon_state = weapon_manager.snapshot_state()
	if sol_manager != null:
		if level_index == 0 and not keep_state:
			sol_manager.reset_run()
		sol_manager.start_level(level_index)
	var text = "TRAINING"
	if level_index == GameDataScript.LEVELS.size() - 1:
		text = "ALGORE"
	elif GameDataScript.is_trench_map_level(level_index):
		text = "LEVEL 10: MAP 1 V2"
	elif GameDataScript.is_ramp_test_level(level_index):
		text = "LEVEL 11: SLIDE RAMP"
	elif GameDataScript.is_city_prototype_level(level_index):
		text = "BRUTALIST CITY PROTOTYPE"
	elif GameDataScript.is_horror_sequence_level(level_index):
		text = "MNEMONIC SERVICE LABYRINTH"
	elif level_index > 0:
		text = "LEVEL %d" % [level_index]
	transition.play(text)

func _respawn_current_level() -> void:
	var saved_state = level_entry_weapon_state.duplicate(true)
	_load_level(level_index, false, false)
	if level_index != GameDataScript.LEVELS.size() - 1 and not saved_state.is_empty():
		weapon_manager.restore_state(saved_state)
	level_entry_weapon_state = weapon_manager.snapshot_state()

func _next_level() -> void:
	if sol_manager != null and sol_manager.should_intercept_level_complete(level_index):
		sol_choice_triggered_from_proximity = false
		player.paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		sol_manager.begin_level_end_choice(level_index)
		return
	_advance_to_next_level()

func _check_sol_exit_proximity() -> void:
	if sol_manager == null or not sol_manager.should_intercept_level_complete(level_index):
		return
	if not level_manager.has_method("is_player_near_exit") or not level_manager.is_player_near_exit(7.0, 3.5):
		return
	sol_choice_triggered_from_proximity = true
	player.paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	sol_manager.begin_level_end_choice(level_index)

func _advance_to_next_level() -> void:
	if GameDataScript.is_city_prototype_level(level_index) or GameDataScript.is_horror_sequence_level(level_index):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/ui/Menu.tscn")
		return
	if GameDataScript.is_ramp_test_level(level_index):
		level_index = GameDataScript.LEVELS.size() - 1
	else:
		level_index += 1
	if level_index >= GameDataScript.LEVELS.size():
		_show_message("VICTORY")
		_load_level(0, false)
	else:
		_load_level(level_index, true)

func _on_pickup_collected(kind: String, value: String) -> void:
	if kind == "weapon":
		var msg = weapon_manager.pickup_weapon(value)
		_show_message(msg)
		audio_manager.play("pickup", 0.06)
	elif kind == "ammo":
		var added = weapon_manager.add_general_ammo()
		_show_message("AMMO CACHE +%d" % added if added > 0 else "AMMO FULL")
		audio_manager.play("pickup", 0.06)
	elif kind == "powerup":
		player.powerups.apply_powerup(value)
		if value == "berserk":
			player.heal(35, 125)
			weapon_manager.equip("whip")
		_show_message("%s POWER-UP" % value.to_upper())
		audio_manager.play("powerup", 0.0)

func _show_message(text: String) -> void:
	hud.show_message(text)

func _on_sol_choice_finished(_choice_id: String) -> void:
	if audio_manager != null:
		audio_manager.play("key_materialized", 0.02)

func _on_sol_continue_requested() -> void:
	player.paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if sol_choice_triggered_from_proximity:
		sol_choice_triggered_from_proximity = false
		return
	_advance_to_next_level()

func _apply_developer_mode(enabled: bool) -> void:
	if player != null and player.has_method("set_developer_mode"):
		player.set_developer_mode(enabled)
	if weapon_manager != null and weapon_manager.has_method("set_developer_mode"):
		weapon_manager.set_developer_mode(enabled)
	if level_manager != null and level_manager.has_method("set_developer_mode"):
		level_manager.set_developer_mode(enabled)
