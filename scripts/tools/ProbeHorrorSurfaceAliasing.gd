extends SceneTree
## Controlled A/B of the real wall material; no game lighting or UV changes.
const Runtime = preload("res://scripts/world/HorrorSequenceLevel.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(640, 360)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var runtime := Runtime.new()
	world.add_child(runtime)
	var material: ShaderMaterial = runtime._make_concrete_shader(Color(0.35,0.36,0.33), 0.30, 0.94)
	material.set_shader_parameter("surface_kind", 1)
	# Unlit isolates albedo aliasing from shadows, normal maps and flashlight.
	var original := material.shader.code.replace("render_mode diffuse_burley", "render_mode unshaded, diffuse_burley")
	var wall := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(30, 16)
	wall.mesh = quad
	wall.material_override = material
	wall.position.y = 8.0
	world.add_child(wall)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	camera.fov = 40
	var helper := "float filtered_noise(vec2 p) { float footprint = max(length(dFdx(p)), length(dFdy(p))); return mix(noise(p), 0.5, smoothstep(0.5, 1.5, footprint)); }\n"
	# Keep reproducing the unfixed baseline after the production fix ships.
	original = original.replace("filtered_noise(wall_uv * 72.0)", "noise(wall_uv * 72.0)")
	var candidate := original if "float filtered_noise(" in original else original.replace("void vertex()", helper + "void vertex()")
	candidate = candidate.replace("noise(wall_uv * 72.0)", "filtered_noise(wall_uv * 72.0)")
	for distance in [3.0, 24.0]:
		for filtered in [false, true]:
			material.shader.code = candidate if filtered else original
			var images: Array[Image] = []
			for offset in [0.0, 0.002]:
				camera.position = Vector3(offset, 8.0, distance)
				for frame in 8: await process_frame
				RenderingServer.force_draw(false)
				images.append(viewport.get_texture().get_image())
			var error := 0.0
			for y in range(140, 230):
				for x in range(220, 420):
					var a := images[0].get_pixel(x,y)
					var b := images[1].get_pixel(x,y)
					error += (absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
			print("WALL_MICRO_JITTER distance=",distance," filtered=",filtered," mean_8bit_delta=",error*255.0/18000.0)
			images[0].save_png("/private/tmp/wall_alias_%s_%s.png" % [int(distance), "filtered" if filtered else "original"])
	world.queue_free()
	await process_frame
	quit()
