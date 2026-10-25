extends Node3D
class_name FriendlyTurret

var level_manager
var player
var asset_factory
var normal = Vector3.UP
var cooldown = 0.0
var life = 32.0
var hp = 42
var max_hp = 42
var barrel: Node3D
var muzzle: Marker3D
var hp_bar: MeshInstance3D

func configure(factory, lm, player_node, surface_normal: Vector3) -> void:
	asset_factory = factory
	level_manager = lm
	player = player_node
	normal = surface_normal.normalized() if surface_normal.length() > 0.01 else Vector3.UP
	_align_to_surface()
	_build_visual()

func tick(dt: float) -> bool:
	life -= dt
	if life <= 0.0 or hp <= 0:
		_destroy()
		return false
	cooldown = max(0.0, cooldown - dt)
	var target_enemy = _nearest_enemy()
	if target_enemy != null and is_instance_valid(target_enemy):
		var target = target_enemy.global_position + Vector3(0, target_enemy.stats.height * 0.58, 0)
		barrel.look_at(target, normal)
		if cooldown <= 0.0:
			_fire(target)
	return true

func _align_to_surface() -> void:
	var up = normal
	var basis_seed = Vector3.FORWARD
	if abs(basis_seed.dot(up)) > 0.90:
		basis_seed = Vector3.RIGHT
	var right = basis_seed.cross(up).normalized()
	var forward = up.cross(right).normalized()
	global_transform.basis = Basis(right, up, forward).orthonormalized()

func _build_visual() -> void:
	var metal = asset_factory.make_flat_material(Color8(34, 40, 42))
	var armor = asset_factory.make_flat_material(Color8(210, 210, 190))
	var glow = asset_factory.make_glow_material(Color8(86, 238, 255), 0.92)
	var base = MeshInstance3D.new()
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.44
	base_mesh.bottom_radius = 0.54
	base_mesh.height = 0.20
	base_mesh.radial_segments = 10
	base.mesh = base_mesh
	base.material_override = metal
	add_child(base)
	var head = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.62, 0.34, 0.52)
	head.mesh = head_mesh
	head.position.y = 0.32
	head.material_override = armor
	add_child(head)
	var eye = MeshInstance3D.new()
	var eye_mesh = BoxMesh.new()
	eye_mesh.size = Vector3(0.34, 0.08, 0.055)
	eye.mesh = eye_mesh
	eye.position = Vector3(0, 0.38, -0.285)
	eye.material_override = glow
	add_child(eye)
	barrel = Node3D.new()
	barrel.name = "TurretBarrel"
	barrel.position.y = 0.38
	add_child(barrel)
	var tube = MeshInstance3D.new()
	var tube_mesh = CylinderMesh.new()
	tube_mesh.top_radius = 0.075
	tube_mesh.bottom_radius = 0.095
	tube_mesh.height = 0.82
	tube_mesh.radial_segments = 8
	tube.mesh = tube_mesh
	tube.rotation_degrees.x = 90
	tube.position.z = -0.46
	tube.material_override = metal
	barrel.add_child(tube)
	var tip = MeshInstance3D.new()
	var tip_mesh = CylinderMesh.new()
	tip_mesh.top_radius = 0.11
	tip_mesh.bottom_radius = 0.13
	tip_mesh.height = 0.18
	tip_mesh.radial_segments = 8
	tip.mesh = tip_mesh
	tip.rotation_degrees.x = 90
	tip.position.z = -0.91
	tip.material_override = glow
	barrel.add_child(tip)
	muzzle = Marker3D.new()
	muzzle.position = Vector3(0, 0, -1.05)
	barrel.add_child(muzzle)
	hp_bar = MeshInstance3D.new()
	var hp_mesh = BoxMesh.new()
	hp_mesh.size = Vector3(0.72, 0.055, 0.035)
	hp_bar.mesh = hp_mesh
	hp_bar.position = Vector3(0, 0.78, 0)
	hp_bar.material_override = asset_factory.make_flat_material(Color8(88, 244, 136))
	add_child(hp_bar)

func _nearest_enemy():
	var best = null
	var best_d = 26.0 * 26.0
	for e in level_manager.enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best = e
			best_d = d
	return best

func _fire(target: Vector3) -> void:
	cooldown = 0.24
	var aim_dir = (target - muzzle.global_position).normalized()
	var origin = muzzle.global_position + aim_dir * 0.46 + normal * 0.10
	var dir = (target - origin).normalized()
	level_manager.spawn_muzzle_flash(origin, dir, Color8(86, 238, 255))
	level_manager.spawn_player_projectile(origin, dir, 24.0, 1, false, 0.0, 0, Color8(86, 238, 255), 0, false, 0.46)
	level_manager.sound_requested.emit("pistol")

func damage(amount: int, _source: Vector3 = Vector3.ZERO) -> void:
	hp = max(0, hp - amount)
	if hp_bar != null:
		hp_bar.scale.x = max(0.05, float(hp) / float(max_hp))
	if level_manager != null:
		level_manager.spawn_impact_fx(global_position + normal * 0.32, Color8(86, 238, 255))

func _destroy() -> void:
	if level_manager != null:
		level_manager.spawn_impact_fx(global_position + normal * 0.22, Color8(86, 238, 255))
