// pixel_glow.gdshader
// Pixel-art-friendly glow shader for Godot 4
// Apply to a CanvasItem material (Sprite2D, TextureRect, etc.)

shader_type canvas_item;

/// Colour of the glow
uniform vec4  glow_color      : source_color = vec4(1.0, 0.5, 0.1, 1.0);

/// How bright/far the glow spreads (1.0 = subtle, 5+ = vivid)
uniform float glow_strength   : hint_range(0.0, 14.0, 0.01) = 2.0;

/// Radius in texels — keep 1–3 for clean pixel art
uniform int   glow_radius     : hint_range(1, 8) = 2;

/// Pixels below this alpha are treated as transparent
uniform float alpha_threshold : hint_range(0.0, 1.0, 0.0001) = 0.1;

/// When true: glow replaces the sprite entirely (pure glow_color, no original RGB)
/// When false: glow only bleeds outward into transparent areas (halo)
uniform bool  glow_over_sprite = false;

vec2 snap(vec2 uv, vec2 texel_size) {
    return (floor(uv / texel_size) + 0.5) * texel_size;
}

void fragment() {
    vec2 ts       = TEXTURE_PIXEL_SIZE;
    vec4 original = texture(TEXTURE, snap(UV, ts));

    // ── Sample neighbours for glow accumulation ───────────────────────────────
    float glow_acc     = 0.0;
    float sample_count = 0.0;

    for (int x = -glow_radius; x <= glow_radius; x++) {
        for (int y = -glow_radius; y <= glow_radius; y++) {
            if (x == 0 && y == 0) continue;
            if (abs(x) + abs(y) > glow_radius + 1) continue;

            vec2  offset_uv      = snap(UV + vec2(float(x), float(y)) * ts, ts);
            float neighbour_alpha = texture(TEXTURE, offset_uv).a;

            if (neighbour_alpha >= alpha_threshold) {
                glow_acc += neighbour_alpha;
            }
            sample_count += 1.0;
        }
    }

    float glow_value = clamp(glow_acc / max(sample_count, 1.0) * glow_strength, 0.0, 1.0);

    bool  is_opaque  = original.a >= alpha_threshold;

    if (glow_over_sprite) {
        if (is_opaque) {
            // Sprite pixels: replace RGB entirely with glow_color, no white bleeding
            // glow_value drives how vivid — fallback to full glow_color at alpha edges
            float intensity = clamp(glow_value + original.a, 0.0, 1.0);
            COLOR = vec4(glow_color.rgb * intensity, original.a);
        } else {
            // Transparent pixels: halo bleeds outward in pure glow_color
            COLOR = vec4(glow_color.rgb, glow_value);
        }
    } else {
        if (is_opaque) {
            // Halo mode: keep original sprite untouched
            COLOR = original;
        } else {
            // Transparent pixels get the halo, pure glow_color only
            COLOR = vec4(glow_color.rgb, glow_value);
        }
    }
}