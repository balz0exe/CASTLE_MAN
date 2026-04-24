shader_type canvas_item;

uniform float speed : hint_range(0.1, 3.0) = 1.0;
uniform float cell_size : hint_range(1.0, 16.0) = 4.0;   // pixel block size
uniform float ghost_fade_start : hint_range(0.0, 20.0) = 0.45; // where ghost begins fading
uniform float break_start : hint_range(0.0, 1.0) = 0.45;      // where pixels break off
uniform float drift_scale : hint_range(0.0, 2.0) = 1.0;

// --- Noise ---
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

float hash1(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash1(i), hash1(i + vec2(1,0)), u.x),
        mix(hash1(i + vec2(0,1)), hash1(i + vec2(1,1)), u.x),
        u.y
    );
}

float fbm(vec2 p) {
    return noise(p)       * 0.500
         + noise(p * 2.1 + vec2(3.7, 1.3)) * 0.250
         + noise(p * 4.2 + vec2(1.1, 5.7)) * 0.125;
}

void fragment() {
    vec2 uv = UV;
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    float t = TIME * speed;

    // rise: 0 at bottom of label, 1 at top
    float rise = 1.0 - uv.y;

    float break_zone = clamp((rise - break_start) / (1.0 - break_start), 0.0, 1.0);
    float ghost_zone = clamp(rise / ghost_fade_start, 0.0, 1.0);

    vec2 sample_uv = uv;

    if (break_zone > 0.0) {
        // Snap UV to pixel cell grid
        vec2 cell_uv = floor(uv * tex_size / cell_size) * cell_size / tex_size;
        vec2 cell_id = floor(uv * tex_size / cell_size);

        // Per-cell unique seed and phase
        float phase    = hash1(cell_id * 0.17) * 6.2832;
        float drift_spd = 0.4 + hash1(cell_id * 0.13 + 1.1) * 0.8;

        // Independent drift per cell via fbm
        float wind_x = (fbm(cell_id * 0.17 + vec2(t * drift_spd * 0.4, phase)) - 0.5) * 2.0;
        float wind_y = (fbm(cell_id * 0.13 + vec2(5.0, t * drift_spd * 0.5 + phase)) - 0.5);

        // Upward + lateral displacement, grows with break_zone
        float disp = break_zone * break_zone * drift_scale * 0.12;
        sample_uv = cell_uv + vec2(
            wind_x * disp,
            wind_y * disp * 0.5 - break_zone * 0.08
        );
    }

    vec4 tex = texture(TEXTURE, sample_uv);

    // --- Alpha ---
    float fade;
    if (break_zone > 0.0) {
        // Each cell fades out at its own rate using its hash
        vec2 cell_id = floor(uv * tex_size / cell_size);
        float cell_life = hash1(cell_id * vec2(0.17, 0.13) + t * 0.08);
        fade = pow(1.0 - break_zone, 1.4) * (0.5 + cell_life * 0.5);
    } else {
        fade = 1.0 - ghost_zone * 0.35;
    }

    // Color: bright white at base → dim gray as it breaks apart
    float gray = break_zone > 0.0
        ? 0.5 + (1.0 - break_zone) * 0.35
        : 0.85 - ghost_zone * 0.08;

    COLOR = vec4(vec3(gray), tex.a * fade);
}