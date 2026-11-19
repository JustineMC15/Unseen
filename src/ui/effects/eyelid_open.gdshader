shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float open : hint_range(0.0, 1.0) = 0.0;   // 0 = shut, 1 = fully open
uniform float blur : hint_range(0.0, 1.0) = 1.0;   // 1 = very blurry
uniform float softness = 0.25;                      // soft edge of the eyelids

void fragment() {
	float x = abs(UV.x * 2.0 - 1.0);
	float y = abs(UV.y * 2.0 - 1.0);
	// The slit is slightly curved: the corners close first.
	float lid = open * (1.2 + softness) - x * x * 0.2 * (1.0 - open);
	float seen = 1.0 - smoothstep(lid - softness, lid, y);
	vec3 scene = textureLod(screen_tex, SCREEN_UV, blur * 4.5).rgb;
	COLOR = vec4(scene * seen, 1.0);
}