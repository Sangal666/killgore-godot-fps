extends SceneTree
## Deterministic construction contract: run before/after a structural refactor.
## No simulation ticks; no persisted settings or scene edits.
var node_records: Array = []
var shader_sources: Dictionary = {}

func _initialize() -> void: call_deferred("run")

func digest(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func canonical(value):
	if value is Dictionary:
		var result := {}
		var keys = value.keys()
		keys.sort_custom(func(a,b): return str(a)<str(b))
		for key in keys: result[str(key)] = canonical(value[key])
		return result
	if value is Array:
		var result: Array = []
		for entry in value: result.append(canonical(entry))
		return result
	if value is Node: return str(value.name)
	if value is Resource: return value.resource_path if not value.resource_path.is_empty() else value.get_class()
	if typeof(value) in [TYPE_VECTOR2,TYPE_VECTOR3,TYPE_VECTOR2I,TYPE_VECTOR3I,TYPE_TRANSFORM3D,TYPE_COLOR,TYPE_BASIS]: return str(value)
	return value

func material_record(material: Material) -> Dictionary:
	if material == null: return {}
	if material is ShaderMaterial:
		var hash_text = material.shader.code.strip_edges().sha256_text()
		shader_sources[hash_text] = true
		var parameters := {}
		for uniform in material.shader.get_shader_uniform_list():
			var key := String(uniform.name)
			parameters[key] = canonical(material.get_shader_parameter(key))
		return {"shader":hash_text,"parameters":canonical(parameters)}
	if material is BaseMaterial3D:
		return {"albedo":str(material.albedo_color),"texture":canonical(material.albedo_texture),"roughness":material.roughness,"metallic":material.metallic,"emission":material.emission_enabled}
	return {"type":material.get_class()}

func record(node: Node, base: Node) -> void:
	var entry := {"path":str(base.get_path_to(node)),"class":node.get_class()}
	if node is Node3D:
		entry["transform"] = str(node.transform)
		entry["visible"] = node.visible
	if node is MeshInstance3D:
		entry["mesh"] = node.mesh.get_class() if node.mesh != null else "null"
		entry["aabb"] = str(node.get_aabb())
		entry["material"] = material_record(node.material_override)
	if node is MultiMeshInstance3D:
		entry["instances"] = node.multimesh.instance_count
		entry["buffer"] = digest(var_to_bytes(node.multimesh.buffer))
		entry["material"] = material_record(node.material_override)
	if node is Light3D:
		entry["light"] = [str(node.light_color),node.light_energy,node.shadow_enabled]
	if node is AudioStreamPlayer3D and node.stream is AudioStreamWAV:
		entry["pcm"] = digest(node.stream.data)
		entry["audio"] = [node.stream.mix_rate,node.stream.loop_mode,node.stream.loop_begin,node.stream.loop_end]
	node_records.append(entry)
	for child in node.get_children(): record(child,base)

func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	var main = load("res://Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.set_process(false)
	main.set_physics_process(false)
	main.player.set_process(false)
	main.player.set_physics_process(false)
	var r = main.level_manager.horror_runtime
	record(r,r)
	var hashes := shader_sources.keys()
	hashes.sort()
	if node_records.size()<1000 or main.level_manager.solid_areas.size()<100 or hashes.is_empty():
		push_error("Incomplete horror construction; do not accept a partial snapshot")
		main.queue_free()
		quit(1)
		return
	var snapshot := {
		"nodes":node_records,"solids":canonical(main.level_manager.solid_areas),
		"lights":canonical(r.route_light_positions),"wards":canonical(r.monster_warding_lights),
		"tasks":canonical(r.task_states),"anchors":canonical(r.task_anchors),
		"interactables":canonical(r.interactables),"batteries":canonical(r.battery_pickups),
		"shader_sources":hashes,"spawn":str(main.player.global_position)
	}
	var output := OS.get_environment("HORROR_SNAPSHOT_PATH")
	if output.is_empty(): output = "/private/tmp/killgore_modular_snapshot.json"
	var file := FileAccess.open(output,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write QA snapshot "+output)
		quit(1)
		return
	file.store_string(JSON.stringify(canonical(snapshot),"\t"))
	file.close()
	print("HORROR_CONSTRUCTION_SNAPSHOT_OK nodes=",node_records.size()," solids=",main.level_manager.solid_areas.size()," shaders=",hashes.size()," output=",output)
	main.queue_free()
	for frame in 4: await process_frame
	quit()
