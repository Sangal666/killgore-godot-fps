extends Node3D
class_name LevelManager

const GameDataScript = preload("res://scripts/core/GameData.gd")
const GameSettingsScript = preload("res://scripts/core/GameSettings.gd")
const EnemyBaseScript = preload("res://scripts/enemies/EnemyBase.gd")
const PickupScript = preload("res://scripts/pickups/Pickup.gd")
const GibScript = preload("res://scripts/world/Gib.gd")
const TurretScript = preload("res://scripts/world/Turret.gd")
const WeaponArtFactoryScript = preload("res://scripts/core/WeaponArtFactory.gd")
const TrenchMapRuntimeScript = preload("res://scripts/world/TrenchMapRuntime.gd")
const BrutalistCityPrototypeScript = preload("res://scripts/world/BrutalistCityPrototype.gd")
const HorrorSequenceLevelScript = preload("res://scripts/world/HorrorSequenceLevel.gd")
const CombatObjectPoolScript = preload("res://scripts/world/CombatObjectPool.gd")
const WALL_HEIGHT = 5.25
const BOSS_LOW_WALL_HEIGHT = 1.55
const CEILING_HEIGHT = 18.0
const HORROR_CEILING_HEIGHT = 3.65
const NORMAL_LEVEL_ENEMY_CAP = 15
const SPIDER_SEEK_LOOP_ID = "spider_boss_seek_loop"
const SPIDER_SEEK_LOOP_PATH = "res://assets/audio/spider_seek_loop_16.wav"
const SPIDER_SEEK_AUDIBLE_DISTANCE = 30.0
const ALGORE_ATMOSPHERE1_PATH = "res://assets/audio/algore_atmosphere1.wav"
const ALGORE_PHASE2_PATH = "res://assets/audio/algore_phase2_transition.wav"
const ALGORE_PHASE2_VOICE_PATH = "res://assets/audio/algore_phase2_voice.wav"
const ALGORE_DEAD_PATH = "res://assets/audio/algore_dead.wav"
const ALGORE_MUSIC1_PATH = "res://assets/audio/algore_music1.wav"
const ALGORE_FINAL_LOOP_PATH = "res://assets/audio/algore_final_loop.wav"
const RAMP_EXPLODER_ID = "EX"
const RAMP_DRONE_ID = "DRONE"
const RAMP_SURVIVAL_DURATION = 180.0
const RAMP_DRONE_FIRST_SPAWN_TIME = 45.0
const RAMP_DRONE_SECOND_SPAWN_TIME = 90.0
const RAMP_DRONE_BARREL_INTERVAL = 0.92

signal pickup_collected(kind, value)
signal level_completed
signal message(text)
signal boss_hp_changed(current, maximum, visible)
signal sound_requested(sfx_name)
signal sound_loop_at_requested(sfx_name, loop_id, world_position, volume_db_offset)
signal sound_loop_stop_requested(loop_id)

var asset_factory
var player
var weapon_manager
var themes: Array = []
var enemy_data = {}
var game_map: Array = []
var level_index = 0
var spawn_pos = Vector3.ZERO
var exit_pos = Vector3.ZERO
var has_key = false
var developer_mode = false
var world_root: Node3D
var entity_root: Node3D
var projectile_root: Node3D
var pickups: Array = []
var enemies: Array = []
var projectiles: Array = []
var projectile_pool := {}
var grenades: Array = []
var grenade_pool := {}
var transient_mesh_pool: Array[MeshInstance3D] = []
var combat_object_pool
var cluster_spawn_queue: Array = []
var turrets: Array = []
var door_nodes = {}
var platform_areas: Array = []
var solid_areas: Array = []
var horror_solid_buckets: Dictionary = {}
var horror_solid_index_count := -1
const HORROR_SOLID_BUCKET_SIZE := 8.0
var jump_pads: Array = []
var accelerator_areas: Array = []
var ledge_areas: Array = []
var exit_light: OmniLight3D
var theme
var map_rows = 0
var map_cols = 0
var boss_spawn_timer = 0.0
var boss_spawn_points: Array = []
var respawn_pickups: Array = []
var burn_areas: Array = []
var status_fields: Array = []
var blood_splat_nodes: Array = []
var key_pending = false
var key_spawned = false
var key_spawn_pos = Vector3.ZERO
var key_spawn_color = Color.WHITE
var key_spawn_accent = Color.WHITE
var key_required_kills = 0
var level_kill_count = 0
var key_pressure_timer = 0.0
var key_pressure_spawn_points: Array = []
var weapon_art_factory = WeaponArtFactoryScript.new()
var miniboss_ids = ["0", "6", "7", "8", "9", RAMP_DRONE_ID]
var weather_quality = "medium"
var vfx_quality = "medium"
var music_volume = 0.80
var muzzle_flash_textures = {}
var weapon_locker_pos = Vector3.ZERO
var weapon_locker_active = false
var explosion_pressure = 0.0
var trench_runtime = null
var horror_runtime = null
var light_grapple_mesh: BoxMesh
var light_grapple_material: Material
var trench_exit_triggered = false
var ramp_test_active = false
var ramp_exit_triggered = false
var ramp_length = 680.0
var ramp_width = 22.0
var ramp_start_height = 34.0
var ramp_end_height = 1.0
var ramp_slide_force = 12.4
var ramp_floor_normal = Vector3.UP
var ramp_loop_wrap_z = 470.0
var ramp_loop_shift = 430.0
var ramp_survival_time = 0.0
var ramp_spawn_timer = 0.0
var ramp_exit_available = false
var ramp_drone_spawned = false
var ramp_drone = null
var ramp_drones: Array = []
var ramp_drone_barrel_timer = 0.0
var normal_enemy_spawned_count = 0
var spider_seek_loop_active = false
var spider_seek_target = null
var spider_seek_loop_player: AudioStreamPlayer
var spider_seek_stream: AudioStream
var algore_audio_player: AudioStreamPlayer
var algore_phase2_player: AudioStreamPlayer
var algore_phase2_voice_player: AudioStreamPlayer3D
var algore_phase2_started = false
var algore_music_started = false
var algore_final_loop_started = false

func configure(factory, player_node, e_data: Dictionary, theme_data: Array) -> void:
	asset_factory = factory
	player = player_node
	enemy_data = e_data
	themes = theme_data
	set_performance_settings(GameSettingsScript.load_settings())
	world_root = Node3D.new()
	world_root.name = "WorldGeometry"
	add_child(world_root)
	entity_root = Node3D.new()
	entity_root.name = "Entities"
	add_child(entity_root)
	projectile_root = Node3D.new()
	projectile_root.name = "Projectiles"
	add_child(projectile_root)
	_ensure_combat_object_pool()

func _ensure_combat_object_pool() -> void:
	if combat_object_pool == null:
		combat_object_pool = CombatObjectPoolScript.new()
	combat_object_pool.configure(projectile_root)
	# Preserve the public diagnostic references used by validation tooling.
	projectile_pool = combat_object_pool.projectile_pools
	grenade_pool = combat_object_pool.grenade_pools
	transient_mesh_pool = combat_object_pool.transient_meshes

func set_weapon_manager(manager) -> void:
	weapon_manager = manager

func set_developer_mode(enabled: bool) -> void:
	developer_mode = enabled
	if developer_mode:
		has_key = true
		key_pending = false
		key_spawned = false

func set_performance_settings(settings: Dictionary) -> void:
	weather_quality = String(settings.get("weather_quality", "medium")).to_lower()
	vfx_quality = String(settings.get("vfx_quality", "medium")).to_lower()
	music_volume = clamp(float(settings.get("music_volume", 0.80)), 0.0, 1.0)
	_apply_algore_music_volume()

func _quality_scale(value: String) -> float:
	match value.to_lower():
		"off":
			return 0.0
		"low":
			return 0.45
		"high":
			return 1.35
		_:
			return 1.0

func _weather_count(base: int) -> int:
	var quality_multiplier = _quality_scale(weather_quality)
	if quality_multiplier <= 0.0 or base <= 0:
		return 0
	return max(1, int(round(float(base) * quality_multiplier)))

func _vfx_count(base: int) -> int:
	var quality_multiplier = _quality_scale(vfx_quality)
	if quality_multiplier <= 0.0:
		return 0
	match vfx_quality.to_lower():
		"low":
			quality_multiplier *= 0.65
		"medium":
			quality_multiplier *= 0.72
		"high":
			quality_multiplier *= 0.88
	return max(1, int(round(float(base) * quality_multiplier)))

func _vfx_scale() -> float:
	var quality_multiplier = max(0.0, _quality_scale(vfx_quality))
	match vfx_quality.to_lower():
		"low":
			return quality_multiplier * 0.70
		"medium":
			return quality_multiplier * 0.82
		"high":
			return quality_multiplier * 0.92
	return quality_multiplier

func _is_boss_level() -> bool:
	return level_index == GameDataScript.LEVELS.size() - 1

func _normal_enemy_cap_reached() -> bool:
	if ramp_test_active:
		return false
	return not _is_boss_level() and normal_enemy_spawned_count >= NORMAL_LEVEL_ENEMY_CAP

func _using_trench_runtime() -> bool:
	return trench_runtime != null and is_instance_valid(trench_runtime)

func _map_wall_height() -> float:
	if GameDataScript.is_horror_sequence_level(level_index):
		return HORROR_CEILING_HEIGHT
	return BOSS_LOW_WALL_HEIGHT if _is_boss_level() else WALL_HEIGHT

func _current_ceiling_height() -> float:
	return HORROR_CEILING_HEIGHT if GameDataScript.is_horror_sequence_level(level_index) else CEILING_HEIGHT

func _theme_by_id(id: String):
	for candidate in themes:
		if candidate.id == id:
			return candidate
	return null

func _theme_for_level(index: int):
	if index == 0:
		var training_theme = _theme_by_id("training")
		if training_theme != null:
			return training_theme
	if GameDataScript.is_city_prototype_level(index):
		var city_theme = _theme_by_id("city")
		if city_theme != null:
			return city_theme
	if GameDataScript.is_horror_sequence_level(index):
		var horror_theme = _theme_by_id("horror")
		if horror_theme != null:
			return horror_theme
	if index >= GameDataScript.LEVELS.size() - 1:
		var boss_theme = _theme_by_id("boss")
		if boss_theme != null:
			return boss_theme
	var normal_themes = []
	for candidate in themes:
		if candidate.id != "training" and candidate.id != "boss" and candidate.id != "city" and candidate.id != "horror":
			normal_themes.append(candidate)
	if normal_themes.is_empty():
		return themes[0]
	return normal_themes[max(0, index - 1) % normal_themes.size()]

func load_level(index: int) -> Vector3:
	_stop_spider_seek_loop()
	_stop_algore_audio()
	level_index = index
	theme = _theme_for_level(index)
	_clear()
	game_map.clear()
	has_key = developer_mode
	door_nodes.clear()
	platform_areas.clear()
	solid_areas.clear()
	horror_solid_index_count = -1
	horror_solid_buckets.clear()
	jump_pads.clear()
	accelerator_areas.clear()
	ledge_areas.clear()
	boss_spawn_points.clear()
	respawn_pickups.clear()
	turrets.clear()
	key_pending = false
	key_spawned = false
	key_spawn_pos = Vector3.ZERO
	key_spawn_color = Color8(255, 230, 72)
	key_spawn_accent = theme.glow
	key_required_kills = 0
	level_kill_count = 0
	key_pressure_timer = randf_range(5.0, 7.0)
	key_pressure_spawn_points.clear()
	normal_enemy_spawned_count = 0
	boss_spawn_timer = randf_range(3.0, 5.0)
	weapon_locker_pos = Vector3.ZERO
	weapon_locker_active = false
	trench_exit_triggered = false
	ramp_exit_triggered = false
	ramp_exit_available = false
	if _is_boss_level():
		_start_algore_atmosphere_one()
	if GameDataScript.is_trench_map_level(index):
		return _load_trench_map_level()
	if GameDataScript.is_ramp_test_level(index):
		return _load_ramp_test_level()
	var raw = GameDataScript.make_level(index)
	var horror_fragments: Array = []
	if GameDataScript.is_horror_sequence_level(index):
		horror_runtime = HorrorSequenceLevelScript.new()
		horror_runtime.name = "MnemonicServiceLabyrinth"
		world_root.add_child(horror_runtime)
		horror_runtime.prepare(self)
		horror_runtime.fragment_collected.connect(_on_horror_fragment_collected)
		horror_runtime.sequence_completed.connect(_on_horror_sequence_completed)
	_build_floor_and_ceiling(raw)
	for row in raw.size():
		var map_row = []
		var line: String = raw[row]
		for col in line.length():
			var ch = line.substr(col, 1)
			var pos = grid_to_world(col, row)
			if ch == "#":
				map_row.append("#")
				if not GameDataScript.is_horror_sequence_level(level_index):
					_add_wall(pos, false, row, col)
			elif ch == "D":
				map_row.append("D")
				_add_wall(pos, true, row, col)
			elif ch == "X":
				map_row.append("X")
				var exit_world = pos + Vector3(0, _compact_level_upper_height() if _is_compact_interlude() else 0.0, 0)
				exit_pos = exit_world
				if not GameDataScript.is_horror_sequence_level(level_index):
					_add_exit(exit_world)
			elif ch == "P":
				spawn_pos = pos + Vector3(0, 0, 0)
				map_row.append(".")
			elif ch == "K":
				map_row.append(".")
				key_pending = true
				key_spawn_pos = pos
				key_spawn_color = Color8(255, 232, 58)
				key_spawn_accent = theme.glow
			elif ch == "F" and GameDataScript.is_horror_sequence_level(level_index):
				map_row.append(".")
				horror_fragments.append(pos)
			elif ch == "M":
				map_row.append(".")
				_add_pickup(pos, "medkit", "", Color8(236, 236, 232), Color8(220, 30, 36))
			elif ch in ["S", "A", "L", "H", "W", "N", "U", "C", "o", "p", "m", "u", "h", "k", "v"]:
				map_row.append(".")
				if _is_boss_level():
					_add_pickup(pos, "ammo", "all", GameDataScript.AMMO_PICKUPS.b.color, theme.glow)
				else:
					var lookup = {"S": "shotgun", "A": "auto", "L": "plasma", "H": "heavy", "W": "whip", "N": "railgun", "U": "incinerator", "C": "seeker", "o": "saw", "p": "cryo", "m": "marksman", "u": "toxic", "h": "grenade_launcher", "k": "shock_flux", "v": "flak"}
					var wid = lookup[ch]
					_add_pickup(pos, "weapon", wid, GameDataScript.make_weapon_data()[wid].color, theme.glow)
			elif GameDataScript.AMMO_PICKUPS.has(ch):
				map_row.append(".")
				var info = GameDataScript.AMMO_PICKUPS[ch]
				_add_pickup(pos, "ammo", "all", info.color, theme.glow)
			elif ch in ["Z", "Y", "I"]:
				map_row.append(".")
				if ch == "Z":
					_add_pickup(pos, "medkit", "", Color8(236, 236, 232), Color8(220, 30, 36))
				else:
					_add_pickup(pos, "ammo", "all", GameDataScript.AMMO_PICKUPS.b.color, theme.glow)
			elif ch in ["O", "V"]:
				map_row.append(".")
				_add_theme_decor(pos, ch)
			elif enemy_data.has(ch):
				map_row.append(".")
				_add_enemy(pos, ch)
			else:
				map_row.append(".")
		game_map.append(map_row)
	if GameDataScript.is_horror_sequence_level(level_index):
		has_key = true
		key_pending = false
		key_spawned = false
		key_required_kills = 0
		horror_runtime.build(raw, horror_fragments, exit_pos)
		_update_boss_signal()
		return spawn_pos
	if not GameDataScript.is_city_prototype_level(level_index):
		_add_platforms(raw)
		_add_compact_interlude_extras()
		_add_upper_decks(raw)
		_elevate_key_encounter()
		_add_wall_top_stalkers()
	key_required_kills = max(1, int(ceil(float(enemy_count()) * 0.90))) if key_pending and not _is_boss_level() else 0
	if level_index == GameDataScript.LEVELS.size() - 1:
		_add_boss_arena_extras()
	elif not GameDataScript.is_city_prototype_level(level_index):
		_add_spawn_weapon_pickup()
	if not GameDataScript.is_city_prototype_level(level_index):
		_add_weapon_locker()
		_add_campaign_decay_dressing()
		_add_weather_effects()
	else:
		_add_brutalist_city_prototype()
		has_key = true
	_update_boss_signal()
	return spawn_pos

func _load_trench_map_level() -> Vector3:
	game_map = [["."]]
	map_rows = 1
	map_cols = 1
	trench_runtime = TrenchMapRuntimeScript.new()
	trench_runtime.name = "Level10_Map1V2_Runtime"
	world_root.add_child(trench_runtime)
	var ok = trench_runtime.configure(asset_factory, theme, GameDataScript.TRENCH_MAP_PATH)
	if not ok:
		message.emit("MAP 1 V2 LOAD FAILED")
		return Vector3.ZERO
	spawn_pos = trench_runtime.spawn_pos
	exit_pos = trench_runtime.exit_pos
	has_key = true
	key_pending = false
	key_spawned = false
	key_required_kills = 0
	key_pressure_spawn_points.clear()
	_add_exit(exit_pos, false)
	_add_weapon_locker()
	_update_boss_signal()
	return spawn_pos

func _load_ramp_test_level() -> Vector3:
	game_map = [["."]]
	map_rows = 1
	map_cols = 1
	ramp_test_active = true
	ramp_exit_triggered = false
	ramp_survival_time = 0.0
	ramp_spawn_timer = 0.0
	ramp_exit_available = false
	ramp_drone_spawned = false
	ramp_drone = null
	ramp_drones.clear()
	ramp_drone_barrel_timer = 0.0
	var drop = ramp_start_height - ramp_end_height
	ramp_floor_normal = Vector3(0.0, ramp_length, drop).normalized()
	spawn_pos = Vector3(0.0, _ramp_floor_height_at(Vector3.ZERO) + 0.05, 3.0)
	exit_pos = Vector3(0.0, _ramp_floor_height_at(Vector3(0, 0, ramp_length)) + 0.05, ramp_length - 7.0)
	has_key = true
	key_pending = false
	key_spawned = false
	key_required_kills = 0
	key_pressure_spawn_points.clear()
	_build_ramp_test_geometry()
	_populate_ramp_test_level()
	_add_exit(exit_pos, false)
	_add_weapon_locker()
	_update_boss_signal()
	return spawn_pos

func _build_ramp_test_geometry() -> void:
	var root = Node3D.new()
	root.name = "Level11_EndlessSlideRamp"
	world_root.add_child(root)
	var floor_mat = asset_factory.make_flat_material(Color8(46, 49, 48))
	var edge_mat = asset_factory.make_flat_material(Color8(24, 26, 25))
	var amber_mat = asset_factory.make_glow_material(Color8(206, 148, 54), 0.28)
	var cyan_mat = asset_factory.make_glow_material(Color8(72, 190, 190), 0.30)
	var floor_mesh = ArrayMesh.new()
	var half_w = ramp_width * 0.5
	var verts = PackedVector3Array([
		Vector3(-half_w, ramp_start_height, 0.0),
		Vector3(half_w, ramp_start_height, 0.0),
		Vector3(half_w, ramp_end_height, ramp_length),
		Vector3(-half_w, ramp_start_height, 0.0),
		Vector3(half_w, ramp_end_height, ramp_length),
		Vector3(-half_w, ramp_end_height, ramp_length)
	])
	var uvs = PackedVector2Array([
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 28),
		Vector2(0, 0),
		Vector2(1, 28),
		Vector2(0, 28)
	])
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	floor_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var floor = MeshInstance3D.new()
	floor.name = "SlipperyConcreteRamp_Surface"
	floor.mesh = floor_mesh
	floor.material_override = floor_mat
	root.add_child(floor)
	var slope_angle = atan2(ramp_start_height - ramp_end_height, ramp_length)
	var mid_z = ramp_length * 0.5
	var mid_y = _ramp_floor_height_at(Vector3(0, 0, mid_z))
	for side in [-1.0, 1.0]:
		_ramp_add_box(root, Vector3(0.45, 2.8, ramp_length + 10.0), Vector3(side * (half_w + 0.35), mid_y + 1.25, mid_z), Vector3(rad_to_deg(slope_angle), 0, 0), edge_mat, "SideRail")
		_ramp_add_box(root, Vector3(0.12, 0.18, ramp_length), Vector3(side * (half_w - 1.25), mid_y + 0.10, mid_z), Vector3(rad_to_deg(slope_angle), 0, 0), amber_mat if side < 0 else cyan_mat, "GuidanceStrip")
	var panel_count = 28
	for i in panel_count:
		var z = 18.0 + float(i) * (ramp_length - 48.0) / float(panel_count)
		var y = _ramp_floor_height_at(Vector3(0, 0, z)) + 0.035
		_ramp_add_box(root, Vector3(ramp_width - 2.8, 0.045, 0.08), Vector3(0, y, z), Vector3(rad_to_deg(slope_angle), 0, 0), edge_mat, "ExpansionSeam")
	var lamp_count = 16
	for i in lamp_count:
		var z = 26.0 + float(i) * (ramp_length - 72.0) / float(max(1, lamp_count - 1))
		var y = _ramp_floor_height_at(Vector3(0, 0, z)) + 3.2
		var x = -half_w + 1.0 if i % 2 == 0 else half_w - 1.0
		_ramp_add_box(root, Vector3(0.18, 2.2, 0.18), Vector3(x, y - 1.0, z), Vector3(rad_to_deg(slope_angle), 0, 0), edge_mat, "LightPost")
		var lamp = OmniLight3D.new()
		lamp.name = "FadedRampLamp_%02d" % i
		lamp.light_color = Color8(230, 190, 92) if i % 3 != 0 else Color8(90, 190, 190)
		lamp.light_energy = 0.52
		lamp.omni_range = 7.0
		lamp.position = Vector3(x * 0.92, y, z)
		root.add_child(lamp)

func _populate_ramp_test_level() -> void:
	for z in [42.0, 58.0, 74.0, 92.0, 112.0, 134.0, 158.0, 184.0, 212.0, 242.0, 274.0, 308.0, 344.0, 382.0, 420.0, 462.0, 504.0, 548.0]:
		_spawn_ramp_exploder(z)
	var supplies = [
		{"z": 42.0, "x": 3.0, "kind": "weapon", "value": "auto"},
		{"z": 196.0, "x": -6.0, "kind": "ammo", "value": "all"},
		{"z": 258.0, "x": 5.0, "kind": "medkit", "value": ""},
		{"z": 334.0, "x": 6.0, "kind": "medkit", "value": ""},
		{"z": 416.0, "x": -4.5, "kind": "medkit", "value": ""},
		{"z": 488.0, "x": -6.0, "kind": "ammo", "value": "all"},
		{"z": 622.0, "x": 5.5, "kind": "medkit", "value": ""},
		{"z": 716.0, "x": -5.0, "kind": "medkit", "value": ""}
	]
	var weapon_data = GameDataScript.make_weapon_data()
	for item in supplies:
		var z = float(item.z)
		var pos = Vector3(float(item.x), _ramp_floor_height_at(Vector3(0, 0, z)), z)
		if item.kind == "weapon" and weapon_data.has(item.value):
			_add_pickup(pos, "weapon", String(item.value), weapon_data[item.value].color, theme.glow)
		elif item.kind == "ammo":
			_add_pickup(pos, "ammo", "all", GameDataScript.AMMO_PICKUPS.b.color, theme.glow)
		else:
			_add_pickup(pos, "medkit", "", Color8(236, 236, 232), Color8(220, 30, 36))

