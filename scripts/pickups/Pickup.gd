extends Node3D
class_name Pickup

var kind = ""
var value = ""
var base_y = 0.0
var model_root: Node3D
var asset_factory

const IMPORTED_WEAPON_PICKUP_MODELS = {
	"pistol": {"path": "res://assets/models/weapons/pistol.glb", "size": 0.96, "rot": Vector3(0, 24, 0)},
	"shotgun": {"path": "res://assets/models/weapons/shotgun.glb", "size": 1.14, "rot": Vector3(0, 24, 0)},
	"auto": {"path": "res://assets/models/weapons/auto.glb", "size": 1.16, "rot": Vector3(0, 24, 0)},
	"plasma": {"path": "res://assets/models/weapons/plasma.glb", "size": 1.12, "rot": Vector3(0, 24, 0)},
	"heavy": {"path": "res://assets/models/weapons/heavy.glb", "size": 1.22, "rot": Vector3(0, 24, 0)},
	"railgun": {"path": "res://assets/models/weapons/railgun.glb", "size": 1.18, "rot": Vector3(0, 24, 0)},
	"incinerator": {"path": "res://assets/models/weapons/incinerator.glb", "size": 1.08, "rot": Vector3(0, 24, 0)},
	"seeker": {"path": "res://assets/models/weapons/seeker.glb", "size": 1.10, "rot": Vector3(0, 24, 0)}
}

func configure(factory, p_kind: String, p_value: String, color: Color, accent: Color = Color.WHITE) -> void:
	kind = p_kind
	value = p_value
	asset_factory = factory
	base_y = global_position.y
	model_root = Node3D.new()
	model_root.position.y = 0.55
	add_child(model_root)
	if kind == "key":
		model_root.scale = Vector3(1.42, 1.42, 1.42)
	_build_model(color, accent)
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.18 if kind == "key" else 0.42
	light.omni_range = 6.2 if kind == "key" else 2.9
	light.position.y = 0.8
	add_child(light)

func tick() -> void:
	rotate_y(0.025)
	global_position.y = base_y + sin(Time.get_ticks_msec() * 0.005 + global_position.x) * 0.12

func _build_model(color: Color, accent: Color) -> void:
	if kind == "key":
		_build_key(color)
	elif kind == "medkit":
		_build_medkit()
	elif kind == "ammo":
		_build_ammo(color)
	elif kind == "weapon":
		_build_weapon(color)
	elif kind == "powerup":
		_build_powerup(color, accent)
	else:
		_add_sphere(0.25, Vector3.ZERO, color, true)

func _build_key(color: Color) -> void:
	_add_sphere(0.18, Vector3(0.0, 0.08, 0.0), Color8(255, 246, 160), true)
	for i in 8:
		var a = TAU * float(i) / 8.0
		_add_sphere(0.078, Vector3(cos(a) * 0.31, 0.08, sin(a) * 0.31), color.lightened(0.14), true)
	_add_box(Vector3(0.70, 0.11, 0.11), Vector3(0.56, 0.08, 0), Vector3.ZERO, color.lightened(0.08), true)
	_add_box(Vector3(0.11, 0.30, 0.11), Vector3(0.82, -0.04, 0), Vector3.ZERO, color, true)
	_add_box(Vector3(0.11, 0.22, 0.11), Vector3(1.04, 0.01, 0), Vector3.ZERO, color, true)

func _build_medkit() -> void:
	_add_box(Vector3(0.58, 0.34, 0.42), Vector3.ZERO, Vector3.ZERO, Color8(236, 236, 230), false)
	_add_neon_outline(Vector3(0.66, 0.42, 0.50), Color8(174, 64, 255))
	_add_box(Vector3(0.12, 0.40, 0.46), Vector3(0, 0.02, 0), Vector3.ZERO, Color8(210, 28, 34), false)
	_add_box(Vector3(0.62, 0.12, 0.46), Vector3(0, 0.02, 0), Vector3.ZERO, Color8(210, 28, 34), false)
	_add_box(Vector3(0.44, 0.08, 0.08), Vector3(0, 0.24, 0), Vector3.ZERO, Color8(70, 70, 72), false)

func _build_ammo(color: Color) -> void:
	_add_box(Vector3(0.54, 0.34, 0.44), Vector3.ZERO, Vector3.ZERO, color.darkened(0.18), false)
	_add_neon_outline(Vector3(0.64, 0.44, 0.54), Color8(255, 118, 28))
	_add_box(Vector3(0.46, 0.08, 0.48), Vector3(0, 0.13, 0), Vector3.ZERO, color.lightened(0.16), false)
	_add_box(Vector3(0.38, 0.06, 0.08), Vector3(0, -0.02, -0.24), Vector3.ZERO, Color8(30, 30, 32), false)
	if value == "all":
		_add_box(Vector3(0.08, 0.22, 0.08), Vector3(-0.18, 0.24, -0.02), Vector3.ZERO, Color8(188, 82, 48), false)
		_add_box(Vector3(0.08, 0.22, 0.08), Vector3(0.00, 0.24, -0.02), Vector3.ZERO, Color8(80, 210, 240), true)
		_add_box(Vector3(0.08, 0.22, 0.08), Vector3(0.18, 0.24, -0.02), Vector3.ZERO, Color8(175, 176, 186), false)
		_add_sphere(0.10, Vector3(0.0, 0.30, 0.15), Color8(88, 156, 88), false)

