shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 shaft_color : source_color;
void fragment() {
	float length_fade = smoothstep(0.01, 0.13, UV.y) * (1.0 - smoothstep(0.76, 1.0, UV.y));
	float mist_bands = 0.72 + sin((UV.y * 5.0 + UV.x * 0.8) * 6.28318 + TIME * 0.20) * 0.14;
	mist_bands += sin(UV.y * 71.0 - TIME * 0.13) * 0.07;
	ALBEDO = shaft_color.rgb;
	float opacity = shaft_color.a * length_fade * mist_bands;
	EMISSION = shaft_color.rgb * 1.10;
	ALPHA = opacity;
}
