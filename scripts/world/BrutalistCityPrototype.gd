extends Node3D

const TILE = 4.0
const ASSET_ROOT = "res://assets/environment/brutalist_city/urban/"

var _scene_cache: Dictionary = {}

func build() -> void:
	name = "BrutalistCityVisualPrototype"
	var concrete = _material(Color8(52, 54, 53))
	var concrete_light = _material(Color8(91, 88, 80))
	var charcoal = _material(Color8(23, 25, 25))
	var dirty_white = _material(Color8(157, 153, 139))
	var amber = _material(Color8(191, 139, 55), 1.25)
	var cyan = _material(Color8(71, 139, 137), 0.82)
	var warning = _material(Color8(145, 43, 34), 0.72)

	_add_city_ambient_light()

	# Imported urban buildings sit on low collision-backed plinths. The two far
	# masses remain as the monumental brutalist skyline.
	_add_box(Vector3(31, 1.8, 27), Vector3(34, 6.1, 24), Vector3.ZERO, concrete)
	_add_box(Vector3(31, 2.2, 23), Vector3(86, 6.3, 22), Vector3.ZERO, charcoal)
	_add_mass(Vector3(134, 9.2, 26), Vector3(23, 7.8, 31), concrete, dirty_white, warning, 2)
	_add_box(Vector3(35, 1.8, 23), Vector3(36, 6.1, 86), Vector3.ZERO, charcoal)
	_add_box(Vector3(31, 1.8, 19), Vector3(94, 6.1, 88), Vector3.ZERO, concrete)
	_add_mass(Vector3(138, 12.0, 84), Vector3(15, 13.5, 27), charcoal, concrete_light, warning, 5)

	# A suspended civic bridge sells the failed-utopia scale without changing routes.
	_add_box(Vector3(45, 1.25, 4.2), Vector3(82, 11.8, 57), Vector3.ZERO, charcoal)
	_add_box(Vector3(42, 0.12, 0.20), Vector3(82, 11.25, 54.9), Vector3.ZERO, amber)
	_add_box(Vector3(42, 0.12, 0.20), Vector3(82, 11.25, 59.1), Vector3.ZERO, cyan)

	_add_street_markings(amber, dirty_white)
	_add_lighting(amber, cyan, warning)
	_add_imported_details()
	_add_haze(charcoal)

func _add_mass(center: Vector3, box_size: Vector3, body_mat: Material, cap_mat: Material, accent_mat: Material, seed: int) -> void:
	_add_box(box_size, center, Vector3.ZERO, body_mat)
	_add_box(Vector3(box_size.x + 0.5, 0.38, box_size.z + 0.5), center + Vector3(0, box_size.y * 0.5 + 0.18, 0), Vector3.ZERO, cap_mat)
	var front_z = center.z - box_size.z * 0.5 - 0.03
	for floor_index in range(3):
		var y = center.y - box_size.y * 0.29 + floor_index * min(2.15, box_size.y * 0.22)
		var strip_width = box_size.x * (0.46 if (floor_index + seed) % 2 == 0 else 0.28)
		var offset_x = box_size.x * 0.15 if (floor_index + seed) % 2 == 0 else -box_size.x * 0.18
		_add_box(Vector3(strip_width, 0.16, 0.08), Vector3(center.x + offset_x, y, front_z), Vector3.ZERO, accent_mat)
	for column in range(3):
		var x = center.x - box_size.x * 0.32 + column * box_size.x * 0.32
		_add_box(Vector3(0.32, box_size.y * 0.72, 0.18), Vector3(x, center.y, front_z - 0.03), Vector3.ZERO, cap_mat)

func _add_street_markings(amber: Material, dirty_white: Material) -> void:
	for index in range(14):
		var x = 10.0 + index * 10.5
		_add_box(Vector3(4.8, 0.025, 0.18), Vector3(x, 0.025, 55.0), Vector3.ZERO, dirty_white)
		_add_box(Vector3(4.8, 0.025, 0.10), Vector3(x, 0.026, 61.0), Vector3.ZERO, amber)
	for z in [45.0, 71.0]:
		_add_box(Vector3(148.0, 0.022, 0.09), Vector3(82.0, 0.024, z), Vector3.ZERO, dirty_white)

func _add_lighting(amber: Material, cyan: Material, warning: Material) -> void:
	var light_specs = [
		[Vector3(20, 3.0, 48), Color8(210, 153, 65)], [Vector3(52, 3.0, 67), Color8(81, 155, 151)],
		[Vector3(80, 3.0, 48), Color8(210, 153, 65)], [Vector3(110, 3.0, 67), Color8(81, 155, 151)],
		[Vector3(140, 3.0, 48), Color8(178, 58, 43)], [Vector3(151, 3.0, 67), Color8(210, 153, 65)]
	]
	for spec in light_specs:
		var pos: Vector3 = spec[0]
		var color: Color = spec[1]
		var pole_mat = warning if color.r > color.g * 1.7 else (amber if color.r > color.b * 1.4 else cyan)
		_add_box(Vector3(0.56, 0.08, 0.24), pos - Vector3(0, 0.12, 0), Vector3.ZERO, pole_mat)
		_add_sphere(0.19, pos - Vector3(0, 0.22, 0), _material(color, 2.8))
		_add_sphere(0.34, pos - Vector3(0, 0.22, 0), _transparent_glow(color, 0.18))
		var light = OmniLight3D.new()
		light.position = pos - Vector3(0, 0.32, 0)
		light.light_color = color
		light.light_energy = 1.65
		light.omni_range = 12.5
		light.shadow_enabled = false
		add_child(light)