func _spawn_ramp_exploder(z_override: float = -1.0) -> void:
	if not enemy_data.has(RAMP_EXPLODER_ID):
		return
	var base_z = player.global_position.z if player != null else 0.0
	var z = z_override if z_override >= 0.0 else base_z + randf_range(38.0, 245.0)
	z = clamp(z, 12.0, ramp_length - 24.0)
	var lanes = [-8.6, -5.6, -2.7, 0.0, 2.7, 5.6, 8.6]
	var x = lanes[randi() % lanes.size()] + randf_range(-0.45, 0.45)
	var pos = Vector3(x, _ramp_floor_height_at(Vector3(0, 0, z)) + 0.05, z)
	var before = enemies.size()
	_add_enemy(pos, RAMP_EXPLODER_ID)
	if enemies.size() > before:
		var e = enemies[enemies.size() - 1]
		if is_instance_valid(e):
			e.scale *= randf_range(0.88, 1.12)

func _ramp_exploder_count() -> int:
	var count = 0
	for e in enemies:
		if is_instance_valid(e) and not e.dead and String(e.stats.id) == RAMP_EXPLODER_ID:
			count += 1
	return count

func _ensure_ramp_forward_medkits() -> void:
	if player == null:
		return
	var forward_count = 0
	for p in pickups:
		if not is_instance_valid(p) or p.kind != "medkit":
			continue
		if p.global_position.z > player.global_position.z + 18.0 and p.global_position.z < player.global_position.z + 270.0:
			forward_count += 1
	var lanes = [-7.6, -4.0, 0.0, 4.0, 7.6]
	while forward_count < 6:
		var z = clamp(player.global_position.z + randf_range(58.0, 250.0), 24.0, ramp_length - 18.0)
		var x = lanes[randi() % lanes.size()] + randf_range(-0.35, 0.35)
		var pos = Vector3(x, _ramp_floor_height_at(Vector3(0, 0, z)), z)
		_add_pickup(pos, "medkit", "", Color8(236, 236, 232), Color8(174, 64, 255))
		forward_count += 1

func _ramp_add_box(parent: Node3D, box_size: Vector3, pos: Vector3, rot_deg: Vector3, mat: Material, node_name: String) -> MeshInstance3D:
	var part = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = box_size
	part.mesh = mesh
	part.name = node_name
	part.position = pos
	part.rotation_degrees = rot_deg
	part.material_override = mat
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part

func _ramp_floor_height_at(pos: Vector3) -> float:
	var z = clamp(pos.z, 0.0, ramp_length)
	return lerp(ramp_start_height, ramp_end_height, z / ramp_length)

func _ramp_blocks_world(pos: Vector3, radius: float) -> bool:
	if pos.z < -4.0 - radius or pos.z > ramp_length + 10.0 + radius:
		return true
	var floor_y = _ramp_floor_height_at(pos)
	if pos.y > floor_y + 3.0:
		return false
	return abs(pos.x) > ramp_width * 0.5 - radius

func _ramp_wall_contact_normal(pos: Vector3, radius: float) -> Vector3:
	if pos.z < -4.0 or pos.z > ramp_length + 10.0:
		return Vector3(0, 0, -sign(pos.z - ramp_length * 0.5))
	if abs(pos.x) > ramp_width * 0.5 - radius * 1.15:
		return Vector3(-sign(pos.x), 0, 0)
	return Vector3.ZERO

func _ramp_wall_hit_along_segment(from: Vector3, to: Vector3, step_radius: float) -> Dictionary:
	var dist = from.distance_to(to)
	var steps = max(1, int(ceil(dist / 0.34)))
	var previous = from
	var previous_floor_delta = from.y - _ramp_floor_height_at(from) - step_radius
	for i in range(1, steps + 1):
		var p = from.lerp(to, float(i) / float(steps))
		if _ramp_blocks_world(p, step_radius):
			return {"hit": true, "position": p, "normal": _ramp_wall_contact_normal(p, step_radius)}
		var floor_delta = p.y - _ramp_floor_height_at(p) - step_radius
		if previous_floor_delta >= 0.0 and floor_delta <= 0.0:
			var t = previous_floor_delta / max(0.001, previous_floor_delta - floor_delta)
			var hit_pos = previous.lerp(p, clamp(t, 0.0, 1.0))
			var floor_y = _ramp_floor_height_at(hit_pos)
			return {"hit": true, "position": Vector3(hit_pos.x, floor_y + step_radius, hit_pos.z), "normal": ramp_floor_normal}
		previous = p
		previous_floor_delta = floor_delta
	var dir = (to - from).normalized()
	if _ramp_can_magnetic_grapple_floor(from, dir):
		var target_dist = clamp(dist * 0.68, 9.0, 24.0)
		var hit_pos = from + dir * target_dist
		hit_pos.x = clamp(hit_pos.x, -ramp_width * 0.5 + 0.7, ramp_width * 0.5 - 0.7)
		hit_pos.z = clamp(hit_pos.z, 2.0, ramp_length - 2.0)
		hit_pos.y = _ramp_floor_height_at(hit_pos) + step_radius
		return {
			"hit": true,
			"position": hit_pos,
			"safe_position": hit_pos + ramp_floor_normal * 0.42,
			"normal": ramp_floor_normal
		}
	return {"hit": false, "position": to, "normal": Vector3.ZERO}

func _ramp_can_magnetic_grapple_floor(from: Vector3, dir: Vector3) -> bool:
	if from.z < -2.0 or from.z > ramp_length + 4.0:
		return false
	if abs(from.x) > ramp_width * 0.5 + 1.5:
		return false
	var forward_intent = dir.z > 0.18
	var side_intent = abs(dir.x) > 0.34
	var downward_intent = dir.y < -0.04
	return forward_intent or side_intent or downward_intent

func tick(dt: float) -> void:
	explosion_pressure = max(0.0, explosion_pressure - dt * 2.4)
	if horror_runtime != null and is_instance_valid(horror_runtime):
		horror_runtime.tick(dt, player)
	if _using_trench_runtime():
		_tick_trench_exit()
	if ramp_test_active:
		_tick_ramp_loop()
		_tick_ramp_survival(dt)
		if ramp_exit_available:
			_tick_ramp_exit()
	_tick_cluster_spawn_queue(dt)
	var pickup_index := 0
	while pickup_index < pickups.size():
		var pickup = pickups[pickup_index]
		if not is_instance_valid(pickup):
			pickups.remove_at(pickup_index)
			continue
		pickup.tick()
		if pickup.kind != "weapon" and player.global_position.distance_squared_to(pickup.global_position) < 1.1025:
			_collect_pickup(pickup)
			continue
		pickup_index += 1
	for e in enemies:
		if is_instance_valid(e) and not e.dead:
			e.tick(dt, player, self)
	if ramp_test_active:
		_tick_ramp_drone(dt)
		_tick_ramp_exploder_contacts()
	var projectile_index := 0
	while projectile_index < projectiles.size():
		var projectile = projectiles[projectile_index]
		if not is_instance_valid(projectile) or not projectile.tick(dt):
			projectiles.remove_at(projectile_index)
			if is_instance_valid(projectile):
				_recycle_projectile(projectile)
			continue
		projectile_index += 1
	var grenade_index := 0
	while grenade_index < grenades.size():
		var grenade = grenades[grenade_index]
		if not is_instance_valid(grenade) or not grenade.tick(dt):
			grenades.remove_at(grenade_index)
			if is_instance_valid(grenade):
				_recycle_grenade(grenade)
			continue
		grenade_index += 1
	var turret_index := 0
	while turret_index < turrets.size():
		var turret = turrets[turret_index]
		if not is_instance_valid(turret) or not turret.tick(dt):
			turrets.remove_at(turret_index)
			if is_instance_valid(turret):
				turret.queue_free()
			continue
		turret_index += 1
	_tick_burn_areas(dt)
	_tick_status_fields(dt)
	_tick_key_spawn()
	_tick_key_pressure_spawns(dt)
	_tick_respawn_pickups(dt)
	_tick_boss_minions(dt)
	_update_boss_signal()
	_tick_spider_seek_loop()
	_tick_algore_audio()

func _on_horror_fragment_collected(current: int, total: int) -> void:
	message.emit("MEMORY FRAGMENT %d / %d" % [current, total])
	sound_requested.emit("key_materialized")

func _on_horror_sequence_completed() -> void:
	level_completed.emit()

func horror_fragment_status() -> Dictionary:
	if horror_runtime == null or not is_instance_valid(horror_runtime):
		return {"current": 0, "total": 3, "flashlight_required": false, "objective": "Recover the memory fragments"}
	return {
		"current": int(horror_runtime.fragments_collected),
		"total": 3,
		"flashlight_required": true,
		"objective": horror_runtime.objective_text()
	}

func horror_map_data() -> Dictionary:
	var fragment_positions: Array = []
	var map_exit_position = exit_pos
	var exit_open = false
	if horror_runtime != null and is_instance_valid(horror_runtime):
		map_exit_position = horror_runtime.exit_position
		exit_open = int(horror_runtime.fragments_collected) >= int(horror_runtime.FRAGMENT_TOTAL)
		for fragment in horror_runtime.fragments:
			var fragment_node = fragment.get("node")
			if not bool(fragment.get("collected", false)) and is_instance_valid(fragment_node):
				fragment_positions.append(fragment_node.global_position)
	return {
		"fragments": fragment_positions,
		"tasks": horror_runtime.map_markers() if horror_runtime != null and is_instance_valid(horror_runtime) else [],
		"monster": horror_runtime.monster_map_marker() if horror_runtime != null and is_instance_valid(horror_runtime) else {},
		"exit": map_exit_position,
		"exit_open": exit_open
	}

func _tick_trench_exit() -> void:
	if trench_exit_triggered or player == null:
		return
	if player.global_position.distance_to(exit_pos) <= 2.4 and abs(player.global_position.y - exit_pos.y) <= 2.2:
		trench_exit_triggered = true
		level_completed.emit()

func _tick_ramp_exit() -> void:
	if ramp_exit_triggered or player == null:
		return
	if player.global_position.distance_to(exit_pos) <= 3.2 and abs(player.global_position.y - exit_pos.y) <= 3.0:
		ramp_exit_triggered = true
		level_completed.emit()

func _tick_ramp_survival(dt: float) -> void:
	if ramp_exit_triggered or player == null:
		return
	if ramp_exit_available:
		return
	ramp_survival_time += dt
	if ramp_survival_time >= RAMP_SURVIVAL_DURATION:
		ramp_survival_time = RAMP_SURVIVAL_DURATION
		ramp_exit_available = true
		message.emit("EXIT OPEN")
		return
	ramp_spawn_timer -= dt
	var drone_count = _ramp_drone_count()
	var target_alive = 15 if drone_count >= 2 else (10 if drone_count >= 1 else 20)
	if ramp_spawn_timer <= 0.0:
		var missing = target_alive - _ramp_exploder_count()
		for i in min(8, max(0, missing)):
			_spawn_ramp_exploder()
		_ensure_ramp_forward_medkits()
		ramp_spawn_timer = randf_range(0.20, 0.42)
	if ramp_survival_time >= RAMP_DRONE_FIRST_SPAWN_TIME and drone_count < 1:
		_spawn_ramp_drone()
	elif ramp_survival_time >= RAMP_DRONE_SECOND_SPAWN_TIME and drone_count < 2:
		_spawn_ramp_drone()
	_cleanup_ramp_old_enemies()

func _tick_ramp_loop() -> void:
	if player == null or ramp_exit_triggered or ramp_exit_available:
		return
	if player.global_position.z < ramp_loop_wrap_z:
		return
	_shift_ramp_dynamic_world(-ramp_loop_shift)

func _shift_ramp_dynamic_world(delta_z: float) -> void:
	_shift_ramp_node(player, delta_z, false)
	for e in enemies:
		if is_instance_valid(e) and not e.dead:
			_shift_ramp_node(e, delta_z, String(e.stats.id) != RAMP_DRONE_ID)
	for p in pickups:
		if is_instance_valid(p):
			_shift_ramp_node(p, delta_z, false)
	for p in projectiles:
		if is_instance_valid(p):
			_shift_ramp_node(p, delta_z, false)
	for gr in grenades:
		if is_instance_valid(gr):
			_shift_ramp_node(gr, delta_z, false)
	for turret in turrets:
		if is_instance_valid(turret):
			_shift_ramp_node(turret, delta_z, false)
	for i in burn_areas.size():
		var burn = burn_areas[i]
		var center: Vector3 = burn["center"]
		center.z += delta_z
		burn["center"] = center
		burn_areas[i] = burn
	for i in status_fields.size():
		var field = status_fields[i]
		var center: Vector3 = field["center"]
		center.z += delta_z
		field["center"] = center
		status_fields[i] = field
	for i in cluster_spawn_queue.size():
		var queued = cluster_spawn_queue[i]
		var origin: Vector3 = queued["origin"]
		origin.z += delta_z
		queued["origin"] = origin
		cluster_spawn_queue[i] = queued
	ramp_spawn_timer = 0.0
	_ensure_ramp_forward_medkits()
	if not ramp_test_active:
		_reseed_ramp_remaining_enemies()

func _cleanup_ramp_old_enemies() -> void:
	if player == null:
		return
	var drone_count = _ramp_drone_count()
	var target_alive = 15 if drone_count >= 2 else (10 if drone_count >= 1 else 20)
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if not is_instance_valid(e) or e.dead:
			continue
		if String(e.stats.id) == RAMP_DRONE_ID:
			continue
		if drone_count > 0 and _ramp_exploder_count() > target_alive and e.global_position.z < player.global_position.z - 18.0:
			e.queue_free()
			enemies.remove_at(i)
			continue
		if e.global_position.z < player.global_position.z - 92.0 or e.global_position.z > player.global_position.z + 430.0:
			e.queue_free()
			enemies.remove_at(i)

func _tick_ramp_exploder_contacts() -> void:
	if player == null or ramp_exit_triggered:
		return
	for e in enemies:
		if not is_instance_valid(e) or e.dead or String(e.stats.id) != RAMP_EXPLODER_ID:
			continue
		var delta = e.global_position - player.global_position
		var flat_dist = Vector2(delta.x, delta.z).length()
		if flat_dist <= 0.70 and abs(delta.y) <= 1.72:
			_trigger_ramp_contact_explosion(e)
			return

func _trigger_ramp_contact_explosion(enemy) -> void:
	var center = enemy.global_position + Vector3(0, enemy.stats.height * 0.45, 0)
	explode(center, 2.15, 18, 0.0, 0.0)
	if is_instance_valid(enemy) and not enemy.dead:
		enemy.die()
	if player != null and not developer_mode:
		player.damage(38)
		player.horizontal_velocity *= 0.34
		player.slide_velocity *= 0.34
		player.momentum_intensity = min(player.momentum_intensity, 0.25)
		if player.has_method("apply_slow"):
			player.apply_slow(0.28, 2.0)

func _spawn_ramp_drone() -> void:
	ramp_drone_spawned = true
	if not enemy_data.has(RAMP_DRONE_ID) or player == null:
		return
	var pos = player.global_position + Vector3(0, 5.2, 26.0)
	pos.z += float(_ramp_drone_count()) * 8.0
	pos.x = clamp(pos.x, -ramp_width * 0.5 + 3.0, ramp_width * 0.5 - 3.0)
	pos.y = max(pos.y, _ramp_floor_height_at(pos) + 4.4)
	var before = enemies.size()
	_add_enemy(pos, RAMP_DRONE_ID)
	if enemies.size() > before:
		ramp_drone = enemies[enemies.size() - 1]
		ramp_drones.append(ramp_drone)
		ramp_drone.set_meta("barrel_timer", 0.65 + float(ramp_drones.size() - 1) * 0.35)
		message.emit("DRIFT DRONE ONLINE")

func _ramp_drone_count() -> int:
	for i in range(ramp_drones.size() - 1, -1, -1):
		var drone = ramp_drones[i]
		if not is_instance_valid(drone) or drone.dead:
			ramp_drones.remove_at(i)
	return ramp_drones.size()

func _tick_ramp_drone(dt: float) -> void:
	if player == null:
		return
	_ramp_drone_count()
	var t = Time.get_ticks_msec() * 0.001
	for idx in range(ramp_drones.size()):
		var drone = ramp_drones[idx]
		if not is_instance_valid(drone) or drone.dead:
			continue
		var desired = player.global_position
		desired.z += 24.0 + sin(t * 0.9 + float(idx)) * 4.0 + float(idx) * 7.5
		desired.x += sin(t * 2.4 + float(idx) * 1.7) * 7.2 + sin(t * 4.9 + float(idx)) * 1.6
		desired.x = clamp(desired.x, -ramp_width * 0.5 + 2.4, ramp_width * 0.5 - 2.4)
		desired.y = max(player.camera_origin().y + 1.2 + sin(t * 1.7 + float(idx)) * 0.85, _ramp_floor_height_at(desired) + 4.2)
		drone.global_position = drone.global_position.lerp(desired, clamp(dt * 4.8, 0.0, 1.0))
		drone.look_at(Vector3(player.global_position.x, drone.global_position.y, player.global_position.z), Vector3.UP)
		if ramp_exit_available:
			continue
		var timer = float(drone.get_meta("barrel_timer", 0.4)) - dt
		if timer <= 0.0:
			_fire_ramp_drone_barrel_pattern(drone)
			timer = randf_range(RAMP_DRONE_BARREL_INTERVAL * 0.75, RAMP_DRONE_BARREL_INTERVAL * 1.10)
		drone.set_meta("barrel_timer", timer)

func _fire_ramp_drone_barrel_pattern(source_drone = null) -> void:
	var roll = randf()
	if roll < 0.24:
		for offset in [-3.8, 0.0, 3.8]:
			_spawn_ramp_drone_barrel(offset, 0.0, true, source_drone)
	elif roll < 0.48:
		for i in 3:
			_spawn_ramp_drone_barrel(randf_range(-1.2, 1.2), float(i) * 0.78, true, source_drone)
	else:
		_spawn_ramp_drone_barrel(999.0, 0.0, false, source_drone)

func _spawn_ramp_drone_barrel(lane_bias: float = 999.0, forward_bias: float = 0.0, lightweight := false, source_drone = null) -> void:
	var drone = source_drone if is_instance_valid(source_drone) else ramp_drone
	if not is_instance_valid(drone) or player == null:
		return
	var lane_offsets = [-5.2, -2.4, 0.0, 2.4, 5.2]
	var target = player.global_position
	var lane = lane_bias if lane_bias < 900.0 else lane_offsets[randi() % lane_offsets.size()]
	target.x = clamp(target.x + lane + randf_range(-0.45, 0.45), -ramp_width * 0.5 + 1.8, ramp_width * 0.5 - 1.8)
	target.z += randf_range(13.0, 24.0) + forward_bias
	target.y = _ramp_floor_height_at(target) + 0.62
	var throw_dir = (target - drone.global_position).normalized()
	var origin = drone.global_position + throw_dir * 2.65 + Vector3(0.0, -0.55, 0.0)
	var dir = (target - origin).normalized()
	var velocity = dir * randf_range(13.0, 15.4) + Vector3(0.0, -2.35, 0.0)
	spawn_grenade(origin, velocity, "ramp_barrel", lightweight, 2.65)
	spawn_muzzle_flash(origin, dir, Color8(255, 170, 70), "heavy")

func _shift_ramp_node(node: Node3D, delta_z: float, snap_to_floor: bool) -> void:
	var pos = node.global_position
	var floor_clearance = max(0.05, pos.y - _ramp_floor_height_at(pos))
	pos.z += delta_z
	pos.x = clamp(pos.x, -ramp_width * 0.5 + 0.65, ramp_width * 0.5 - 0.65)
	if snap_to_floor:
		pos.y = _ramp_floor_height_at(pos) + 0.05
		if node.get("base_y") != null:
			node.set("base_y", pos.y)
	else:
		var floor_y = _ramp_floor_height_at(pos)
		pos.y = max(floor_y + floor_clearance, floor_y + 0.05)
	node.global_position = pos

func _reseed_ramp_remaining_enemies() -> void:
	if player == null:
		return
	var living = []
	for e in enemies:
		if is_instance_valid(e) and not e.dead:
			living.append(e)
	if living.is_empty():
		return
	living.sort_custom(func(a, b): return a.global_position.z < b.global_position.z)
	var lanes = [-7.2, -3.4, 0.0, 3.4, 7.2]
	var start_z = clamp(player.global_position.z + 48.0, 58.0, ramp_length - 140.0)
	var spacing = clamp(360.0 / float(max(1, living.size())), 26.0, 54.0)
	for i in living.size():
		var e = living[i]
		var target_z = start_z + float(i) * spacing
		if target_z > ramp_length - 52.0:
			target_z = 62.0 + fmod(target_z - 62.0, ramp_length - 130.0)
		var target_x = lanes[i % lanes.size()] + randf_range(-0.65, 0.65)
		e.global_position = Vector3(target_x, _ramp_floor_height_at(Vector3(0, 0, target_z)) + 0.05, target_z)
		if e.get("base_y") != null:
			e.set("base_y", e.global_position.y)

func is_player_near_exit(horizontal_radius: float = 7.0, vertical_tolerance: float = 3.5) -> bool:
	if player == null or exit_pos == Vector3.ZERO:
		return false
	var player_flat = Vector2(player.global_position.x, player.global_position.z)
	var exit_flat = Vector2(exit_pos.x, exit_pos.z)
	return player_flat.distance_to(exit_flat) <= horizontal_radius and abs(player.global_position.y - exit_pos.y) <= vertical_tolerance

func use() -> void:
	if GameDataScript.is_horror_sequence_level(level_index) and horror_runtime != null and is_instance_valid(horror_runtime):
		horror_runtime.use(player)
		return
	var weapon_pickup = nearest_weapon_pickup()
	if weapon_pickup != null:
		_collect_pickup(weapon_pickup)
		return
	if weapon_locker_active and weapon_manager != null and player.global_position.distance_to(weapon_locker_pos) <= 4.2:
		weapon_manager.open_weapon_locker()
		sound_requested.emit("pickup")
		return
	if _using_trench_runtime():
		if player.global_position.distance_to(exit_pos) <= 4.0 and abs(player.global_position.y - exit_pos.y) <= 2.4:
			level_completed.emit()
		else:
			message.emit("GET CLOSER TO EXIT")
		return
	if ramp_test_active:
		if ramp_exit_available:
			message.emit("RIDE TO EXIT")
		else:
			var remaining = max(0, int(ceil(RAMP_SURVIVAL_DURATION - ramp_survival_time)))
			message.emit("SURVIVE %d SECONDS" % remaining)
		return
	var target = player.global_position + player.aim_dir() * 3.6
	var cell = world_to_cell(target)
	var cell_value = get_cell(cell.x, cell.y)
	if cell_value == "D":
		if key_status():
			game_map[cell.y][cell.x] = "."
			var key = "%d_%d" % [cell.y, cell.x]
			if door_nodes.has(key) and is_instance_valid(door_nodes[key]):
				var d = door_nodes[key]
				var tw = create_tween()
				tw.tween_property(d, "position:y", d.position.y + _map_wall_height() + 0.25, 0.25)
				tw.tween_callback(d.queue_free)
				message.emit("DOOR OPENED")
				sound_requested.emit("door")
		else:
			message.emit("NEED KEY")
	elif cell_value == "X":
		if player.global_position.distance_to(exit_pos) > 3.4 or abs(player.global_position.y - exit_pos.y) > 1.35:
			message.emit("GET CLOSER TO EXIT")
			return
		if level_index == GameDataScript.LEVELS.size() - 1 and _boss_alive():
			message.emit("BOSS STILL LIVES")
			return
		level_completed.emit()

func nearest_weapon_pickup(radius: float = 2.15):
	var best = null
	var best_dist = radius * radius
	for p in pickups:
		if not is_instance_valid(p) or p.kind != "weapon":
			continue
		var d = player.global_position.distance_squared_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best = p
	return best

func weapon_pickup_prompt() -> String:
	if GameDataScript.is_horror_sequence_level(level_index) and horror_runtime != null and is_instance_valid(horror_runtime):
		return horror_runtime.interact_prompt(player)
	var p = nearest_weapon_pickup()
	if p == null:
		return ""
	var data = GameDataScript.make_weapon_data()
	var label = String(p.value).to_upper()
	if data.has(p.value):
		label = data[p.value].display_name
	return "E PICK UP %s" % label

