shader_type canvas_item;

uniform float strength = 0.003;
uniform float blur = 0.002;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Wavy distortion
	uv.x += sin(uv.y * 20.0 + TIME * 2.0) * strength;
	uv.y += cos(uv.x * 15.0 + TIME * 1.5) * strength;
	
	// Simple blur
	vec4 col = texture(SCREEN_TEXTURE, uv) * 0.4;
	col += texture(SCREEN_TEXTURE, uv + vec2(blur, 0.0)) * 0.15;
	col += texture(SCREEN_TEXTURE, uv - vec2(blur, 0.0)) * 0.15;
	col += texture(SCREEN_TEXTURE, uv + vec2(0.0, blur)) * 0.15;
	col += texture(SCREEN_TEXTURE, uv - vec2(0.0, blur)) * 0.15;

	COLOR = col;
	
	float noise = fract(sin(dot(uv * TIME, vec2(12.9898,78.233))) * 43758.5453);
	COLOR.rgb += noise * 0.05;
}
