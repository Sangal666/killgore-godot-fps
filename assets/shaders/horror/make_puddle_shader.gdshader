shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
void fragment() {
	float ripple = sin((UV.x + UV.y) * 24.0 + TIME * 0.34) * 0.015;
	ALBEDO = vec3(0.025, 0.035, 0.034) + ripple;
	METALLIC = 0.25;
	ROUGHNESS = 0.13;
	ALPHA = 0.72;
}
