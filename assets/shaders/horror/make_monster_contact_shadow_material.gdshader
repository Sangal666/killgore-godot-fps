shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float motion = 0.0;
uniform float distress = 0.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	p.x *= 1.10 + motion * 0.22;
	p.y *= 0.78 - motion * 0.16;
	float irregular = sin(p.x * 8.0 + TIME * 0.7) * sin(p.y * 6.0 - TIME * 0.43) * 0.035;
	float body = 1.0 - smoothstep(0.04, 1.0, dot(p, p) + irregular);
	vec3 tint = mix(vec3(0.008, 0.010, 0.009), vec3(0.018, 0.026, 0.022), distress);
	ALBEDO = tint;
	ALPHA = body * (0.30 + distress * 0.10);
}
