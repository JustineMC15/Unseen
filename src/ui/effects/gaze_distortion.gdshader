shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float warp = 0.004;            // wobble, in UV units
uniform float tear_chance = 0.12;      // chance per band, per frame
uniform float tear_shift = 0.03;       // how far a torn band is shoved sideways
uniform float split = 0.02;            // colour split toward the edges
uniform float grain_strength = 0.18;
uniform float grain_size = 2.0;
uniform float static_fps = 20.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = mod(floor(TIME * static_fps), 1000.0);

	// Wobble, like the picture is being pulled.
	vec2 uv = SCREEN_UV;
	uv.x += sin(UV.y * 38.0 + TIME * 14.0) * warp;
	uv.y += sin(UV.x * 21.0 - TIME * 9.0) * warp * 0.6;

	// Random horizontal bands shoved sideways.
	float band = floor(UV.y * 24.0);
	float torn = step(1.0 - tear_chance, hash(vec2(band, t)));
	uv.x += (hash(vec2(band, t + 7.0)) - 0.5) * tear_shift * torn;

	// Colour split.
	vec2 dir = (UV - 0.5) * split;
	vec3 scene = vec3(
		texture(screen_tex, uv + dir).r,
		texture(screen_tex, uv).g,
		texture(screen_tex, uv - dir).b
	);

	// Light grain over everything. Added, not blended, so the scene stays readable.
	vec2 cell = floor(FRAGCOORD.xy / grain_size);
	float n = hash(cell + vec2(t * 37.0, t * 17.0));
	scene += (n - 0.5) * grain_strength;

	vec3 base = texture(screen_tex, SCREEN_UV).rgb;
	COLOR = vec4(mix(base, clamp(scene, 0.0, 1.0), amount), 1.0);
}