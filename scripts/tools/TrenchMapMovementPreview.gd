extends Node3D

const GameDataScript = preload("res://scripts/core/GameData.gd")
const AudioManagerScript = preload("res://scripts/core/AudioManager.gd")

const MAP_PATH = "res://assets/maps/map_1_v2.map"
const MAP_UNIT_TO_GODOT = 1.0 / 64.0
const PLAYER_RADIUS = 0.34
const PLAYER_HEIGHT = 1.72
const FLOOR_EPS = 0.08

var player
var audio_manager
var map_root: Node3D
var faces: Array = []
var floor_faces: Array = []
var wall_faces: Array = []
var ceiling_faces: Array = []
var solid_brushes: Array = []
var bounds := AABB()
var preview_offset := Vector3.ZERO
var spawn_pos := Vector3.ZERO
var info_label: Label

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_setup_environment()
	_load_map()
	_spawn_player()
	_add_info_label()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	player.tick(min(delta, 0.05))

func _setup_environment() -> void:
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color8(18, 20, 24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color8(128, 132, 142)
	env.ambient_light_energy = 0.76
	env_node.environment = env
	add_child(env_node)
	var sun = DirectionalLight3D.new()
	sun.name = "PreviewSun"
	sun.rotation_degrees = Vector3(-48, 36, 0)
	sun.light_energy = 1.35
	add_child(sun)
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)

func _load_map() -> void:
	map_root = Node3D.new()
	map_root.name = "Map_1_V2_TrenchBroomPreview"
	add_child(map_root)
	var raw_brushes = _parse_map_brushes()
	var brush_data = []
	for planes in raw_brushes:
		var brush = _build_brush(planes)
		if brush.is_empty():
			continue
		brush_data.append(brush)
	if brush_data.is_empty():
		push_error("No valid brushes parsed from %s" % MAP_PATH)
		return
	bounds = brush_data[0].bounds
	for i in range(1, brush_data.size()):
		bounds = bounds.merge(brush_data[i].bounds)
	preview_offset = Vector3(
		-(bounds.position.x + bounds.size.x * 0.5),
		-bounds.position.y,
		-bounds.position.z + 1.8
	)
	_add_map_visual(brush_data)
	_prepare_spawn_position()

func _parse_map_brushes() -> Array:
	var file = FileAccess.open(MAP_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open map file: %s" % MAP_PATH)
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
				if point == null:
					continue
				if _point_inside_planes(point, planes):
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
				"d": float(plane.d) + plane_normal.dot(preview_offset)
			})
		solid_brushes.append({
			"planes": transformed_planes,
			"bounds": AABB(brush.bounds.position + preview_offset, brush.bounds.size)
		})
		var brush_color = _brush_color(brush_index)
		for poly_info in brush.polys:
			var transformed = []
			for p in poly_info.points:
				transformed.append(p + preview_offset)
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

func _brush_color(index: int) -> Color:
	var hue = fmod(0.04 + float(index % 9) * 0.037, 1.0)
	return Color.from_hsv(hue, 0.22, 0.62)

func _map_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.88
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _brush_material(index: int) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = _brush_color(index)
	mat.roughness = 0.88
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

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
	if not found:
		spawn_pos = Vector3(0.0, 2.0, 0.0)
		return
	spawn_pos = Vector3(spawn_x, spawn_y + 0.02, spawn_z)

func _spawn_player() -> void:
	player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(player)
	player.configure(self, GameDataScript.make_powerup_data())
	player.reset_spawn(spawn_pos)
	player.sound_requested.connect(_on_player_sound)
	player.hp = 100
	player.developer_mode = true

func _add_info_label() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	info_label = Label.new()
	info_label.position = Vector2(18, 18)
	info_label.add_theme_font_size_override("font_size", 15)
	info_label.add_theme_color_override("font_color", Color8(235, 225, 175))
	info_label.text = "MAP 1 V2 | movement-only level | ESC mouse/Q quit\nWASD, Shift slide/glide, Space jump/super/double, Q grapple\n1 Godot unit = 64 map units | map approx X %.1f / Length %.1f / Height %.1f" % [
		bounds.size.x,
		bounds.size.z,
		bounds.size.y
	]
	canvas.add_child(info_label)

func _on_player_sound(sfx: String) -> void:
	if audio_manager != null and audio_manager.has_method("play"):
		audio_manager.play(sfx, 0.04)

func floor_height_at(pos: Vector3) -> float:
	var best = -64.0
	for face in floor_faces:
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
	var head_probe = pos + Vector3(0, PLAYER_HEIGHT, 0)
	for face in ceiling_faces:
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
	if best < INF and head_probe.y > best:
		return best
	return best

func is_blocked_world(pos: Vector3, radius: float) -> bool:
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
		if wall_hit_along_segment(from_probe, to_probe, max(radius, 0.22)).hit:
			return true
	return is_blocked_world(to_pos, radius)

func _ceiling_penetration(pos: Vector3, radius: float) -> float:
	var ceiling_y = ceiling_height_at(pos, radius)
	if ceiling_y == INF:
		return 0.0
	return max(0.0, pos.y + PLAYER_HEIGHT - ceiling_y)

func _nearest_wall_contact(pos: Vector3, radius: float) -> Dictionary:
	var body_mid = pos + Vector3(0, PLAYER_HEIGHT * 0.52, 0)
	var best = {}
	var best_penetration = -INF
	for face in wall_faces:
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

func wall_hit_along_segment(from: Vector3, to: Vector3, step_radius: float) -> Dictionary:
	var dir = to - from
	var best_t = INF
	var best = {}
	var probe_radius = max(step_radius, 0.18)
	var segment_bounds = _points_to_bounds([from, to]).grow(probe_radius)
	for face in faces:
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
			best = {"hit": true, "position": point, "normal": n}
	if best.is_empty():
		return {"hit": false, "position": to, "normal": Vector3.ZERO}
	return best

func jump_boost_at(_pos: Vector3) -> float:
	return 0.0

func accelerator_at(_pos: Vector3) -> Dictionary:
	return {}

func surface_slide_factor_at(_pos: Vector3) -> float:
	return 0.18

func grapple_enemy_hit_info(_origin: Vector3, _dir: Vector3, _max_dist: float, _radius: float = 1.0) -> Dictionary:
	return {}

func enemy_hit_info_in_ray(_origin: Vector3, _dir: Vector3, _max_dist: float) -> Dictionary:
	return {}

func is_miniboss_enemy(_enemy) -> bool:
	return false

func spawn_grapple_cable(from: Vector3, to: Vector3) -> void:
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.018
	mesh.bottom_radius = 0.018
	mesh.height = max(0.01, from.distance_to(to))
	mesh.radial_segments = 6
	var cable = MeshInstance3D.new()
	cable.mesh = mesh
	cable.material_override = _glow_material(Color8(78, 205, 255))
	add_child(cable)
	cable.global_position = (from + to) * 0.5
	cable.look_at(to, Vector3.UP)
	cable.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	var tween = create_tween()
	tween.tween_interval(0.07)
	tween.tween_callback(cable.queue_free)

func _glow_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.75
	return mat

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
