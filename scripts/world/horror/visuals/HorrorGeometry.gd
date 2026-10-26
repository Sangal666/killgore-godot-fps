extends RefCounted
## Geometry responsibility extracted from HorrorSequenceLevel.
## No autonomous ticks or scene ownership; runtime coordinates lifecycle.
## Bare runtime dependencies are explicit parameters; pure helpers need none.

func add_box(parent: Node3D, box_size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = box_size
	node.mesh = mesh
	node.position = position
	node.material_override = material
	parent.add_child(node)
	return node

func add_structure_box(_runtime, parent: Node3D, box_size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	# These are ordinary authored solids registered through the same collision list
	# used by the rest of the level. No grid-cell replacement or kitchen-specific
	# movement exception is involved.
	var node = add_box(parent, box_size, position, material)
	var center = node.global_position
	_runtime.level_manager.solid_areas.append({
		"center": center,
		"half": Vector2(box_size.x * 0.5, box_size.z * 0.5),
		"height": box_size.y
	})
	return node

func add_pipe(parent: Node3D, position: Vector3, rotation_degrees_value: Vector3, radius: float, height: float, material: Material) -> void:
	var pipe = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	pipe.mesh = mesh
	pipe.position = position
	pipe.rotation_degrees = rotation_degrees_value
	pipe.material_override = material
	parent.add_child(pipe)

func add_disc(parent: Node3D, position: Vector3, radius: float, height: float, material: Material, rotation_degrees_value: Vector3 = Vector3.ZERO) -> void:
	var disc = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	disc.mesh = mesh
	disc.position = position
	disc.rotation_degrees = rotation_degrees_value
	disc.material_override = material
	parent.add_child(disc)

func add_kitchen_chair(parent: Node3D, position: Vector3, frame_material: Material, seat_material: Material) -> void:
	add_box(parent, Vector3(1.25, 0.14, 1.15), position + Vector3(0, 0.58, 0), seat_material)
	add_box(parent, Vector3(1.25, 1.20, 0.13), position + Vector3(0, 1.16, 0.52), frame_material)
	for offset in [Vector3(-0.48, 0.28, -0.42), Vector3(0.48, 0.28, -0.42), Vector3(-0.48, 0.28, 0.42), Vector3(0.48, 0.28, 0.42)]:
		add_box(parent, Vector3(0.12, 0.56, 0.12), position + offset, frame_material)

func add_traffic_cone(parent: Node3D, position: Vector3, cone_material: Material, stripe_material: Material) -> void:
	add_box(parent, Vector3(0.75, 0.08, 0.75), position + Vector3(0, -0.30, 0), cone_material)
	add_box(parent, Vector3(0.26, 0.70, 0.26), position, cone_material)
	add_box(parent, Vector3(0.31, 0.11, 0.31), position + Vector3(0, 0.05, 0), stripe_material)

func add_room_sign(parent: Node3D, text: String, position: Vector3, color: Color, pixel_size: float) -> void:
	var label = Label3D.new()
	label.text = text
	label.position = position
	label.pixel_size = min(pixel_size, 0.0048)
	label.font_size = 32
	label.modulate = color
	label.outline_modulate = Color(0.02, 0.025, 0.025, 1.0)
	label.outline_size = 4
	label.no_depth_test = false
	parent.add_child(label)

func add_segmented_ceiling(_runtime, parent: Node3D, room_size: Vector2, columns: int, rows: int, panel_material: Material, frame_material: Material) -> void:
	var cell_width = room_size.x / float(columns)
	var cell_depth = room_size.y / float(rows)
	for row_index in rows:
		for column_index in columns:
			var panel_position = Vector3(
				-room_size.x * 0.5 + cell_width * (float(column_index) + 0.5),
				_runtime.WALL_HEIGHT - 0.12,
				-room_size.y * 0.5 + cell_depth * (float(row_index) + 0.5)
			)
			add_box(parent, Vector3(cell_width - 0.16, 0.12, cell_depth - 0.16), panel_position, panel_material)
	for column_index in range(columns + 1):
		var x = -room_size.x * 0.5 + cell_width * float(column_index)
		add_box(parent, Vector3(0.13, 0.18, room_size.y), Vector3(x, _runtime.WALL_HEIGHT - 0.20, 0), frame_material)
	for row_index in range(rows + 1):
		var z = -room_size.y * 0.5 + cell_depth * float(row_index)
		add_box(parent, Vector3(room_size.x, 0.18, 0.13), Vector3(0, _runtime.WALL_HEIGHT - 0.20, z), frame_material)

func add_emissive_task_marker(parent: Node3D, position: Vector3, material: Material, length: float = 2.4) -> void:
	add_box(parent, Vector3(length, 0.028, 0.13), position, material)
	add_box(parent, Vector3(0.13, 0.028, 0.72), position + Vector3(-length * 0.5, 0, 0.30), material)

func add_ceiling_raft(parent: Node3D, position: Vector3, dimensions: Vector3, frame_material: Material, strip_material: Material) -> void:
	var raft = Node3D.new()
	raft.name = "SuspendedCeilingRaft"
	raft.position = position
	parent.add_child(raft)
	# An open service frame keeps the authored room visible. The former solid slab
	# filled most of the camera and made the detailed rooms read like a blockout.
	var rail_height = min(0.14, dimensions.y * 0.42)
	var edge_z = max(0.20, dimensions.z * 0.5 - 0.12)
	var edge_x = max(0.20, dimensions.x * 0.5 - 0.12)
	for z in [-edge_z, edge_z]:
		add_box(raft, Vector3(dimensions.x, rail_height, 0.18), Vector3(0, 0, z), frame_material)
	for x in [-edge_x, edge_x]:
		add_box(raft, Vector3(0.18, rail_height, dimensions.z), Vector3(x, 0, 0), frame_material)
	for x in [-dimensions.x * 0.22, dimensions.x * 0.22]:
		add_box(raft, Vector3(0.12, rail_height * 0.72, dimensions.z * 0.82), Vector3(x, -0.015, 0), frame_material)
	add_box(raft, Vector3(dimensions.x * 0.42, 0.025, 0.12), Vector3(0, -rail_height * 0.72, 0), strip_material)
	for x in [-dimensions.x * 0.42, dimensions.x * 0.42]:
		add_box(raft, Vector3(0.07, 0.34, 0.07), Vector3(x, 0.22, 0), frame_material)

func make_task_prop(parent: Node3D, position: Vector3, kind: String, material: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "TaskProp_%s" % kind
	root.position = position
	parent.add_child(root)
	match kind:
		"wheel":
			var mesh = CylinderMesh.new()
			mesh.top_radius = 0.58
			mesh.bottom_radius = 0.58
			mesh.height = 0.32
			mesh.radial_segments = 12
			var wheel = MeshInstance3D.new()
			wheel.mesh = mesh
			wheel.rotation_degrees.z = 90.0
			wheel.material_override = material
			root.add_child(wheel)
		"pan":
			add_box(root, Vector3(1.0, 0.10, 0.72), Vector3.ZERO, material)
			add_box(root, Vector3(0.85, 0.07, 0.13), Vector3(0.85, 0, 0), material)
		"knife":
			add_box(root, Vector3(1.1, 0.06, 0.16), Vector3.ZERO, material)
		"paper", "guide":
			add_box(root, Vector3(0.72 if kind == "paper" else 1.2, 0.035, 0.48 if kind == "paper" else 0.82), Vector3.ZERO, material)
		"engine":
			add_box(root, Vector3(1.15, 0.72, 0.85), Vector3.ZERO, material)
			add_box(root, Vector3(0.68, 0.32, 1.12), Vector3(0, 0.18, 0), material)
		"can":
			add_box(root, Vector3(0.62, 0.92, 0.38), Vector3.ZERO, material)
		_:
			add_box(root, Vector3(0.72, 0.62, 0.72), Vector3.ZERO, material)
	return root

func batch_static_room_boxes(_runtime, room_root: Node3D) -> void:
	if _runtime.get_tree().has_meta("killgore_disable_static_room_batching") and bool(_runtime.get_tree().get_meta("killgore_disable_static_room_batching")):
		return
	if bool(room_root.get_meta("skip_static_room_batch", false)):
		return
	var groups = {}
	var originals: Array[MeshInstance3D] = []
	collect_static_room_boxes(room_root, room_root, groups, originals)
	var unit_box = BoxMesh.new()
	unit_box.size = Vector3.ONE
	var batch_index = 0
	for group_key in groups.keys():
		var group: Dictionary = groups[group_key]
		var transforms: Array = group["transforms"]
		if transforms.size() < 2:
			continue
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = unit_box
		multimesh.instance_count = transforms.size()
		for transform_index in transforms.size():
			multimesh.set_instance_transform(transform_index, transforms[transform_index])
		var instance = MultiMeshInstance3D.new()
		instance.name = "StaticRoomBatch_%03d" % batch_index
		instance.multimesh = multimesh
		instance.material_override = group["material"]
		instance.cast_shadow = group["cast_shadow"]
		room_root.add_child(instance)
		batch_index += 1
		for original in group["nodes"]:
			originals.append(original)
	for original in originals:
		if not is_instance_valid(original):
			continue
		var parent = original.get_parent()
		if parent != null:
			parent.remove_child(original)
		original.free()

func collect_static_room_boxes(node: Node, room_root: Node3D, groups: Dictionary, originals: Array[MeshInstance3D]) -> void:
	if node != room_root and bool(node.get_meta("skip_static_room_batch", false)):
		return
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh is BoxMesh and mesh_instance.material_override != null and mesh_instance.visible:
			var material := mesh_instance.material_override
			var transparent := material is BaseMaterial3D and (material as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
			if not transparent:
				var local_transform := room_root.global_transform.affine_inverse() * mesh_instance.global_transform
				var mesh_size: Vector3 = (mesh_instance.mesh as BoxMesh).size
				var packed_transform := local_transform * Transform3D(Basis.IDENTITY.scaled(mesh_size), Vector3.ZERO)
				# Keep batches local enough that a visible cabinet or wall section does
				# not pull an entire room's hidden boxes through the frustum culler.
				# Eight metres retains most of the submission reduction while avoiding
				# the overdraw seen with the original 16 m groups.
				var chunk_x := floori(local_transform.origin.x / 8.0)
				var chunk_z := floori(local_transform.origin.z / 8.0)
				var key := "%d:%d:%d:%d" % [material.get_instance_id(), int(mesh_instance.cast_shadow), chunk_x, chunk_z]
				if not groups.has(key):
					groups[key] = {
						"material": material,
						"cast_shadow": mesh_instance.cast_shadow,
						"transforms": [],
						"nodes": []
					}
				groups[key]["transforms"].append(packed_transform)
				groups[key]["nodes"].append(mesh_instance)
	for child in node.get_children():
		collect_static_room_boxes(child, room_root, groups, originals)

func add_box_multimesh(parent: Node3D, parts: Array, material: Material, node_name: String) -> MultiMeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = parts.size()
	for index in parts.size():
		var part = parts[index]
		var transform: Transform3D
		if part is Transform3D:
			transform = part
		else:
			var size: Vector3 = part[0]
			var position: Vector3 = part[1]
			var rotation_degrees: Vector3 = part[2]
			transform = Transform3D(Basis.from_euler(rotation_degrees * PI / 180.0).scaled(size), position)
		multimesh.set_instance_transform(index, transform)
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	parent.add_child(instance)
	return instance

func add_room_asset(_runtime, parent: Node3D, file_name: String, position: Vector3, yaw: float, target_height: float) -> Node3D:
	var path = _runtime.URBAN_ASSET_ROOT + file_name
	var packed: PackedScene = _runtime.room_asset_cache.get(path)
	if packed == null:
		if not ResourceLoader.exists(path):
			return null
		packed = load(path) as PackedScene
		if packed == null:
			return null
		_runtime.room_asset_cache[path] = packed
	var imported = packed.instantiate()
	if not imported is Node3D:
		imported.queue_free()
		return null
	var holder = Node3D.new()
	holder.name = "UrbanAsset_%s" % file_name.get_basename()
	holder.position = position
	holder.rotation_degrees.y = yaw
	parent.add_child(holder)
	holder.add_child(imported)
	prepare_room_asset(imported)
	normalize_room_asset(imported, target_height)
	return holder

func prepare_room_asset(root: Node) -> void:
	if root is MeshInstance3D:
		root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if root is CollisionObject3D:
		root.collision_layer = 0
		root.collision_mask = 0
	if root is CollisionShape3D:
		root.disabled = true
	if root is Light3D or root is Camera3D:
		root.visible = false
	for child in root.get_children():
		prepare_room_asset(child)

func normalize_room_asset(root: Node3D, target_height: float) -> void:
	var bounds = room_asset_bounds(root)
	if bounds.size == Vector3.ZERO or bounds.size.y <= 0.001:
		return
	var ratio = target_height / bounds.size.y
	var center = bounds.position + bounds.size * 0.5
	root.scale = Vector3.ONE * ratio
	root.position = Vector3(-center.x * ratio, -bounds.position.y * ratio, -center.z * ratio)

func room_asset_bounds(root: Node3D) -> AABB:
	var found = false
	var bounds = AABB()
	var root_inverse = root.global_transform.affine_inverse()
	for node in walk_room_asset_nodes(root):
		if not node is MeshInstance3D:
			continue
		var mesh_node = node as MeshInstance3D
		var local_bounds = mesh_node.get_aabb()
		if local_bounds.size == Vector3.ZERO:
			continue
		for corner in room_aabb_corners(local_bounds):
			var point = root_inverse * mesh_node.to_global(corner)
			if not found:
				bounds = AABB(point, Vector3.ZERO)
				found = true
			else:
				bounds = bounds.expand(point)
	return bounds if found else AABB()

func walk_room_asset_nodes(root: Node) -> Array:
	var nodes: Array = [root]
	for child in root.get_children():
		nodes.append_array(walk_room_asset_nodes(child))
	return nodes

func room_aabb_corners(box: AABB) -> Array:
	var p = box.position
	var s = box.size
	return [p, p + Vector3(s.x, 0, 0), p + Vector3(0, s.y, 0), p + Vector3(0, 0, s.z), p + Vector3(s.x, s.y, 0), p + Vector3(s.x, 0, s.z), p + Vector3(0, s.y, s.z), p + s]

func prepare_memory_figure(root: Node) -> void:
	if root is MeshInstance3D:
		(root as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		(root as MeshInstance3D).extra_cull_margin = 0.45
	if root is CollisionObject3D:
		(root as CollisionObject3D).collision_layer = 0
		(root as CollisionObject3D).collision_mask = 0
	if root is CollisionShape3D:
		(root as CollisionShape3D).disabled = true
	if root is Light3D or root is Camera3D:
		(root as Node3D).visible = false
	for child in root.get_children():
		prepare_memory_figure(child)

