shader_type spatial;
render_mode blend_add, unshaded, cull_front, depth_draw_never, shadows_disabled;
uniform float pain = 0.0;
uniform float flash = 0.0;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.2);
	float fracture = 0.55 + 0.45 * sin((VERTEX.x * 13.0 + VERTEX.y * 17.0 + VERTEX.z * 11.0) + TIME * 15.0);
	vec3 distress = mix(vec3(0.035, 0.045, 0.041), vec3(0.32, 0.38, 0.34), clamp(pain + flash * 0.25, 0.0, 1.0));
	ALBEDO = distress * 0.035;
	EMISSION = distress * (rim * (0.34 + flash * 0.22) + fracture * flash * 0.055);
	ALPHA = rim * pain * 0.16 + flash * fracture * 0.032;
}