func is_blocked_world(pos: Vector3, radius: float) -> bool:
	if _using_trench_runtime():
		return trench_runtime.is_blocked_world(pos, radius)
	if ramp_test_active:
		return _ramp_blocks_world(pos, radius)
	if _outside_map_bounds(pos, radius):
		return true
	if GameDataScript.is_horror_sequence_level(level_index):
		if pos.y >= HORROR_CEILING_HEIGHT - 0.10:
			return true
		var horror_checks = [
			Vector3(pos.x + radius, pos.y, pos.z + radius),
			Vector3(pos.x - radius, pos.y, pos.z + radius),
			Vector3(pos.x + radius, pos.y, pos.z - radius),
			Vector3(pos.x - radius, pos.y, pos.z - radius)
		]
		for horror_point in horror_checks:
			var horror_cell = world_to_cell(horror_point)
			if get_cell(horror_cell.x, horror_cell.y) in ["#", "D"]:
				return true
		return _solid_area_blocks(pos, radius)
	var wall_h = _map_wall_height()
	var high_cell = world_to_cell(pos)
	if _is_roofed_exit_barrier_cell(high_cell.x, high_cell.y) and pos.y < WALL_HEIGHT - 0.20:
		return true
	if pos.y >= wall_h - 0.30:
		return _solid_area_blocks(pos, radius)
	var checks = [
		Vector3(pos.x + radius, 0, pos.z + radius),
		Vector3(pos.x - radius, 0, pos.z + radius),
		Vector3(pos.x + radius, 0, pos.z - radius),
		Vector3(pos.x - radius, 0, pos.z - radius)
	]
	for p in checks:
		var cell = world_to_cell(p)
		if get_cell(cell.x, cell.y) in ["#", "D"]:
			return true
	return _solid_area_blocks(pos, radius)

func _outside_map_bounds(pos: Vector3, radius: float) -> bool:
	if map_cols <= 0 or map_rows <= 0:
		return false
	var min_x = -GameDataScript.TILE * 0.5 + radius
	var min_z = -GameDataScript.TILE * 0.5 + radius
	var max_x = (float(map_cols) - 0.5) * GameDataScript.TILE - radius
	var max_z = (float(map_rows) - 0.5) * GameDataScript.TILE - radius
	return pos.x < min_x or pos.z < min_z or pos.x > max_x or pos.z > max_z

func is_enemy_blocked_world(pos: Vector3, radius: float, current_y: float, flying: bool = false, climbing: bool = false) -> bool:
	if _using_trench_runtime():
		return false if flying else trench_runtime.is_blocked_world(Vector3(pos.x, current_y, pos.z), radius)
	if ramp_test_active:
		return false if flying else _ramp_blocks_world(Vector3(pos.x, current_y, pos.z), radius)
	var wall_h = _map_wall_height()
	if climbing and current_y >= wall_h - 0.85:
		if _outside_map_bounds(pos, radius):
			return true
		return _solid_area_blocks(pos, radius)
	if is_blocked_world(Vector3(pos.x, min(pos.y, wall_h - 0.4), pos.z), radius):
		return true
	if flying:
		return false
	for platform in platform_areas + ledge_areas:
		var center: Vector3 = platform.center
		var half: Vector2 = platform.half
		var height = float(platform.height)
		if abs(pos.x - center.x) <= half.x + radius and abs(pos.z - center.z) <= half.y + radius:
			if current_y >= height - 0.70 and current_y < height - 0.18:
				if climbing and height - current_y < 3.4:
					continue
				return true
	return false

func wall_contact_normal(pos: Vector3, radius: float) -> Vector3:
	if _using_trench_runtime():
		return trench_runtime.wall_contact_normal(pos, radius)
	if ramp_test_active:
		return _ramp_wall_contact_normal(pos, radius)
	var wall_h = _map_wall_height()
	var probes = [
		{"offset": Vector3(radius, 0, 0), "normal": Vector3(-1, 0, 0)},
		{"offset": Vector3(-radius, 0, 0), "normal": Vector3(1, 0, 0)},
		{"offset": Vector3(0, 0, radius), "normal": Vector3(0, 0, -1)},
		{"offset": Vector3(0, 0, -radius), "normal": Vector3(0, 0, 1)}
	]
	for probe in probes:
		var p = pos + probe.offset
		if p.y >= wall_h - 0.25:
			continue
		var cell = world_to_cell(p)
		if get_cell(cell.x, cell.y) in ["#", "D"]:
			return probe.normal
	for solid in solid_areas:
		var center: Vector3 = solid.center
		var half: Vector2 = solid.half
		var height = float(solid.height)
		if pos.y < height - 0.18:
			if abs(pos.z - center.z) <= half.y + radius:
				if abs(pos.x - (center.x + half.x)) <= radius:
					return Vector3(1, 0, 0)
				if abs(pos.x - (center.x - half.x)) <= radius:
					return Vector3(-1, 0, 0)
			if abs(pos.x - center.x) <= half.x + radius:
				if abs(pos.z - (center.z + half.y)) <= radius:
					return Vector3(0, 0, 1)
				if abs(pos.z - (center.z - half.y)) <= radius:
					return Vector3(0, 0, -1)
	for platform in platform_areas + ledge_areas:
		var center: Vector3 = platform.center
		var half: Vector2 = platform.half
		var top = float(platform.height)
		if pos.y > top - 0.1 and pos.y < top + 1.8:
			if abs(pos.z - center.z) <= half.y + radius:
				if abs(pos.x - (center.x + half.x)) <= radius:
					return Vector3(1, 0, 0)
				if abs(pos.x - (center.x - half.x)) <= radius:
					return Vector3(-1, 0, 0)
			if abs(pos.x - center.x) <= half.x + radius:
				if abs(pos.z - (center.z + half.y)) <= radius:
					return Vector3(0, 0, 1)
				if abs(pos.z - (center.z - half.y)) <= radius:
					return Vector3(0, 0, -1)
	return Vector3.ZERO

func floor_height_at(pos: Vector3) -> float:
	if _using_trench_runtime():
		return trench_runtime.floor_height_at(pos)
	if ramp_test_active:
		return _ramp_floor_height_at(pos)
	var height = 0.0
	var cell = world_to_cell(pos)
	var wall_h = _map_wall_height()
	if get_cell(cell.x, cell.y) in ["#", "D"] and pos.y >= wall_h - 0.70:
		height = wall_h
	for platform in platform_areas:
		var center: Vector3 = platform.center
		var half: Vector2 = platform.half
		if abs(pos.x - center.x) <= half.x and abs(pos.z - center.z) <= half.y and _can_use_surface(pos.y, float(platform.height)):
			height = max(height, float(platform.height))
	for ledge in ledge_areas:
		var center: Vector3 = ledge.center
		var half: Vector2 = ledge.half
		if abs(pos.x - center.x) <= half.x and abs(pos.z - center.z) <= half.y and _can_use_surface(pos.y, float(ledge.height)):
			height = max(height, float(ledge.height))
	return height

func ceiling_height_at(pos: Vector3, radius: float = 0.34) -> float:
	if _using_trench_runtime():
		return trench_runtime.ceiling_height_at(pos, radius)
	if ramp_test_active:
		return 120.0
	return _current_ceiling_height()

func _can_use_surface(pos_y: float, surface_y: float) -> bool:
	return pos_y >= surface_y - 0.72

func jump_boost_at(_pos: Vector3) -> float:
	return 0.0

func surface_slide_factor_at(pos: Vector3) -> float:
	if _using_trench_runtime():
		return trench_runtime.surface_slide_factor_at(pos)
	if ramp_test_active:
		return 0.88
	var cell = world_to_cell(pos)
	var factor = 0.0
	var floor_y = floor_height_at(pos)
	if floor_y > 0.25:
		factor = max(factor, 0.22)
	if _is_boss_level():
		factor = max(factor, 0.26)
	match level_index:
		1, 6:
			factor = max(factor, 0.18)
		4, 5, 7:
			factor = max(factor, 0.24)
	var panel_hash = int(cell.x * 17 + cell.y * 31 + level_index * 9)
	if posmod(panel_hash, 11) in [0, 3]:
		factor = max(factor, 0.36)
	return clamp(factor, 0.0, 0.62)

func surface_flow_at(_pos: Vector3) -> Vector3:
	if ramp_test_active:
		var slow_factor = 1.0
		if player != null and player.slow_timer > 0.0:
			slow_factor = min(slow_factor, player.slow_multiplier)
		return Vector3(0.0, 0.0, ramp_slide_force * slow_factor)
	return Vector3.ZERO

func find_enemy_in_ray(origin: Vector3, dir: Vector3, max_dist: float):
	var hit = enemy_hit_info_in_ray(origin, dir, max_dist)
	return hit.enemy if hit.has("enemy") else null

func enemy_hit_info_in_ray(origin: Vector3, dir: Vector3, max_dist: float) -> Dictionary:
	var best = {}
	var best_t = max_dist
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var info = _ray_enemy_hit_info(e, origin, dir, best_t)
		if info.has("enemy") and info.distance < best_t:
			best = info
			best_t = info.distance
	return best

func find_enemies_in_ray(origin: Vector3, dir: Vector3, max_dist: float) -> Array:
	var hits = []
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var info = _ray_enemy_hit_info(e, origin, dir, max_dist)
		if info.has("enemy"):
			hits.append(info)
	hits.sort_custom(func(a, b): return a.distance < b.distance)
	return hits

func _ray_enemy_hit_info(e, origin: Vector3, dir: Vector3, max_dist: float) -> Dictionary:
	var best = {}
	var body_points = [
		{"center": e.global_position + Vector3(0, e.stats.height * 0.50, 0), "radius": e.stats.width * 0.52 + 0.22, "head": false},
		{"center": e.global_position + Vector3(0, e.stats.height * 0.90, -e.stats.width * 0.03), "radius": e.stats.width * 0.30 + 0.14, "head": true},
		{"center": e.global_position + Vector3(0, e.stats.height * 0.20, 0), "radius": e.stats.width * 0.50 + 0.18, "head": false}
	]
	var best_t = max_dist
	for point in body_points:
		var center: Vector3 = point.center
		var to_center = center - origin
		var t = to_center.dot(dir)
		if t < 0.0 or t > best_t:
			continue
		var closest = origin + dir * t
		var radius = float(point.radius) + (0.42 if e.stats.boss else 0.0)
		if closest.distance_to(center) <= radius:
			best_t = t
			best = {"enemy": e, "distance": t, "position": closest, "headshot": bool(point.head)}
	return best

func find_enemy_in_cone(origin: Vector3, dir: Vector3, max_dist: float, min_dot: float):
	var best = null
	var best_dist = max_dist
	var flat_dir = Vector3(dir.x, 0, dir.z).normalized()
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var diff = e.global_position - origin
		var dist = diff.length()
		if dist <= 0.0 or dist > best_dist:
			continue
		var flat = Vector3(diff.x, 0, diff.z).normalized()
		if flat.dot(flat_dir) >= min_dot:
			best = e
			best_dist = dist
	return best

