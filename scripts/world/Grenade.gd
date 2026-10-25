extends Node3D
class_name Grenade

const WeaponArtFactoryScript = preload("res://scripts/core/WeaponArtFactory.gd")

var velocity = Vector3.ZERO
var timer = 1.05
var level_manager
var visual: MeshInstance3D
var bounces = 0
var weapon_art_factory = WeaponArtFactoryScript.new()
var bomb_type = "frag"
var lightweight_visual = false
var pool_key := ""

func configure(factory, start: Vector3, vel: Vector3, lm, p_bomb_type: String = "frag", p_lightweight_visual: bool = false, p_timer: float = -1.0, p_pool_key: String = "") -> void:
	visible = true
	pool_key = p_pool_key
	global_position = start
	velocity = vel
	level_manager = lm
	bomb_type = p_bomb_type
	lightweight_visual = p_lightweight_visual or bomb_type == "cluster_child"
	timer = 1.05
	bounces = 0
	if bomb_type == "cluster_child":
		timer = randf_range(0.38, 0.62)
	if p_timer > 0.0:
		timer = p_timer
	var core_color = _bomb_color()
	if get_child_count() > 0:
		return
	if lightweight_visual:
		_add_lightweight_visual(factory, core_color)
		return
	var sprite = Sprite3D.new()
	sprite.texture = weapon_art_factory.make_grenade_texture()
	sprite.centered = true
	sprite.pixel_size = 0.0030
	sprite.position = Vector3(0, 0.03, 0)
	sprite.shaded = false
	sprite.double_sided = true
	sprite.no_depth_test = true
	add_child(sprite)
	visual = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.20
	mesh.height = 0.40
	mesh.radial_segments = 10
	mesh.rings = 5
	visual.mesh = mesh
	visual.material_override = factory.make_flat_material(Color8(216, 214, 198))
	add_child(visual)
	var core = MeshInstance3D.new()
	var core_mesh = SphereMesh.new()
	core_mesh.radius = 0.105
	core_mesh.height = 0.21
	core_mesh.radial_segments = 8
	core_mesh.rings = 4
	core.mesh = core_mesh
	core.position = Vector3(0, 0, -0.13)
	core.material_override = factory.make_glow_material(core_color, 0.92)
	add_child(core)
	for i in 6:
		var a = TAU * float(i) / 6.0
		var panel = MeshInstance3D.new()
		var panel_mesh = BoxMesh.new()
		panel_mesh.size = Vector3(0.12, 0.045, 0.055)
		panel.mesh = panel_mesh
		panel.position = Vector3(cos(a) * 0.20, sin(a) * 0.20, 0.0)
		panel.rotation_degrees = Vector3(0, 0, rad_to_deg(a))
		panel.material_override = factory.make_flat_material(Color8(30, 35, 36) if i % 2 == 0 else Color8(236, 178, 34))
		add_child(panel)
	for z in [-0.14, 0.14]:
		var ring = MeshInstance3D.new()
		var ring_mesh = CylinderMesh.new()
		ring_mesh.top_radius = 0.22
		ring_mesh.bottom_radius = 0.22
		ring_mesh.height = 0.035
		ring_mesh.radial_segments = 10
		ring.mesh = ring_mesh
		ring.position.z = z
		ring.rotation_degrees.x = 90
		ring.material_override = factory.make_flat_material(Color8(42, 47, 48))
		add_child(ring)

func deactivate_for_pool() -> void:
	visible = false
	velocity = Vector3.ZERO
	level_manager = null

func _add_lightweight_visual(factory, core_color: Color) -> void:
	visual = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.115
	mesh.height = 0.23
	mesh.radial_segments = 6
	mesh.rings = 3
	visual.mesh = mesh
	visual.material_override = factory.make_glow_material(core_color, 0.78)
	add_child(visual)
	var cap = MeshInstance3D.new()
	var cap_mesh = BoxMesh.new()
	cap_mesh.size = Vector3(0.18, 0.055, 0.10)
	cap.mesh = cap_mesh
	cap.position = Vector3(0, 0.0, -0.04)
	cap.material_override = factory.make_flat_material(Color8(42, 38, 26))
	add_child(cap)

