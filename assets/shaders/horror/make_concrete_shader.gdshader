shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;
uniform vec3 base_color = vec3(0.1);
uniform float grime = 0.3;
uniform float roughness_value = 0.9;
uniform float metallic_value = 0.0;
uniform int surface_kind = 0;
uniform float ambient_lift = 0.0;
uniform bool flashlight_enabled = false;
uniform vec3 flashlight_origin = vec3(0.0);
uniform vec3 flashlight_direction = vec3(0.0, 0.0, -1.0);
uniform int fixture_count = 0;
uniform vec3 fixture_positions[32];
uniform vec3 fixture_colors[32];
uniform float fixture_strengths[32];
varying vec3 world_position;
float hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x), mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
float filtered_noise(vec2 p) {
	float footprint = max(length(dFdx(p)), length(dFdy(p)));
	if (footprint >= 1.5) { return 0.5; }
	return mix(noise(p), 0.5, smoothstep(0.5, 1.5, footprint));
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = floor(world_position.xz * 2.1);
	float n = hash(p) * 0.55 + hash(floor(p * 0.23)) * 0.45;
	float stain = smoothstep(0.52, 0.98, n) * grime;
	vec3 surface_color = base_color * (0.78 + n * 0.25 - stain * 0.30);
	if (surface_kind == 1) {
		vec2 wall_uv = vec2(world_position.x + world_position.z, world_position.y);
		float damp = noise(wall_uv * vec2(1.1, 0.6));
		float plaster = filtered_noise(wall_uv * 72.0);
		float streak = noise(wall_uv * vec2(7.0, 0.7)) * noise(wall_uv * 1.8);
		float band = 1.0 - smoothstep(1.19, 1.21, world_position.y);
		surface_color = mix(base_color * vec3(1.08, 1.02, 0.88), vec3(0.13, 0.15, 0.135), band);
		surface_color *= 0.69 + damp * 0.35 + plaster * 0.13;
			surface_color *= 1.0 - smoothstep(0.35, 0.85, streak) * grime * 0.6;
		surface_color *= mix(0.56, 1.0, smoothstep(0.0, 0.32, world_position.y));
	} else if (surface_kind == 2) {
		vec2 tile_uv = world_position.xz / 0.65;
		// Integrate thin grout over a pixel footprint, instead of sampling a
		// subpixel hard line (which became dotted/shimmering diagonal bands).
		vec2 footprint = max(fwidth(tile_uv), vec2(0.0001));
		vec2 hi = tile_uv + vec2(0.014) + footprint * 0.5;
		vec2 lo = tile_uv + vec2(0.014) - footprint * 0.5;
		vec2 integral_hi = floor(hi) * 0.028 + min(fract(hi), vec2(0.028));
		vec2 integral_lo = floor(lo) * 0.028 + min(fract(lo), vec2(0.028));
		vec2 lines = clamp((integral_hi - integral_lo) / footprint, vec2(0.0), vec2(1.0));
		float grout = 1.0 - max(lines.x, lines.y);
		float tile = hash(floor(tile_uv));
		float wear = filtered_noise(world_position.xz * 8.0) * 0.14 + filtered_noise(world_position.xz * 95.0) * 0.07;
		surface_color = base_color * (0.57 + tile * 0.35 + wear);
		surface_color *= mix(0.40, 1.0, grout);
	}
	ALBEDO = surface_color;
	ROUGHNESS = clamp(roughness_value + stain * 0.08, 0.0, 1.0);
	METALLIC = metallic_value;
	SPECULAR = 0.18;
	EMISSION = vec3(0.0);
}