func _build_weapon(color: Color) -> void:
	_add_cylinder(0.46, 0.08, Vector3(0, -0.28, 0), Vector3.ZERO, Color8(24, 26, 28), false)
	_add_cylinder(0.34, 0.045, Vector3(0, -0.21, 0), Vector3.ZERO, color.lightened(0.16), true)
	if _try_build_imported_weapon_pickup():
		return
	var accent = _weapon_accent(value, color)
	var armor = Color8(226, 222, 205)
	var metal = Color8(34, 38, 39)
	var dark = Color8(14, 17, 18)
	if value == "whip":
		_add_box(Vector3(0.34, 0.16, 0.22), Vector3(0.25, 0.02, 0), Vector3.ZERO, armor, false)
		_add_box(Vector3(0.20, 0.20, 0.26), Vector3(0.10, 0.03, 0), Vector3.ZERO, metal, false)
		for i in 8:
			var p = float(i) / 7.0
			var pos = Vector3(-0.10 - p * 0.70, sin(p * PI) * 0.22, 0)
			_add_box(Vector3(0.08, 0.07, 0.08), pos, Vector3(0, i * 18, 0), dark, false)
			_add_sphere(0.025, pos + Vector3(0, 0.035, 0), accent, true)
		_add_box(Vector3(0.18, 0.08, 0.18), Vector3(-0.90, 0.02, 0), Vector3(0, 45, 0), armor, false)
		_add_box(Vector3(0.06, 0.26, 0.06), Vector3(-0.98, 0.02, 0), Vector3(0, 0, 28), accent, true)
	elif value == "heavy":
		_build_sci_pickup_gun(0.94, 0.40, accent, true)
		_add_cylinder(0.16, 0.32, Vector3(-0.50, 0.06, 0), Vector3(0, 90, 0), dark, false)
		_add_cylinder(0.12, 0.26, Vector3(-0.57, 0.06, 0), Vector3(0, 90, 0), accent, true)
		_add_cylinder(0.13, 0.28, Vector3(0.16, -0.20, 0), Vector3(0, 0, 90), accent, false)
	elif value == "plasma":
		_build_sci_pickup_gun(0.74, 0.34, accent, false)
		_add_sphere(0.13, Vector3(-0.42, 0.06, 0), accent, true)
		_add_cylinder(0.06, 0.55, Vector3(-0.02, 0.10, 0.20), Vector3(0, 90, 0), accent, true)
		_add_cylinder(0.06, 0.55, Vector3(-0.02, 0.10, -0.20), Vector3(0, 90, 0), accent, true)
	elif value == "railgun":
		_build_sci_pickup_gun(1.08, 0.24, accent, false)
		_add_box(Vector3(1.16, 0.06, 0.07), Vector3(0, 0.17, -0.15), Vector3.ZERO, accent, true)
		_add_box(Vector3(1.16, 0.06, 0.07), Vector3(0, 0.17, 0.15), Vector3.ZERO, accent, true)
	elif value == "incinerator":
		_build_sci_pickup_gun(0.80, 0.36, accent, true)
		_add_sphere(0.13, Vector3(0.26, 0.15, 0.20), Color8(255, 190, 62), true)
		_add_cylinder(0.13, 0.30, Vector3(-0.44, 0.04, 0), Vector3(0, 90, 0), accent, true)
	else:
		var length = 0.58 if value == "pistol" else (0.96 if value == "shotgun" else 0.86)
		var height = 0.26 if value == "pistol" else 0.32
		_build_sci_pickup_gun(length, height, accent, value == "shotgun")
		_add_box(Vector3(0.16, 0.34, 0.16), Vector3(0.12, -0.22, 0), Vector3(0, 0, -12), dark, false)

func _try_build_imported_weapon_pickup() -> bool:
	if not IMPORTED_WEAPON_PICKUP_MODELS.has(value):
		return false
	var profile = IMPORTED_WEAPON_PICKUP_MODELS[value]
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
	holder.name = "ImportedPickupWeapon_%s" % value
	holder.position = Vector3(0, 0.08, 0)
	holder.rotation_degrees = profile.rot
	model_root.add_child(holder)
	holder.add_child(imported)
	_prepare_imported_pickup_node(imported)
	_normalize_imported_pickup(imported, float(profile.size))
	return true

func _prepare_imported_pickup_node(root: Node) -> void:
	for node in _walk_imported_pickup_nodes(root):
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