func tick(dt: float) -> bool:
	timer -= dt
	velocity.y -= 9.8 * dt
	var from = global_position
	var next = global_position + velocity * dt
	if bomb_type == "ramp_barrel" and level_manager.player != null:
		var to_player = level_manager.player.global_position - next
		var flat_dist = Vector2(to_player.x, to_player.z).length()
		if flat_dist <= 0.78 and abs(to_player.y) <= 1.55:
			global_position = next
			_detonate()
			return false
	var direct_hit = level_manager.find_enemy_along_segment(from, next, 0.62)
	if direct_hit != null:
		global_position = direct_hit.global_position + Vector3(0, direct_hit.stats.height * 0.42, 0)
		_detonate()
		return false
	var x_target = Vector3(next.x, global_position.y, global_position.z)
	if level_manager.wall_hit_along_segment(global_position, x_target, 0.16).hit:
		velocity.x *= -0.48
		bounces += 1
	else:
		global_position.x = next.x
	var z_target = Vector3(global_position.x, global_position.y, next.z)
	if level_manager.wall_hit_along_segment(global_position, z_target, 0.16).hit:
		velocity.z *= -0.48
		bounces += 1
	else:
		global_position.z = next.z
	var floor_y = level_manager.floor_height_at(global_position) + 0.18
	global_position.y = max(floor_y, next.y)
	if global_position.y <= floor_y + 0.01:
		if velocity.y < -1.2:
			bounces += 1
		velocity.y *= -0.38
		velocity.x *= 0.82
		velocity.z *= 0.82
	if is_instance_valid(visual):
		visual.rotate_x(velocity.z * dt * 1.8)
		visual.rotate_z(-velocity.x * dt * 1.8)
	if timer <= 0.0:
		_detonate()
		return false
	return true

func _bomb_color() -> Color:
	match bomb_type:
		"incendiary":
			return Color8(255, 128, 36)
		"cryo":
			return Color8(120, 230, 255)
		"toxic":
			return Color8(130, 255, 92)
		"shock":
			return Color8(190, 120, 255)
		"cluster", "cluster_child":
			return Color8(255, 204, 72)
		"ramp_barrel":
			return Color8(255, 154, 52)
		_:
			return Color8(86, 246, 255)

func _detonate() -> void:
	match bomb_type:
		"incendiary":
			level_manager.explode(global_position, 5.8, 13, 0.24)
			level_manager.spawn_burning_patch(global_position, Color8(255, 118, 34), 4.8, 4.8, 7.2)
		"cryo":
			level_manager.explode(global_position, 8.8, 5, 0.10)
			if level_manager.has_method("apply_status_area"):
				level_manager.apply_status_area(global_position, 9.2, "slow", 0.48, 3.0)
				level_manager.apply_status_area(global_position, 5.4, "freeze", 0.0, 1.10)
			if level_manager.has_method("spawn_status_field"):
				level_manager.spawn_status_field(global_position, "cryo", Color8(118, 226, 255), 9.2, 4.4, 0.48)
		"toxic":
			level_manager.explode(global_position, 4.4, 6, 0.16)
			level_manager.spawn_burning_patch(global_position, Color8(112, 255, 86), 5.4, 6.2, 7.8)
		"shock":
			level_manager.explode(global_position, 6.6, 8, 0.16)
			if level_manager.has_method("apply_status_area"):
				level_manager.apply_status_area(global_position, 7.4, "stun", 0.0, 1.35)
			if level_manager.has_method("spawn_status_field"):
				level_manager.spawn_status_field(global_position, "shock", Color8(190, 120, 255), 7.2, 1.65, 0.0)
			if level_manager.has_method("spawn_lightning_burst"):
				level_manager.spawn_lightning_burst(global_position, 7.2, Color8(190, 120, 255))
		"cluster":
			level_manager.explode(global_position, 4.8, 11, 0.18)
			if level_manager.has_method("spawn_cluster_grenades"):
				level_manager.spawn_cluster_grenades(global_position, Color8(255, 204, 72))
		"cluster_child":
			level_manager.explode(global_position, 2.6, 6, 0.08)
		"ramp_barrel":
			level_manager.explode(global_position, 3.7, 8, 0.54, 0.0)
		_:
			level_manager.explode(global_position, 6.4, 18, 0.30)
