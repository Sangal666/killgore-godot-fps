shader_type spatial;
render_mode unshaded;
uniform float phase = 0.0;
void fragment() {
	float scan = smoothstep(0.25, 0.95, sin((UV.y + TIME * 0.08) * 92.0) * 0.5 + 0.5);
	float glitch = step(0.94, fract(sin(floor(TIME * 9.0 + phase) * 71.73) * 4831.21));
	float pulse = 1.25 + sin(TIME * 2.4 + phase) * 0.45 + scan * 0.18 + glitch * 0.55;
	vec3 color = vec3(0.48, 0.72, 0.60);
	ALBEDO = color * (0.82 + scan * 0.18);
	EMISSION = color * pulse;
}
