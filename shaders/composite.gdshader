shader_type canvas_item;

uniform sampler2D trail_tex : filter_linear;
uniform float invert_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 c = texture(trail_tex, UV);
	// Composite over background, then optional invert.
	vec3 rgb = mix(bg_color.rgb, c.rgb, c.a);
	vec3 inverted = vec3(1.0) - rgb;
	COLOR = vec4(mix(rgb, inverted, invert_amount), 1.0);
}
