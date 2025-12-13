shader_type canvas_item;
uniform vec4 blink_color: source_color;
uniform float blink_intensity = 0;

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 color_mix = mix(t.rgb, blink_color.rgb, blink_intensity);

	COLOR = vec4(color_mix, t.a); // Preserve the alpha value from the texture
}

