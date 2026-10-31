shader_type canvas_item;

uniform sampler2D trail_tex : filter_linear;
uniform float fade : hint_range(0.0, 1.0) = 0.93;
uniform vec4 clear_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 prev = texture(trail_tex, UV);
	COLOR = mix(clear_color, prev, fade);
}