func _add_imported_details() -> void:
	_instance_asset("flat_Lshape_large_alt.glb", Vector3(34, 7.0, 24), 90.0, 12.0)
	_instance_asset("flat_square_concrete.glb", Vector3(86, 7.4, 22), 180.0, 13.0)
	_instance_asset("flat_square_brick.glb", Vector3(94, 7.0, 88), 0.0, 10.5)
	_instance_asset("Hangar1.glb", Vector3(36, 7.0, 86), 90.0, 8.5)
	for spec in [
		["street_light.glb", Vector3(20, 0, 48), 0.0, 3.4],
		["street_light.glb", Vector3(52, 0, 67), 180.0, 3.4],
		["street_light.glb", Vector3(80, 0, 48), 0.0, 3.4],
		["street_light.glb", Vector3(110, 0, 67), 180.0, 3.4],
		["street_light.glb", Vector3(140, 0, 48), 0.0, 3.4],
		["street_light.glb", Vector3(151, 0, 67), 180.0, 3.4],
		["busstop.glb", Vector3(69, 0, 49), 180.0, 2.5],
		["busstop.glb", Vector3(124, 0, 68), 0.0, 2.5],
		["dumpster_lid_closed.glb", Vector3(115, 0, 69), 90.0, 1.15],
		["dumpster_lid_closed.glb", Vector3(44, 0, 47), -90.0, 1.15],
		["pipe_rusted.glb", Vector3(18, 0, 68), 0.0, 1.25],
		["duct_long.glb", Vector3(127, 5.4, 38), 90.0, 1.5]
	]:
		_instance_asset(spec[0], spec[1], spec[2], spec[3])

func _instance_asset(file_name: String, world_pos: Vector3, yaw: float, target_height: float) -> void:
	var path = ASSET_ROOT + file_name
	var scene: PackedScene = _scene_cache.get(path)
	if scene == null:
		if not ResourceLoader.exists(path):
			return
		var loaded = load(path)
		if not loaded is PackedScene:
			return
		scene = loaded
		_scene_cache[path] = scene
	var imported = scene.instantiate()
	if not imported is Node3D:
		imported.queue_free()
		return
	var holder = Node3D.new()
	holder.name = file_name.get_basename()
	holder.position = world_pos
	holder.rotation_degrees.y = yaw
	add_child(holder)
	holder.add_child(imported)
	_prepare_import(imported)
	_normalize_import(imported, target_height)

func _prepare_import(root: Node) -> void:
	if root is MeshInstance3D:
		root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if root is CollisionObject3D:
		root.collision_layer = 0
		root.collision_mask = 0
	if root is CollisionShape3D:
		root.disabled = true
	if root is Light3D:
		root.visible = false
	if root is Camera3D:
		root.current = false
	for child in root.get_children():
		_prepare_import(child)

func _normalize_import(root: Node3D, target_height: float) -> void:
	var bounds = _bounds_for(root)
	if bounds.size.y <= 0.001:
		return
	var ratio = target_height / bounds.size.y
	var center = bounds.position + bounds.size * 0.5
	root.scale = Vector3.ONE * ratio
	root.position = Vector3(-center.x * ratio, -bounds.position.y * ratio, -center.z * ratio)

func _bounds_for(root: Node3D) -> AABB:
	var found = false
	var result = AABB()
	var inverse = root.global_transform.affine_inverse()
	for node in _walk(root):
		if not node is MeshInstance3D:
			continue
		var mesh_node: MeshInstance3D = node
		var box = mesh_node.get_aabb()
		for corner in _aabb_corners(box):
			var point = inverse * mesh_node.to_global(corner)
			if not found:
				result = AABB(point, Vector3.ZERO)
				found = true
			else:
				result = result.expand(point)
	return result if found else AABB()

func _walk(root: Node) -> Array:
	var nodes: Array = [root]
	for child in root.get_children():
		nodes.append_array(_walk(child))
	return nodes

func _aabb_corners(box: AABB) -> Array:
	var p = box.position
	var s = box.size
	return [p, p + Vector3(s.x, 0, 0), p + Vector3(0, s.y, 0), p + Vector3(0, 0, s.z), p + Vector3(s.x, s.y, 0), p + Vector3(s.x, 0, s.z), p + Vector3(0, s.y, s.z), p + s]

func _add_haze(charcoal: Material) -> void:
	for z in [39.0, 77.0]:
		var haze_mat = charcoal.duplicate()
		haze_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		haze_mat.albedo_color.a = 0.055
		haze_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_add_box(Vector3(160, 4.5, 0.08), Vector3(80, 2.3, z), Vector3.ZERO, haze_mat)

func _add_box(box_size: Vector3, pos: Vector3, rotation: Vector3, material: Material) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = box_size
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rotation
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _add_sphere(radius: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _add_city_ambient_light() -> void:
	var ambient = DirectionalLight3D.new()
	ambient.name = "OvercastCityAmbient"
	ambient.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	ambient.light_color = Color8(126, 137, 137)
	ambient.light_energy = 0.46
	ambient.shadow_enabled = false
	add_child(ambient)

func _transparent_glow(color: Color, alpha: float) -> StandardMaterial3D:
	var mat = _material(color, 1.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = alpha
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _material(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	return mat
