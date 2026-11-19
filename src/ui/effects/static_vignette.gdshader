shader_type canvas_item;

// Full-screen TV static. `intensity` (0-1) drives everything:
//   low  = grain creeping in at the corners
//   mid  = heavy edges, colour split, scanlines, glitch bands
//   ~1.0 = the whole screen is static
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float grain_size = 2.0;         // static pixel size, in screen pixels
uniform float static_fps = 24.0;
uniform float contrast = 1.8;
uniform float aberration = 0.025;       // colour split at full intensity
uniform float scanline_strength = 0.25;
uniform float glitch_amount = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	float t = mod(floor(TIME * static_fps), 1000.0);

	// Vignette: starts at the corners and creeps inward as intensity rises.
	vec2 c = (UV - 0.5) * 2.0;
	float r = length(c);
	float inner = mix(1.05, 0.0, intensity);
	float vig = smoothstep(inner, inner + 0.6, r);
	float cover = smoothstep(0.85, 1.0, intensity);   // total cover near 1.0
	float mask = clamp(vig + cover, 0.0, 1.0) * smoothstep(0.0, 0.08, intensity);

	// Cable-rub bursts: random frames where the static flares up.
	float burst = step(0.96 - 0.25 * intensity, hash(vec2(t, 91.0)));
	float amount = clamp(mask * mix(0.15, 1.0, intensity) + burst * 0.35 * mask, 0.0, 1.0);

	// Horizontal glitch bands that shove the picture sideways (only inside the mask).
	vec2 suv = SCREEN_UV;
	float band = floor(UV.y * 30.0);
	float g = step(1.0 - 0.15 * intensity * glitch_amount, hash(vec2(band, t)));
	suv.x += (hash(vec2(band, t + 3.0)) - 0.5) * 0.08 * g * mask;

	// Colour split, stronger toward the edges.
	vec2 dir = UV - 0.5;
	float ab = aberration * intensity * mask;
	vec3 scene = vec3(
		texture(screen_tex, suv + dir * ab).r,
		texture(screen_tex, suv).g,
		texture(screen_tex, suv - dir * ab).b
	);

	// Scanlines, flicker, edge darkening.
	scene *= 1.0 - scanline_strength * mask * (0.5 + 0.5 * sin(FRAGCOORD.y * 2.0));
	scene *= 1.0 + (hash(vec2(t, 5.0)) - 0.5) * 0.12 * intensity;
	scene *= 1.0 - mask * 0.4 * intensity;

	// The static itself.
	vec2 cell = floor(FRAGCOORD.xy / grain_size);
	float n = hash(cell + vec2(t * 37.0, t * 17.0));
	n = clamp((n - 0.5) * contrast + 0.5, 0.0, 1.0);
	float row = hash(vec2(floor(FRAGCOORD.y / grain_size), t));
	n = mix(n, row, 0.15 * intensity);

	COLOR = vec4(mix(scene, vec3(n), amount), 1.0);
}