func find_enemies_in_cone(origin: Vector3, dir: Vector3, max_dist: float, min_dot: float) -> Array:
	var hits = []
	var flat_dir = Vector3(dir.x, 0, dir.z).normalized()
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var diff = e.global_position - origin
		var dist = diff.length()
		if dist <= 0.0 or dist > max_dist:
			continue
		var flat = Vector3(diff.x, 0, diff.z).normalized()
		var vertical_ok = abs((e.global_position.y + e.stats.height * 0.45) - (origin.y + 0.85)) <= max(2.8, e.stats.height + 0.8)
		if vertical_ok and flat.dot(flat_dir) >= min_dot:
			hits.append(e)
	hits.sort_custom(func(a, b): return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	return hits

func find_enemy_sphere(pos: Vector3, radius: float):
	for e in enemies:
		if is_instance_valid(e) and not e.dead and e.global_position.distance_to(pos) < radius + e.stats.width * 0.45:
			return e
	return null

func find_enemy_along_segment(from: Vector3, to: Vector3, radius: float):
	var best = null
	var best_t = INF
	var segment = to - from
	var len_sq = max(0.0001, segment.length_squared())
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		for center in [
			e.global_position + Vector3(0, e.stats.height * 0.48, 0),
			e.global_position + Vector3(0, e.stats.height * 0.86, 0),
			e.global_position + Vector3(0, e.stats.height * 0.18, 0)
		]:
			var t = clamp((center - from).dot(segment) / len_sq, 0.0, 1.0)
			var closest = from + segment * t
			var hit_radius = radius + e.stats.width * 0.54 + (0.42 if e.stats.boss else 0.0)
			if closest.distance_to(center) <= hit_radius and t < best_t:
				best = e
				best_t = t
	return best

func grapple_enemy_hit_info(origin: Vector3, dir: Vector3, max_dist: float, radius: float = 1.15) -> Dictionary:
	var best := {}
	var best_t := max_dist
	var normalized_dir = dir.normalized()
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var chest = e.global_position + Vector3(0, e.stats.height * 0.55, 0)
		var to_chest = chest - origin
		var t = to_chest.dot(normalized_dir)
		if t < 0.0 or t > best_t:
			continue
		var closest = origin + normalized_dir * t
		var forgiving_radius = radius + e.stats.width * 0.72 + (0.55 if e.stats.boss else 0.0)
		if closest.distance_to(chest) <= forgiving_radius:
			best_t = t
			best = {"enemy": e, "distance": t, "position": chest, "headshot": false}
	return best

func segment_hits_player(from: Vector3, to: Vector3, radius: float) -> bool:
	var center = player.global_position + Vector3(0, 0.82, 0)
	var segment = to - from
	var len_sq = max(0.0001, segment.length_squared())
	var t = clamp((center - from).dot(segment) / len_sq, 0.0, 1.0)
	var closest = from + segment * t
	return closest.distance_to(center) <= radius

func player_sweep_blocked(from_pos: Vector3, to_pos: Vector3, radius: float) -> bool:
	if _using_trench_runtime():
		return trench_runtime.player_sweep_blocked(from_pos, to_pos, radius)
	if ramp_test_active:
		return _ramp_blocks_world(to_pos, radius)
	if GameDataScript.is_horror_sequence_level(level_index):
		var distance = from_pos.distance_to(to_pos)
		var steps = max(1, int(ceil(distance / 0.24)))
		for i in range(1, steps + 1):
			var base = from_pos.lerp(to_pos, float(i) / float(steps))
			for height in [0.08, 0.82, 1.58]:
				if is_blocked_world(base + Vector3(0, height, 0), radius):
					return true
	return false

func wall_hit_along_segment(from: Vector3, to: Vector3, step_radius: float) -> Dictionary:
	if _using_trench_runtime():
		return trench_runtime.wall_hit_along_segment(from, to, step_radius)
	if ramp_test_active:
		return _ramp_wall_hit_along_segment(from, to, step_radius)
	var dist = from.distance_to(to)
	var steps = max(1, int(ceil(dist / 0.28)))
	var delta = to - from
	for i in range(1, steps + 1):
		var p = from.lerp(to, float(i) / float(steps))
		if is_blocked_world(p, step_radius):
			return {"hit": true, "position": p, "normal": _wall_normal_for_hit(from, p, delta, step_radius)}
		var floor_y = floor_height_at(p)
		if from.y >= floor_y + step_radius and p.y <= floor_y + step_radius:
			return {"hit": true, "position": Vector3(p.x, floor_y + step_radius, p.z), "normal": Vector3.UP}
		var platform_hit = _platform_hit_at_point(p, step_radius)
		if platform_hit.hit:
			return platform_hit
		var ceiling_y = _current_ceiling_height()
		if p.y >= ceiling_y - step_radius:
			return {"hit": true, "position": Vector3(p.x, ceiling_y - step_radius, p.z), "normal": Vector3.DOWN}
	return {"hit": false, "position": to, "normal": Vector3.ZERO}

func _platform_hit_at_point(pos: Vector3, radius: float) -> Dictionary:
	for platform in platform_areas + ledge_areas:
		var center: Vector3 = platform.center
		var half: Vector2 = platform.half
		var height = float(platform.height)
		if abs(pos.x - center.x) <= half.x + radius and abs(pos.z - center.z) <= half.y + radius and abs(pos.y - height) <= 0.34 + radius:
			return {"hit": true, "position": Vector3(pos.x, height + radius, pos.z), "normal": Vector3.UP}
	return {"hit": false, "position": pos, "normal": Vector3.ZERO}

func _wall_normal_for_hit(from: Vector3, hit: Vector3, delta: Vector3, step_radius: float) -> Vector3:
	var x_probe = Vector3(hit.x, from.y, from.z)
	var z_probe = Vector3(from.x, from.y, hit.z)
	if is_blocked_world(x_probe, step_radius) and abs(delta.x) > 0.001:
		return Vector3(-sign(delta.x), 0, 0)
	if is_blocked_world(z_probe, step_radius) and abs(delta.z) > 0.001:
		return Vector3(0, 0, -sign(delta.z))
	if abs(delta.x) >= abs(delta.z) and abs(delta.x) > 0.001:
		return Vector3(-sign(delta.x), 0, 0)
	if abs(delta.z) > 0.001:
		return Vector3(0, 0, -sign(delta.z))
	return (from - hit).normalized()

func rebuild_horror_solid_index() -> void:
	horror_solid_buckets.clear()
	for index in solid_areas.size():
		var solid: Dictionary = solid_areas[index]
		var center: Vector3 = solid.center
		var half: Vector2 = solid.half
		var first := Vector2i(floori((center.x-half.x)/HORROR_SOLID_BUCKET_SIZE),floori((center.z-half.y)/HORROR_SOLID_BUCKET_SIZE))
		var last := Vector2i(floori((center.x+half.x)/HORROR_SOLID_BUCKET_SIZE),floori((center.z+half.y)/HORROR_SOLID_BUCKET_SIZE))
		for z in range(first.y,last.y+1):
			for x in range(first.x,last.x+1):
				var key := Vector2i(x,z)
				if not horror_solid_buckets.has(key):
					horror_solid_buckets[key]=[]
				horror_solid_buckets[key].append(index)
	horror_solid_index_count=solid_areas.size()

func query_solid_areas(from: Vector3, to: Vector3) -> Array:
	# Broad phase only; callers keep their exact original collision tests.
	# Non-horror levels retain their dynamic solid handling unchanged.
	if not GameDataScript.is_horror_sequence_level(level_index):
		return solid_areas
	if horror_solid_index_count != solid_areas.size():
		rebuild_horror_solid_index()
	var first := Vector2i(floori(minf(from.x,to.x)/HORROR_SOLID_BUCKET_SIZE),floori(minf(from.z,to.z)/HORROR_SOLID_BUCKET_SIZE))
	var last := Vector2i(floori(maxf(from.x,to.x)/HORROR_SOLID_BUCKET_SIZE),floori(maxf(from.z,to.z)/HORROR_SOLID_BUCKET_SIZE))
	var ids: Dictionary = {}
	for z in range(first.y,last.y+1):
		for x in range(first.x,last.x+1):
			for index in horror_solid_buckets.get(Vector2i(x,z),[]):
				ids[index]=true
	var ordered := ids.keys()
	ordered.sort()
	var result: Array=[]
	for index in ordered:
		result.append(solid_areas[index])
	return result

func _solid_area_blocks(pos: Vector3, radius: float) -> bool:
	for solid in query_solid_areas(pos - Vector3(radius,0,radius), pos + Vector3(radius,0,radius)):
		var center: Vector3 = solid.center
		var half: Vector2 = solid.half
		var height = float(solid.height)
		if pos.y < height - 0.16 and abs(pos.x - center.x) <= half.x + radius and abs(pos.z - center.z) <= half.y + radius:
			return true
	return false

func _push_out_of_solid_areas(pos: Vector3, radius: float) -> Vector3:
	var resolved := pos
	# Structural boxes can meet at corners. Resolve a few times so a recovery from
	# one box cannot leave the player embedded in its neighbour.
	for _iteration in 6:
		var moved := false
		for solid in query_solid_areas(resolved - Vector3(radius,0,radius), resolved + Vector3(radius,0,radius)):
			var center: Vector3 = solid.center
			var half: Vector2 = solid.half
			var height = float(solid.height)
			if resolved.y >= height - 0.16:
				continue
			var limit_x := half.x + radius
			var limit_z := half.y + radius
			var dx := resolved.x - center.x
			var dz := resolved.z - center.z
			if absf(dx) > limit_x or absf(dz) > limit_z:
				continue
			var shifts := [
				Vector3((-limit_x - dx) - 0.002, 0.0, 0.0),
				Vector3((limit_x - dx) + 0.002, 0.0, 0.0),
				Vector3(0.0, 0.0, (-limit_z - dz) - 0.002),
				Vector3(0.0, 0.0, (limit_z - dz) + 0.002)
			]
			shifts.sort_custom(func(a: Vector3, b: Vector3): return a.length_squared() < b.length_squared())
			resolved += shifts[0]
			moved = true
			break
		if not moved:
			break
	return resolved

func damage_enemy(enemy, amount: int, source: Vector3) -> void:
	enemy.take_damage(amount, source)
	var hit_pos = enemy.global_position + Vector3(0, enemy.stats.height * randf_range(0.38, 0.66), 0)
	spawn_body_hit_fx(hit_pos, enemy.stats.color, enemy.stats.accent, amount, String(enemy.stats.sprite_key))
	var blood_count = 3 if amount <= 3 else (6 if amount < 8 else 12)
	_spawn_blood(hit_pos, blood_count, enemy.stats.color)
	sound_requested.emit("hit")

func damage_enemy_headshot(enemy, amount: int, source: Vector3) -> void:
	enemy.take_damage(amount, source, true)
	var head_pos = enemy.global_position + Vector3(0, enemy.stats.height * 0.92, 0)
	spawn_headshot_fx(head_pos, enemy.stats.accent)
	_spawn_blood(head_pos, 22, enemy.stats.color.lightened(0.18))
	sound_requested.emit("railgun")

func is_miniboss_id(id: String) -> bool:
	return id in miniboss_ids

func is_miniboss_enemy(enemy) -> bool:
	return is_instance_valid(enemy) and enemy.has_method("get") and enemy.stats != null and is_miniboss_id(String(enemy.stats.id))

func _is_compact_interlude() -> bool:
	return level_index == GameDataScript.COMPACT_INTERLUDE_LEVEL

func _compact_level_upper_height() -> float:
	return 5.35

func spawn_player_projectile(origin: Vector3, dir: Vector3, speed: float, damage: int, explosive: bool, radius: float, explosive_damage: int, color: Color, max_bounces: int = 0, split_on_impact: bool = false, visual_scale: float = 1.0, burn_on_impact: bool = false, homing: bool = false, effect_type: String = "") -> void:
	var pool_key := _projectile_pool_key("player", explosive, effect_type, color, visual_scale)
	var p = _acquire_projectile(pool_key)
	p.configure(asset_factory, color, origin, dir.normalized() * speed, explosive_damage if explosive else damage, "player", self, player, explosive, radius, max_bounces, split_on_impact, visual_scale, burn_on_impact, homing, false, effect_type, pool_key)
	projectiles.append(p)

func nearest_enemy_for_homing(pos: Vector3, max_range: float):
	var best = null
	var best_dist = max_range * max_range
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var to_enemy = e.global_position + Vector3(0, e.stats.height * 0.50, 0) - pos
		var d = to_enemy.length_squared()
		if d < best_dist:
			best_dist = d
			best = e
	return best

func aimed_enemy_for_homing(pos: Vector3, dir: Vector3, max_range: float):
	var forward = dir.normalized()
	if forward.length() <= 0.01:
		return nearest_enemy_for_homing(pos, max_range)
	var best = null
	var best_score = INF
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var center = e.global_position + Vector3(0, e.stats.height * 0.52, 0)
		var to_enemy = center - pos
		var dist = to_enemy.length()
		if dist <= 0.01 or dist > max_range:
			continue
		var dot = forward.dot(to_enemy / dist)
		if dot < 0.58:
			continue
		var lateral = (to_enemy - forward * to_enemy.dot(forward)).length()
		var score = lateral * 2.2 + dist * 0.08 - dot * 1.6
		if score < best_score:
			best_score = score
			best = e
	return best

func spawn_enemy_projectile(enemy, dir: Vector3, speed: float, damage: int) -> void:
	if ramp_test_active and is_instance_valid(enemy) and String(enemy.stats.id) == RAMP_DRONE_ID:
		return
	var explosive = String(enemy.stats.sprite_key) in ["minitank", "minibomber"]
	var radius = 4.2 if explosive else 0.0
	var slow_web = String(enemy.stats.sprite_key) == "spider"
	var boss_scale = 1.0 if enemy.stats.boss else 0.54
	var visual_scale = (0.68 if explosive else (0.40 if slow_web else 0.24)) * boss_scale
	var pool_key := _projectile_pool_key("enemy", explosive, "", enemy.stats.accent, visual_scale)
	var p = _acquire_projectile(pool_key)
	p.configure(asset_factory, enemy.stats.accent, enemy.global_position + Vector3(0, enemy.stats.height * 0.6, 0), dir.normalized() * speed, damage, "enemy", self, player, explosive, radius, 0, false, visual_scale, false, false, slow_web, "", pool_key)
	projectiles.append(p)
	sound_requested.emit("enemy_shoot")

func spawn_enemy_bomb(enemy, dir: Vector3, speed: float, damage: int) -> void:
	if ramp_test_active and is_instance_valid(enemy) and String(enemy.stats.id) == RAMP_DRONE_ID:
		return
	var origin = enemy.global_position + Vector3(0, enemy.stats.height * 0.68, 0)
	var bomb_color: Color = enemy.stats.accent.lightened(0.10)
	var visual_scale := 0.92 if enemy.stats.boss else 0.76
	var pool_key := _projectile_pool_key("enemy", true, "bomb", bomb_color, visual_scale)
	var p = _acquire_projectile(pool_key)
	p.configure(asset_factory, bomb_color, origin, dir.normalized() * speed, damage, "enemy", self, player, true, 5.25 if enemy.stats.boss else 4.35, 0, false, visual_scale, false, false, false, "", pool_key)
	projectiles.append(p)
	sound_requested.emit("heavy")

func _projectile_pool_key(owner_id: String, explosive: bool, effect_type: String, color: Color, visual_scale: float) -> String:
	_ensure_combat_object_pool()
	return combat_object_pool.projectile_key(owner_id, explosive, effect_type, color, visual_scale)

func _acquire_projectile(pool_key: String):
	_ensure_combat_object_pool()
	return combat_object_pool.acquire_projectile(pool_key)

func _recycle_projectile(projectile) -> void:
	_ensure_combat_object_pool()
	combat_object_pool.recycle_projectile(projectile)

func spawn_enemy_laser(enemy, dir: Vector3, damage: int) -> void:
	var origin = enemy.global_position + Vector3(0, enemy.stats.height * 0.72, 0)
	var end = origin + dir.normalized() * 80.0
	var wall = wall_hit_along_segment(origin, end, 0.08)
	var max_dist = origin.distance_to(wall.position) if wall.hit else 80.0
	var hit_player = segment_hits_player(origin, origin + dir.normalized() * max_dist, 0.62)
	var laser_end = player.camera_origin() if hit_player else (wall.position if wall.hit else end)
	spawn_rail_trail(origin, laser_end, enemy.stats.accent.lightened(0.24))
	spawn_impact_fx(laser_end, enemy.stats.accent)
	if hit_player:
		player.damage(damage)
		player.add_shake(0.052)
	sound_requested.emit("railgun")

func _on_enemy_phase2_started(enemy) -> void:
	if not is_instance_valid(enemy) or not enemy.stats.boss:
		return
	message.emit("ALGORE PHASE TWO")
	_start_algore_phase_two_audio(enemy)
	var picks = ["8", "6"]
	for i in picks.size():
		var angle = TAU * (float(i) / float(picks.size())) + 0.55
		var pos = enemy.global_position + Vector3(cos(angle) * 12.5, 0, sin(angle) * 12.5)
		pos.y = floor_height_at(pos)
		if enemy_data.has(picks[i]):
			_add_enemy(pos, picks[i])

func split_plasma(center: Vector3, incoming_dir: Vector3, damage: int, color: Color) -> void:
	var base = incoming_dir.normalized()
	if base.length() <= 0.01:
		base = Vector3.FORWARD
	for i in 3:
		var random_side = Vector3(randf_range(-0.85, 0.85), randf_range(0.18, 0.75), randf_range(-0.85, 0.85)).normalized()
		var dir = (-base * randf_range(0.15, 0.42) + random_side).normalized()
		spawn_player_projectile(center + dir * 0.22, dir, randf_range(11.5, 15.5), max(1, int(ceil(float(damage) * 0.56))), false, 0.0, 0, color.lightened(0.16), 2, false, 0.58, false, false, "plasma_shard")

func spawn_burning_patch(pos: Vector3, color: Color, radius: float = 1.65, duration: float = 2.65, dps: float = 5.2) -> void:
	var center = pos
	var floor_y = floor_height_at(center)
	if center.y < floor_y + 0.10:
		center.y = floor_y + 0.10
	for i in range(burn_areas.size()):
		var existing = burn_areas[i]
		var existing_center: Vector3 = existing["center"]
		if Vector2(existing_center.x - center.x, existing_center.z - center.z).length() <= radius * 0.58 and abs(existing_center.y - center.y) <= 1.4:
			existing["timer"] = max(float(existing["timer"]), duration)
			existing["tick"] = min(float(existing["tick"]), 0.05)
			burn_areas[i] = existing
			return
	if burn_areas.size() >= 28:
		burn_areas.remove_at(0)
	burn_areas.append({"center": center, "radius": radius, "timer": duration, "tick": 0.05, "dps": dps, "color": color})
	_spawn_burning_patch_visual(center, radius, duration, color)

func _tick_burn_areas(dt: float) -> void:
	for i in range(burn_areas.size() - 1, -1, -1):
		var burn = burn_areas[i]
		burn["timer"] = float(burn["timer"]) - dt
		burn["tick"] = float(burn["tick"]) - dt
		if float(burn["timer"]) <= 0.0:
			burn_areas.remove_at(i)
			continue
		if float(burn["tick"]) <= 0.0:
			burn["tick"] = 0.30
			var center: Vector3 = burn["center"]
			var radius = float(burn["radius"])
			var damage = max(1, int(ceil(float(burn["dps"]) * 0.30)))
			for e in enemies:
				if not is_instance_valid(e) or e.dead:
					continue
				var e_center = e.global_position + Vector3(0, e.stats.height * 0.42, 0)
				var horizontal = Vector2(e_center.x - center.x, e_center.z - center.z).length()
				if horizontal <= radius + e.stats.width * 0.42 and abs(e_center.y - center.y) <= max(2.2, e.stats.height + 0.5):
					e.take_damage(damage, center)
					if randf() < 0.16:
						spawn_impact_fx(e_center, burn["color"])
		burn_areas[i] = burn

func _spawn_burning_patch_visual(center: Vector3, radius: float, duration: float, color: Color) -> void:
	var disc = MeshInstance3D.new()
	var disc_mesh = CylinderMesh.new()
	disc_mesh.top_radius = radius
	disc_mesh.bottom_radius = radius * 0.78
	disc_mesh.height = 0.035
	disc_mesh.radial_segments = 18
	disc.mesh = disc_mesh
	disc.position = Vector3(center.x, floor_height_at(center) + 0.035, center.z)
	disc.material_override = asset_factory.make_glow_material(color.darkened(0.18), 0.56)
	projectile_root.add_child(disc)
	var disc_tween = create_tween()
	disc_tween.tween_property(disc, "scale", Vector3(1.12, 1.0, 1.12), 0.12)
	disc_tween.tween_interval(max(0.05, duration - 0.40))
	disc_tween.tween_property(disc, "scale", Vector3.ZERO, 0.28)
	disc_tween.tween_callback(disc.queue_free)
	var flame_count = _vfx_count(4 if explosion_pressure < 2.5 else 2)
	var flame_mesh = SphereMesh.new()
	flame_mesh.radius = 0.18
	flame_mesh.height = 0.46
	flame_mesh.radial_segments = 6
	flame_mesh.rings = 3
	var flame_mat = asset_factory.make_glow_material(color.lightened(0.20), 0.82)
	for i in flame_count:
		var flame = MeshInstance3D.new()
		flame.mesh = flame_mesh
		var angle = randf() * TAU
		var r = randf_range(0.15, radius * 0.88)
		flame.position = disc.position + Vector3(cos(angle) * r, randf_range(0.08, 0.42), sin(angle) * r)
		flame.scale = Vector3.ONE * randf_range(0.72, 1.18)
		flame.material_override = flame_mat
		projectile_root.add_child(flame)
		var tw = create_tween()
		tw.set_loops(max(1, floori(duration / 0.86)))
		tw.tween_property(flame, "position:y", flame.position.y + randf_range(0.42, 0.95), 0.42).set_trans(Tween.TRANS_SINE)
		tw.tween_property(flame, "position:y", flame.position.y, 0.40).set_trans(Tween.TRANS_SINE)
		var cleanup = create_tween()
		cleanup.tween_interval(duration + randf_range(-0.12, 0.18))
		cleanup.tween_property(flame, "scale", Vector3.ZERO, 0.18)
		cleanup.tween_callback(flame.queue_free)

func spawn_status_field(pos: Vector3, field_type: String, color: Color, radius: float = 3.0, duration: float = 3.0, power: float = 0.35) -> void:
	var center = pos
	center.y = floor_height_at(center) + 0.06
	if status_fields.size() >= 20:
		status_fields.remove_at(0)
	status_fields.append({"center": center, "radius": radius, "timer": duration, "tick": 0.08, "type": field_type, "power": power, "color": color})
	_spawn_status_field_visual(center, radius, duration, color, field_type)

func _tick_status_fields(dt: float) -> void:
	for i in range(status_fields.size() - 1, -1, -1):
		var field = status_fields[i]
		field["timer"] = float(field["timer"]) - dt
		field["tick"] = float(field["tick"]) - dt
		if float(field["timer"]) <= 0.0:
			status_fields.remove_at(i)
			continue
		if float(field["tick"]) <= 0.0:
			field["tick"] = 0.24
			var center: Vector3 = field["center"]
			var radius = float(field["radius"])
			var field_type = String(field["type"])
			for e in enemies:
				if not is_instance_valid(e) or e.dead:
					continue
				var e_center = e.global_position + Vector3(0, e.stats.height * 0.45, 0)
				var horizontal = Vector2(e_center.x - center.x, e_center.z - center.z).length()
				if horizontal > radius + e.stats.width * 0.45 or abs(e_center.y - center.y) > max(2.8, e.stats.height + 0.9):
					continue
				if field_type == "cryo":
					apply_enemy_status(e, "slow", float(field["power"]), 0.72)
					if randf() < 0.22:
						apply_enemy_status(e, "freeze", 0.0, 0.38)
				elif field_type == "shock":
					apply_enemy_status(e, "stun", 0.0, 0.26)
					if e.has_method("apply_impulse"):
						var push = e.global_position - center
						push.y = 0.15
						e.apply_impulse(push.normalized() * 2.2)
		status_fields[i] = field

func _spawn_status_field_visual(center: Vector3, radius: float, duration: float, color: Color, field_type: String) -> void:
	var disc = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.026
	mesh.radial_segments = 24
	disc.mesh = mesh
	disc.position = center
	disc.material_override = asset_factory.make_glow_material(color, 0.42 if field_type == "cryo" else 0.55)
	projectile_root.add_child(disc)
	disc.scale = Vector3(0.08, 1.0, 0.08)
	var tw = create_tween()
	tw.tween_property(disc, "scale", Vector3.ONE, 0.16)
	tw.tween_interval(max(0.05, duration - 0.42))
	tw.tween_property(disc, "scale", Vector3.ZERO, 0.24)
	tw.tween_callback(disc.queue_free)
	var bits = _vfx_count(14 if field_type == "cryo" else 18)
	for i in bits:
		var spark = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		var tall = field_type == "shock"
		s_mesh.size = Vector3(0.06, randf_range(0.16, 0.52) if tall else 0.06, 0.06)
		spark.mesh = s_mesh
		var a = randf() * TAU
		var r = randf_range(radius * 0.10, radius * 0.95)
		spark.position = center + Vector3(cos(a) * r, randf_range(0.05, 0.65), sin(a) * r)
		spark.material_override = asset_factory.make_glow_material(color.lightened(randf_range(0.0, 0.26)), 0.72)
		projectile_root.add_child(spark)
		var st = create_tween()
		st.tween_property(spark, "position:y", spark.position.y + randf_range(0.18, 0.62), randf_range(0.22, 0.44))
		st.parallel().tween_property(spark, "scale", Vector3.ZERO, randf_range(0.34, 0.62))
		st.tween_callback(spark.queue_free)

func spawn_lightning_arc(from: Vector3, to: Vector3, color: Color, branches: int = 1) -> void:
	var segment = to - from
	if segment.length() <= 0.05:
		return
	var steps = 5
	var last = from
	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		var jitter = Vector3(randf_range(-0.16, 0.16), randf_range(-0.12, 0.12), randf_range(-0.16, 0.16)) * (1.0 - abs(t - 0.5))
		var next = from.lerp(to, t) + jitter
		spawn_tracer(last, next, color.lightened(0.14))
		last = next
	for b in branches:
		var p = from.lerp(to, randf_range(0.25, 0.82))
		spawn_tracer(p, p + Vector3(randf_range(-0.8, 0.8), randf_range(-0.35, 0.65), randf_range(-0.8, 0.8)), color)

func spawn_lightning_burst(center: Vector3, radius: float, color: Color) -> void:
	for i in _vfx_count(8):
		var dir = Vector3(randf_range(-1, 1), randf_range(0.05, 0.85), randf_range(-1, 1)).normalized()
		if dir.length() <= 0.01:
			dir = Vector3.UP
		spawn_lightning_arc(center + Vector3.UP * 0.4, center + dir * randf_range(radius * 0.45, radius * 0.95), color, 1)

func spawn_grenade(origin: Vector3, velocity: Vector3, bomb_type: String = "frag", lightweight_visual: bool = false, fuse_time: float = -1.0) -> void:
	var actual_lightweight := lightweight_visual or bomb_type == "cluster_child"
	var pool_key := "%s:%s" % [bomb_type, "light" if actual_lightweight else "full"]
	var gr = _acquire_grenade(pool_key)
	gr.configure(asset_factory, origin, velocity, self, bomb_type, actual_lightweight, fuse_time, pool_key)
	grenades.append(gr)

func _acquire_grenade(pool_key: String):
	_ensure_combat_object_pool()
	return combat_object_pool.acquire_grenade(pool_key)

func _recycle_grenade(grenade) -> void:
	_ensure_combat_object_pool()
	combat_object_pool.recycle_grenade(grenade)

func _acquire_transient_mesh() -> MeshInstance3D:
	_ensure_combat_object_pool()
	return combat_object_pool.acquire_transient_mesh()

func _recycle_transient_mesh(mesh_instance) -> void:
	_ensure_combat_object_pool()
	combat_object_pool.recycle_transient_mesh(mesh_instance)

func spawn_cluster_grenades(center: Vector3, color: Color = Color8(255, 190, 72)) -> void:
	var count = randi_range(5, 7)
	for i in count:
		var a = TAU * float(i) / float(count) + randf_range(-0.18, 0.18)
		var dir = Vector3(cos(a), randf_range(0.18, 0.46), sin(a)).normalized()
		cluster_spawn_queue.append({
			"delay": float(i) * 0.026,
			"origin": center + dir * 0.35 + Vector3.UP * 0.22,
			"velocity": dir * randf_range(7.5, 10.8)
		})
	if _vfx_count(1) > 0:
		spawn_impact_fx(center + Vector3.UP * 0.25, color.lightened(0.10))

func _tick_cluster_spawn_queue(dt: float) -> void:
	if cluster_spawn_queue.is_empty():
		return
	for i in range(cluster_spawn_queue.size() - 1, -1, -1):
		var entry = cluster_spawn_queue[i]
		entry.delay = float(entry.delay) - dt
		if entry.delay <= 0.0:
			spawn_grenade(entry.origin, entry.velocity, "cluster_child", true)
			cluster_spawn_queue.remove_at(i)
		else:
			cluster_spawn_queue[i] = entry

func apply_enemy_status(enemy, status: String, power: float, duration: float) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return
	match status:
		"freeze":
			if enemy.has_method("apply_freeze"):
				enemy.apply_freeze(duration)
		"slow":
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(power, duration)
		"stun":
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(duration)

func apply_status_area(center: Vector3, radius: float, status: String, power: float, duration: float) -> void:
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var e_center = e.global_position + Vector3(0, e.stats.height * 0.45, 0)
		var horizontal = Vector2(e_center.x - center.x, e_center.z - center.z).length()
		if horizontal <= radius + e.stats.width * 0.5 and abs(e_center.y - center.y) <= max(2.5, e.stats.height + 0.8):
			apply_enemy_status(e, status, power, duration)

func place_turret_from_player() -> void:
	if player == null:
		return
	var origin = player.camera_origin()
	var dir = player.aim_dir()
	var hit = wall_hit_along_segment(origin, origin + dir * 24.0, 0.10)
	if not hit.hit:
		message.emit("NO SURFACE")
		sound_requested.emit("empty")
		return
	var turret = TurretScript.new()
	entity_root.add_child(turret)
	turret.global_position = hit.position + hit.normal.normalized() * 0.11
	turret.configure(asset_factory, self, player, hit.normal)
	turrets.append(turret)
	while turrets.size() > 4:
		var old = turrets.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	message.emit("TURRET DEPLOYED")
	sound_requested.emit("powerup")

func best_turret_target_for_enemy(enemy_pos: Vector3, player_pos: Vector3):
	var best = null
	var best_dist = min(20.0 * 20.0, enemy_pos.distance_squared_to(player_pos) * 0.92)
	for turret in turrets:
		if not is_instance_valid(turret) or turret.hp <= 0:
			continue
		var d = enemy_pos.distance_squared_to(turret.global_position)
		if d < best_dist:
			best = turret
			best_dist = d
	return best

func find_turret_along_segment(from: Vector3, to: Vector3, radius: float):
	var best = null
	var best_t = INF
	var segment = to - from
	var len_sq = max(0.0001, segment.length_squared())
	for turret in turrets:
		if not is_instance_valid(turret) or turret.hp <= 0:
			continue
		var center = turret.global_position + turret.normal * 0.38
		var t = clamp((center - from).dot(segment) / len_sq, 0.0, 1.0)
		var closest = from + segment * t
		if closest.distance_to(center) <= radius + 0.52 and t < best_t:
			best = turret
			best_t = t
	return best

func explode(center: Vector3, radius: float, damage: int, player_damage_scale: float = 1.0, enemy_damage_scale: float = 1.0) -> void:
	_spawn_explosion(center, radius)
	sound_requested.emit("explosion")
	var player_dist = player.global_position.distance_to(center)
	if player_dist < radius * 2.4:
		var shake_falloff = 1.0 - player_dist / (radius * 2.4)
		player.add_shake(0.15 * shake_falloff)
	if player_dist < radius:
		var falloff = 1.0 - player_dist / radius
		player.damage(max(1, int(damage * 5.0 * falloff * player_damage_scale)))
		player.add_shake(0.18 * falloff)
	if enemy_damage_scale > 0.0:
		for e in enemies:
			if is_instance_valid(e) and not e.dead and e.global_position.distance_to(center) < radius:
				var ef = 1.0 - e.global_position.distance_to(center) / radius
				damage_enemy(e, max(1, int(damage * 1.35 * ef * enemy_damage_scale)), center)
				var push = e.global_position - center
				if push.length() > 0.01:
					e.apply_impulse(push.normalized() * (7.6 * ef))

func _weather_kind() -> String:
	if level_index == 6:
		return "fog"
	var weather_index = max(0, level_index - 1)
	if _is_boss_level():
		weather_index = 8
	match weather_index:
		0:
			return "fog"
		1:
			return "rain"
		2:
			return "dust"
		3:
			return "storm"
		4:
			return "toxic_fog"
		5:
			return "ember"
		6:
			return "snow"
		7:
			return "blood_fog"
		_:
			return "storm"

func _add_weather_effects() -> void:
	if _weather_count(1) <= 0:
		return
	var kind = _weather_kind()
	var center = Vector3((map_cols - 1) * GameDataScript.TILE * 0.5, 0, (map_rows - 1) * GameDataScript.TILE * 0.5)
	var span = Vector2(max(12.0, map_cols * GameDataScript.TILE), max(12.0, map_rows * GameDataScript.TILE))
	match kind:
		"rain":
			_spawn_weather_rain(center, span, Color8(150, 198, 240), _weather_count(88), true)
			_spawn_weather_fog(center, span, Color(0.22, 0.34, 0.38, 0.16), _weather_count(4))
		"storm":
			_spawn_weather_rain(center, span, Color8(170, 205, 255), _weather_count(96), true)
			_spawn_weather_fog(center, span, Color(0.20, 0.18, 0.24, 0.18), _weather_count(4))
			_spawn_weather_lightning(center)
		"snow":
			_spawn_weather_snow(center, span, _weather_count(46))
			_spawn_weather_fog(center, span, Color(0.58, 0.70, 0.82, 0.14), _weather_count(4))
		"toxic_fog":
			_spawn_weather_fog(center, span, Color(0.32, 0.62, 0.24, 0.22), _weather_count(5))
		"blood_fog":
			_spawn_weather_fog(center, span, Color(0.55, 0.12, 0.16, 0.18), _weather_count(5))
		"ember":
			_spawn_weather_embers(center, span, _weather_count(70))
			_spawn_weather_fog(center, span, Color(0.55, 0.24, 0.10, 0.14), _weather_count(4))
		"dust", "fog":
			_spawn_weather_dust(center, span, _weather_count(56))
			_spawn_weather_fog(center, span, Color(0.46, 0.38, 0.28, 0.16), _weather_count(5))

func _weather_pos(center: Vector3, span: Vector2, y_min: float, y_max: float) -> Vector3:
	return center + Vector3(randf_range(-span.x * 0.48, span.x * 0.48), randf_range(y_min, y_max), randf_range(-span.y * 0.48, span.y * 0.48))

func _spawn_weather_rain(center: Vector3, span: Vector2, color: Color, count: int, angled: bool) -> void:
	var mat = asset_factory.make_glow_material(color, 0.42)
	for i in count:
		var drop = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.024, 1.36 if angled else 0.95, 0.024)
		drop.mesh = mesh
		drop.rotation_degrees = Vector3(0, 0, -16 if angled else 0)
		drop.material_override = mat
		world_root.add_child(drop)
		_cycle_weather_rain(drop, center, span, angled)

func _cycle_weather_rain(drop: MeshInstance3D, center: Vector3, span: Vector2, angled: bool) -> void:
	if not is_instance_valid(drop):
		return
	var start = _weather_pos(center, span, 8.4, CEILING_HEIGHT - 0.6)
	var fall = Vector3(-5.4 if angled else 0.0, -22.0, 1.6 if angled else 0.0)
	drop.position = start
	var tw = create_tween().bind_node(drop)
	tw.tween_property(drop, "position", start + fall, randf_range(0.20, 0.34))
	tw.tween_callback(func():
		_cycle_weather_rain(drop, center, span, angled)
	)

