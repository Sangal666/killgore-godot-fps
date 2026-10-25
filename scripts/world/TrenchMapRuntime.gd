extends Node3D
class_name TrenchMapRuntime

const MAP_UNIT_TO_GODOT = 1.0 / 64.0
const PLAYER_RADIUS = 0.34
const PLAYER_HEIGHT = 1.72
const SPATIAL_CELL_SIZE = 6.0
const ART_LAYER_SCENE_PATH = "res://scenes/levels/Level10ArtLayer.tscn"
const CONCRETE_TEXTURE_PATH = "res://assets/textures/level10/brutalist_concrete.png"
const METAL_TEXTURE_PATH = "res://assets/textures/level10/aged_maintenance_metal.png"
const ART_MODE_SCENE = "scene"
const ART_MODE_PROCEDURAL = "procedural"
const ART_MODE_NONE = "none"

var asset_factory
var theme
var map_path := ""
var map_root: Node3D
var faces: Array = []
var floor_faces: Array = []
var wall_faces: Array = []
var ceiling_faces: Array = []
var solid_brushes: Array = []
var spatial_faces := {}
var spatial_floors := {}
var spatial_walls := {}
var spatial_ceilings := {}
var bounds := AABB()
var map_offset := Vector3.ZERO
var spawn_pos := Vector3.ZERO
var exit_pos := Vector3.ZERO
var visual_material_cache := {}
var art_mode := ART_MODE_SCENE

func configure(factory, level_theme, path: String, requested_art_mode: String = ART_MODE_SCENE) -> bool:
	asset_factory = factory
	theme = level_theme
	map_path = path
	art_mode = requested_art_mode
	map_root = Node3D.new()
	map_root.name = "Map1V2Runtime"
	add_child(map_root)
	return _load_map()

func _load_map() -> bool:
	var raw_brushes = _parse_map_brushes()
	var brush_data = []
	for planes in raw_brushes:
		var brush = _build_brush(planes)
		if not brush.is_empty():
			brush_data.append(brush)
	if brush_data.is_empty():
		push_error("No valid brushes parsed from %s" % map_path)
		return false
	bounds = brush_data[0].bounds
	for i in range(1, brush_data.size()):
		bounds = bounds.merge(brush_data[i].bounds)
	map_offset = Vector3(
		-(bounds.position.x + bounds.size.x * 0.5),
		-bounds.position.y,
		-bounds.position.z + 1.8
	)
	_add_map_visual(brush_data)
	_build_spatial_index()
	_prepare_spawn_position()
	_prepare_exit_position()
	_add_art_layer()
	return true

func _add_art_layer() -> void:
	if art_mode == ART_MODE_NONE:
		return
	if art_mode == ART_MODE_SCENE and ResourceLoader.exists(ART_LAYER_SCENE_PATH):
		var packed = load(ART_LAYER_SCENE_PATH)
		if packed is PackedScene:
			var art_layer = packed.instantiate()
			art_layer.name = "Level10EditableArtLayer"
			map_root.add_child(art_layer)
			return
	_add_brutalist_digital_decay_dressing()

func _parse_map_brushes() -> Array:
	var file = FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		push_error("Could not open map file: %s" % map_path)
		return []
	var text = file.get_as_text()
	var out = []
	var coord_regex = RegEx.new()
	coord_regex.compile("\\(\\s*(-?\\d+(?:\\.\\d+)?)\\s+(-?\\d+(?:\\.\\d+)?)\\s+(-?\\d+(?:\\.\\d+)?)\\s*\\)")
	var in_brush = false
	var brace_depth = 0
	var current = []
	for raw_line in text.split("\n"):
		var line = raw_line.strip_edges()
		if line.begins_with("// brush"):
			in_brush = true
			brace_depth = 0
			current = []
			continue
		if in_brush and line == "{":
			brace_depth += 1
			continue
		if in_brush and line == "}":
			brace_depth -= 1
			if brace_depth <= 0:
				if current.size() >= 4:
					out.append(current)
				in_brush = false
			continue
		if not in_brush:
			continue
		var matches = coord_regex.search_all(line)
		if matches.size() < 3:
			continue
		var pts = []
		for i in 3:
			var match_item = matches[i]
			var tb = Vector3(
				float(match_item.get_string(1)),
				float(match_item.get_string(2)),
				float(match_item.get_string(3))
			)
			pts.append(_tb_to_godot(tb))
		var normal = (pts[1] - pts[0]).cross(pts[2] - pts[0])
		if normal.length() <= 0.0001:
			continue
		normal = normal.normalized()
		current.append({"normal": normal, "d": normal.dot(pts[0])})
	return out

func _tb_to_godot(point: Vector3) -> Vector3:
	return Vector3(point.x, point.z, point.y) * MAP_UNIT_TO_GODOT

func _build_brush(input_planes: Array) -> Dictionary:
	var best = {}
	var best_count = 0
	for side_sign in [1.0, -1.0]:
		var planes = []
		for p in input_planes:
			planes.append({"normal": p.normal * side_sign, "d": float(p.d) * side_sign})
		var verts = _brush_vertices_from_planes(planes)
		if verts.size() > best_count:
			var polys = _brush_polygons_from_vertices(planes, verts)
			if not polys.is_empty():
				best = {"planes": planes, "vertices": verts, "polys": polys, "bounds": _points_to_bounds(verts)}
				best_count = verts.size()
	return best

func _brush_vertices_from_planes(planes: Array) -> Array:
	var verts = []
	for i in planes.size():
		for j in range(i + 1, planes.size()):
			for k in range(j + 1, planes.size()):
				var point = _intersect_three_planes(planes[i], planes[j], planes[k])
				if point != null and _point_inside_planes(point, planes):
					_add_unique_point(verts, point)
	return verts

func _intersect_three_planes(a: Dictionary, b: Dictionary, c: Dictionary):
	var n1: Vector3 = a.normal
	var n2: Vector3 = b.normal
	var n3: Vector3 = c.normal
	var denom = n1.dot(n2.cross(n3))
	if abs(denom) < 0.00001:
		return null
	return ((n2.cross(n3) * float(a.d)) + (n3.cross(n1) * float(b.d)) + (n1.cross(n2) * float(c.d))) / denom

func _point_inside_planes(point: Vector3, planes: Array) -> bool:
	for plane in planes:
		if plane.normal.dot(point) - float(plane.d) > 0.035:
			return false
	return true

func _add_unique_point(points: Array, point: Vector3) -> void:
	for existing in points:
		if existing.distance_to(point) < 0.015:
			return
	points.append(point)

func _brush_polygons_from_vertices(planes: Array, verts: Array) -> Array:
	var polys = []
	for plane in planes:
		var poly = []
		for v in verts:
			if abs(plane.normal.dot(v) - float(plane.d)) < 0.045:
				poly.append(v)
		if poly.size() < 3:
			continue
		poly = _sort_polygon(poly, plane.normal)
		var poly_normal = _polygon_normal(poly)
		if poly_normal.dot(plane.normal) < 0.0:
			poly.reverse()
			poly_normal = -poly_normal
		polys.append({"points": poly, "normal": poly_normal.normalized(), "d": poly_normal.normalized().dot(poly[0]), "aabb": _points_to_bounds(poly)})
	return polys

func _sort_polygon(poly: Array, normal: Vector3) -> Array:
	var center = Vector3.ZERO
	for p in poly:
		center += p
	center /= float(poly.size())
	var u = normal.cross(Vector3.UP)
	if u.length() < 0.001:
		u = normal.cross(Vector3.RIGHT)
	u = u.normalized()
	var v = normal.cross(u).normalized()
	poly.sort_custom(func(a, b):
		var da = a - center
		var db = b - center
		return atan2(da.dot(v), da.dot(u)) < atan2(db.dot(v), db.dot(u))
	)
	return poly

func _polygon_normal(poly: Array) -> Vector3:
	if poly.size() < 3:
		return Vector3.UP
	var n = Vector3.ZERO
	for i in poly.size():
		var a: Vector3 = poly[i]
		var b: Vector3 = poly[(i + 1) % poly.size()]
		n.x += (a.y - b.y) * (a.z + b.z)
		n.y += (a.z - b.z) * (a.x + b.x)
		n.z += (a.x - b.x) * (a.y + b.y)
	return n.normalized() if n.length() > 0.0001 else Vector3.UP

