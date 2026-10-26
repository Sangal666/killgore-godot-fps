shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 pool_color : source_color;
uniform float brightness = 1.0;
void fragment() {
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	vec2 ellipse = centered * vec2(0.68, 1.0);
	float radial = dot(ellipse, ellipse);
	float core = 1.0 - smoothstep(0.0, 0.36, radial);
	float spill = 1.0 - smoothstep(0.10, 1.0, radial);
	float intensity = clamp(spill * 0.72 + core * 0.28, 0.0, 1.0);
	ALBEDO = pool_color.rgb * (0.35 + intensity * 0.25);
	EMISSION = pool_color.rgb * intensity * brightness;
	ALPHA = pool_color.a * intensity;
}