func _walk_imported_pickup_nodes(root: Node) -> Array:
	var out = [root]
	for child in root.get_children():
		out.append_array(_walk_imported_pickup_nodes(child))
	return out

func _normalize_imported_pickup(root: Node3D, target_size: float) -> void:
	var bounds = _imported_pickup_bounds(root)
	if bounds.size == Vector3.ZERO:
		return
	var longest = max(bounds.size.x, max(bounds.size.y, bounds.size.z))
	if longest <= 0.001:
		return
	var scale_ratio = target_size / longest
	var center = bounds.position + bounds.size * 0.5
	root.scale *= scale_ratio
	root.position -= center * scale_ratio

func _imported_pickup_bounds(root: Node3D) -> AABB:
	var found = false
	var bounds = AABB()
	var root_inv = root.global_transform.affine_inverse()
	for node in _walk_imported_pickup_nodes(root):
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

func _build_sci_pickup_gun(length: float, height: float, accent: Color, bulky: bool) -> void:
	var armor = Color8(226, 222, 205)
	var metal = Color8(34, 38, 39)
	var dark = Color8(14, 17, 18)
	_add_box(Vector3(length, height, 0.30 if not bulky else 0.38), Vector3.ZERO, Vector3.ZERO, metal, false)
	_add_box(Vector3(length * 0.72, height * 0.45, 0.34 if not bulky else 0.42), Vector3(0.04, height * 0.34, 0), Vector3.ZERO, armor, false)
	_add_box(Vector3(length * 0.44, 0.055, 0.42 if bulky else 0.34), Vector3(0.02, height * 0.58, 0), Vector3.ZERO, accent, true)
	_add_box(Vector3(0.12, height * 0.70, 0.34), Vector3(length * 0.30, -height * 0.35, 0), Vector3(0, 0, -10), dark, false)
	_add_cylinder(0.055 if not bulky else 0.09, 0.34, Vector3(-length * 0.55, 0.06, 0), Vector3(0, 90, 0), dark, false)
	for i in 4:
		_add_box(Vector3(0.045, 0.025, 0.035), Vector3(-length * 0.22 + i * length * 0.13, height * 0.64, 0.19), Vector3.ZERO, accent if i % 2 == 0 else Color8(58, 62, 64), i % 2 == 0)

func _weapon_accent(id: String, fallback: Color) -> Color:
	match id:
		"plasma":
			return Color8(72, 255, 96)
		"railgun":
			return Color8(178, 72, 255)
		"heavy", "shotgun", "incinerator", "whip":
			return Color8(236, 178, 34)
		_:
			return Color8(72, 220, 240) if fallback == Color.WHITE else fallback.lightened(0.15)

func _build_powerup(color: Color, accent: Color) -> void:
	_add_sphere(0.27, Vector3.ZERO, color, true)
	_add_sphere(0.12, Vector3(0, 0.03, 0), accent, true)
	for i in 4:
		var a = TAU * float(i) / 4.0
		_add_box(Vector3(0.34, 0.035, 0.035), Vector3(cos(a) * 0.32, 0, sin(a) * 0.32), Vector3(0, -rad_to_deg(a), 0), color.lightened(0.16), true)

func _add_box(size: Vector3, pos: Vector3, rot_deg: Vector3, color: Color, glow: bool) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	return _add_mesh(mesh, pos, rot_deg, color, glow)

func _add_cylinder(radius: float, height: float, pos: Vector3, rot_deg: Vector3, color: Color, glow: bool) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return _add_mesh(mesh, pos, rot_deg, color, glow)

func _add_sphere(radius: float, pos: Vector3, color: Color, glow: bool) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return _add_mesh(mesh, pos, Vector3.ZERO, color, glow)

func _add_neon_outline(size: Vector3, color: Color) -> void:
	var sx = size.x
	var sy = size.y
	var sz = size.z
	var t = 0.035
	for y in [-sy * 0.5, sy * 0.5]:
		for z in [-sz * 0.5, sz * 0.5]:
			_add_box(Vector3(sx, t, t), Vector3(0, y, z), Vector3.ZERO, color, true)
	for x in [-sx * 0.5, sx * 0.5]:
		for z in [-sz * 0.5, sz * 0.5]:
			_add_box(Vector3(t, sy, t), Vector3(x, 0, z), Vector3.ZERO, color, true)
	for x in [-sx * 0.5, sx * 0.5]:
		for y in [-sy * 0.5, sy * 0.5]:
			_add_box(Vector3(t, t, sz), Vector3(x, y, 0), Vector3.ZERO, color, true)

func _add_mesh(mesh: Mesh, pos: Vector3, rot_deg: Vector3, color: Color, glow: bool) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot_deg
	node.material_override = asset_factory.make_glow_material(color, 0.9) if glow else asset_factory.make_flat_material(color)
	model_root.add_child(node)
	return node