func _add_map_visual(brush_data: Array) -> void:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	faces.clear()
	floor_faces.clear()
	wall_faces.clear()
	ceiling_faces.clear()
	solid_brushes.clear()
	for brush_index in brush_data.size():
		var brush: Dictionary = brush_data[brush_index]
		var transformed_planes = []
		for plane in brush.planes:
			var plane_normal: Vector3 = plane.normal
			transformed_planes.append({
				"normal": plane_normal,
				"d": float(plane.d) + plane_normal.dot(map_offset)
			})
		solid_brushes.append({
			"planes": transformed_planes,
			"bounds": AABB(brush.bounds.position + map_offset, brush.bounds.size)
		})
		var brush_color = _brush_color(brush_index)
		for poly_info in brush.polys:
			var transformed = []
			for p in poly_info.points:
				transformed.append(p + map_offset)
			var normal: Vector3 = poly_info.normal
			var base = verts.size()
			for p in transformed:
				verts.append(p)
				normals.append(normal)
				colors.append(brush_color)
			for i in range(1, transformed.size() - 1):
				indices.append(base)
				indices.append(base + i)
				indices.append(base + i + 1)
			var face = {
				"id": faces.size(),
				"points": transformed,
				"normal": normal,
				"d": normal.dot(transformed[0]),
				"aabb": _points_to_bounds(transformed)
			}
			faces.append(face)
			if normal.y > 0.28:
				floor_faces.append(face)
			elif normal.y < -0.28:
				ceiling_faces.append(face)
			else:
				wall_faces.append(face)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance = MeshInstance3D.new()
	instance.name = "Map_1_V2_CombinedBrushes"
	instance.mesh = mesh
	instance.material_override = _map_material()
	map_root.add_child(instance)
	bounds = AABB(bounds.position + map_offset, bounds.size)

func _brush_color(index: int) -> Color:
	var palette = [
		Color8(46, 48, 47),
		Color8(29, 31, 33),
		Color8(59, 58, 54),
		Color8(78, 73, 62),
		Color8(36, 40, 42),
		Color8(89, 82, 65),
		Color8(49, 53, 53)
	]
	return palette[index % palette.size()]

func _map_material() -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D concrete_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D metal_tex : source_color, repeat_enable, filter_linear_mipmap;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec4 vertex_tint;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 triplanar_sample(sampler2D tex, vec3 p, vec3 normal, float texture_scale) {
	vec3 weights = pow(abs(normal), vec3(4.0));
	weights /= max(weights.x + weights.y + weights.z, 0.0001);
	vec3 x_sample = texture(tex, p.zy * texture_scale).rgb;
	vec3 y_sample = texture(tex, p.xz * texture_scale).rgb;
	vec3 z_sample = texture(tex, p.xy * texture_scale).rgb;
	return x_sample * weights.x + y_sample * weights.y + z_sample * weights.z;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	vertex_tint = COLOR;
}

