shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D puppet_roughness : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_mix = 0.0;
uniform float vertex_color_mix = 0.0;
uniform float normal_mix = 0.0;
uniform float head_surface = 0.0;
uniform float distress = 0.0;
uniform float distress_phase = 0.0;
uniform bool flashlight_enabled = false;
uniform vec3 flashlight_origin = vec3(0.0);
uniform vec3 flashlight_direction = vec3(0.0, 0.0, -1.0);
uniform int fixture_count = 0;
uniform vec3 fixture_positions[32];
uniform vec3 fixture_colors[32];
uniform float fixture_strengths[32];
varying vec3 world_position;
varying vec3 model_position;
float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	model_position = VERTEX;
}
void fragment() {
	vec3 texture_color = texture(base_texture, UV).rgb;
	vec3 raw_color = mix(vec3(1.0), texture_color, texture_mix);
	raw_color *= mix(vec3(1.0), COLOR.rgb, vertex_color_mix);
	// Authored UV-baked paint/wood/face regions. Never desaturate the source
	// or generate animated object-space grime: both erased the approved design.
	ALBEDO = raw_color * (1.0 - distress * 0.045);
	ROUGHNESS = clamp(texture(puppet_roughness, UV).r, 0.65, 0.98);
	METALLIC = 0.0;
	SPECULAR = 0.16;
	vec3 sampled_normal = texture(normal_texture, UV).rgb;
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), sampled_normal, normal_mix);
	NORMAL_MAP_DEPTH = mix(0.0, 0.38, normal_mix);
	EMISSION = vec3(0.0);
}