func _spawn_weather_snow(center: Vector3, span: Vector2, count: int) -> void:
	var mat = asset_factory.make_glow_material(Color(0.82, 0.92, 1.0, 0.42), 0.42)
	for i in count:
		var flake = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = randf_range(0.035, 0.075)
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 6
		mesh.rings = 3
		flake.mesh = mesh
		flake.position = _weather_pos(center, span, 6.0, CEILING_HEIGHT - 1.0)
		flake.material_override = mat
		world_root.add_child(flake)
		var start = flake.position
		var drift = Vector3(randf_range(-1.4, 1.4), -8.5, randf_range(-1.4, 1.4))
		var tw = create_tween().bind_node(flake)
		tw.set_loops(70)
		tw.tween_property(flake, "position", start + drift, randf_range(1.8, 3.2))
		tw.tween_callback(func():
			if is_instance_valid(flake):
				flake.position = _weather_pos(center, span, 8.0, CEILING_HEIGHT - 1.0)
		)

func _spawn_weather_embers(center: Vector3, span: Vector2, count: int) -> void:
	var mat = asset_factory.make_glow_material(Color8(255, 122, 36), 0.56)
	for i in count:
		var ember = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(randf_range(0.065, 0.115), randf_range(0.065, 0.115), randf_range(0.065, 0.115))
		ember.mesh = mesh
		ember.position = _weather_pos(center, span, 1.0, 8.5)
		ember.material_override = mat
		world_root.add_child(ember)
		var start = ember.position
		var tw = create_tween().bind_node(ember)
		tw.set_loops(70)
		tw.tween_property(ember, "position", start + Vector3(randf_range(-1.4, 1.4), randf_range(3.6, 7.2), randf_range(-1.4, 1.4)), randf_range(0.85, 1.55))
		tw.tween_callback(func():
			if is_instance_valid(ember):
				ember.position = _weather_pos(center, span, 0.8, 4.0)
		)

func _spawn_weather_dust(center: Vector3, span: Vector2, count: int) -> void:
	var mat = asset_factory.make_glow_material(Color(0.74, 0.58, 0.36, 0.34), 0.34)
	for i in count:
		var dust = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = randf_range(0.060, 0.135)
		mesh.height = mesh.radius * 1.65
		mesh.radial_segments = 6
		mesh.rings = 3
		dust.mesh = mesh
		dust.position = _weather_pos(center, span, 0.8, 6.2)
		dust.material_override = mat
		world_root.add_child(dust)
		var start = dust.position
		var tw = create_tween().bind_node(dust)
		tw.set_loops(70)
		tw.tween_property(dust, "position", start + Vector3(randf_range(-4.5, 4.5), randf_range(-0.45, 0.85), randf_range(-2.8, 2.8)), randf_range(1.3, 2.4))
		tw.tween_callback(func():
			if is_instance_valid(dust):
				dust.position = _weather_pos(center, span, 0.8, 6.2)
		)

func _spawn_weather_fog(center: Vector3, span: Vector2, color: Color, count: int) -> void:
	var mat = asset_factory.make_glow_material(color, color.a)
	for i in count:
		var fog = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.top_radius = randf_range(6.0, 14.0)
		mesh.bottom_radius = mesh.top_radius * randf_range(0.85, 1.20)
		mesh.height = 0.045
		mesh.radial_segments = 16
		fog.mesh = mesh
		fog.position = _weather_pos(center, span, 0.55, 4.8)
		fog.scale.z = randf_range(0.55, 1.35)
		fog.material_override = mat
		world_root.add_child(fog)
		var tw = create_tween().bind_node(fog)
		tw.set_loops(40)
		tw.tween_property(fog, "position", fog.position + Vector3(randf_range(-2.4, 2.4), randf_range(-0.2, 0.2), randf_range(-2.4, 2.4)), randf_range(3.0, 5.8))
		tw.tween_property(fog, "position", fog.position, randf_range(3.0, 5.8))

func _spawn_weather_lightning(center: Vector3) -> void:
	var light = OmniLight3D.new()
	light.light_color = Color8(160, 190, 255)
	light.light_energy = 0.0
	light.omni_range = max(map_cols, map_rows) * GameDataScript.TILE * 0.42
	light.position = center + Vector3(0, CEILING_HEIGHT - 2.0, 0)
	world_root.add_child(light)
	var tw = create_tween().bind_node(light)
	tw.set_loops(24)
	tw.tween_interval(2.6)
	tw.tween_property(light, "light_energy", 4.0, 0.035)
	tw.tween_property(light, "light_energy", 0.0, 0.12)

func key_status() -> bool:
	return developer_mode or has_key

func enemy_count() -> int:
	var count = 0
	for e in enemies:
		if is_instance_valid(e) and not e.dead:
			count += 1
	return count

func _build_floor_and_ceiling(raw: Array) -> void:
	var rows = raw.size()
	var cols = 0
	for line in raw:
		cols = max(cols, String(line).length())
	map_rows = rows
	map_cols = cols
	if GameDataScript.is_horror_sequence_level(level_index) and horror_runtime != null and is_instance_valid(horror_runtime):
		_build_horror_floor_and_ceiling_chunks(rows, cols)
		return
	var center = Vector3((cols - 1) * GameDataScript.TILE * 0.5, 0, (rows - 1) * GameDataScript.TILE * 0.5)
	var floor_node = MeshInstance3D.new()
	var floor_mesh = PlaneMesh.new()
	floor_mesh.size = Vector2(cols * GameDataScript.TILE, rows * GameDataScript.TILE)
	floor_node.mesh = floor_mesh
	floor_node.position = center + Vector3(0, -0.02, 0)
	floor_node.material_override = horror_runtime.floor_material if horror_runtime != null and is_instance_valid(horror_runtime) else asset_factory.make_world_material(theme, "floor")
	world_root.add_child(floor_node)
	if not GameDataScript.is_city_prototype_level(level_index):
		var ceiling = MeshInstance3D.new()
		var ceiling_mesh = PlaneMesh.new()
		ceiling_mesh.size = floor_mesh.size
		ceiling.mesh = ceiling_mesh
		ceiling.position = center + Vector3(0, _current_ceiling_height(), 0)
		ceiling.rotation_degrees.x = 180
		ceiling.material_override = horror_runtime.ceiling_material if horror_runtime != null and is_instance_valid(horror_runtime) else asset_factory.make_world_material(theme, "ceiling")
		world_root.add_child(ceiling)
	if not GameDataScript.is_horror_sequence_level(level_index):
		_add_outer_boundary(rows, cols)

func _build_horror_floor_and_ceiling_chunks(rows: int, cols: int) -> void:
	const CHUNK_CELLS = 8
	for row_start in range(0, rows, CHUNK_CELLS):
		for col_start in range(0, cols, CHUNK_CELLS):
			var chunk_rows = mini(CHUNK_CELLS, rows - row_start)
			var chunk_cols = mini(CHUNK_CELLS, cols - col_start)
			var chunk_size = Vector2(float(chunk_cols) * GameDataScript.TILE, float(chunk_rows) * GameDataScript.TILE)
			var chunk_center = Vector3(
				(float(col_start) + float(chunk_cols - 1) * 0.5) * GameDataScript.TILE,
				0.0,
				(float(row_start) + float(chunk_rows - 1) * 0.5) * GameDataScript.TILE
			)
			var floor_node = MeshInstance3D.new()
			floor_node.name = "HorrorFloor_%02d_%02d" % [floori(float(col_start) / CHUNK_CELLS), floori(float(row_start) / CHUNK_CELLS)]
			var floor_mesh = PlaneMesh.new()
			floor_mesh.size = chunk_size
			floor_node.mesh = floor_mesh
			floor_node.position = chunk_center + Vector3(0, -0.02, 0)
			floor_node.material_override = horror_runtime.floor_material
			world_root.add_child(floor_node)
			var ceiling = MeshInstance3D.new()
			ceiling.name = "HorrorCeiling_%02d_%02d" % [floori(float(col_start) / CHUNK_CELLS), floori(float(row_start) / CHUNK_CELLS)]
			var ceiling_mesh = PlaneMesh.new()
			ceiling_mesh.size = chunk_size
			ceiling.mesh = ceiling_mesh
			ceiling.position = chunk_center + Vector3(0, _current_ceiling_height(), 0)
			ceiling.rotation_degrees.x = 180.0
			ceiling.material_override = horror_runtime.ceiling_material
			world_root.add_child(ceiling)

func _add_brutalist_city_prototype() -> void:
	var city = BrutalistCityPrototypeScript.new()
	world_root.add_child(city)
	city.build()

func _add_outer_boundary(rows: int, cols: int) -> void:
	var height = CEILING_HEIGHT + 2.5
	var half_y = height * 0.5
	var width = cols * GameDataScript.TILE
	var depth = rows * GameDataScript.TILE
	var center_x = (cols - 1) * GameDataScript.TILE * 0.5
	var center_z = (rows - 1) * GameDataScript.TILE * 0.5
	var barriers = [
		{"pos": Vector3(center_x, half_y, -GameDataScript.TILE * 0.98), "size": Vector3(width + GameDataScript.TILE * 2.0, height, 0.34)},
		{"pos": Vector3(center_x, half_y, (rows - 1) * GameDataScript.TILE + GameDataScript.TILE * 0.98), "size": Vector3(width + GameDataScript.TILE * 2.0, height, 0.34)},
		{"pos": Vector3(-GameDataScript.TILE * 0.98, half_y, center_z), "size": Vector3(0.34, height, depth + GameDataScript.TILE * 2.0)},
		{"pos": Vector3((cols - 1) * GameDataScript.TILE + GameDataScript.TILE * 0.98, half_y, center_z), "size": Vector3(0.34, height, depth + GameDataScript.TILE * 2.0)}
	]
	for b in barriers:
		var wall = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = b.size
		wall.mesh = mesh
		wall.position = b.pos
		wall.material_override = asset_factory.make_world_material(theme, "wall")
		world_root.add_child(wall)

func _add_wall(pos: Vector3, door: bool, row: int, col: int) -> void:
	var wall = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	var wall_h = _map_wall_height()
	mesh.size = Vector3(GameDataScript.TILE, wall_h, GameDataScript.TILE)
	wall.mesh = mesh
	wall.position = pos + Vector3(0, wall_h * 0.5, 0)
	wall.material_override = asset_factory.make_world_material(theme, "wall")
	world_root.add_child(wall)
	if door:
		wall.material_override = asset_factory.make_world_material(theme, "door")
		wall.name = "Door_%d_%d" % [row, col]
		door_nodes["%d_%d" % [row, col]] = wall
		_add_door_frame(pos)
	else:
		_add_wall_trim(pos, row, col)

func _add_wall_trim(pos: Vector3, row: int, col: int) -> void:
	if (row + col) % 3 != 0:
		return
	var wall_h = _map_wall_height()
	var trim = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(GameDataScript.TILE * 0.72, 0.08, 0.06)
	trim.mesh = mesh
	trim.position = pos + Vector3(0, max(0.34, wall_h - 0.70), -GameDataScript.TILE * 0.51)
	trim.material_override = asset_factory.make_glow_material(theme.glow, 0.58)
	world_root.add_child(trim)

func _add_door_frame(pos: Vector3) -> void:
	var wall_h = _map_wall_height()
	for x in [-1.0, 1.0]:
		var frame = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.18, wall_h + 0.16, 0.28)
		frame.mesh = mesh
		frame.position = pos + Vector3(x * GameDataScript.TILE * 0.5, (wall_h + 0.16) * 0.5, -GameDataScript.TILE * 0.52)
		frame.material_override = asset_factory.make_glow_material(theme.glow, 0.72)
		world_root.add_child(frame)

func _add_exit(pos: Vector3, roofed: bool = true) -> void:
	var pad = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(GameDataScript.TILE * 0.72, 0.10, GameDataScript.TILE * 0.72)
	pad.mesh = mesh
	pad.position = pos + Vector3(0, 0.05, 0)
	pad.material_override = asset_factory.make_glow_material(Color8(70, 220, 118), 0.88)
	world_root.add_child(pad)
	exit_light = OmniLight3D.new()
	exit_light.light_color = Color8(70, 255, 140)
	exit_light.light_energy = 1.25
	exit_light.omni_range = 5.2
	exit_light.position = pos + Vector3(0, 1.4, 0)
	world_root.add_child(exit_light)
	if roofed and not _is_boss_level():
		_add_exit_room_roof(pos)

func _add_exit_room_roof(pos: Vector3) -> void:
	var roof = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(GameDataScript.TILE * 6.6, 0.34, GameDataScript.TILE * 6.6)
	roof.mesh = mesh
	var roof_center = pos + Vector3(-GameDataScript.TILE * 1.0, 0, 0)
	roof.position = roof_center + Vector3(0, WALL_HEIGHT + 0.18, 0)
	roof.material_override = asset_factory.make_world_material(theme, "ceiling")
	world_root.add_child(roof)
	ledge_areas.append({
		"center": roof_center,
		"half": Vector2(GameDataScript.TILE * 3.30, GameDataScript.TILE * 3.30),
		"height": WALL_HEIGHT + 0.36
	})
	for offset in [Vector3(-GameDataScript.TILE * 3.45, 0, 0), Vector3(GameDataScript.TILE * 1.45, 0, 0), Vector3(-GameDataScript.TILE, 0, -GameDataScript.TILE * 3.45), Vector3(-GameDataScript.TILE, 0, GameDataScript.TILE * 3.45)]:
		var trim = MeshInstance3D.new()
		var trim_mesh = BoxMesh.new()
		trim_mesh.size = Vector3(0.18, 0.20, GameDataScript.TILE * 6.8) if abs(offset.x) > 0.01 else Vector3(GameDataScript.TILE * 6.8, 0.20, 0.18)
		trim.mesh = trim_mesh
		trim.position = pos + offset + Vector3(0, WALL_HEIGHT + 0.42, 0)
		trim.material_override = asset_factory.make_glow_material(theme.glow, 0.48)
		world_root.add_child(trim)

func _add_pickup(pos: Vector3, kind: String, value: String, color: Color, accent: Color) -> void:
	var p = PickupScript.new()
	entity_root.add_child(p)
	p.global_position = pos
	p.configure(asset_factory, kind, value, color, accent)
	p.set_meta("spawn_pos", pos)
	p.set_meta("spawn_color", color)
	p.set_meta("spawn_accent", accent)
	pickups.append(p)
	if kind in ["medkit", "ammo"]:
		p.set_meta("respawnable", true)

func _add_spawn_weapon_pickup() -> void:
	var order = ["shotgun", "shotgun", "auto", "marksman", "seeker", "grenade_launcher", "plasma", "saw", "cryo", "shock_flux", "railgun", "toxic", "flak", "heavy", "incinerator"]
	var idx = clamp(level_index, 0, order.size() - 1)
	var wid = order[idx]
	var data = GameDataScript.make_weapon_data()
	if not data.has(wid):
		return
	var forward = Vector3(0, 0, -1)
	var pos = spawn_pos + forward * 3.0
	if is_blocked_world(pos, 0.42):
		pos = spawn_pos + Vector3(3.0, 0, 0)
	pos.y = floor_height_at(pos)
	_add_pickup(pos, "weapon", wid, data[wid].color, theme.glow)

func _add_weapon_locker() -> void:
	weapon_locker_active = true
	var forward = Vector3(0, 0, -1)
	var candidates = [
		spawn_pos + Vector3(3.0, 0, 3.0),
		spawn_pos + Vector3(-3.0, 0, 3.0),
		spawn_pos + forward * 4.2,
		spawn_pos + Vector3(4.5, 0, 0)
	]
	var pos = candidates[0]
	for candidate in candidates:
		candidate.y = floor_height_at(candidate)
		if not is_blocked_world(candidate, 0.72):
			pos = candidate
			break
	pos.y = floor_height_at(pos)
	weapon_locker_pos = pos
	var root = Node3D.new()
	root.name = "WeaponLocker"
	root.position = pos
	entity_root.add_child(root)
	var body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(1.45, 1.35, 0.78)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.72, 0)
	body.material_override = asset_factory.make_flat_material(Color8(26, 34, 38))
	root.add_child(body)
	var face = MeshInstance3D.new()
	var face_mesh = BoxMesh.new()
	face_mesh.size = Vector3(1.26, 0.72, 0.045)
	face.mesh = face_mesh
	face.position = Vector3(0, 0.86, -0.41)
	face.material_override = asset_factory.make_glow_material(theme.glow.lightened(0.12), 0.34)
	root.add_child(face)
	for i in 5:
		var slot = MeshInstance3D.new()
		var slot_mesh = BoxMesh.new()
		slot_mesh.size = Vector3(0.18, 0.40, 0.07)
		slot.mesh = slot_mesh
		slot.position = Vector3(-0.48 + i * 0.24, 0.86, -0.47)
		slot.material_override = asset_factory.make_glow_material(Color8(110, 232, 255), 0.52)
		root.add_child(slot)
	var light = OmniLight3D.new()
	light.light_color = theme.glow
	light.light_energy = 0.68
	light.omni_range = 4.5
	light.position = Vector3(0, 1.3, -0.5)
	root.add_child(light)

func _add_enemy(pos: Vector3, id: String) -> void:
	if _normal_enemy_cap_reached() and not is_miniboss_id(id):
		return
	var e = EnemyBaseScript.new()
	entity_root.add_child(e)
	e.global_position = pos
	e.configure(enemy_data[id], asset_factory)
	e.died.connect(_on_enemy_died)
	e.requested_projectile.connect(spawn_enemy_projectile)
	e.requested_bomb.connect(spawn_enemy_bomb)
	e.requested_laser.connect(spawn_enemy_laser)
	e.phase2_started.connect(_on_enemy_phase2_started)
	enemies.append(e)
	if id == "0" or String(e.stats.sprite_key) == "spider":
		spider_seek_target = e
		_play_spider_seek_loop_direct(-3.0)
	if not _is_boss_level():
		normal_enemy_spawned_count += 1

func _add_key_pickup(pos: Vector3) -> void:
	key_spawned = true
	_add_pickup(pos, "key", "K", key_spawn_color, key_spawn_accent)
	message.emit("KEY MATERIALIZED")
	sound_requested.emit("key_materialized")

func _add_theme_decor(pos: Vector3, ch: String) -> void:
	var node = MeshInstance3D.new()
	if ch == "V":
		var wall_h = _map_wall_height()
		var mesh = CylinderMesh.new()
		mesh.top_radius = 0.36
		mesh.bottom_radius = 0.46
		mesh.height = wall_h - 0.2
		node.mesh = mesh
		node.position = pos + Vector3(0, (wall_h - 0.2) * 0.5, 0)
	else:
		var mesh = BoxMesh.new()
		mesh.size = Vector3(1.25, 1.25, 1.25)
		node.mesh = mesh
		node.position = pos + Vector3(0, 0.62, 0)
	node.material_override = asset_factory.make_world_material(theme, "wall")
	world_root.add_child(node)

func _add_campaign_decay_dressing() -> void:
	if world_root == null or GameDataScript.is_trench_map_level(level_index) or GameDataScript.is_ramp_test_level(level_index):
		return
	var root = Node3D.new()
	root.name = "CampaignBrutalistDigitalDecay_%02d" % level_index
	world_root.add_child(root)
	var concrete_mat = asset_factory.make_flat_material(theme.wall_a.darkened(0.18))
	var dark_mat = asset_factory.make_flat_material(Color8(15, 17, 18))
	var metal_mat = asset_factory.make_flat_material(theme.wall_b.darkened(0.24))
	var amber_mat = asset_factory.make_glow_material(Color8(184, 132, 49), 0.58)
	var cyan_mat = asset_factory.make_glow_material(theme.glow, 0.52)
	var red_mat = asset_factory.make_glow_material(Color8(157, 48, 39), 0.44)
	var open_cells: Array = []
	for row in range(1, max(1, map_rows - 1)):
		for col in range(1, max(1, map_cols - 1)):
			if get_cell(col, row) == "." and (row * 17 + col * 11) % 7 == 0:
				open_cells.append(Vector2i(col, row))
	if open_cells.is_empty():
		for row in range(1, max(1, map_rows - 1)):
			for col in range(1, max(1, map_cols - 1)):
				if get_cell(col, row) == ".":
					open_cells.append(Vector2i(col, row))
	var max_floor_marks = min(6, open_cells.size())
	for i in max_floor_marks:
		var cell: Vector2i = open_cells[int(float(i) / max(1.0, float(max_floor_marks)) * max(0, open_cells.size() - 1))]
		var pos = grid_to_world(cell.x, cell.y)
		var stripe_size = Vector3(1.35, 0.026, 0.22) if i % 2 == 0 else Vector3(0.22, 0.026, 1.35)
		_add_decay_visual_box(root, stripe_size, pos + Vector3(0, 0.035, 0), Vector3.ZERO, cyan_mat if i % 3 != 0 else amber_mat)
		if i % 3 == 0:
			_add_decay_light(root, pos + Vector3(0, 1.18, 0), theme.glow, 0.24, 4.0)
	var wall_panels_added = 0
	for cell in open_cells:
		if wall_panels_added >= 7:
			break
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if wall_panels_added >= 7:
				break
			if get_cell(cell.x + dir.x, cell.y + dir.y) not in ["#", "D"]:
				continue
			var base = grid_to_world(cell.x, cell.y) + Vector3(dir.x, 0, dir.y) * (GameDataScript.TILE * 0.46)
			var panel_size = Vector3(0.08, 1.32, 0.88) if dir.x != 0 else Vector3(0.88, 1.32, 0.08)
			_add_decay_visual_box(root, panel_size, base + Vector3(0, 1.08, 0), Vector3.ZERO, dark_mat)
			var screen_size = Vector3(panel_size.x * 0.82, panel_size.y * 0.16, panel_size.z * 0.82)
			_add_decay_visual_box(root, screen_size, base + Vector3(0, 1.30, 0), Vector3.ZERO, cyan_mat if wall_panels_added % 4 != 0 else red_mat)
			wall_panels_added += 1
	var server_count = min(4, open_cells.size())
	for i in server_count:
		var cell: Vector2i = open_cells[posmod(i * 5 + 2, open_cells.size())]
		var offset_x = (float(posmod(i * 13 + level_index * 7, 9)) - 4.0) * 0.045
		var offset_z = (float(posmod(i * 7 + level_index * 11, 9)) - 4.0) * 0.045
		var pos = grid_to_world(cell.x, cell.y) + Vector3(offset_x, 0.46, offset_z)
		_add_decay_visual_box(root, Vector3(0.70, 0.92, 0.52), pos, Vector3(0, 90.0 * (i % 2), 0), metal_mat if i % 2 == 0 else concrete_mat)
		_add_decay_visual_box(root, Vector3(0.48, 0.055, 0.055), pos + Vector3(0, 0.20, -0.29), Vector3.ZERO, amber_mat)
	var center = Vector3((map_cols - 1) * GameDataScript.TILE * 0.5, CEILING_HEIGHT - 0.42, (map_rows - 1) * GameDataScript.TILE * 0.5)
	var span_x = max(8.0, map_cols * GameDataScript.TILE)
	var span_z = max(8.0, map_rows * GameDataScript.TILE)
	for i in 4:
		var z = center.z - span_z * 0.34 + span_z * 0.17 * i
		var cable_yaw = -2.0 + float(posmod(i * 3 + level_index, 5))
		_add_decay_visual_box(root, Vector3(span_x * 0.58, 0.035, 0.035), Vector3(center.x, center.y - float(i % 2) * 0.10, z), Vector3(0, cable_yaw, 0), dark_mat)

func _add_decay_visual_box(parent: Node3D, size: Vector3, pos: Vector3, rot_deg: Vector3, mat: Material) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot_deg
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func _add_decay_light(parent: Node3D, pos: Vector3, color: Color, energy: float, radius: float) -> void:
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = false
	light.position = pos
	parent.add_child(light)

