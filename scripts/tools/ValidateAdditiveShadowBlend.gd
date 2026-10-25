extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(800,600)
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	var solid := MeshInstance3D.new()
	solid.mesh = BoxMesh.new()
	solid.position.z = -5
	world.add_child(solid)
	for x in [-0.5,0.5]:
		var light := SpotLight3D.new()
		light.position = Vector3(x,0,-1)
		light.shadow_enabled = true
		light.spot_range = 10
		world.add_child(light)
	var card := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(8,6)
	card.mesh = quad
	card.position.z = -2
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(card)
	var failures := 0
	var compatibility := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	print("BLEND_RENDERER ",RenderingServer.get_current_rendering_method())
	for mode in ["add","mix"]:
		var shader := Shader.new()
		var fragment := "ALBEDO=vec3(0.86,0.83,0.67); ALPHA=0.01;"
		shader.code = "shader_type spatial; render_mode unshaded,blend_%s,depth_draw_never; void fragment(){%s}" % [mode,fragment]
		var material := ShaderMaterial.new()
		material.shader = shader
		card.material_override = material
		for frame in 30: await process_frame
		RenderingServer.force_draw(false)
		var img := root.get_texture().get_image()
		img.save_png("/private/tmp/blend_%s.png" % mode)
		print("BLEND ",mode," background=",img.get_pixel(100,100))
		if compatibility and mode == "add" and img.get_pixel(100,100).r < 0.9: failures += 1
		if mode == "mix" and img.get_pixel(100,100).r > 0.4: failures += 1
	# Exercise the production ray marcher, not just a simplified proxy quad.
	var source := FileAccess.get_file_as_string("res://scripts/player/PlayerController.gd")
	var air_code: String = source.split("func _ensure_flashlight_air_volume()")[1].split('"""')[1]
	var box := BoxMesh.new()
	box.size = Vector3(2.44,2.44,20)
	card.mesh = box
	card.position.z = -10
	for mode in ["legacy","fixed"]:
		var shader := Shader.new()
		shader.code = air_code.replace("blend_mix", "blend_add") if mode == "legacy" else air_code
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("lens_position",Vector3(0.2,-0.2,-0.2))
		material.set_shader_parameter("lens_direction",Vector3.FORWARD)
		card.material_override = material
		for frame in 30: await process_frame
		RenderingServer.force_draw(false)
		var img := root.get_texture().get_image()
		img.save_png("/private/tmp/production_air_%s.png" % mode)
		var c := img.get_pixel(400,450)
		print("PRODUCTION_AIR ",mode," color=",c)
		if compatibility and mode == "legacy" and c.r < 0.9: failures += 1
		if mode == "fixed" and c.r > 0.5: failures += 1
	print("ADDITIVE_SHADOW_BLEND_OK" if failures == 0 else "ADDITIVE_SHADOW_BLEND_FAILED")
	quit(1 if failures else 0)
