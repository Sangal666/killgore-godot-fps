shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 mist_color : source_color;
void vertex() { MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]); }
void fragment() {
	vec2 p = UV - vec2(0.5);
	float radius = length(p);
	float soft = exp(-radius * radius * 7.4);
	float drift = 0.72 + 0.18 * sin(UV.x * 13.0 + TIME * 0.10) + 0.10 * sin(UV.y * 21.0 - TIME * 0.07);
	float alpha = mist_color.a * soft * soft * drift * 0.46;
	ALBEDO = mix(vec3(0.020), mist_color.rgb, 0.52);
	EMISSION = mist_color.rgb * 0.12;
	ALPHA = alpha;
}
