shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 shaft_color : source_color;
void fragment() {
	float vertical_fade = smoothstep(0.0, 0.07, UV.y) * (1.0 - smoothstep(0.90, 1.0, UV.y));
	float view_edge = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 0.72);
	float volume = mix(0.28, 1.0, view_edge);
	float air = 0.94 + 0.06 * sin(UV.y * 23.0 + TIME * 0.10);
	ALBEDO = shaft_color.rgb * 0.025;
	EMISSION = shaft_color.rgb * (0.18 + volume * 0.46);
	ALPHA = shaft_color.a * vertical_fade * volume * air;
}
