shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float strength = 0.0;
uniform float phase = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = UV - vec2(0.5);
	p.x *= 2.7;
	float taper = mix(1.0, 0.34, UV.y);
	float drift = sin(UV.y * 8.0 + TIME * 2.4 + phase) * 0.16 + sin(UV.y * 15.0 - TIME * 1.3 + phase * 0.7) * 0.07;
	float strand = 1.0 - smoothstep(taper * 0.18, taper * 0.58, abs(p.x + drift));
	float fade = smoothstep(0.0, 0.20, UV.y) * (1.0 - smoothstep(0.56, 1.0, UV.y));
	float torn = 0.84 + 0.16 * sin(UV.y * 10.0 - TIME * 2.1 + phase);
	vec3 ash = mix(vec3(0.32, 0.35, 0.33), vec3(0.60, 0.64, 0.59), UV.y);
	ALBEDO = ash * 0.58;
	EMISSION = ash * 0.075;
	ALPHA = strand * fade * torn * strength * 0.24;
}