void fragment() {
	vec3 normal = normalize(world_normal);
	vec3 base = max(vertex_tint.rgb, vec3(0.09));
	float wallness = 1.0 - abs(world_normal.y);
	float horizontal_surface = smoothstep(0.54, 0.92, abs(normal.y));
	vec3 concrete_texel = triplanar_sample(concrete_tex, world_pos, normal, 0.155);
	vec3 metal_texel = triplanar_sample(metal_tex, world_pos, normal, 0.118);
	vec3 surface_texel = mix(concrete_texel, metal_texel, horizontal_surface * 0.82);
	float coarse = hash21(floor(world_pos.xz * 1.35));
	float fine = hash21(floor((world_pos.xy + world_pos.zy) * 5.0));
	float damp = smoothstep(0.60, 0.98, hash21(vec2(floor(world_pos.x * 0.42), floor(world_pos.z * 0.34))));
	float vertical_stain = smoothstep(0.72, 0.98, sin(world_pos.x * 0.53 + world_pos.z * 0.29) * 0.5 + 0.5) * wallness;
	float seam_x = 1.0 - smoothstep(0.0, 0.025, abs(fract(world_pos.x * 0.25) - 0.5));
	float seam_z = 1.0 - smoothstep(0.0, 0.025, abs(fract(world_pos.z * 0.25) - 0.5));
	float seam = max(seam_x, seam_z) * (0.16 + wallness * 0.10);
	float wear = coarse * 0.08 + fine * 0.035;
	vec3 concrete = surface_texel * (0.46 + base * 0.68) * (0.96 + wear);
	concrete *= 1.0 - damp * 0.07 - vertical_stain * 0.06 - seam * 0.58;
	concrete += horizontal_surface * vec3(0.135, 0.126, 0.105);
	float old_paint = smoothstep(0.76, 0.94, hash21(floor(world_pos.xz * 0.20 + world_pos.y * 0.13)));
	concrete = mix(concrete, vec3(0.46, 0.45, 0.40), old_paint * 0.10);
	ALBEDO = max(concrete, vec3(0.045));
	EMISSION = concrete * (0.028 + horizontal_surface * 0.075);
	ROUGHNESS = clamp(0.78 + coarse * 0.18 + damp * 0.04 - horizontal_surface * 0.16, 0.0, 1.0);
	METALLIC = mix(0.025, 0.22, horizontal_surface);
}
"""
	mat.shader = shader
	if ResourceLoader.exists(CONCRETE_TEXTURE_PATH):
		mat.set_shader_parameter("concrete_tex", load(CONCRETE_TEXTURE_PATH))
	if ResourceLoader.exists(METAL_TEXTURE_PATH):
		mat.set_shader_parameter("metal_tex", load(METAL_TEXTURE_PATH))
	return mat

func _add_brutalist_digital_decay_dressing() -> void:
	if not is_instance_valid(map_root):
		return
	var dressing = Node3D.new()
	dressing.name = "BrutalistDigitalDecayDressing"
	map_root.add_child(dressing)
	_add_global_decay_fill(dressing)
	_add_decay_light_pools(dressing)
	_add_story_landmarks(dressing)
	_add_memory_landmarks(dressing)
	_add_brutalist_portal_ribs(dressing)
	_add_route_spine(dressing)
	_add_overhead_service_network(dressing)
	_add_wall_maintenance_spines(dressing)
	_add_corridor_codes(dressing)
	_add_architectural_maintenance_frames(dressing)
	_add_abandoned_workstations(dressing)
	_add_floor_direction_strips(dressing)
	_add_wall_terminal_panels(dressing)
	_add_digital_decay_scars(dressing)
	_add_wayfinding_markers(dressing)
	_add_server_room_remnants(dressing)
	_add_ceiling_light_fixtures(dressing)
	_add_ceiling_cable_runs(dressing)
	_add_decay_fog_bands(dressing)

func _add_memory_landmarks(parent: Node3D) -> void:
	var route = exit_pos - spawn_pos
	route.y = 0.0
	if route.length() < 4.0:
		return
	var forward = route.normalized()
	var right = Vector3(forward.z, 0.0, -forward.x)
	var yaw = rad_to_deg(atan2(forward.x, forward.z))
	_add_entry_observation_gate(parent, spawn_pos + forward * 4.8, forward, right, yaw)
	_add_memory_archive(parent, spawn_pos.lerp(exit_pos, 0.52), forward, right, yaw)
	_add_exit_recovery_frame(parent, exit_pos - forward * 2.8, right, yaw)

func _add_entry_observation_gate(parent: Node3D, center: Vector3, forward: Vector3, right: Vector3, yaw: float) -> void:
	var floor_y = floor_height_at(center)
	if floor_y == -INF:
		floor_y = spawn_pos.y
	var concrete = _visual_mat("landmark_entry_concrete", Color8(41, 43, 42), 0.0, 1.0, 0.03)
	var dirty_white = _visual_mat("landmark_entry_dirty_white", Color8(133, 130, 116), 0.0, 0.96, 0.06)
	var cyan = _visual_mat("landmark_entry_cyan", Color8(72, 151, 146), 0.68, 0.86, 0.02)
	for side in [-1.0, 1.0]:
		var suffix = "L" if side < 0.0 else "R"
		var pillar_pos = center + right * side * 2.55
		pillar_pos.y = floor_y + 1.75
		_add_visual_box(parent, "ArchitectureEntryPillar_%s" % suffix, Vector3(0.58, 3.50, 0.72), pillar_pos, Vector3(0, yaw, 0), concrete)
		_add_visual_box(parent, "ArchitectureEntryInset_%s" % suffix, Vector3(0.64, 0.12, 0.78), pillar_pos + Vector3(0, 0.74, 0), Vector3(0, yaw, 0), dirty_white)
	_add_visual_box(parent, "ArchitectureEntryBeam", Vector3(5.68, 0.48, 0.78), Vector3(center.x, floor_y + 3.30, center.z), Vector3(0, yaw, 0), concrete)
	var sign_pos = Vector3(center.x, floor_y + 3.08, center.z) - forward * 0.42
	_add_visual_box(parent, "ArchitectureEntryStatus", Vector3(1.65, 0.075, 0.82), sign_pos, Vector3(0, yaw, 0), cyan)
	_add_story_label(parent, 0, sign_pos + Vector3(0, -0.16, -0.02))
	_add_spot_light(parent, "EntryObservationPool", Vector3(center.x, floor_y + 3.05, center.z), Color8(111, 189, 180), 2.4, 8.2)

func _add_memory_archive(parent: Node3D, center: Vector3, forward: Vector3, right: Vector3, yaw: float) -> void:
	var floor_y = floor_height_at(center)
	if floor_y == -INF:
		return
	var charcoal = _visual_mat("archive_charcoal", Color8(17, 19, 20), 0.0, 1.0, 0.18)
	var dirty_white = _visual_mat("archive_dirty_white", Color8(145, 140, 122), 0.0, 0.96, 0.05)
	var amber = _visual_mat("archive_amber", Color8(191, 137, 49), 0.62, 0.84, 0.03)
	for i in 5:
		var side = -1.0 if i % 2 == 0 else 1.0
		var lane_offset = 2.0 + float(i % 3) * 0.38
		var slab_pos = center + forward * (float(i) - 2.0) * 0.92 + right * side * lane_offset
		slab_pos.y = floor_y + 1.42 + float(i % 2) * 0.34
		var slab_rot = Vector3(-3.0 + float(i), yaw + side * 4.0, side * 2.0)
		_add_visual_box(parent, "StoryArchiveSlab_%02d" % i, Vector3(0.86, 1.92, 0.18), slab_pos, slab_rot, dirty_white if i % 3 != 1 else charcoal)
		_add_visual_box(parent, "StoryArchivePulse_%02d" % i, Vector3(0.58, 0.055, 0.205), slab_pos + Vector3(0, 0.24, 0), slab_rot, amber)
		_add_visual_box(parent, "CablesArchiveDrop_%02d" % i, Vector3(0.036, 1.55, 0.036), slab_pos + Vector3(0, 1.72, 0), Vector3(0, yaw, 0), charcoal)
	_add_visual_box(parent, "ArchitectureArchiveLintel", Vector3(5.6, 0.24, 0.34), Vector3(center.x, floor_y + 3.45, center.z), Vector3(0, yaw, 0), charcoal)
	_add_spot_light(parent, "ArchiveMemoryPool", Vector3(center.x, floor_y + 3.18, center.z), Color8(210, 151, 64), 2.25, 8.8)

func _add_exit_recovery_frame(parent: Node3D, center: Vector3, right: Vector3, yaw: float) -> void:
	var floor_y = floor_height_at(center)
	if floor_y == -INF:
		floor_y = exit_pos.y
	var dark = _visual_mat("exit_recovery_dark", Color8(14, 17, 18), 0.0, 1.0, 0.20)
	var dirty_white = _visual_mat("exit_recovery_white", Color8(138, 136, 123), 0.0, 0.96, 0.05)
	var green = _visual_mat("exit_recovery_green", Color8(68, 159, 103), 0.86, 0.82, 0.01)
	for side in [-1.0, 1.0]:
		var suffix = "L" if side < 0.0 else "R"
		var pillar_pos = center + right * side * 2.15
		pillar_pos.y = floor_y + 1.55
		_add_visual_box(parent, "ArchitectureExitPillar_%s" % suffix, Vector3(0.42, 3.10, 0.54), pillar_pos, Vector3(0, yaw, 0), dark)
		_add_visual_box(parent, "ArchitectureExitBrace_%s" % suffix, Vector3(0.50, 0.15, 0.62), pillar_pos + Vector3(0, 0.68, 0), Vector3(0, yaw, 0), dirty_white)
	_add_visual_box(parent, "ArchitectureExitBeam", Vector3(4.72, 0.38, 0.62), Vector3(center.x, floor_y + 2.94, center.z), Vector3(0, yaw, 0), dark)
	_add_visual_box(parent, "ArchitectureExitHalo", Vector3(2.20, 0.075, 0.66), Vector3(center.x, floor_y + 2.68, center.z), Vector3(0, yaw, 0), green)
	_add_spot_light(parent, "ExitRecoveryPool", Vector3(center.x, floor_y + 2.72, center.z), Color8(87, 188, 127), 2.65, 9.4)

func _add_spot_light(parent: Node3D, light_name: String, pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light = SpotLight3D.new()
	light.name = light_name
	light.position = pos
	light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	light.light_color = color
	light.light_energy = energy
	light.spot_range = light_range
	light.spot_angle = 48.0
	light.shadow_enabled = false
	parent.add_child(light)

func _add_global_decay_fill(parent: Node3D) -> void:
	var cool_fill = DirectionalLight3D.new()
	cool_fill.name = "GlobalDecayFillCool"
	cool_fill.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	cool_fill.light_color = Color8(120, 145, 143)
	cool_fill.light_energy = 0.32
	cool_fill.shadow_enabled = false
	parent.add_child(cool_fill)
	var warm_fill = DirectionalLight3D.new()
	warm_fill.name = "GlobalDecayFillWarm"
	warm_fill.rotation_degrees = Vector3(42.0, 148.0, 0.0)
	warm_fill.light_color = Color8(151, 128, 91)
	warm_fill.light_energy = 0.18
	warm_fill.shadow_enabled = false
	parent.add_child(warm_fill)
	_add_omni_light(parent, "EntrySafetyLight", spawn_pos + Vector3(0.0, 2.20, 1.2), Color8(215, 196, 148), 1.48, 9.2)
	_add_omni_light(parent, "ExitSafetyLight", exit_pos + Vector3(0.0, 2.20, -0.8), Color8(91, 174, 151), 1.52, 9.0)

func _add_decay_light_pools(parent: Node3D) -> void:
	var usable_floors = _route_floor_faces(10)
	for i in usable_floors.size():
		var face: Dictionary = usable_floors[i]
		var center = _face_center(face)
		var color = Color8(88, 151, 146) if i % 4 == 0 else (Color8(211, 163, 74) if i % 4 in [1, 2] else Color8(126, 139, 105))
		var energy = 1.34 if i in [0, usable_floors.size() - 1] else 1.02
		_add_omni_light(parent, "DecayLight_%02d" % i, center + Vector3(0, 2.15 + float(i % 2) * 0.42, 0), color, energy, 7.0)
		_add_visual_box(parent, "LightPool_%02d" % i, Vector3(1.55, 0.018, 0.16), center + Vector3(0, 0.035, 0), Vector3.ZERO, _visual_mat("floor_light_%d" % (i % 4), color, 0.62, 0.60))

func _add_route_spine(parent: Node3D) -> void:
	var plate = _visual_mat("route_spine_plate", Color8(69, 70, 65), 0.10, 0.96, 0.20)
	var amber = _visual_mat("route_spine_amber", Color8(183, 133, 48), 0.68, 0.98, 0.02)
	var ghost = _visual_mat("route_spine_ghost", Color8(148, 147, 132), 0.24, 0.94, 0.02)
	var route_faces = _route_floor_faces(12)
	for i in route_faces.size():
		var face: Dictionary = route_faces[i]
		var box: AABB = face.aabb
		var center = _face_center(face) + Vector3(0, 0.042, 0)
		var along_z = box.size.z >= box.size.x
		var length = min(4.8, max(box.size.z if along_z else box.size.x, 0.7) * 0.58)
		var plate_size = Vector3(min(1.45, box.size.x * 0.62), 0.012, length) if along_z else Vector3(length, 0.012, min(1.45, box.size.z * 0.62))
		var strip_size = Vector3(0.10, 0.016, length * 0.92) if along_z else Vector3(length * 0.92, 0.016, 0.10)
		var lateral = Vector3(min(plate_size.x * 0.39, 0.56), 0.012, 0) if along_z else Vector3(0, 0.012, min(plate_size.z * 0.39, 0.56))
		_add_visual_box(parent, "FloorRoutePlate_%02d" % i, plate_size, center, Vector3.ZERO, plate)
		_add_visual_box(parent, "FloorRouteAmber_%02d" % i, strip_size, center + lateral, Vector3.ZERO, amber)
		_add_visual_box(parent, "FloorRouteGhost_%02d" % i, strip_size, center - lateral, Vector3.ZERO, ghost)

func _add_ceiling_light_fixtures(parent: Node3D) -> void:
	var casing_mat = _visual_mat("ceiling_light_casing", Color8(72, 73, 68), 0.0, 0.92, 0.05)
	var colors = [Color8(226, 214, 170), Color8(88, 164, 160), Color8(202, 142, 60)]
	var route_faces = _route_floor_faces(15)
	for i in route_faces.size():
		var floor_face: Dictionary = route_faces[i]
		var box: AABB = floor_face.aabb
		var center = _face_center(floor_face)
		var ceiling_y = ceiling_height_at(center, 0.35)
		if ceiling_y == INF:
			continue
		var color: Color = colors[i % colors.size()]
		var glow_energy = 0.82 if i % 5 != 3 else 0.30
		var glow_mat = _visual_mat("ceiling_light_glow_%d_%d" % [i % colors.size(), i % 5], color, glow_energy, 0.76)
		var fixture_pos = Vector3(center.x, ceiling_y - 0.045, center.z)
		var long_z = box.size.z >= box.size.x
		var fixture_size = Vector3(0.18, 0.035, min(1.80, max(0.65, box.size.z * 0.34))) if long_z else Vector3(min(1.80, max(0.65, box.size.x * 0.34)), 0.035, 0.18)
		var glow_size = fixture_size + Vector3(0.0 if long_z else 0.14, -0.012, 0.14 if long_z else 0.0)
		_add_visual_box(parent, "CeilingLightCase_%02d" % i, fixture_size + Vector3(0.14, 0.014, 0.14), fixture_pos + Vector3(0, 0.006, 0), Vector3.ZERO, casing_mat)
		_add_visual_box(parent, "CeilingLightGlow_%02d" % i, glow_size, fixture_pos + Vector3(0, -0.010, 0), Vector3.ZERO, glow_mat)
		if i % 3 == 0 or i in [0, route_faces.size() - 1]:
			_add_omni_light(parent, "CeilingPoolLight_%02d" % i, fixture_pos + Vector3(0, -0.56, 0), color, 0.84, 6.6)

func _add_overhead_service_network(parent: Node3D) -> void:
	var dark = _visual_mat("service_network_dark", Color8(13, 15, 16), 0.0, 1.0, 0.18)
	var metal = _visual_mat("service_network_metal", Color8(82, 81, 74), 0.0, 0.97, 0.25)
	var white = _visual_mat("service_network_white", Color8(137, 133, 117), 0.03, 0.97, 0.04)
	var amber = _visual_mat("service_network_amber", Color8(188, 134, 48), 0.52, 0.92, 0.02)
	var cyan = _visual_mat("service_network_cyan", Color8(70, 145, 141), 0.44, 0.92, 0.02)
	var codes = ["SECTOR 10", "MAINT/04", "CACHE LOST", "ARCHIVE", "NO UPLINK", "CREATOR"]
	var route_faces = _route_floor_faces(13)
	for i in route_faces.size():
		var face: Dictionary = route_faces[i]
		var box: AABB = face.aabb
		var center = _face_center(face)
		var ceiling_y = ceiling_height_at(center, 0.35)
		if ceiling_y == INF:
			continue
		var along_z = box.size.z >= box.size.x
		var tray_length = clamp((box.size.z if along_z else box.size.x) * 0.54, 1.4, 5.2)
		var tray_size = Vector3(0.24, 0.08, tray_length) if along_z else Vector3(tray_length, 0.08, 0.24)
		var side_axis = Vector3(0.52, 0, 0) if along_z else Vector3(0, 0, 0.52)
		var service_y = ceiling_y - 0.28 - float(i % 2) * 0.08
		var service_center = Vector3(center.x, service_y, center.z)
		_add_visual_box(parent, "ServiceTrayA_%02d" % i, tray_size, service_center + side_axis, Vector3.ZERO, dark)
		_add_visual_box(parent, "ServiceTrayB_%02d" % i, tray_size * Vector3(0.62 if along_z else 1.0, 0.58, 1.0 if along_z else 0.62), service_center - side_axis, Vector3.ZERO, metal)
		var cable_size = Vector3(0.045, 0.045, tray_length * 0.96) if along_z else Vector3(tray_length * 0.96, 0.045, 0.045)
		_add_visual_box(parent, "ServiceCableAmber_%02d" % i, cable_size, service_center + side_axis + Vector3(0, -0.07, 0), Vector3.ZERO, amber if i % 3 == 0 else cyan)
		if i % 3 != 1:
			continue
		var sign_y = max(center.y + 2.35, service_y - 0.62)
		var sign_pos = Vector3(center.x, sign_y, center.z)
		_add_visual_box(parent, "ServiceSignBack_%02d" % i, Vector3(1.72, 0.52, 0.075), sign_pos, Vector3.ZERO, dark)
		_add_visual_box(parent, "ServiceSignPaint_%02d" % i, Vector3(1.48, 0.08, 0.082), sign_pos + Vector3(0, 0.14, 0), Vector3.ZERO, white)
		for side in [-1.0, 1.0]:
			_add_visual_box(parent, "ServiceSignHanger_%02d_%s" % [i, "L" if side < 0.0 else "R"], Vector3(0.035, max(0.20, service_y - sign_y), 0.035), sign_pos + Vector3(side * 0.66, (service_y - sign_y) * 0.5, 0), Vector3.ZERO, metal)
		var label = Label3D.new()
		label.name = "StoryServiceCode_%02d" % i
		label.text = codes[posmod(i, codes.size())]
		label.position = sign_pos + Vector3(0, -0.08, -0.052)
		label.font_size = 30
		label.pixel_size = 0.0057
		label.modulate = Color8(205, 194, 158) if i % 2 == 0 else Color8(91, 161, 154)
		label.outline_size = 4
		label.outline_modulate = Color8(7, 9, 9)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		parent.add_child(label)

func _add_wall_maintenance_spines(parent: Node3D) -> void:
	var recess_mat = _visual_mat("wall_spine_recess", Color8(12, 14, 15), 0.0, 1.0, 0.10)
	var metal_mat = _visual_mat("wall_spine_metal", Color8(91, 89, 80), 0.02, 0.96, 0.22)
	var paint_mat = _visual_mat("wall_spine_paint", Color8(139, 135, 119), 0.08, 0.96, 0.04)
	var amber_mat = _visual_mat("wall_spine_amber", Color8(188, 134, 48), 0.56, 0.94, 0.02)
	var cyan_mat = _visual_mat("wall_spine_cyan", Color8(68, 145, 140), 0.46, 0.92, 0.02)
	var selected = _distributed_faces(wall_faces, 20, 1.8, 1.2)
	for i in selected.size():
		var face: Dictionary = selected[i]
		var box: AABB = face.aabb
		var normal: Vector3 = face.normal.normalized()
		var center = _face_center(face)
		center.y = box.position.y + clamp(box.size.y * 0.42, 0.72, 1.62)
		center += normal * 0.042
		var along_x = abs(normal.z) >= abs(normal.x)
		var span = clamp(max(box.size.x, box.size.z) * 0.62, 1.35, 4.8)
		var recess_size = Vector3(span, 0.42, 0.035) if along_x else Vector3(0.035, 0.42, span)
		var rail_size = Vector3(span * 0.94, 0.075, 0.048) if along_x else Vector3(0.048, 0.075, span * 0.94)
		var signal_size = Vector3(clamp(span * 0.22, 0.38, 0.88), 0.038, 0.055) if along_x else Vector3(0.055, 0.038, clamp(span * 0.22, 0.38, 0.88))
		_add_visual_box(parent, "MaintenanceSpineRecess_%02d" % i, recess_size, center, Vector3.ZERO, recess_mat)
		_add_visual_box(parent, "MaintenanceSpineRail_%02d" % i, rail_size, center + Vector3(0, 0.10, 0) + normal * 0.014, Vector3.ZERO, metal_mat)
		_add_visual_box(parent, "MaintenanceSpinePaint_%02d" % i, rail_size * Vector3(0.74 if along_x else 1.0, 0.34, 1.0 if along_x else 0.74), center - Vector3(0, 0.11, 0) + normal * 0.018, Vector3.ZERO, paint_mat)
		var signal_shift = Vector3(span * 0.27, 0, 0) if along_x else Vector3(0, 0, span * 0.27)
		if i % 2 == 0:
			_add_visual_box(parent, "MaintenanceSpineSignal_%02d" % i, signal_size, center + signal_shift + Vector3(0, 0.10, 0) + normal * 0.032, Vector3.ZERO, amber_mat if i % 4 == 0 else cyan_mat)

func _add_corridor_codes(parent: Node3D) -> void:
	var messages = ["SYS/10", "CACHE", "NO SIGNAL", "MAINT", "RETURN", "ARCHIVE", "USER: NULL", "KEEP ALIVE"]
	var selected = _distributed_faces(wall_faces, 8, 2.4, 1.5)
	for i in selected.size():
		var face: Dictionary = selected[i]
		var box: AABB = face.aabb
		var normal: Vector3 = face.normal.normalized()
		var label = Label3D.new()
		label.name = "StoryCorridorCode_%02d" % i
		label.text = messages[i % messages.size()]
		label.position = _face_center(face) + normal * 0.060
		label.position.y = box.position.y + clamp(box.size.y * 0.68, 1.12, 2.35)
		label.font_size = 28
		label.pixel_size = 0.0062
		label.modulate = Color8(201, 190, 153) if i % 3 != 1 else Color8(91, 161, 154)
		label.outline_size = 4
		label.outline_modulate = Color8(8, 10, 10)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = false
		parent.add_child(label)

func _add_story_landmarks(parent: Node3D) -> void:
	var dark_mat = _visual_mat("story_charcoal", Color8(18, 20, 21), 0.0, 1.0, 0.16)
	var dirty_mat = _visual_mat("story_dirty_white", Color8(126, 123, 111), 0.0, 0.96, 0.08)
	var amber_mat = _visual_mat("story_faded_amber", Color8(192, 139, 52), 0.48, 0.88, 0.02)
	var cyan_mat = _visual_mat("story_muted_cyan", Color8(65, 146, 141), 0.62, 0.90, 0.02)
	var red_mat = _visual_mat("story_warning_red", Color8(151, 46, 38), 0.48, 0.88, 0.02)
	var route_faces = _route_floor_faces(5)
	for i in route_faces.size():
		var face: Dictionary = route_faces[i]
		var box: AABB = face.aabb
		if box.size.x < 2.2 or box.size.z < 1.0:
			continue
		var center = _face_center(face)
		var side = -1.0 if i % 2 == 0 else 1.0
		var side_offset = clamp(box.size.x * 0.34, 1.10, 2.80) * side
		var floor_y = box.position.y + box.size.y
		var anchor = Vector3(center.x + side_offset, floor_y, center.z)
		_add_visual_box(parent, "StoryPlinth_%02d" % i, Vector3(0.86, 0.10, 0.54), anchor + Vector3(0, 0.05, 0), Vector3.ZERO, dirty_mat)
		_add_visual_box(parent, "StoryTerminal_%02d" % i, Vector3(0.62, 1.08, 0.38), anchor + Vector3(0, 0.64, 0), Vector3(0, float((i % 3) - 1) * 5.0, 0), dark_mat)
		_add_visual_box(parent, "StoryScreen_%02d" % i, Vector3(0.48, 0.31, 0.028), anchor + Vector3(0, 0.78, -0.205), Vector3(-4.0, 0, 0), cyan_mat if i % 3 != 2 else red_mat)
		_add_story_label(parent, i, anchor + Vector3(0, 0.79, -0.224))
		for led in 3:
			_add_visual_box(parent, "StoryLED_%02d_%02d" % [i, led], Vector3(0.08 + led * 0.04, 0.025, 0.030), anchor + Vector3(-0.18 + led * 0.16, 0.42, -0.205), Vector3.ZERO, amber_mat if led == 0 else cyan_mat)
		if i in [0, route_faces.size() - 1]:
			var opposite_x = center.x - side_offset
			_add_visual_box(parent, "StorySignalPillar_%02d" % i, Vector3(0.22, 2.25, 0.22), Vector3(opposite_x, floor_y + 1.125, center.z), Vector3.ZERO, dark_mat)
			_add_visual_box(parent, "StorySignal_%02d" % i, Vector3(0.28, 0.52, 0.28), Vector3(opposite_x, floor_y + 1.78, center.z), Vector3.ZERO, amber_mat if i == 0 else cyan_mat)

func _add_story_label(parent: Node3D, index: int, pos: Vector3) -> void:
	var messages = [
		"SESSION 10 // ACTIVE",
		"NO USERS FOUND",
		"MEMORY MAINTENANCE",
		"CREATOR CACHE: UNSTABLE",
		"PLEASE DO NOT LEAVE"
	]
	var label = Label3D.new()
	label.name = "StoryText_%02d" % index
	label.text = messages[index % messages.size()]
	label.position = pos
	label.rotation_degrees = Vector3(-4.0, 180.0, 0.0)
	label.font_size = 20
	label.pixel_size = 0.0042
	label.modulate = Color8(151, 207, 194) if index % 3 != 2 else Color8(212, 158, 70)
	label.outline_size = 3
	label.outline_modulate = Color8(7, 9, 9)
	label.no_depth_test = false
	parent.add_child(label)

func _add_brutalist_portal_ribs(parent: Node3D) -> void:
	var concrete_mat = _visual_mat("portal_raw_concrete", Color8(47, 49, 48), 0.0, 1.0, 0.02)
	var metal_mat = _visual_mat("portal_aged_metal", Color8(24, 27, 28), 0.0, 1.0, 0.24)
	var amber_mat = _visual_mat("portal_service_amber", Color8(191, 139, 52), 0.34, 0.90, 0.04)
	var route_faces = _route_floor_faces(6)
	for i in route_faces.size():
		if i == 0 or i == route_faces.size() - 1 or i % 2 != 0:
			continue
		var face: Dictionary = route_faces[i]
		var box: AABB = face.aabb
		if box.size.x < 2.6:
			continue
		var center = _face_center(face)
		var floor_y = box.position.y + box.size.y
		var ceiling_y = ceiling_height_at(center, 0.45)
		if ceiling_y == INF or ceiling_y - floor_y < 2.5:
			continue
		var height = min(ceiling_y - floor_y, 4.8)
		var half_width = min(box.size.x * 0.44, 4.6)
		var rib_mat = concrete_mat if i % 4 == 0 else metal_mat
		_add_visual_box(parent, "ArchitecturePortalLeft_%02d" % i, Vector3(0.26, height, 0.42), Vector3(center.x - half_width, floor_y + height * 0.5, center.z), Vector3.ZERO, rib_mat)
		_add_visual_box(parent, "ArchitecturePortalRight_%02d" % i, Vector3(0.26, height, 0.42), Vector3(center.x + half_width, floor_y + height * 0.5, center.z), Vector3.ZERO, rib_mat)
		_add_visual_box(parent, "ArchitecturePortalBeam_%02d" % i, Vector3(half_width * 2.0 + 0.26, 0.30, 0.48), Vector3(center.x, floor_y + height - 0.15, center.z), Vector3.ZERO, rib_mat)
		_add_visual_box(parent, "ArchitecturePortalSignal_%02d" % i, Vector3(0.90, 0.055, 0.50), Vector3(center.x + half_width * 0.48, floor_y + height - 0.32, center.z - 0.26), Vector3.ZERO, amber_mat)

func _add_floor_direction_strips(parent: Node3D) -> void:
	var strip_mat = _visual_mat("worn_amber_strip", Color8(176, 132, 54), 0.34, 0.92)
	var dark_mat = _visual_mat("charcoal_floor_decal", Color8(92, 92, 84), 0.08, 0.78)
	var usable_floors = _large_floor_faces(14)
	for i in usable_floors.size():
		var face: Dictionary = usable_floors[i]
		var box: AABB = face.aabb
		var center = _face_center(face) + Vector3(0, 0.026, 0)
		if box.size.z > box.size.x:
			_add_visual_box(parent, "FloorDecayStrip_%02d" % i, Vector3(0.10, 0.018, min(3.4, box.size.z * 0.48)), center + Vector3(box.size.x * 0.22, 0, 0), Vector3.ZERO, strip_mat if i % 2 == 0 else dark_mat)
		else:
			_add_visual_box(parent, "FloorDecayStrip_%02d" % i, Vector3(min(3.4, box.size.x * 0.48), 0.018, 0.10), center + Vector3(0, 0, box.size.z * 0.22), Vector3.ZERO, strip_mat if i % 2 == 0 else dark_mat)

func _add_wall_terminal_panels(parent: Node3D) -> void:
	var panel_mat = _visual_mat("dirty_white_panel", Color8(154, 151, 134), 0.0, 0.92)
	var cyan_mat = _visual_mat("muted_cyan_terminal", Color8(74, 166, 166), 0.72, 0.90)
	var warning_mat = _visual_mat("red_warning_terminal", Color8(166, 48, 42), 0.55, 0.88)
	var added = 0
	for face in _distributed_faces(wall_faces, 14, 1.2, 0.8):
		var box: AABB = face.aabb
		if box.size.y < 0.8 or max(box.size.x, box.size.z) < 1.2:
			continue
		if added % 3 != 0 and max(box.size.x, box.size.z) < 2.4:
			continue
		var normal: Vector3 = face.normal.normalized()
		var center = _face_center(face)
		center.y = box.position.y + min(box.size.y * 0.52, 1.45)
		center += normal * 0.028
		if abs(normal.x) > abs(normal.z):
			_add_visual_box(parent, "WallPanel_%02d" % added, Vector3(0.028, 0.55, 0.82), center, Vector3.ZERO, panel_mat)
			_add_visual_box(parent, "WallScreen_%02d" % added, Vector3(0.034, 0.16, 0.38), center + normal * 0.010 + Vector3(0, 0.08, 0), Vector3.ZERO, cyan_mat if added % 4 != 0 else warning_mat)
		else:
			_add_visual_box(parent, "WallPanel_%02d" % added, Vector3(0.82, 0.55, 0.028), center, Vector3.ZERO, panel_mat)
			_add_visual_box(parent, "WallScreen_%02d" % added, Vector3(0.38, 0.16, 0.034), center + normal * 0.010 + Vector3(0, 0.08, 0), Vector3.ZERO, cyan_mat if added % 4 != 0 else warning_mat)
		added += 1

func _add_server_room_remnants(parent: Node3D) -> void:
	var body_mat = _visual_mat("aged_server_body", Color8(24, 27, 28), 0.0, 1.0, 0.08)
	var edge_mat = _visual_mat("worn_metal_edge", Color8(92, 88, 78), 0.0, 1.0, 0.14)
	var green_mat = _visual_mat("crt_green_led", Color8(82, 180, 96), 0.80, 0.88)
	var floors = _large_floor_faces(8)
	for i in floors.size():
		if i % 2 != 0:
			continue
		var face: Dictionary = floors[i]
		var box: AABB = face.aabb
		var center = _face_center(face)
		var side = -1.0 if i % 4 == 0 else 1.0
		var pos = Vector3(
			center.x + clamp(box.size.x * 0.32 * side, -2.0, 2.0),
			box.position.y + 0.52,
			center.z - clamp(box.size.z * 0.30, 0.5, 2.2)
		)
		_add_visual_box(parent, "ServerGhost_%02d" % i, Vector3(0.48, 1.04, 0.34), pos, Vector3(0, 0, 0), body_mat)
		_add_visual_box(parent, "ServerEdge_%02d" % i, Vector3(0.50, 0.08, 0.36), pos + Vector3(0, 0.45, 0), Vector3.ZERO, edge_mat)
		_add_visual_box(parent, "ServerLED_%02d" % i, Vector3(0.08, 0.028, 0.38), pos + Vector3(0.25, 0.16, 0), Vector3.ZERO, green_mat)

func _add_ceiling_cable_runs(parent: Node3D) -> void:
	var cable_mat = _visual_mat("exposed_cable", Color8(12, 13, 13), 0.0, 1.0)
	var amber_mat = _visual_mat("cable_warning_amber", Color8(194, 136, 54), 0.38, 0.78)
	var added = 0
	for face in _distributed_faces(ceiling_faces, 8, 1.4, 1.0):
		if added >= 8:
			break
		var box: AABB = face.aabb
		if box.size.x < 1.4 and box.size.z < 1.4:
			continue
		var center = _face_center(face) + Vector3(0, -0.026, 0)
		if box.size.x > box.size.z:
			_add_visual_box(parent, "CeilingCable_%02d" % added, Vector3(min(box.size.x * 0.62, 4.0), 0.030, 0.038), center + Vector3(0, 0, box.size.z * 0.18), Vector3.ZERO, cable_mat)
			if added % 3 == 0:
				_add_visual_box(parent, "CeilingCableGlow_%02d" % added, Vector3(0.45, 0.024, 0.045), center + Vector3(box.size.x * 0.18, -0.005, box.size.z * 0.18), Vector3.ZERO, amber_mat)
		else:
			_add_visual_box(parent, "CeilingCable_%02d" % added, Vector3(0.038, 0.030, min(box.size.z * 0.62, 4.0)), center + Vector3(box.size.x * 0.18, 0, 0), Vector3.ZERO, cable_mat)
			if added % 3 == 0:
				_add_visual_box(parent, "CeilingCableGlow_%02d" % added, Vector3(0.045, 0.024, 0.45), center + Vector3(box.size.x * 0.18, -0.005, box.size.z * 0.18), Vector3.ZERO, amber_mat)
		added += 1

func _add_decay_fog_bands(parent: Node3D) -> void:
	var fog_mat = _visual_mat("soft_charcoal_fog_band", Color8(18, 22, 22), 0.0, 0.18)
	var cyan_fog_mat = _visual_mat("muted_cyan_fog_band", Color8(42, 86, 86), 0.0, 0.12)
	var min_pos = bounds.position
	var max_pos = bounds.position + bounds.size
	var span_x = max(2.0, bounds.size.x * 0.72)
	var span_z = max(2.0, bounds.size.z * 0.18)
	for i in 5:
		var t = float(i) / 4.0
		var z = lerp(min_pos.z + bounds.size.z * 0.18, max_pos.z - bounds.size.z * 0.14, t)
		var y = min_pos.y + 1.25 + float(i % 3) * 0.55
		var x = (min_pos.x + max_pos.x) * 0.5 + sin(float(i) * 1.7) * bounds.size.x * 0.10
		var mat = fog_mat if i % 2 == 0 else cyan_fog_mat
		var deterministic_rotation = -3.5 + float((i * 17) % 8)
		_add_visual_box(parent, "DecayFogBand_%02d" % i, Vector3(span_x, 0.035, span_z), Vector3(x, y, z), Vector3(0, deterministic_rotation, 0), mat)

func _add_architectural_maintenance_frames(parent: Node3D) -> void:
	var frame_mat = _visual_mat("maintenance_dirty_white", Color8(118, 117, 108), 0.0, 0.94, 0.12)
	var recess_mat = _visual_mat("maintenance_recess", Color8(15, 17, 18), 0.0, 1.0, 0.08)
	var amber_mat = _visual_mat("maintenance_faded_amber", Color8(188, 132, 48), 0.28, 0.88, 0.04)
	var selected = _distributed_faces(wall_faces, 10, 2.0, 1.5)
	for i in selected.size():
		var face: Dictionary = selected[i]
		var box: AABB = face.aabb
		var normal: Vector3 = face.normal.normalized()
		var center = _face_center(face)
		center.y = box.position.y + min(box.size.y * 0.47, 2.1)
		center += normal * 0.036
		var horizontal = abs(normal.z) > abs(normal.x)
		var span = clamp(max(box.size.x, box.size.z) * 0.34, 0.95, 1.75)
		if horizontal:
			_add_visual_box(parent, "MaintenanceRecess_%02d" % i, Vector3(span, 1.46, 0.030), center, Vector3.ZERO, recess_mat)
			_add_visual_box(parent, "MaintenanceFrameTop_%02d" % i, Vector3(span + 0.18, 0.075, 0.045), center + Vector3(0, 0.77, 0), Vector3.ZERO, frame_mat)
			_add_visual_box(parent, "MaintenanceFrameLeft_%02d" % i, Vector3(0.075, 1.56, 0.045), center + Vector3(-span * 0.52, 0, 0), Vector3.ZERO, frame_mat)
			_add_visual_box(parent, "MaintenanceFrameRight_%02d" % i, Vector3(0.075, 1.56, 0.045), center + Vector3(span * 0.52, 0, 0), Vector3.ZERO, frame_mat)
			_add_visual_box(parent, "MaintenanceCode_%02d" % i, Vector3(0.36, 0.055, 0.052), center + Vector3(span * 0.26, 0.52, 0), Vector3.ZERO, amber_mat)
		else:
			_add_visual_box(parent, "MaintenanceRecess_%02d" % i, Vector3(0.030, 1.46, span), center, Vector3.ZERO, recess_mat)
			_add_visual_box(parent, "MaintenanceFrameTop_%02d" % i, Vector3(0.045, 0.075, span + 0.18), center + Vector3(0, 0.77, 0), Vector3.ZERO, frame_mat)
			_add_visual_box(parent, "MaintenanceFrameLeft_%02d" % i, Vector3(0.045, 1.56, 0.075), center + Vector3(0, 0, -span * 0.52), Vector3.ZERO, frame_mat)
			_add_visual_box(parent, "MaintenanceFrameRight_%02d" % i, Vector3(0.045, 1.56, 0.075), center + Vector3(0, 0, span * 0.52), Vector3.ZERO, frame_mat)
			_add_visual_box(parent, "MaintenanceCode_%02d" % i, Vector3(0.052, 0.055, 0.36), center + Vector3(0, 0.52, span * 0.26), Vector3.ZERO, amber_mat)

func _add_abandoned_workstations(parent: Node3D) -> void:
	var frame_mat = _visual_mat("workstation_aged_metal", Color8(50, 52, 50), 0.0, 1.0, 0.16)
	var surface_mat = _visual_mat("workstation_dirty_surface", Color8(104, 101, 89), 0.0, 0.94, 0.04)
	var screen_mat = _visual_mat("workstation_dead_screen", Color8(18, 27, 27), 0.08, 0.96)
	var active_screen_mat = _visual_mat("workstation_crt_screen", Color8(62, 132, 112), 0.54, 0.90)
	var floors = _large_floor_faces(5)
	for i in floors.size():
		var face: Dictionary = floors[i]
		var box: AABB = face.aabb
		var center = _face_center(face)
		var side = -1.0 if i % 2 == 0 else 1.0
		var edge_x = clamp(box.size.x * 0.34 * side, -2.4, 2.4)
		var edge_z = clamp(box.size.z * 0.30, 0.65, 2.2)
		var base_pos = Vector3(center.x + edge_x, box.position.y + 0.42, center.z - edge_z)
		_add_visual_box(parent, "WorkstationDesk_%02d" % i, Vector3(1.18, 0.10, 0.48), base_pos, Vector3.ZERO, surface_mat)
		_add_visual_box(parent, "WorkstationLegA_%02d" % i, Vector3(0.08, 0.74, 0.08), base_pos + Vector3(-0.48, -0.37, 0.14), Vector3.ZERO, frame_mat)
		_add_visual_box(parent, "WorkstationLegB_%02d" % i, Vector3(0.08, 0.74, 0.08), base_pos + Vector3(0.48, -0.37, 0.14), Vector3.ZERO, frame_mat)
		_add_visual_box(parent, "WorkstationMonitor_%02d" % i, Vector3(0.58, 0.38, 0.07), base_pos + Vector3(0.0, 0.34, -0.14), Vector3(-8.0, float((i % 3) - 1) * 7.0, 0), frame_mat)
		_add_visual_box(parent, "WorkstationScreen_%02d" % i, Vector3(0.46, 0.27, 0.075), base_pos + Vector3(0.0, 0.35, -0.18), Vector3(-8.0, float((i % 3) - 1) * 7.0, 0), active_screen_mat if i % 3 == 0 else screen_mat)
		_add_visual_box(parent, "WorkstationKeyboard_%02d" % i, Vector3(0.46, 0.025, 0.18), base_pos + Vector3(0.06, 0.075, 0.08), Vector3(0, float((i % 3) - 1) * 5.0, 0), frame_mat)

func _add_digital_decay_scars(parent: Node3D) -> void:
	var cyan_mat = _visual_mat("decay_scar_cyan", Color8(62, 138, 134), 0.42, 0.78)
	var warning_mat = _visual_mat("decay_scar_warning", Color8(150, 51, 40), 0.38, 0.82)
	var dead_mat = _visual_mat("decay_scar_dead", Color8(8, 10, 10), 0.0, 1.0)
	var selected = _distributed_faces(wall_faces, 8, 1.6, 1.0)
	for i in selected.size():
		var face: Dictionary = selected[i]
		var box: AABB = face.aabb
		var normal: Vector3 = face.normal.normalized()
		var center = _face_center(face) + normal * 0.045
		center.y = box.position.y + clamp(box.size.y * (0.35 + float(i % 3) * 0.12), 0.45, max(0.5, box.size.y - 0.25))
		for band in 3:
			var offset = (float(band) - 1.0) * 0.16
			var length = 0.42 + float((i * 7 + band * 3) % 6) * 0.14
			var mat = warning_mat if i % 5 == 0 and band == 1 else (cyan_mat if band != 2 else dead_mat)
			if abs(normal.z) > abs(normal.x):
				_add_visual_box(parent, "DecayScar_%02d_%02d" % [i, band], Vector3(length, 0.045, 0.052), center + Vector3(offset * 1.8, offset, 0), Vector3.ZERO, mat)
			else:
				_add_visual_box(parent, "DecayScar_%02d_%02d" % [i, band], Vector3(0.052, 0.045, length), center + Vector3(0, offset, offset * 1.8), Vector3.ZERO, mat)

func _add_wayfinding_markers(parent: Node3D) -> void:
	var amber_mat = _visual_mat("wayfinding_amber", Color8(190, 139, 54), 0.48, 0.94)
	var dirty_mat = _visual_mat("wayfinding_dirty_white", Color8(136, 133, 119), 0.12, 0.94)
	var floors = _large_floor_faces(8)
	for i in floors.size():
		var face: Dictionary = floors[i]
		var box: AABB = face.aabb
		var center = _face_center(face) + Vector3(0, 0.032, 0)
		var along_z = box.size.z >= box.size.x
		var bar_size = Vector3(0.11, 0.018, min(1.65, box.size.z * 0.25)) if along_z else Vector3(min(1.65, box.size.x * 0.25), 0.018, 0.11)
		var offset_axis = Vector3(min(box.size.x * 0.17, 0.65), 0, 0) if along_z else Vector3(0, 0, min(box.size.z * 0.17, 0.65))
		_add_visual_box(parent, "WayfindingAmber_%02d" % i, bar_size, center + offset_axis, Vector3.ZERO, amber_mat)
		_add_visual_box(parent, "WayfindingGhost_%02d" % i, bar_size * Vector3(0.72, 1.0, 0.72), center - offset_axis, Vector3.ZERO, dirty_mat)

func _large_floor_faces(limit: int) -> Array:
	var candidates = []
	for face in floor_faces:
		var box: AABB = face.aabb
		if face.normal.y < 0.82 or box.size.x < 1.0 or box.size.z < 1.0:
			continue
		candidates.append(face)
	return _distributed_faces(candidates, limit, 1.0, 1.0)

func _route_floor_faces(limit: int) -> Array:
	var candidates = []
	for face in floor_faces:
		var box: AABB = face.aabb
		if face.normal.y < 0.82 or box.size.x < 0.8 or box.size.z < 0.8:
			continue
		candidates.append(face)
	if candidates.is_empty() or candidates.size() <= limit:
		return candidates
	candidates.sort_custom(func(a, b):
		return _face_center(a).z < _face_center(b).z
	)
	var out = []
	for i in limit:
		var target_z = lerp(_face_center(candidates[0]).z, _face_center(candidates[candidates.size() - 1]).z, float(i) / float(max(1, limit - 1)))
		var best_face = candidates[0]
		var best_score = INF
		for face in candidates:
			if out.has(face):
				continue
			var box: AABB = face.aabb
			var center = _face_center(face)
			var score = abs(center.z - target_z) - min(box.size.x * box.size.z, 12.0) * 0.025
			if score < best_score:
				best_score = score
				best_face = face
		out.append(best_face)
	return out

func _distributed_faces(source: Array, limit: int, min_horizontal: float, min_vertical: float) -> Array:
	var candidates = []
	for face in source:
		var box: AABB = face.aabb
		if max(box.size.x, box.size.z) < min_horizontal or box.size.y < min_vertical:
			continue
		candidates.append(face)
	if candidates.size() <= limit:
		return candidates
	candidates.sort_custom(func(a, b):
		var ca = _face_center(a)
		var cb = _face_center(b)
		return ca.z + ca.y * 0.42 < cb.z + cb.y * 0.42
	)
	var out = []
	for i in limit:
		var index = int(round(float(i) * float(candidates.size() - 1) / float(max(1, limit - 1))))
		var candidate = candidates[index]
		if not out.has(candidate):
			out.append(candidate)
	return out

func _face_center(face: Dictionary) -> Vector3:
	var center = Vector3.ZERO
	for point in face.points:
		center += point
	return center / max(1.0, float(face.points.size()))

func _visual_mat(key: String, color: Color, emission_energy: float = 0.0, alpha: float = 1.0, metallic: float = 0.0) -> StandardMaterial3D:
	if visual_material_cache.has(key):
		return visual_material_cache[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.roughness = 0.92
	mat.metallic = metallic
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if alpha < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	visual_material_cache[key] = mat
	return mat

func _add_visual_box(parent: Node3D, node_name: String, box_size: Vector3, pos: Vector3, rot_deg: Vector3, mat: Material) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = box_size
	var part = MeshInstance3D.new()
	part.name = node_name
	part.mesh = mesh
	part.position = pos
	part.rotation_degrees = rot_deg
	part.material_override = mat
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part

func _add_omni_light(parent: Node3D, node_name: String, pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light = OmniLight3D.new()
	light.name = node_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false
	parent.add_child(light)

func _build_spatial_index() -> void:
	spatial_faces.clear()
	spatial_floors.clear()
	spatial_walls.clear()
	spatial_ceilings.clear()
	for face in faces:
		_add_face_to_spatial(face, spatial_faces)
	for face in floor_faces:
		_add_face_to_spatial(face, spatial_floors)
	for face in wall_faces:
		_add_face_to_spatial(face, spatial_walls)
	for face in ceiling_faces:
		_add_face_to_spatial(face, spatial_ceilings)

func _add_face_to_spatial(face: Dictionary, table: Dictionary) -> void:
	var box: AABB = face.aabb.grow(0.28)
	var min_cell = _cell_for_point(box.position)
	var max_cell = _cell_for_point(box.position + box.size)
	for cz in range(min_cell.y, max_cell.y + 1):
		for cx in range(min_cell.x, max_cell.x + 1):
			var key = _cell_key(cx, cz)
			if not table.has(key):
				table[key] = []
			table[key].append(face)

func _cell_for_point(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / SPATIAL_CELL_SIZE), floori(pos.z / SPATIAL_CELL_SIZE))

func _cell_key(cx: int, cz: int) -> String:
	return "%d:%d" % [cx, cz]

func _faces_near(pos: Vector3, radius: float, table: Dictionary, fallback: Array) -> Array:
	if table.is_empty():
		return fallback
	var cell_radius = max(1, int(ceil(radius / SPATIAL_CELL_SIZE)) + 1)
	var center = _cell_for_point(pos)
	var out = []
	var seen = {}
	for z in range(center.y - cell_radius, center.y + cell_radius + 1):
		for x in range(center.x - cell_radius, center.x + cell_radius + 1):
			var key = _cell_key(x, z)
			if not table.has(key):
				continue
			for face in table[key]:
				var id = int(face.id)
				if seen.has(id):
					continue
				seen[id] = true
				out.append(face)
	return out

func _faces_in_bounds(box: AABB, table: Dictionary, fallback: Array) -> Array:
	if table.is_empty():
		return fallback
	var min_cell = _cell_for_point(box.position)
	var max_cell = _cell_for_point(box.position + box.size)
	var out = []
	var seen = {}
	for z in range(min_cell.y - 1, max_cell.y + 2):
		for x in range(min_cell.x - 1, max_cell.x + 2):
			var key = _cell_key(x, z)
			if not table.has(key):
				continue
			for face in table[key]:
				var id = int(face.id)
				if seen.has(id):
					continue
				seen[id] = true
				out.append(face)
	return out

func _prepare_spawn_position() -> void:
	var min_z = INF
	var spawn_x = 0.0
	var spawn_z = 0.0
	var spawn_y = 0.0
	var found = false
	for face in floor_faces:
		var n: Vector3 = face.normal
		if n.y < 0.55:
			continue
		var face_bounds: AABB = face.aabb
		if face_bounds.position.z < min_z and face_bounds.size.x > 0.8 and face_bounds.size.z > 0.8:
			min_z = face_bounds.position.z
			spawn_x = face_bounds.position.x + face_bounds.size.x * 0.5
			spawn_z = clamp(min_z + 2.4, face_bounds.position.z + 0.45, face_bounds.position.z + face_bounds.size.z - 0.45)
			spawn_y = (float(face.d) - n.x * spawn_x - n.z * spawn_z) / n.y
			found = true
	spawn_pos = Vector3(spawn_x, spawn_y + 0.02, spawn_z) if found else Vector3(0.0, 2.0, 0.0)

func _prepare_exit_position() -> void:
	var max_z = -INF
	var exit_x = 0.0
	var exit_z = 0.0
	var exit_y = 0.0
	var found = false
	for face in floor_faces:
		var n: Vector3 = face.normal
		if n.y < 0.55:
			continue
		var face_bounds: AABB = face.aabb
		var far_z = face_bounds.position.z + face_bounds.size.z
		if far_z > max_z and face_bounds.size.x > 0.8 and face_bounds.size.z > 0.8:
			max_z = far_z
			exit_x = face_bounds.position.x + face_bounds.size.x * 0.5
			exit_z = clamp(max_z - 2.4, face_bounds.position.z + 0.45, far_z - 0.45)
			exit_y = (float(face.d) - n.x * exit_x - n.z * exit_z) / n.y
			found = true
	exit_pos = Vector3(exit_x, exit_y, exit_z) if found else spawn_pos + Vector3(0, 0, 8.0)

func floor_height_at(pos: Vector3) -> float:
	var best = -64.0
	for face in _faces_near(pos, 1.5, spatial_floors, floor_faces):
		var face_bounds: AABB = face.aabb
		if pos.x < face_bounds.position.x - 0.12 or pos.x > face_bounds.position.x + face_bounds.size.x + 0.12:
			continue
		if pos.z < face_bounds.position.z - 0.12 or pos.z > face_bounds.position.z + face_bounds.size.z + 0.12:
			continue
		var n: Vector3 = face.normal
		if abs(n.y) < 0.001:
			continue
		var y = (float(face.d) - n.x * pos.x - n.z * pos.z) / n.y
		if y > pos.y + 0.72 or y < best:
			continue
		if _point_in_polygon_projected(Vector3(pos.x, y, pos.z), face.points, n, 0.05):
			best = y
	return best

func ceiling_height_at(pos: Vector3, radius: float = PLAYER_RADIUS) -> float:
	var best = INF
	for face in _faces_near(pos, radius + 1.6, spatial_ceilings, ceiling_faces):
		var face_bounds: AABB = face.aabb
		if pos.x < face_bounds.position.x - radius or pos.x > face_bounds.position.x + face_bounds.size.x + radius:
			continue
		if pos.z < face_bounds.position.z - radius or pos.z > face_bounds.position.z + face_bounds.size.z + radius:
			continue
		var n: Vector3 = face.normal
		if abs(n.y) < 0.001:
			continue
		var y = (float(face.d) - n.x * pos.x - n.z * pos.z) / n.y
		if y < pos.y + 0.25 or y > best:
			continue
		if _point_in_polygon_projected(Vector3(pos.x, y, pos.z), face.points, n, radius + 0.08):
			best = y
	return best

func is_blocked_world(pos: Vector3, radius: float) -> bool:
	var bounds_end = bounds.position + bounds.size
	if pos.x < bounds.position.x - radius or pos.x > bounds_end.x + radius:
		return true
	if pos.z < bounds.position.z - radius or pos.z > bounds_end.z + radius:
		return true
	if _ceiling_penetration(pos, radius) > 0.0:
		return true
	return _nearest_wall_contact(pos, radius).has("normal")

func wall_contact_normal(pos: Vector3, radius: float) -> Vector3:
	var hit = _nearest_wall_contact(pos, radius)
	return hit.normal if hit.has("normal") else Vector3.ZERO

func push_out_of_solid(pos: Vector3, radius: float) -> Vector3:
	var ceiling_push = _ceiling_penetration(pos, radius)
	if ceiling_push > 0.0:
		return pos - Vector3(0, ceiling_push + 0.025, 0)
	var hit = _nearest_wall_contact(pos, radius)
	if not hit.has("normal"):
		return pos
	return pos + hit.normal * (radius - float(hit.distance) + 0.035)

func player_sweep_blocked(from_pos: Vector3, to_pos: Vector3, radius: float) -> bool:
	if from_pos.distance_to(to_pos) <= 0.001:
		return is_blocked_world(to_pos, radius)
	for height in [0.36, 0.96, 1.56]:
		var from_probe = from_pos + Vector3(0, height, 0)
		var to_probe = to_pos + Vector3(0, height, 0)
		if _wall_sweep_hit_along_segment(from_probe, to_probe, max(radius, 0.22)):
			return true
	return is_blocked_world(to_pos, radius)

func _wall_sweep_hit_along_segment(from: Vector3, to: Vector3, step_radius: float) -> bool:
	var dir = to - from
	if dir.length_squared() <= 0.000001:
		return false
	var probe_radius = max(step_radius, 0.18)
	var segment_bounds = _points_to_bounds([from, to]).grow(probe_radius)
	for face in _faces_in_bounds(segment_bounds, spatial_walls, wall_faces):
		if not face.aabb.intersects(segment_bounds):
			continue
		var n: Vector3 = face.normal
		var denom = n.dot(dir)
		if abs(denom) < 0.0001:
			continue
		var t = (float(face.d) - n.dot(from)) / denom
		if t < 0.0 or t > 1.0:
			continue
		var point = from + dir * t
		if _point_in_polygon_projected(point, face.points, n, probe_radius):
			return true
	return false

func wall_hit_along_segment(from: Vector3, to: Vector3, step_radius: float) -> Dictionary:
	var dir = to - from
	var best_t = INF
	var best = {}
	var probe_radius = max(step_radius, 0.18)
	var segment_bounds = _points_to_bounds([from, to]).grow(probe_radius)
	for face in _faces_in_bounds(segment_bounds, spatial_faces, faces):
		if not face.aabb.intersects(segment_bounds):
			continue
		var n: Vector3 = face.normal
		var denom = n.dot(dir)
		if abs(denom) < 0.0001:
			continue
		var t = (float(face.d) - n.dot(from)) / denom
		if t < 0.0 or t > 1.0 or t >= best_t:
			continue
		var point = from + dir * t
		if _point_in_polygon_projected(point, face.points, n, probe_radius):
			best_t = t
			var safe_offset = max(PLAYER_RADIUS + 0.12, probe_radius + 0.24)
			var safe_pos = point + n.normalized() * safe_offset
			var alternate_safe_pos = point - n.normalized() * safe_offset
			if is_blocked_world(safe_pos, PLAYER_RADIUS) and not is_blocked_world(alternate_safe_pos, PLAYER_RADIUS):
				safe_pos = alternate_safe_pos
			best = {
				"hit": true,
				"position": point,
				"safe_position": safe_pos,
				"normal": n
			}
	if best.is_empty():
		return {"hit": false, "position": to, "safe_position": to, "normal": Vector3.ZERO}
	return best

func _ceiling_penetration(pos: Vector3, radius: float) -> float:
	var ceiling_y = ceiling_height_at(pos, radius)
	if ceiling_y == INF:
		return 0.0
	return max(0.0, pos.y + PLAYER_HEIGHT - ceiling_y)

func _nearest_wall_contact(pos: Vector3, radius: float) -> Dictionary:
	var body_mid = pos + Vector3(0, PLAYER_HEIGHT * 0.52, 0)
	var best = {}
	var best_penetration = -INF
	for face in _faces_near(pos, radius + 1.6, spatial_walls, wall_faces):
		var face_bounds: AABB = face.aabb
		if body_mid.y < face_bounds.position.y - 0.12 or body_mid.y > face_bounds.position.y + face_bounds.size.y + 0.12:
			continue
		if pos.x < face_bounds.position.x - radius or pos.x > face_bounds.position.x + face_bounds.size.x + radius:
			continue
		if pos.z < face_bounds.position.z - radius or pos.z > face_bounds.position.z + face_bounds.size.z + radius:
			continue
		var n: Vector3 = face.normal
		var horizontal = Vector3(n.x, 0, n.z)
		if horizontal.length() < 0.001:
			continue
		horizontal = horizontal.normalized()
		var dist = horizontal.dot(pos) - horizontal.dot(face.points[0])
		var abs_dist = abs(dist)
		if abs_dist > radius:
			continue
		var projected = body_mid - horizontal * dist
		if not _point_in_polygon_projected(projected, face.points, n, radius + 0.04):
			continue
		var penetration = radius - abs_dist
		if penetration > best_penetration:
			best_penetration = penetration
			best = {"normal": horizontal if dist >= 0.0 else -horizontal, "distance": abs_dist}
	return best

func jump_boost_at(_pos: Vector3) -> float:
	return 0.0

func accelerator_at(_pos: Vector3) -> Dictionary:
	return {}

func surface_slide_factor_at(_pos: Vector3) -> float:
	return 0.18

func _point_in_polygon_projected(point: Vector3, poly: Array, normal: Vector3, padding: float = 0.0) -> bool:
	var axis = _dominant_axis(normal)
	var p2 = _project_point(point, axis)
	var sign = 0
	for i in poly.size():
		var a = _project_point(poly[i], axis)
		var b = _project_point(poly[(i + 1) % poly.size()], axis)
		var edge = b - a
		var rel = p2 - a
		var cross = edge.x * rel.y - edge.y * rel.x
		if abs(cross) <= padding:
			continue
		var current_sign = 1 if cross > 0.0 else -1
		if sign == 0:
			sign = current_sign
		elif sign != current_sign:
			return false
	return true

func _dominant_axis(normal: Vector3) -> int:
	var a = normal.abs()
	if a.x > a.y and a.x > a.z:
		return 0
	if a.y > a.z:
		return 1
	return 2

func _project_point(point: Vector3, axis: int) -> Vector2:
	match axis:
		0:
			return Vector2(point.y, point.z)
		1:
			return Vector2(point.x, point.z)
		_:
			return Vector2(point.x, point.y)

func _points_to_bounds(points: Array) -> AABB:
	if points.is_empty():
		return AABB()
	var box = AABB(points[0], Vector3.ZERO)
	for i in range(1, points.size()):
		box = box.expand(points[i])
	return box
