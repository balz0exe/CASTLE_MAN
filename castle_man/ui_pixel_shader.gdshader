shader_type canvas_item;

uniform float pixel_size = 2.0;   // smaller = finer effect
uniform float mix_strength = 0.5; // how much neighbors affect each other
uniform float noise_strength = 0.3; // how much neighbors affect each other

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 grid = vec2(pixel_size) / vec2(textureSize(SCREEN_TEXTURE, 0));

    // Apply noise to UV before snapping
    float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    vec2 noisy_uv = uv + (noise - noise_strength) * grid * 0.3;

    vec2 base_uv = floor(noisy_uv / grid) * grid;

    vec4 center = texture(SCREEN_TEXTURE, base_uv);
    vec4 right  = texture(SCREEN_TEXTURE, base_uv + vec2(grid.x, 0.0));
    vec4 up     = texture(SCREEN_TEXTURE, base_uv + vec2(0.0, grid.y));
    vec4 diag   = texture(SCREEN_TEXTURE, base_uv + grid);

    vec4 mixed = (center + right + up + diag) * 0.25;
    COLOR = mix(center, mixed, mix_strength / 100.0);
}