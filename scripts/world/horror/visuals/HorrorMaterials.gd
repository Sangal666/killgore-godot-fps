extends RefCounted
## Materials responsibility extracted from HorrorSequenceLevel.
## No autonomous ticks or scene ownership; runtime coordinates lifecycle.
## Bare runtime dependencies are explicit parameters; pure helpers need none.

func flat_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func dim_lit_material(color: Color, roughness: float, _emission_energy: float) -> StandardMaterial3D:
	var material = flat_material(color, roughness)
	return material

func glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material = flat_material(color, 0.34)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func room_surface(_runtime, color: Color, roughness: float, metallic: float = 0.0) -> Material:
	# Task-room surfaces use the same compatibility-safe flashlight response as
	# the maze shell. Relying only on realtime lights made these meshes black once
	# the renderer's per-object light budget was exhausted.
	# Transparent glass/puddles stay on StandardMaterial3D because their callers
	# configure BaseMaterial3D transparency after this helper returns.
	if color.a < 0.995:
		var transparent_material = flat_material(color, roughness)
		transparent_material.metallic = metallic
		return transparent_material
	var material = make_concrete_shader(_runtime, color, 0.08, roughness)
	material.set_shader_parameter("metallic_value", metallic)
	material.set_shader_parameter("ambient_lift", lerp(0.018, 0.045, 1.0 - color.get_luminance()))
	return material

func make_concrete_shader(_runtime, base_color: Color, grime: float, roughness: float) -> ShaderMaterial:
	var shader = preload("res://assets/shaders/horror/make_concrete_shader.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Vector3(base_color.r, base_color.g, base_color.b))
	material.set_shader_parameter("grime", grime)
	material.set_shader_parameter("roughness_value", roughness)
	_runtime.flashlight_reactive_materials.append(material)
	return material

func make_puddle_shader() -> ShaderMaterial:
	var shader = preload("res://assets/shaders/horror/make_puddle_shader.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	return material

func make_memory_shader(phase: float) -> ShaderMaterial:
	var shader = preload("res://assets/shaders/horror/make_memory_shader.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("phase", phase)
	return material

func make_monster_integrated_material(_runtime, source: BaseMaterial3D, is_head: bool) -> ShaderMaterial:
	var shader = preload("res://assets/shaders/horror/make_monster_integrated_material.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	var albedo_texture = load("res://assets/characters/corridor_creature/painted_puppet_v2/puppet_albedo.png") as Texture2D
	material.set_shader_parameter("puppet_roughness", load("res://assets/characters/corridor_creature/painted_puppet_v2/puppet_roughness.png"))
	if albedo_texture != null:
		material.set_shader_parameter("base_texture", albedo_texture)
		material.set_shader_parameter("texture_mix", 1.0)
	else:
		material.set_shader_parameter("texture_mix", 0.0)
	material.set_shader_parameter("vertex_color_mix", 0.0)
	var puppet_normal = load("res://assets/characters/corridor_creature/painted_puppet_v2/puppet_normal.png") as Texture2D
	if puppet_normal != null:
		material.set_shader_parameter("normal_texture", puppet_normal)
		material.set_shader_parameter("normal_mix", 1.0)
	else:
		material.set_shader_parameter("normal_mix", 0.0)
	material.set_shader_parameter("head_surface", 1.0 if is_head else 0.0)
	material.set_shader_parameter("distress", 0.0)
	material.set_shader_parameter("distress_phase", float(_runtime.monster_scorch_materials.size()) * 1.73)
	material.set_shader_parameter("fixture_count", _runtime.shader_light_positions.size())
	material.set_shader_parameter("fixture_positions", _runtime.shader_light_positions)
	material.set_shader_parameter("fixture_colors", _runtime.shader_light_colors)
	material.set_shader_parameter("fixture_strengths", _runtime.shader_light_strengths)
	_runtime.flashlight_reactive_materials.append(material)
	return material

func make_monster_light_wisp_material(phase: float) -> ShaderMaterial:
	var shader = preload("res://assets/shaders/horror/make_monster_light_wisp_material.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("strength", 0.0)
	material.set_shader_parameter("phase", phase)
	return material

func make_monster_smoke_material(texture_path: String, tint: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = load(texture_path)
	material.albedo_color = tint
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func make_monster_burn_aura_material() -> ShaderMaterial:
	var shader = preload("res://assets/shaders/horror/make_monster_burn_aura_material.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("pain", 0.0)
	material.set_shader_parameter("flash", 0.0)
	return material

func make_monster_contact_shadow_material() -> ShaderMaterial:
	var shader = preload("res://assets/shaders/horror/make_monster_contact_shadow_material.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("motion", 0.0)
	material.set_shader_parameter("distress", 0.0)
	return material

func light_shaft_material(_runtime, color: Color, opacity: float) -> ShaderMaterial:
	var cache_key = "%s_%.3f" % [color.to_html(false), opacity]
	if _runtime.light_shaft_material_cache.has(cache_key):
		return _runtime.light_shaft_material_cache[cache_key]
	var shader = preload("res://assets/shaders/horror/light_shaft_material.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shaft_color", Color(color.r, color.g, color.b, opacity))
	_runtime.light_shaft_material_cache[cache_key] = material
	return material

func corridor_mist_material(_runtime, color: Color, opacity: float) -> ShaderMaterial:
	var cache_key = "mist_%s_%.3f" % [color.to_html(false), opacity]
	if _runtime.mist_material_cache.has(cache_key):
		return _runtime.mist_material_cache[cache_key]
	var shader = preload("res://assets/shaders/horror/corridor_mist_material.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("mist_color", Color(color.r, color.g, color.b, opacity))
	_runtime.mist_material_cache[cache_key] = material
	return material

func fixture_floor_pool_material(_runtime, color: Color, opacity: float, brightness: float) -> ShaderMaterial:
	var cache_key = "floor_pool_%s_%.3f_%.3f" % [color.to_html(false), opacity, brightness]
	if _runtime.fixture_pool_material_cache.has(cache_key):
		return _runtime.fixture_pool_material_cache[cache_key]
	var shader = preload("res://assets/shaders/horror/fixture_floor_pool_material.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("pool_color", Color(color.r, color.g, color.b, opacity))
	material.set_shader_parameter("brightness", brightness)
	_runtime.fixture_pool_material_cache[cache_key] = material
	return material

func fixture_light_shaft_material(_runtime, color: Color, opacity: float) -> ShaderMaterial:
	var cache_key = "shaft_%s_%.3f" % [color.to_html(false), opacity]
	if _runtime.light_shaft_material_cache.has(cache_key):
		return _runtime.light_shaft_material_cache[cache_key]
	var shader = preload("res://assets/shaders/horror/fixture_light_shaft_material.gdshader").duplicate() as Shader
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shaft_color", Color(color.r, color.g, color.b, opacity))
	_runtime.light_shaft_material_cache[cache_key] = material
	return material

