extends SceneTree
const Creature = preload("res://assets/characters/corridor_creature/corridor_creature.glb")
func _initialize() -> void: call_deferred("run")
func find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var player := find_player(child)
		if player != null: return player
	return null
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := Node3D.new()
	viewport.add_child(scene)
	var model := Creature.instantiate()
	scene.add_child(model)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.06,0.07,0.08)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8,0.85,1.0)
	world.environment.ambient_light_energy = 0.5
	scene.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50,-35,0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	scene.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(5,0.05,5)
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.026
	scene.add_child(floor_mesh)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(2.6,1.7,3.0)
	camera.look_at(Vector3(0,0.65,0))
	camera.fov = 38
	camera.current = true
	var player := find_player(model)
	for clip in player.get_animation_list():
		if clip == "RESET": continue
		player.play(clip)
		player.seek(player.get_animation(clip).length * (0.5 if clip == "Attack" else 0.35), true)
		player.pause()
		for frame in 6: await process_frame
		RenderingServer.force_draw(false)
		viewport.get_texture().get_image().save_png("/private/tmp/final_creature_%s.png" % clip)
		print("CREATURE_CLIP_CAPTURE ", clip)
	viewport.queue_free()
	await process_frame
	quit()