func _add_platforms(raw: Array) -> void:
	if _is_boss_level():
		return
	var made = 0
	var target_count = min(34, 18 + level_index * 3)
	for row in range(1, raw.size() - 1):
		var line: String = raw[row]
		for col in range(1, line.length() - 1):
			if made >= target_count:
				return
			var ch = line.substr(col, 1)
			if ch != ".":
				continue
			if abs(grid_to_world(col, row).distance_to(spawn_pos)) < GameDataScript.TILE * 2.2:
				continue
				if (row * 7 + col * 5 + level_index * 3) % 11 == 0:
					var step = (row + col + level_index) % 5
					var height = [0.72, 1.28, 2.05, 2.95, 3.85][step]
					var platform_size = 0.72 if step >= 3 else (0.86 if step == 2 else 1.05)
					_add_platform(grid_to_world(col, row), height, platform_size)
				made += 1

func _add_platform(pos: Vector3, height: float, size: float = 0.82) -> void:
	var platform = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(GameDataScript.TILE * size, height, GameDataScript.TILE * size)
	platform.mesh = mesh
	platform.position = pos + Vector3(0, height * 0.5, 0)
	platform.material_override = asset_factory.make_world_material(theme, "floor")
	world_root.add_child(platform)
	var rim = MeshInstance3D.new()
	var rim_mesh = BoxMesh.new()
	rim_mesh.size = Vector3(GameDataScript.TILE * size, 0.06, GameDataScript.TILE * 0.08)
	rim.mesh = rim_mesh
	rim.position = pos + Vector3(0, height + 0.04, -GameDataScript.TILE * size * 0.5)
	rim.material_override = asset_factory.make_glow_material(theme.glow, 0.58)
	world_root.add_child(rim)
	platform_areas.append({
		"center": pos,
		"half": Vector2(GameDataScript.TILE * size * 0.5, GameDataScript.TILE * size * 0.5),
		"height": height
	})

func _add_compact_interlude_extras() -> void:
	if not _is_compact_interlude():
		return
	var h = _compact_level_upper_height()
	var mid_z = GameDataScript.TILE * 4.0
	for p in [
		Vector3(GameDataScript.TILE * 10.5, 0, mid_z),
		Vector3(GameDataScript.TILE * 14.5, 0, mid_z),
		Vector3(GameDataScript.TILE * 18.5, 0, mid_z),
		Vector3(GameDataScript.TILE * 21.0, 0, GameDataScript.TILE * 7.0)
	]:
		_add_ledge(p, h, 1.35, 1.20)
	var exit_cell = world_to_cell(exit_pos)
	var exit_base = grid_to_world(exit_cell.x, exit_cell.y)
	_add_ledge(exit_base + Vector3(-GameDataScript.TILE * 1.0, 0, 0), h, 2.3, 1.25)
	for p in [
		Vector3(GameDataScript.TILE * 12.0, h, GameDataScript.TILE * 3.0),
		Vector3(GameDataScript.TILE * 16.0, h, GameDataScript.TILE * 5.0),
		Vector3(GameDataScript.TILE * 20.0, h, GameDataScript.TILE * 4.0),
		Vector3(GameDataScript.TILE * 19.0, h, GameDataScript.TILE * 7.0)
	]:
		_add_enemy(p, ["1", "3", "4", "E"][int(p.x) % 4])

func _add_upper_decks(raw: Array) -> void:
	var made = 0
	var target_count = min(14, 5 + level_index)
	for row in range(2, raw.size() - 2):
		var line: String = raw[row]
		for col in range(2, line.length() - 2):
			if made >= target_count:
				return
			if line.substr(col, 1) != ".":
				continue
			var pos = grid_to_world(col, row)
			if pos.distance_to(spawn_pos) < GameDataScript.TILE * 3.0:
				continue
			if (row * 19 + col * 11 + level_index * 9) % 37 == 0:
				var height = (4.40 + float((made + level_index) % 3) * 1.05) if _is_boss_level() else (3.65 + float((made + level_index) % 5) * 0.92)
				var sx = 1.95 if made % 2 == 0 else 1.35
				var sz = 1.35 if made % 2 == 0 else 1.95
				_add_ledge(pos, height, sx, sz)
				made += 1

func _add_ledge(pos: Vector3, height: float, size_x: float, size_z: float) -> void:
	var deck = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(GameDataScript.TILE * size_x, 0.32, GameDataScript.TILE * size_z)
	deck.mesh = mesh
	deck.position = pos + Vector3(0, height - 0.16, 0)
	deck.material_override = asset_factory.make_world_material(theme, "floor")
	world_root.add_child(deck)
	for side in [-1.0, 1.0]:
		var rail = MeshInstance3D.new()
		var rail_mesh = BoxMesh.new()
		rail_mesh.size = Vector3(GameDataScript.TILE * size_x, 0.08, 0.12)
		rail.mesh = rail_mesh
		rail.position = pos + Vector3(0, height + 0.05, side * GameDataScript.TILE * size_z * 0.5)
		rail.material_override = asset_factory.make_glow_material(theme.glow, 0.55)
		world_root.add_child(rail)
	for side in [-1.0, 1.0]:
		var rail_x = MeshInstance3D.new()
		var rail_x_mesh = BoxMesh.new()
		rail_x_mesh.size = Vector3(0.12, 0.08, GameDataScript.TILE * size_z)
		rail_x.mesh = rail_x_mesh
		rail_x.position = pos + Vector3(side * GameDataScript.TILE * size_x * 0.5, height + 0.05, 0)
		rail_x.material_override = asset_factory.make_glow_material(theme.glow, 0.55)
		world_root.add_child(rail_x)
	ledge_areas.append({
		"center": pos,
		"half": Vector2(GameDataScript.TILE * size_x * 0.5, GameDataScript.TILE * size_z * 0.5),
		"height": height
	})

func _add_jump_pads(_raw: Array) -> void:
	pass

func _add_jump_pad(_pos: Vector3) -> void:
	pass

func _add_accelerators(_raw: Array) -> void:
	pass

func _add_accelerator(_pos: Vector3, _dir: Vector3, _force: float, _lift: float) -> void:
	pass

func accelerator_at(_pos: Vector3) -> Dictionary:
	return {}

func _elevate_key_encounter() -> void:
	if _is_boss_level() or not key_pending:
		return
	var height = 5.45 + float(level_index % 5) * 1.05
	var pos = key_spawn_pos
	_add_ledge(pos, height, 1.25, 1.25)
	key_spawn_pos = pos + Vector3(0, height + 0.72, 0)
	var approach_a = pos + Vector3(0, 0, GameDataScript.TILE * 2.55)
	var approach_b = pos - Vector3(0, 0, GameDataScript.TILE * 2.55)
	var approach_c = pos + Vector3((-2.75 if pos.x > float(map_cols) * GameDataScript.TILE * 0.50 else 2.75) * GameDataScript.TILE, 0, 0)
	_add_ledge(approach_a, max(2.9, height - 1.35), 1.35, 1.50)
	_add_ledge(approach_b, max(2.4, height - 2.35), 1.50, 1.35)
	_add_ledge(approach_c, max(3.4, height - 0.85), 1.35, 1.35)
	key_pressure_spawn_points = [approach_a, approach_b, approach_c, pos + Vector3(GameDataScript.TILE * 2.4, 0, GameDataScript.TILE * 1.4), pos + Vector3(-GameDataScript.TILE * 2.2, 0, -GameDataScript.TILE * 1.4)]
	if level_index >= 1:
		_add_enemy(approach_a + Vector3(0, height - 1.35, 0), "1")
	if level_index >= 2:
		_add_enemy(approach_b + Vector3(0, height - 2.35, 0), "3")
	if level_index >= 3:
		_add_enemy(approach_c + Vector3(0, height - 0.85, 0), "4")
	if level_index >= 5:
		_add_enemy(pos + Vector3(0, height + 2.7, -GameDataScript.TILE * 1.35), "5")

func _add_wall_top_stalkers() -> void:
	if _is_boss_level() or level_index < 3:
		return
	var made = 0
	var target = min(9, 2 + level_index)
	for row in range(1, game_map.size() - 1):
		for col in range(1, game_map[row].size() - 1):
			if made >= target:
				return
			if get_cell(col, row) != "#":
				continue
			if (row * 23 + col * 31 + level_index * 7) % 17 != 0:
				continue
			var near_floor = get_cell(col + 1, row) == "." or get_cell(col - 1, row) == "." or get_cell(col, row + 1) == "." or get_cell(col, row - 1) == "."
			if not near_floor:
				continue
			var pos = grid_to_world(col, row) + Vector3(0, _map_wall_height(), 0)
			_add_enemy(pos, "3")
			made += 1

func _add_boss_arena_extras() -> void:
	var center = Vector3((map_cols - 1) * GameDataScript.TILE * 0.5, 0, (map_rows - 1) * GameDataScript.TILE * 0.5)
	var covers = [
		Vector3(-8, 0, -6),
		Vector3(8, 0, -6),
		Vector3(-8, 0, 6),
		Vector3(8, 0, 6)
	]
	for i in covers.size():
		_add_arena_cover(center + covers[i], 0.86 + float(i % 2) * 0.22, 1.08 if i % 2 == 0 else 1.24, 0.50 if i % 2 == 0 else 0.62)
	var pillars = [
		Vector3(-24, 0, -12),
		Vector3(24, 0, -12),
		Vector3(-24, 0, 12),
		Vector3(24, 0, 12),
		Vector3(-4, 0, -20),
		Vector3(4, 0, 20)
	]
	for i in pillars.size():
		_add_arena_pillar(center + pillars[i], 0.54 + float(i % 2) * 0.16)
	var ring = [
		Vector3(-18, 0, -13),
		Vector3(18, 0, -13),
		Vector3(-18, 0, 13),
		Vector3(18, 0, 13),
		Vector3(0, 0, -17),
		Vector3(0, 0, 17),
		Vector3(-28, 0, 0),
		Vector3(28, 0, 0),
		Vector3(-10, 0, 20),
		Vector3(10, 0, -20)
	]
	for i in ring.size():
		var pos = center + ring[i]
		var height = 4.40 + float(i % 5) * 0.95
		_add_ledge(pos, height, 1.65 if i % 2 == 0 else 1.25, 1.25 if i % 2 == 0 else 1.65)
	_add_boss_supplies(center)
	for i in 8:
		var a = TAU * float(i) / 8.0
		var spawn = center + Vector3(cos(a) * 28.0, 0, sin(a) * 18.0)
		boss_spawn_points.append(spawn)

func _add_arena_cover(pos: Vector3, height: float, size_x: float, size_z: float) -> void:
	var cover = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(GameDataScript.TILE * size_x, height, GameDataScript.TILE * size_z)
	cover.mesh = mesh
	cover.position = pos + Vector3(0, height * 0.5, 0)
	cover.material_override = asset_factory.make_world_material(theme, "wall")
	world_root.add_child(cover)
	var cap = MeshInstance3D.new()
	var cap_mesh = BoxMesh.new()
	cap_mesh.size = Vector3(GameDataScript.TILE * size_x, 0.08, GameDataScript.TILE * size_z)
	cap.mesh = cap_mesh
	cap.position = pos + Vector3(0, height + 0.06, 0)
	cap.material_override = asset_factory.make_glow_material(theme.glow, 0.55)
	world_root.add_child(cap)
	platform_areas.append({
		"center": pos,
		"half": Vector2(GameDataScript.TILE * size_x * 0.5, GameDataScript.TILE * size_z * 0.5),
		"height": height
	})
	solid_areas.append({
		"center": pos,
		"half": Vector2(GameDataScript.TILE * size_x * 0.5, GameDataScript.TILE * size_z * 0.5),
		"height": height
	})

func _add_arena_pillar(pos: Vector3, size: float) -> void:
	var height = CEILING_HEIGHT - 0.55
	var pillar = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(GameDataScript.TILE * size, height, GameDataScript.TILE * size)
	pillar.mesh = mesh
	pillar.position = pos + Vector3(0, height * 0.5, 0)
	pillar.material_override = asset_factory.make_world_material(theme, "wall")
	world_root.add_child(pillar)
	for y in [2.8, 7.2, 11.6, 15.2]:
		var band = MeshInstance3D.new()
		var band_mesh = BoxMesh.new()
		band_mesh.size = Vector3(GameDataScript.TILE * size + 0.20, 0.08, GameDataScript.TILE * size + 0.20)
		band.mesh = band_mesh
		band.position = pos + Vector3(0, y, 0)
		band.material_override = asset_factory.make_glow_material(theme.glow, 0.45)
		world_root.add_child(band)
	platform_areas.append({
		"center": pos,
		"half": Vector2(GameDataScript.TILE * size * 0.5, GameDataScript.TILE * size * 0.5),
		"height": height
	})
	solid_areas.append({
		"center": pos,
		"half": Vector2(GameDataScript.TILE * size * 0.5, GameDataScript.TILE * size * 0.5),
		"height": height
	})

func _add_boss_supplies(center: Vector3) -> void:
	var ammo_color = GameDataScript.AMMO_PICKUPS.b.color
	for offset in [Vector3(-12, 0, -16), Vector3(12, 0, -16), Vector3(-20, 0, 10), Vector3(20, 0, 10)]:
		_add_pickup(center + offset, "ammo", "all", ammo_color, theme.glow)
	for offset in [Vector3(0, 0, -22), Vector3(-22, 0, -4), Vector3(22, 0, -4), Vector3(0, 0, 18)]:
		_add_pickup(center + offset, "medkit", "", Color8(236, 236, 232), Color8(220, 30, 36))

func _tick_boss_minions(dt: float) -> void:
	if level_index != GameDataScript.LEVELS.size() - 1 or not _boss_alive():
		return
	boss_spawn_timer -= dt
	if boss_spawn_timer > 0.0:
		return
	boss_spawn_timer = randf_range(4.6, 7.2)
	if enemy_count() >= 9 or boss_spawn_points.is_empty():
		return
	var pos = boss_spawn_points.pick_random()
	for i in 5:
		var cell = world_to_cell(pos)
		if get_cell(cell.x, cell.y) == "." and (player == null or player.global_position.distance_to(pos) >= 10.0):
			break
		pos = boss_spawn_points.pick_random()
	var choices = ["G", "F", "R", "J", "E", "1", "2", "3", "4"]
	_add_enemy(pos, choices.pick_random())

func _tick_key_spawn() -> void:
	if not key_pending or key_spawned or has_key or _is_boss_level():
		return
	if level_kill_count >= key_required_kills and not _miniboss_alive():
		_add_key_pickup(key_spawn_pos)

func _tick_key_pressure_spawns(dt: float) -> void:
	if _is_boss_level() or has_key or key_pressure_spawn_points.is_empty():
		return
	key_pressure_timer -= dt
	if key_pressure_timer > 0.0:
		return
	var pressure = clamp(float(level_index) / 8.0, 0.0, 1.0)
	key_pressure_timer = randf_range(6.6 - pressure * 2.8, 10.2 - pressure * 3.2)
	if _normal_enemy_cap_reached():
		return
	var pos = key_pressure_spawn_points.pick_random()
	if player != null and player.global_position.distance_to(pos) < 8.0:
		return
	var choices = ["G", "F", "R"]
	if level_index >= 2:
		choices.append_array(["1", "3"])
	if level_index >= 4:
		choices.append_array(["4", "J"])
	if level_index >= 6:
		choices.append_array(["2", "5"])
	_add_enemy(pos, choices.pick_random())

func _collect_pickup(p) -> void:
	if p.kind == "weapon" and weapon_manager != null:
		var check = weapon_manager.can_take_weapon_pickup(p.value)
		if not check.take:
			message.emit(check.message)
			return
	_schedule_pickup_respawn(p)
	pickups.erase(p)
	if p.kind == "key":
		has_key = true
		key_pending = false
		key_spawned = false
		message.emit("KEY PICKED UP")
		sound_requested.emit("pickup")
	elif p.kind == "medkit":
		player.heal(35)
		message.emit("MEDKIT +35 HP")
		sound_requested.emit("health")
	else:
		pickup_collected.emit(p.kind, p.value)
	p.queue_free()

func consume_pending_weapon_pickup(id: String) -> void:
	for p in pickups.duplicate():
		if not is_instance_valid(p):
			continue
		if p.kind == "weapon" and p.value == id and player.global_position.distance_to(p.global_position) <= 2.35:
			pickups.erase(p)
			p.queue_free()
			return

func _schedule_pickup_respawn(p) -> void:
	if p.kind not in ["medkit", "ammo"]:
		return
	if not bool(p.get_meta("respawnable", true)):
		return
	respawn_pickups.append({
		"timer": 20.0 if p.kind == "medkit" else 17.0,
		"pos": p.get_meta("spawn_pos", p.global_position),
		"kind": p.kind,
		"value": p.value,
		"color": p.get_meta("spawn_color", Color.WHITE),
		"accent": p.get_meta("spawn_accent", theme.glow)
	})

func _tick_respawn_pickups(dt: float) -> void:
	if respawn_pickups.is_empty():
		return
	var respawn_index := 0
	while respawn_index < respawn_pickups.size():
		var item: Dictionary = respawn_pickups[respawn_index]
		item.timer -= dt
		if item.timer > 0.0:
			respawn_index += 1
			continue
		respawn_pickups.remove_at(respawn_index)
		_add_pickup(item.pos, item.kind, item.value, item.color, item.accent)

func _on_enemy_died(enemy) -> void:
	level_kill_count += 1
	if enemy.stats.boss:
		_stop_algore_audio()
		_play_algore_dead_sound(enemy.global_position + Vector3(0, enemy.stats.height * 0.55, 0))
	if enemy == spider_seek_target:
		spider_seek_target = null
		_stop_spider_seek_loop()
	_spawn_enemy_gibs(enemy)
	_spawn_blood(enemy.global_position + Vector3(0, enemy.stats.height * 0.55, 0), _vfx_count(22), enemy.stats.color)
	_spawn_blood_splats(enemy.global_position, enemy.stats.color, _vfx_count(11 if not enemy.stats.boss else 20))
	_update_boss_signal()

func _miniboss_alive() -> bool:
	for e in enemies:
		if is_instance_valid(e) and not e.dead and is_miniboss_id(String(e.stats.id)):
			return true
	return false

func _spawn_enemy_gibs(enemy) -> void:
	var origin = enemy.global_position + Vector3(0, enemy.stats.height * 0.36, 0)
	var base_parts = 18 if enemy.stats.boss else 12
	var max_parts = min(base_parts, _vfx_count(base_parts))
	if max_parts <= 0:
		return
	var count = 0
	for part in enemy.parts:
		if count >= max_parts:
			break
		if not is_instance_valid(part.node):
			continue
		var gib = GibScript.new()
		gib.mesh = part.node.mesh
		gib.material_override = part.mat
		projectile_root.add_child(gib)
		gib.global_transform = part.node.global_transform
		var away = gib.global_position - origin
		if away.length() < 0.08:
			away = Vector3(randf_range(-1, 1), randf_range(0.1, 1.0), randf_range(-1, 1))
		var bone_name = String(part.get("bone", ""))
		var limb_burst = _gib_bone_velocity_bonus(bone_name, enemy)
		var vel = away.normalized() * randf_range(2.4, 6.0) + limb_burst + Vector3(randf_range(-1.9, 1.9), randf_range(1.9, 4.8), randf_range(-1.9, 1.9))
		var spin = Vector3(randf_range(-540, 540), randf_range(-540, 540), randf_range(-540, 540))
		var life = randf_range(3.8, 5.8) if enemy.stats.boss else randf_range(2.8, 4.6)
		gib.configure(self, vel, spin, life, max(0.07, enemy.stats.width * 0.055))
		count += 1

func _gib_bone_velocity_bonus(bone_name: String, enemy) -> Vector3:
	if bone_name == "":
		return Vector3.ZERO
	var basis = enemy.global_transform.basis
	var right = basis.x.normalized()
	var forward = (-basis.z).normalized()
	var side = 0.0
	if bone_name.ends_with("_l"):
		side = -1.0
	elif bone_name.ends_with("_r"):
		side = 1.0
	else:
		side = -1.0 if randf() < 0.5 else 1.0
	if bone_name == "Head":
		return Vector3.UP * randf_range(2.3, 4.2) + forward * randf_range(1.0, 2.5) + right * side * randf_range(1.1, 2.4)
	if bone_name.begins_with("hand") or bone_name.begins_with("lowerarm") or bone_name.begins_with("upperarm"):
		return right * side * randf_range(3.6, 6.3) + Vector3.UP * randf_range(1.4, 3.0) + forward * randf_range(0.8, 2.4)
	if bone_name.begins_with("thigh") or bone_name.begins_with("calf") or bone_name.begins_with("foot"):
		return right * side * randf_range(2.0, 4.4) + Vector3.UP * randf_range(0.8, 2.2) - forward * randf_range(0.5, 1.8)
	if bone_name.begins_with("spine") or bone_name == "pelvis":
		return right * side * randf_range(1.0, 2.1) + Vector3.UP * randf_range(0.8, 2.0) + forward * randf_range(0.7, 2.0)
	return Vector3.UP * randf_range(0.8, 2.0)

func _spawn_blood_splats(pos: Vector3, color: Color, amount: int) -> void:
	amount = _vfx_count(min(amount, 8))
	if amount <= 0:
		return
	var stain_color = color.darkened(0.35)
	for i in amount:
		var p = pos + Vector3(randf_range(-2.8, 2.8), 0, randf_range(-2.8, 2.8))
		var floor_y = floor_height_at(p)
		_add_horizontal_splat(Vector3(p.x, floor_y + 0.018, p.z), stain_color, randf_range(0.34, 1.05))
	for i in max(1, int(amount * 0.35)):
		var p = pos + Vector3(randf_range(-2.2, 2.2), CEILING_HEIGHT - 0.025, randf_range(-2.2, 2.2))
		_add_horizontal_splat(p, stain_color.lightened(0.08), randf_range(0.22, 0.62), true)
	for i in max(2, int(amount * 0.45)):
		_add_wall_splat_near(pos, stain_color, randf_range(0.42, 1.15))

func _add_horizontal_splat(pos: Vector3, color: Color, radius: float, ceiling := false) -> void:
	var splat = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius * randf_range(0.65, 1.25)
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.018
	mesh.radial_segments = 9
	splat.mesh = mesh
	splat.position = pos
	splat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if ceiling:
		splat.rotation_degrees.x = 180
	splat.material_override = asset_factory.make_glow_material(color, 0.42)
	world_root.add_child(splat)
	_track_blood_splat(splat)

func _add_wall_splat_near(pos: Vector3, color: Color, size: float) -> void:
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d in dirs:
		var probe = world_to_cell(pos + Vector3(d.x, 0, d.y) * GameDataScript.TILE)
		if get_cell(probe.x, probe.y) in ["#", "D"]:
			var wall_pos = grid_to_world(probe.x, probe.y)
			var splat = MeshInstance3D.new()
			var mesh = BoxMesh.new()
			if d.x != 0:
				mesh.size = Vector3(0.035, size * randf_range(0.65, 1.25), size * randf_range(0.8, 1.55))
				splat.position = wall_pos + Vector3(-d.x * GameDataScript.TILE * 0.51, randf_range(0.65, min(WALL_HEIGHT - 0.4, 3.2)), randf_range(-1.1, 1.1))
			else:
				mesh.size = Vector3(size * randf_range(0.8, 1.55), size * randf_range(0.65, 1.25), 0.035)
				splat.position = wall_pos + Vector3(randf_range(-1.1, 1.1), randf_range(0.65, min(WALL_HEIGHT - 0.4, 3.2)), -d.y * GameDataScript.TILE * 0.51)
			splat.mesh = mesh
			splat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			splat.material_override = asset_factory.make_glow_material(color, 0.48)
			world_root.add_child(splat)
			_track_blood_splat(splat)
			return

func _track_blood_splat(splat: Node3D) -> void:
	blood_splat_nodes.append(splat)
	var max_splats = 72 if vfx_quality.to_lower() == "low" else (112 if vfx_quality.to_lower() == "medium" else 160)
	while blood_splat_nodes.size() > max_splats:
		var old = blood_splat_nodes.pop_front()
		if is_instance_valid(old):
			old.queue_free()

