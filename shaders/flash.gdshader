shader_type canvas_item;
// §9.6 受击闪白：flash_amount 1→0 时把像素向 #f4f4f4 混合。
uniform float flash_amount: hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 base = tex * COLOR;
	float f = clamp(flash_amount, 0.0, 1.0);
	vec3 c = mix(base.rgb, vec3(0.957, 0.957, 0.957), f);
	COLOR = vec4(c, base.a);
}