func _spawn_blood(pos: Vector3, amount: int, color: Color = Color8(160, 8, 12)) -> void:
	amount = _vfx_count(min(amount, 10))
	if amount <= 0:
		return
	for i in amount:
		var drop = _acquire_transient_mesh()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.07, 0.07, 0.07)
		drop.mesh = mesh
		drop.position = pos + Vector3(randf_range(-0.25, 0.25), randf_range(-0.08, 0.28), randf_range(-0.25, 0.25))
		drop.material_override = asset_factory.make_glow_material(color.darkened(0.18), 0.9)
		var tween = create_tween()
		tween.tween_property(drop, "position", drop.position + Vector3(randf_range(-0.8, 0.8), -0.35, randf_range(-0.8, 0.8)), 0.35)
		tween.parallel().tween_property(drop, "scale", Vector3.ZERO, 0.35)
		tween.tween_callback(_recycle_transient_mesh.bind(drop))

func _spawn_explosion(pos: Vector3, radius: float) -> void:
	var floor_y = floor_height_at(pos)
	var base_pos = Vector3(pos.x, max(pos.y, floor_y + 0.08), pos.z)
	var vfx_scale = _vfx_scale()
	explosion_pressure = min(8.0, explosion_pressure + clamp(radius / 4.0, 0.65, 2.2))
	var pressure_factor = clamp((explosion_pressure - 1.0) / 5.0, 0.0, 1.0)
	var ring_count = min(_vfx_count(2), 2)
	for ring_index in ring_count:
		var ring = MeshInstance3D.new()
		var ring_mesh = CylinderMesh.new()
		ring_mesh.top_radius = 0.34 + ring_index * 0.18
		ring_mesh.bottom_radius = ring_mesh.top_radius
		ring_mesh.height = 0.035
		ring_mesh.radial_segments = 12
		ring.mesh = ring_mesh
		ring.position = base_pos + Vector3(0, 0.04 + ring_index * 0.06, 0)
		var ring_color = Color8(255, 220, 82) if ring_index == 0 else (Color8(255, 118, 36) if ring_index == 1 else Color8(160, 56, 34))
		ring.material_override = asset_factory.make_glow_material(ring_color, 0.86 - ring_index * 0.16)
		projectile_root.add_child(ring)
		var rt = create_tween()
		ring.scale = Vector3(0.08, 1.0, 0.08)
		rt.tween_property(ring, "scale", Vector3(radius * (0.72 + ring_index * 0.18), 1.0, radius * (0.72 + ring_index * 0.18)), 0.16 + ring_index * 0.035).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		rt.tween_property(ring, "scale", Vector3(radius * (0.90 + ring_index * 0.22), 0.2, radius * (0.90 + ring_index * 0.22)), 0.16)
		rt.tween_callback(ring.queue_free)
	var blast = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	blast.mesh = mesh
	blast.position = base_pos + Vector3(0, 0.78, 0)
	blast.material_override = asset_factory.make_glow_material(Color8(255, 146, 42), 0.46)
	projectile_root.add_child(blast)
	var core = MeshInstance3D.new()
	var core_mesh = SphereMesh.new()
	core_mesh.radius = radius * 0.42
	core_mesh.height = radius * 0.84
	core_mesh.radial_segments = 12
	core_mesh.rings = 6
	core.mesh = core_mesh
	core.position = base_pos + Vector3(0, 0.75, 0)
	core.material_override = asset_factory.make_glow_material(Color8(255, 240, 156), 1.05)
	projectile_root.add_child(core)
	var light: OmniLight3D = null
	if pressure_factor < 0.72 and vfx_quality.to_lower() != "low":
		light = OmniLight3D.new()
		light.light_color = Color8(255, 154, 58)
		light.light_energy = 5.8 * vfx_scale
		light.omni_range = radius * 2.05
		light.position = base_pos + Vector3(0, 0.8, 0)
		projectile_root.add_child(light)
	var tween = create_tween()
	blast.scale = Vector3(0.08, 0.08, 0.08)
	tween.tween_property(blast, "scale", Vector3.ONE, 0.10)
	tween.tween_property(blast, "scale", Vector3.ZERO, 0.26)
	tween.tween_callback(blast.queue_free)
	var core_tween = create_tween()
	core.scale = Vector3(0.12, 0.12, 0.12)
	core_tween.tween_property(core, "scale", Vector3(1.35, 1.35, 1.35), 0.075)
	core_tween.tween_property(core, "scale", Vector3.ZERO, 0.14)
	core_tween.tween_callback(core.queue_free)
	if light != null:
		var light_tween = create_tween()
		if pressure_factor > 0.55:
			light.light_energy *= 0.45
			light_tween.tween_property(light, "light_energy", 0.0, 0.18)
		else:
			light_tween.tween_property(light, "light_energy", 0.0, 0.34)
		light_tween.tween_callback(light.queue_free)
	var particle_budget = int(round(lerp(15.0, 7.0, pressure_factor)))
	var particle_count = _vfx_count(min(particle_budget, max(6, int(radius * 2.6))))
	var shared_spark_mesh = BoxMesh.new()
	shared_spark_mesh.size = Vector3(0.10, 0.10, 0.42)
	var spark_mats = [
		asset_factory.make_glow_material(Color8(255, 216, 94), 0.86),
		asset_factory.make_glow_material(Color8(255, 136, 38), 0.78),
		asset_factory.make_glow_material(Color8(255, 62, 30), 0.72)
	]
	for i in particle_count:
		var spark = _acquire_transient_mesh()
		spark.mesh = shared_spark_mesh
		spark.position = base_pos + Vector3(randf_range(-0.22, 0.22), randf_range(0.25, 1.10), randf_range(-0.22, 0.22))
		spark.material_override = spark_mats[i % spark_mats.size()]
		var dir = Vector3(randf_range(-1, 1), randf_range(0.02, 1.25), randf_range(-1, 1)).normalized()
		if dir.length() <= 0.01:
			dir = Vector3.UP
		spark.look_at(spark.position + dir, Vector3.UP)
		var st = create_tween()
		var dur = randf_range(0.24, 0.50)
		var travel = randf_range(radius * 0.62, radius * 1.42)
		spark.scale = Vector3.ONE * randf_range(0.85, 1.45)
		st.tween_property(spark, "position", spark.position + dir * travel, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(spark, "scale", Vector3.ZERO, dur)
		st.tween_callback(_recycle_transient_mesh.bind(spark))
	var smoke_count = _vfx_count(int(round(lerp(5.0, 2.0, pressure_factor))))
	for i in smoke_count:
		var smoke = _acquire_transient_mesh()
		var smoke_mesh = SphereMesh.new()
		smoke_mesh.radius = randf_range(0.38, 0.78)
		smoke_mesh.height = smoke_mesh.radius * 2.0
		smoke_mesh.radial_segments = 6
		smoke_mesh.rings = 3
		smoke.mesh = smoke_mesh
		smoke.position = base_pos + Vector3(randf_range(-0.55, 0.55), randf_range(0.45, 1.25), randf_range(-0.55, 0.55))
		var smoke_color = Color(0.20, 0.17, 0.14, 0.38) if i % 3 else Color(0.34, 0.21, 0.12, 0.34)
		smoke.material_override = asset_factory.make_glow_material(smoke_color, 0.32)
		var smt = create_tween()
		smt.tween_property(smoke, "position", smoke.position + Vector3(randf_range(-0.95, 0.95), randf_range(0.45, 1.35), randf_range(-0.95, 0.95)), 0.78)
		smt.parallel().tween_property(smoke, "scale", Vector3.ZERO, 0.78)
		smt.tween_callback(_recycle_transient_mesh.bind(smoke))

func spawn_muzzle_flash(origin: Vector3, dir: Vector3, color: Color, weapon_id: String = "", attach_parent: Node3D = null, attach_local_position := Vector3.ZERO) -> void:
	if _vfx_count(1) <= 0:
		return
	if _spawn_textured_muzzle_flash(origin, dir, color, weapon_id, attach_parent, attach_local_position):
		return
	var flash = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	flash.mesh = mesh
	var attached = is_instance_valid(attach_parent)
	flash.position = attach_local_position + Vector3(0.0, 0.0, -0.07) if attached else origin + dir.normalized() * 0.12
	flash.material_override = asset_factory.make_glow_material(color.lightened(0.25), 0.82 * _vfx_scale())
	if attached:
		attach_parent.add_child(flash)
	else:
		projectile_root.add_child(flash)
	var tween = create_tween()
	flash.scale = Vector3(0.25, 0.25, 0.25)
	tween.tween_property(flash, "scale", Vector3(1.8, 1.8, 1.8), 0.055)
	tween.tween_property(flash, "scale", Vector3.ZERO, 0.08)
	tween.tween_callback(flash.queue_free)

func spawn_shotgun_muzzle_smoke(origin: Vector3, dir: Vector3, amount: int, intensity: float = 1.0) -> void:
	var count = _vfx_count(amount)
	if count <= 0:
		return
	var forward = dir.normalized()
	if forward.length() <= 0.01:
		forward = Vector3.FORWARD
	var side = forward.cross(Vector3.UP).normalized()
	if side.length() <= 0.01:
		side = Vector3.RIGHT
	var up = side.cross(forward).normalized()
	for i in count:
		var smoke = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		var radius = randf_range(0.055, 0.120) * lerp(0.85, 1.35, clamp(intensity, 0.0, 1.8))
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 7
		mesh.rings = 4
		smoke.mesh = mesh
		var local_spread = side * randf_range(-0.18, 0.18) + up * randf_range(-0.05, 0.16)
		smoke.position = origin + forward * randf_range(0.42, 1.18 + intensity * 0.22) + local_spread
		var soot = Color(0.18, 0.16, 0.13, 0.30) if i % 3 else Color(0.34, 0.24, 0.15, 0.26)
		smoke.material_override = asset_factory.make_glow_material(soot, clamp(0.26 + intensity * 0.08, 0.24, 0.42))
		smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		projectile_root.add_child(smoke)
		smoke.scale = Vector3.ONE * randf_range(0.38, 0.72)
		var drift = forward * randf_range(0.12, 0.45) + side * randf_range(-0.18, 0.18) + up * randf_range(0.08, 0.32)
		var lifetime = randf_range(0.18, 0.34) * lerp(0.95, 1.25, clamp(intensity, 0.0, 1.8))
		var tween = create_tween()
		tween.tween_property(smoke, "position", smoke.position + drift, lifetime)
		tween.parallel().tween_property(smoke, "scale", Vector3.ONE * randf_range(1.25, 2.15) * clamp(intensity, 0.75, 1.8), lifetime)
		tween.tween_property(smoke, "scale", Vector3.ZERO, 0.10)
		tween.tween_callback(smoke.queue_free)

func _spawn_textured_muzzle_flash(origin: Vector3, dir: Vector3, color: Color, weapon_id: String, attach_parent: Node3D = null, attach_local_position := Vector3.ZERO) -> bool:
	var texture = _muzzle_flash_texture(weapon_id)
	if texture == null:
		return false
	var clean_dir = dir.normalized()
	if clean_dir.length() <= 0.01:
		clean_dir = Vector3.FORWARD
	var flash_key = _muzzle_flash_key(weapon_id)
	var is_ballistic_like = _is_ballistic_muzzle_key(flash_key)
	var layer_count = 1
	if flash_key == "shotgun" and _vfx_scale() > 0.70:
		layer_count = 2
	if _vfx_scale() > 0.75 and not is_ballistic_like:
		layer_count = 2
	if _vfx_scale() > 1.15 and not is_ballistic_like:
		layer_count = 3
	var profile_scale = _muzzle_flash_scale(weapon_id)
	var attached = is_instance_valid(attach_parent)
	var attached_forward_offset = _muzzle_flash_attached_forward_offset(weapon_id)
	for i in layer_count:
		var sprite = Sprite3D.new()
		sprite.texture = texture
		sprite.centered = true
		sprite.region_enabled = not is_ballistic_like
		if not is_ballistic_like:
			sprite.region_rect = _muzzle_flash_region(weapon_id)
		sprite.pixel_size = 0.00046 * profile_scale * (1.0 + float(i) * 0.18)
		sprite.position = attach_local_position + Vector3(0.0, 0.0, attached_forward_offset - float(i) * 0.020) if attached else origin + clean_dir * (0.10 + float(i) * 0.030)
		sprite.shaded = false
		sprite.double_sided = true
		sprite.no_depth_test = false
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.modulate = _muzzle_flash_modulate(weapon_id, color, i)
		if attached:
			attach_parent.add_child(sprite)
		else:
			projectile_root.add_child(sprite)
		sprite.rotate_z(randf_range(-0.03, 0.03))
		sprite.scale = Vector3(0.55, 0.55, 0.55)
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector3.ONE * (0.95 + float(i) * 0.12), 0.022)
		tween.tween_property(sprite, "scale", Vector3.ZERO, _muzzle_flash_fade_time(weapon_id) + float(i) * 0.014)
		tween.tween_callback(sprite.queue_free)
	if _vfx_scale() > 0.7 and not is_ballistic_like:
		var glow = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.055 * profile_scale
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 6
		mesh.rings = 3
		glow.mesh = mesh
		glow.position = attach_local_position + Vector3(0.0, 0.0, attached_forward_offset - 0.010) if attached else origin + clean_dir * 0.12
		glow.material_override = asset_factory.make_glow_material(color.lightened(0.28), 0.34 * _vfx_scale())
		if attached:
			attach_parent.add_child(glow)
		else:
			projectile_root.add_child(glow)
		var gt = create_tween()
		gt.tween_property(glow, "scale", Vector3.ONE * 1.55, 0.035)
		gt.tween_property(glow, "scale", Vector3.ZERO, 0.065)
		gt.tween_callback(glow.queue_free)
	return true

func _muzzle_flash_texture(weapon_id: String):
	var key = _muzzle_flash_key(weapon_id)
	var cache_key = "%s:%s:%.2f" % [key, weapon_id, _muzzle_flash_rotation(weapon_id)]
	if muzzle_flash_textures.has(cache_key):
		return muzzle_flash_textures[cache_key]
	var candidates = []
	match key:
		"shotgun":
			candidates = ["res://assets/vfx/muzzle/muzzle_ballistic_01.png"]
		"rocket":
			candidates = ["res://assets/vfx/muzzle/muzzle_rocket_01.png"]
		"plasma":
			candidates = ["res://assets/vfx/muzzle/muzzle_plasma_01.png"]
		"shock":
			candidates = ["res://assets/vfx/muzzle/muzzle_shock_01.png", "res://assets/vfx/muzzle/muzzle_plasma_01.png"]
		"flak":
			candidates = ["res://assets/vfx/muzzle/muzzle_flak_01.png"]
		"flame":
			candidates = ["res://assets/vfx/muzzle/muzzle_flame_01.png", "res://assets/vfx/muzzle/muzzle_rocket_01.png"]
		_:
			candidates = ["res://assets/vfx/muzzle/muzzle_ballistic_01.png"]
	for path in candidates:
		if key == "ballistic" or key == "shotgun":
			var ballistic_texture = _load_ballistic_muzzle_texture(path, key == "shotgun", _muzzle_flash_rotation(weapon_id))
			if ballistic_texture != null:
				muzzle_flash_textures[cache_key] = ballistic_texture
				return ballistic_texture
		if ResourceLoader.exists(path):
			var texture = load(path)
			muzzle_flash_textures[cache_key] = texture
			return texture
		if FileAccess.file_exists(path):
			var image = Image.new()
			if image.load(path) == OK:
				var texture = ImageTexture.create_from_image(image)
				muzzle_flash_textures[cache_key] = texture
				return texture
	return null

func _load_ballistic_muzzle_texture(path: String, horizontal := false, rotation := 0.0):
	var image = Image.new()
	if ResourceLoader.exists(path):
		var loaded_texture = load(path)
		if loaded_texture == null or not loaded_texture is Texture2D:
			return null
		image = loaded_texture.get_image()
	elif FileAccess.file_exists(path):
		if image.load(path) != OK:
			return null
	else:
		return null
	if image == null or image.is_empty():
		return null
	var region = Rect2i(0, 286, min(512, image.get_width()), min(138, max(1, image.get_height() - 286)))
	var flash_image = image.get_region(region)
	if not horizontal:
		flash_image.rotate_90(0)
	flash_image.rotate_180()
	if abs(rotation) > 0.001:
		flash_image = _rotate_muzzle_image(flash_image, rotation)
	return ImageTexture.create_from_image(flash_image)

func _rotate_muzzle_image(source: Image, angle: float) -> Image:
	var source_width = source.get_width()
	var source_height = source.get_height()
	var output_size = int(ceil(sqrt(float(source_width * source_width + source_height * source_height))))
	var output = Image.create(output_size, output_size, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	var src_center = Vector2(float(source_width) * 0.5, float(source_height) * 0.5)
	var out_center = Vector2(float(output_size) * 0.5, float(output_size) * 0.5)
	var cos_a = cos(-angle)
	var sin_a = sin(-angle)
	for y in output_size:
		for x in output_size:
			var p = Vector2(float(x), float(y)) - out_center
			var src = Vector2(p.x * cos_a - p.y * sin_a, p.x * sin_a + p.y * cos_a) + src_center
			var sx = int(round(src.x))
			var sy = int(round(src.y))
			if sx >= 0 and sx < source_width and sy >= 0 and sy < source_height:
				output.set_pixel(x, y, source.get_pixel(sx, sy))
	return output

func _muzzle_flash_key(weapon_id: String) -> String:
	match weapon_id:
		"pistol", "auto":
			return "ballistic"
		"shotgun":
			return "shotgun"
		"heavy", "grenade_launcher":
			return "rocket"
		"plasma", "cryo", "toxic":
			return "plasma"
		"shock_flux":
			return "shock"
		"flak":
			return "flak"
		"incinerator":
			return "flame"
		_:
			return ""

func _is_ballistic_muzzle_key(key: String) -> bool:
	return key == "ballistic" or key == "shotgun"

func _muzzle_flash_modulate(weapon_id: String, color: Color, layer_index: int) -> Color:
	var key = _muzzle_flash_key(weapon_id)
	if key == "shotgun":
		return Color(1.0, 0.94, 0.74, 1.0)
	if key == "ballistic":
		return Color.WHITE
	return color.lightened(0.20 + float(layer_index) * 0.08)

func _muzzle_flash_fade_time(weapon_id: String) -> float:
	if _muzzle_flash_key(weapon_id) == "shotgun":
		return 0.150
	return 0.050

func _muzzle_flash_attached_forward_offset(weapon_id: String) -> float:
	if _muzzle_flash_key(weapon_id) == "shotgun":
		return -0.095
	if weapon_id == "auto":
		return -0.040
	if weapon_id == "pistol":
		return -0.030
	return -0.055

func _muzzle_flash_scale(weapon_id: String) -> float:
	match weapon_id:
		"pistol":
			return 2.40
		"auto":
			return 2.40
		"shotgun":
			return 3.15
		"heavy":
			return 0.86
		"grenade_launcher":
			return 0.76
		"flak":
			return 0.34
		"plasma", "shock_flux", "incinerator":
			return 0.58
		_:
			return 0.48

func _muzzle_flash_region(weapon_id: String) -> Rect2:
	if _muzzle_flash_key(weapon_id) == "ballistic":
		return Rect2(0, 0, 138, 512)
	return Rect2(0, 0, 512, 512)

func _muzzle_flash_rotation(weapon_id: String) -> float:
	if _muzzle_flash_key(weapon_id) == "ballistic":
		return deg_to_rad (40.0)
	return 0.0

func spawn_tracer(from: Vector3, to: Vector3, color: Color) -> void:
	var dist = from.distance_to(to)
	if dist < 0.35:
		return
	var tracer = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.035, 0.035, min(dist, 12.0))
	tracer.mesh = mesh
	tracer.position = from.lerp(to, 0.5)
	tracer.material_override = asset_factory.make_glow_material(color.lightened(0.2), 0.62)
	projectile_root.add_child(tracer)
	tracer.look_at(to, Vector3.UP)
	var tween = create_tween()
	tween.tween_property(tracer, "scale", Vector3(0.2, 0.2, 1.0), 0.05)
	tween.tween_property(tracer, "scale", Vector3.ZERO, 0.07)
	tween.tween_callback(tracer.queue_free)

func spawn_grapple_cable(from: Vector3, to: Vector3) -> void:
	var dist = from.distance_to(to)
	if dist < 0.35:
		return
	if _using_trench_runtime():
		_spawn_light_grapple_cable(from, to, dist)
		return
	var cable = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.028, 0.028, dist)
	cable.mesh = mesh
	cable.position = from.lerp(to, 0.5)
	cable.material_override = asset_factory.make_flat_material(Color8(48, 62, 68))
	projectile_root.add_child(cable)
	cable.look_at(to, Vector3.UP)
	var glow = MeshInstance3D.new()
	var glow_mesh = BoxMesh.new()
	glow_mesh.size = Vector3(0.012, 0.012, dist)
	glow.mesh = glow_mesh
	glow.position = cable.position + Vector3(0.0, 0.012, 0.0)
	glow.rotation = cable.rotation
	glow.material_override = asset_factory.make_glow_material(Color8(96, 210, 235), 0.34)
	projectile_root.add_child(glow)
	var segments = min(6, floori(dist / 3.2))
	for i in range(1, segments + 1):
		var cuff = MeshInstance3D.new()
		var cuff_mesh = BoxMesh.new()
		cuff_mesh.size = Vector3(0.060, 0.060, 0.08)
		cuff.mesh = cuff_mesh
		cuff.position = from.lerp(to, float(i) / float(segments + 1))
		cuff.rotation = cable.rotation
		cuff.material_override = asset_factory.make_flat_material(Color8(236, 178, 34) if i % 2 == 0 else Color8(22, 26, 28))
		projectile_root.add_child(cuff)
		var ct = create_tween()
		ct.tween_interval(0.07)
		ct.tween_property(cuff, "scale", Vector3.ZERO, 0.055)
		ct.tween_callback(cuff.queue_free)
	var hook = Node3D.new()
	hook.position = to
	projectile_root.add_child(hook)
	hook.look_at(from, Vector3.UP)
	var hook_sprite = Sprite3D.new()
	hook_sprite.texture = weapon_art_factory.make_hook_texture()
	hook_sprite.centered = true
	hook_sprite.pixel_size = 0.0028
	hook_sprite.position = Vector3(0, 0, -0.05)
	hook_sprite.shaded = false
	hook_sprite.double_sided = true
	hook_sprite.no_depth_test = true
	hook.add_child(hook_sprite)
	var hook_mat = asset_factory.make_flat_material(Color8(226, 222, 205))
	var dark_mat = asset_factory.make_flat_material(Color8(34, 38, 40))
	var core = MeshInstance3D.new()
	var core_mesh = SphereMesh.new()
	core_mesh.radius = 0.12
	core_mesh.height = 0.24
	core_mesh.radial_segments = 8
	core_mesh.rings = 4
	core.mesh = core_mesh
	core.position = Vector3(0, 0, -0.06)
	core.material_override = asset_factory.make_glow_material(Color8(84, 255, 112), 0.90)
	hook.add_child(core)
	var head = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.26, 0.18, 0.22)
	head.mesh = head_mesh
	head.material_override = hook_mat
	hook.add_child(head)
	for i in 2:
		var prong = MeshInstance3D.new()
		var prong_mesh = BoxMesh.new()
		prong_mesh.size = Vector3(0.070, 0.20, 0.42)
		prong.mesh = prong_mesh
		prong.position = Vector3((-0.14 if i == 0 else 0.14), 0.0, -0.20)
		prong.rotation_degrees = Vector3(0, 0, -36 if i == 0 else 36)
		prong.material_override = hook_mat
		hook.add_child(prong)
	var claw = MeshInstance3D.new()
	var claw_mesh = BoxMesh.new()
	claw_mesh.size = Vector3(0.12, 0.12, 0.30)
	claw.mesh = claw_mesh
	claw.position = Vector3(0, 0, -0.26)
	claw.material_override = dark_mat
	hook.add_child(claw)
	for node in [cable, glow, hook]:
		var tween = create_tween()
		tween.tween_interval(0.07)
		tween.tween_property(node, "scale", Vector3.ZERO, 0.055)
		tween.tween_callback(node.queue_free)

func _spawn_light_grapple_cable(from: Vector3, to: Vector3, dist: float) -> void:
	if light_grapple_mesh == null:
		light_grapple_mesh = BoxMesh.new()
		light_grapple_mesh.size = Vector3(0.032, 0.032, 1.0)
	if light_grapple_material == null:
		light_grapple_material = asset_factory.make_glow_material(Color8(96, 210, 235), 0.42)
	var cable = MeshInstance3D.new()
	cable.mesh = light_grapple_mesh
	cable.position = from.lerp(to, 0.5)
	cable.scale = Vector3(1.0, 1.0, dist)
	cable.material_override = light_grapple_material
	projectile_root.add_child(cable)
	cable.look_at(to, Vector3.UP)
	var tween = create_tween()
	tween.tween_interval(0.045)
	tween.tween_property(cable, "scale", Vector3(0.0, 0.0, dist), 0.035)
	tween.tween_callback(cable.queue_free)

func spawn_rail_trail(from: Vector3, to: Vector3, color: Color) -> void:
	var dist = from.distance_to(to)
	if dist < 0.5:
		return
	for i in _vfx_count(2):
		var trail = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.045 + i * 0.035, 0.045 + i * 0.035, dist)
		trail.mesh = mesh
		trail.position = from.lerp(to, 0.5) + Vector3(randf_range(-0.025, 0.025), randf_range(-0.025, 0.025), randf_range(-0.025, 0.025))
		var c = color.lightened(0.25) if i == 0 else Color(0.62, 0.72, 0.76, 0.42)
		trail.material_override = asset_factory.make_glow_material(c, 0.68 - i * 0.16)
		projectile_root.add_child(trail)
		trail.look_at(to, Vector3.UP)
		var tween = create_tween()
		tween.tween_interval(i * 0.025)
		tween.tween_property(trail, "scale", Vector3(0.16, 0.16, 1.0), 0.12 + i * 0.05)
		tween.tween_property(trail, "scale", Vector3.ZERO, 0.24 + i * 0.08)
		tween.tween_callback(trail.queue_free)
	for i in _vfx_count(2):
		var smoke = MeshInstance3D.new()
		var mesh_s = SphereMesh.new()
		mesh_s.radius = 0.13
		mesh_s.height = 0.26
		smoke.mesh = mesh_s
		smoke.position = from.lerp(to, randf_range(0.15, 0.92))
		smoke.material_override = asset_factory.make_glow_material(Color(0.42, 0.48, 0.50, 0.34), 0.34)
		projectile_root.add_child(smoke)
		var st = create_tween()
		st.tween_property(smoke, "position", smoke.position + Vector3(randf_range(-0.18, 0.18), randf_range(0.04, 0.22), randf_range(-0.18, 0.18)), 0.42)
		st.parallel().tween_property(smoke, "scale", Vector3.ZERO, 0.42)
		st.tween_callback(smoke.queue_free)

func spawn_impact_fx(pos: Vector3, color: Color) -> void:
	if _vfx_count(1) <= 0:
		return
	var puff = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	puff.mesh = mesh
	puff.position = pos
	puff.material_override = asset_factory.make_glow_material(color, 0.55)
	projectile_root.add_child(puff)
	var tween = create_tween()
	tween.tween_property(puff, "scale", Vector3(2.0, 2.0, 2.0), 0.08)
	tween.tween_property(puff, "scale", Vector3.ZERO, 0.12)
	tween.tween_callback(puff.queue_free)

func spawn_body_hit_fx(pos: Vector3, color: Color, accent: Color, amount: int, enemy_kind: String = "") -> void:
	var style_seed = int(abs(hash(enemy_kind))) + amount + floori(float(Time.get_ticks_msec()) / 83.0)
	var style = posmod(style_seed, 3)
	match style:
		0:
			spawn_impact_fx(pos, accent.lightened(0.12))
			_spawn_hit_shards(pos, color.lightened(0.12), 2, 0.34)
		1:
			spawn_impact_fx(pos, color.lightened(0.18))
			_spawn_hit_shards(pos, accent.lightened(0.20), 3, 0.46)
		_:
			spawn_impact_fx(pos, accent.darkened(0.08))
			_spawn_hit_ring(pos, accent.lightened(0.10))
			_spawn_hit_shards(pos, color.lightened(0.08), 1, 0.28)

func _spawn_hit_shards(pos: Vector3, color: Color, base_count: int, force: float) -> void:
	var count = _vfx_count(base_count)
	for i in count:
		var shard = MeshInstance3D.new()
		var shard_mesh = BoxMesh.new()
		shard_mesh.size = Vector3(0.035, 0.035, randf_range(0.20, 0.34))
		shard.mesh = shard_mesh
		shard.position = pos + Vector3(randf_range(-0.04, 0.04), randf_range(-0.04, 0.08), randf_range(-0.04, 0.04))
		shard.material_override = asset_factory.make_glow_material(color, 0.62)
		projectile_root.add_child(shard)
		var dir = Vector3(randf_range(-0.85, 0.85), randf_range(0.12, 0.78), randf_range(-0.85, 0.85)).normalized()
		if dir.length() <= 0.01:
			dir = Vector3.UP
		shard.look_at(shard.position + dir, Vector3.UP)
		var tw = create_tween()
		var dur = randf_range(0.12, 0.22)
		tw.tween_property(shard, "position", shard.position + dir * randf_range(force * 0.65, force * 1.35), dur)
		tw.parallel().tween_property(shard, "scale", Vector3.ZERO, dur)
		tw.tween_callback(shard.queue_free)

func _spawn_hit_ring(pos: Vector3, color: Color) -> void:
	if _vfx_count(1) <= 0:
		return
	var ring = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.20
	mesh.bottom_radius = 0.20
	mesh.height = 0.018
	mesh.radial_segments = 14
	ring.mesh = mesh
	ring.position = pos
	ring.rotation_degrees = Vector3(randf_range(-24.0, 24.0), randf_range(0.0, 180.0), randf_range(-24.0, 24.0))
	ring.material_override = asset_factory.make_glow_material(color, 0.56)
	projectile_root.add_child(ring)
	var tw = create_tween()
	tw.tween_property(ring, "scale", Vector3(1.75, 1.75, 1.75), 0.10)
	tw.tween_property(ring, "scale", Vector3.ZERO, 0.12)
	tw.tween_callback(ring.queue_free)

func spawn_headshot_fx(pos: Vector3, color: Color) -> void:
	var spike_count = _vfx_count(3)
	if spike_count <= 0:
		return
	for i in spike_count:
		var spike = MeshInstance3D.new()
		var spike_mesh = BoxMesh.new()
		spike_mesh.size = Vector3(0.045 + i * 0.012, 0.045 + i * 0.012, 0.72 + i * 0.12)
		spike.mesh = spike_mesh
		spike.position = pos + Vector3(randf_range(-0.05, 0.05), randf_range(-0.03, 0.08), randf_range(-0.05, 0.05))
		spike.material_override = asset_factory.make_glow_material(color.lightened(0.34), 0.82 - i * 0.10)
		projectile_root.add_child(spike)
		var dir = Vector3(randf_range(-0.42, 0.42), randf_range(0.22, 0.72), randf_range(-0.42, 0.42)).normalized()
		spike.look_at(spike.position + dir, Vector3.UP)
		var tw = create_tween()
		tw.tween_property(spike, "position", spike.position + dir * (0.55 + i * 0.12), 0.12)
		tw.parallel().tween_property(spike, "scale", Vector3(1.35, 1.35, 1.0), 0.08)
		tw.tween_property(spike, "scale", Vector3.ZERO, 0.18)
		tw.tween_callback(spike.queue_free)
	spawn_impact_fx(pos, color.lightened(0.28))

func _boss_alive() -> bool:
	for e in enemies:
		if is_instance_valid(e) and e.stats.boss and not e.dead:
			return true
	return false

func _update_boss_signal() -> void:
	for e in enemies:
		if is_instance_valid(e) and e.stats.boss and not e.dead:
			if exit_light:
				exit_light.light_energy = 0.35
			boss_hp_changed.emit(e.hp, e.stats.hp, true)
			return
	if exit_light:
		exit_light.light_energy = 2.1
	boss_hp_changed.emit(0, 1, false)

func _clear() -> void:
	_stop_spider_seek_loop()
	_stop_algore_audio()
	spider_seek_target = null
	for root in [world_root, entity_root, projectile_root]:
		if root == null:
			continue
		for child in root.get_children():
			child.queue_free()
	pickups.clear()
	enemies.clear()
	projectiles.clear()
	if combat_object_pool != null:
		combat_object_pool.clear()
	projectile_pool.clear()
	grenades.clear()
	grenade_pool.clear()
	transient_mesh_pool.clear()
	cluster_spawn_queue.clear()
	turrets.clear()
	respawn_pickups.clear()
	burn_areas.clear()
	status_fields.clear()
	blood_splat_nodes.clear()
	platform_areas.clear()
	solid_areas.clear()
	horror_solid_index_count = -1
	horror_solid_buckets.clear()
	jump_pads.clear()
	accelerator_areas.clear()
	ledge_areas.clear()
	weapon_locker_active = false
	trench_runtime = null
	horror_runtime = null
	trench_exit_triggered = false
	ramp_test_active = false
	ramp_exit_triggered = false
	ramp_survival_time = 0.0
	ramp_spawn_timer = 0.0
	ramp_exit_available = false
	ramp_drone_spawned = false
	ramp_drone = null
	ramp_drones.clear()
	ramp_drone_barrel_timer = 0.0

func _start_algore_atmosphere_one() -> void:
	algore_phase2_started = false
	algore_music_started = false
	algore_final_loop_started = false
	_stop_algore_audio()
	algore_audio_player = _make_algore_audio_player(ALGORE_ATMOSPHERE1_PATH, true, -2.0)
	if is_instance_valid(algore_audio_player):
		algore_audio_player.play()

func _start_algore_phase_two_audio(enemy = null) -> void:
	if algore_phase2_started:
		return
	algore_phase2_started = true
	algore_music_started = false
	algore_final_loop_started = false
	if is_instance_valid(algore_audio_player):
		algore_audio_player.stop()
		algore_audio_player.queue_free()
	algore_audio_player = null
	algore_phase2_player = _make_algore_audio_player(ALGORE_PHASE2_PATH, false, 0.0)
	if is_instance_valid(enemy):
		algore_phase2_voice_player = _make_algore_spatial_player(ALGORE_PHASE2_VOICE_PATH, enemy, 4.0)
	if is_instance_valid(algore_phase2_player):
		algore_phase2_player.play()
	if is_instance_valid(algore_phase2_voice_player):
		algore_phase2_voice_player.play()
	if is_instance_valid(enemy) and enemy.has_method("get"):
		var transition_len = 0.25
		if is_instance_valid(algore_phase2_player):
			transition_len = max(transition_len, algore_phase2_player.stream.get_length())
		if is_instance_valid(algore_phase2_voice_player):
			transition_len = max(transition_len, algore_phase2_voice_player.stream.get_length())
		enemy.boss_phase_transition_timer = transition_len

func _tick_algore_audio() -> void:
	if not _is_boss_level():
		return
	var paused = player != null and player.paused
	set_algore_audio_paused(paused)
	if paused:
		return
	if algore_phase2_started and not algore_music_started:
		var atmosphere_done = not is_instance_valid(algore_phase2_player) or not algore_phase2_player.playing
		var voice_done = not is_instance_valid(algore_phase2_voice_player) or not algore_phase2_voice_player.playing
		if atmosphere_done and voice_done:
			algore_music_started = true
			if is_instance_valid(algore_phase2_player):
				algore_phase2_player.queue_free()
			if is_instance_valid(algore_phase2_voice_player):
				algore_phase2_voice_player.queue_free()
			algore_phase2_player = null
			algore_phase2_voice_player = null
			algore_audio_player = _make_algore_audio_player(ALGORE_MUSIC1_PATH, false, -1.0)
			if is_instance_valid(algore_audio_player):
				algore_audio_player.play()
	elif algore_music_started and not algore_final_loop_started:
		if not is_instance_valid(algore_audio_player) or not algore_audio_player.playing:
			algore_final_loop_started = true
			if is_instance_valid(algore_audio_player):
				algore_audio_player.queue_free()
			algore_audio_player = _make_algore_audio_player(ALGORE_FINAL_LOOP_PATH, true, -1.0)
			if is_instance_valid(algore_audio_player):
				algore_audio_player.play()

func set_algore_audio_paused(paused: bool) -> void:
	for audio_player in [algore_audio_player, algore_phase2_player, algore_phase2_voice_player]:
		if is_instance_valid(audio_player):
			audio_player.stream_paused = paused

func _stop_algore_audio() -> void:
	for audio_player in [algore_audio_player, algore_phase2_player, algore_phase2_voice_player]:
		if is_instance_valid(audio_player):
			audio_player.stop()
			audio_player.queue_free()
	algore_audio_player = null
	algore_phase2_player = null
	algore_phase2_voice_player = null
	algore_phase2_started = false
	algore_music_started = false
	algore_final_loop_started = false

func _make_algore_audio_player(path: String, loop: bool, volume_db: float) -> AudioStreamPlayer:
	var stream = _load_algore_wav(path, loop)
	if stream == null:
		return null
	var audio_player = AudioStreamPlayer.new()
	audio_player.name = path.get_file().get_basename()
	audio_player.bus = "Master"
	audio_player.stream = stream
	audio_player.set_meta("base_volume_db", volume_db)
	audio_player.volume_db = _music_volume_db(volume_db)
	add_child(audio_player)
	return audio_player

func _music_volume_db(base_volume_db: float) -> float:
	var linear = clamp(music_volume, 0.0, 1.0)
	return -80.0 if linear <= 0.001 else base_volume_db + linear_to_db(linear)

func _apply_algore_music_volume() -> void:
	for audio_player in [algore_audio_player, algore_phase2_player]:
		if is_instance_valid(audio_player):
			var base = float(audio_player.get_meta("base_volume_db", audio_player.volume_db))
			audio_player.volume_db = _music_volume_db(base)

func _make_algore_spatial_player(path: String, parent_node: Node3D, volume_db: float) -> AudioStreamPlayer3D:
	var stream = _load_algore_wav(path, false)
	if stream == null:
		return null
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.name = path.get_file().get_basename()
	audio_player.bus = "Master"
	audio_player.stream = stream
	audio_player.volume_db = volume_db
	audio_player.unit_size = 6.5
	audio_player.max_distance = 85.0
	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	parent_node.add_child(audio_player)
	audio_player.position = Vector3(0, 2.4, 0)
	return audio_player

func _play_algore_dead_sound(pos: Vector3) -> void:
	var stream = _load_algore_wav(ALGORE_DEAD_PATH, false)
	if stream == null:
		return
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "AlgoreDeathSound"
	audio_player.bus = "Master"
	audio_player.stream = stream
	audio_player.volume_db = 5.0
	audio_player.unit_size = 8.0
	audio_player.max_distance = 120.0
	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	audio_player.global_position = pos
	add_child(audio_player)
	audio_player.play()
	var cleanup = create_tween()
	cleanup.tween_interval(max(0.2, stream.get_length() + 0.25))
	cleanup.tween_callback(audio_player.queue_free)

func _load_algore_wav(path: String, loop: bool) -> AudioStream:
	var loaded = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
	if loaded == null:
		loaded = AudioStreamWAV.load_from_file(path)
	if loaded == null:
		return null
	if loop:
		loaded.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loaded.loop_begin = 0
		loaded.loop_end = _spider_wav_frame_count(loaded)
	return loaded

func _tick_spider_seek_loop() -> void:
	var spider = _active_spider_seek_target()
	if spider == null:
		_stop_spider_seek_loop()
		return
	if player == null or player.paused:
		_pause_spider_seek_loop_direct(true)
		return
	var voice_pos = spider.global_position + Vector3(0, float(spider.stats.height) * 0.56, 0)
	var dist = player.global_position.distance_to(voice_pos)
	if dist > SPIDER_SEEK_AUDIBLE_DISTANCE:
		_pause_spider_seek_loop_direct(true)
		spider_seek_loop_active = false
		return
	var proximity = clamp(1.0 - dist / SPIDER_SEEK_AUDIBLE_DISTANCE, 0.0, 1.0)
	var volume_offset = lerp(-36.0, 10.0, pow(proximity, 2.25))
	_play_spider_seek_loop_direct(volume_offset)
	spider_seek_loop_active = true

func _active_spider_seek_target():
	if is_instance_valid(spider_seek_target) and not spider_seek_target.dead:
		return spider_seek_target
	spider_seek_target = _nearest_active_spider_boss()
	return spider_seek_target

func _nearest_active_spider_boss():
	var best = null
	var best_dist = INF
	for e in enemies:
		if not is_instance_valid(e) or e.dead or e.stats == null:
			continue
		if String(e.stats.id) != "0" and String(e.stats.sprite_key) != "spider":
			continue
		var dist = player.global_position.distance_squared_to(e.global_position) if player != null else 0.0
		if best == null or dist < best_dist:
			best = e
			best_dist = dist
	return best

func _stop_spider_seek_loop() -> void:
	if is_instance_valid(spider_seek_loop_player):
		spider_seek_loop_player.stop()
		spider_seek_loop_player.queue_free()
	spider_seek_loop_player = null
	sound_loop_stop_requested.emit(SPIDER_SEEK_LOOP_ID)
	spider_seek_loop_active = false

func _play_spider_seek_loop_direct(volume_db: float) -> void:
	var stream = _get_spider_seek_stream()
	if stream == null:
		return
	if not is_instance_valid(spider_seek_loop_player):
		spider_seek_loop_player = AudioStreamPlayer.new()
		spider_seek_loop_player.name = "BroodWidowShepardLoopDirect"
		spider_seek_loop_player.bus = "Master"
		spider_seek_loop_player.stream = stream
		add_child(spider_seek_loop_player)
	spider_seek_loop_player.volume_db = volume_db
	spider_seek_loop_player.stream_paused = false
	if not spider_seek_loop_player.playing:
		spider_seek_loop_player.play()

func set_spider_seek_loop_paused(paused: bool) -> void:
	_pause_spider_seek_loop_direct(paused)

func _pause_spider_seek_loop_direct(paused: bool) -> void:
	if not is_instance_valid(spider_seek_loop_player):
		return
	spider_seek_loop_player.stream_paused = paused
	if paused:
		spider_seek_loop_player.volume_db = -80.0

func _get_spider_seek_stream() -> AudioStream:
	if spider_seek_stream != null:
		return spider_seek_stream
	var absolute_path = ProjectSettings.globalize_path(SPIDER_SEEK_LOOP_PATH)
	var loaded = AudioStreamWAV.load_from_file(absolute_path)
	if loaded == null:
		loaded = AudioStreamWAV.load_from_file(SPIDER_SEEK_LOOP_PATH)
	if loaded != null:
		spider_seek_stream = _prepare_spider_seek_wav(loaded)
		return spider_seek_stream
	spider_seek_stream = _load_spider_seek_raw_wav(SPIDER_SEEK_LOOP_PATH)
	return spider_seek_stream

func _prepare_spider_seek_wav(wav: AudioStreamWAV) -> AudioStreamWAV:
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = _spider_wav_frame_count(wav)
	return wav

func _load_spider_seek_raw_wav(path: String) -> AudioStream:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var absolute_path = ProjectSettings.globalize_path(path)
		file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return null
	var bytes = file.get_buffer(file.get_length())
	if bytes.size() < 44:
		return null
	var channels = 0
	var sample_rate = 44100
	var bits = 0
	var data_offset = -1
	var data_size = 0
	var offset = 12
	while offset + 8 <= bytes.size():
		var chunk_id = ""
		for j in 4:
			chunk_id += char(bytes[offset + j])
		var chunk_size = _spider_read_u32(bytes, offset + 4)
		var chunk_data = offset + 8
		if chunk_id == "fmt " and chunk_size >= 16:
			channels = _spider_read_u16(bytes, chunk_data + 2)
			sample_rate = _spider_read_u32(bytes, chunk_data + 4)
			bits = _spider_read_u16(bytes, chunk_data + 14)
		elif chunk_id == "data":
			data_offset = chunk_data
			data_size = min(chunk_size, bytes.size() - chunk_data)
			break
		offset = chunk_data + chunk_size + int(chunk_size % 2)
	if data_offset < 0 or data_size <= 0 or bits != 16 or channels < 1:
		return null
	var raw = bytes.slice(data_offset, data_offset + data_size)
	var out = AudioStreamWAV.new()
	out.format = AudioStreamWAV.FORMAT_16_BITS
	out.mix_rate = sample_rate
	out.loop_mode = AudioStreamWAV.LOOP_FORWARD
	out.loop_begin = 0
	if channels == 2:
		out.stereo = true
		out.data = raw
	elif channels == 1:
		out.stereo = false
		out.data = raw
	else:
		return null
	out.loop_end = _spider_wav_frame_count(out)
	return out

func _spider_wav_frame_count(wav: AudioStreamWAV) -> int:
	var channels = 2 if wav.stereo else 1
	var bytes_per_sample = 2
	match wav.format:
		AudioStreamWAV.FORMAT_8_BITS:
			bytes_per_sample = 1
		AudioStreamWAV.FORMAT_16_BITS:
			bytes_per_sample = 2
		_:
			bytes_per_sample = 2
	return max(1, int(wav.data.size() / max(1, channels * bytes_per_sample)))

func _spider_read_u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)

func _spider_read_u32(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)

func grid_to_world(col: int, row: int) -> Vector3:
	return Vector3(col * GameDataScript.TILE, 0, row * GameDataScript.TILE)

func world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(int(round(pos.x / GameDataScript.TILE)), int(round(pos.z / GameDataScript.TILE)))

func get_cell(col: int, row: int) -> String:
	if row < 0 or row >= game_map.size():
		return "#"
	if col < 0 or col >= game_map[row].size():
		return "#"
	return game_map[row][col]

func wall_top_height() -> float:
	return _map_wall_height()

func push_out_of_solid(pos: Vector3, radius: float) -> Vector3:
	if _using_trench_runtime():
		return trench_runtime.push_out_of_solid(pos, radius)
	if ramp_test_active:
		var out = pos
		var limit = ramp_width * 0.5 - radius
		out.x = clamp(out.x, -limit, limit)
		out.y = max(out.y, _ramp_floor_height_at(out))
		return out
	if GameDataScript.is_horror_sequence_level(level_index) and _solid_area_blocks(pos, radius):
		return _push_out_of_solid_areas(pos, radius)
	var cell = world_to_cell(pos)
	if get_cell(cell.x, cell.y) not in ["#", "D"]:
		return pos
	if pos.y >= _map_wall_height() - 0.18:
		return pos
	var best = pos
	var best_dist = INF
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var nx = cell.x + d.x
		var ny = cell.y + d.y
		if get_cell(nx, ny) in ["#", "D"]:
			continue
		var candidate = grid_to_world(nx, ny)
		var dist = Vector2(pos.x - candidate.x, pos.z - candidate.z).length()
		if dist < best_dist:
			best_dist = dist
			best = Vector3(candidate.x, max(pos.y, floor_height_at(candidate)), candidate.z)
	if best_dist < INF:
		return pos.lerp(best, 0.36)
	return pos

func _is_roofed_exit_barrier_cell(col: int, row: int) -> bool:
	if _is_boss_level() or exit_pos == Vector3.ZERO:
		return false
	var exit_cell = world_to_cell(exit_pos)
	if abs(col - exit_cell.x) > 4 or abs(row - exit_cell.y) > 4:
		return false
	return get_cell(col, row) in ["#", "D"]
