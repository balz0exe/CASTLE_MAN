// pixel_glow.gdshader
// Pixel-art-friendly glow shader for Godot 4
// Apply to a CanvasItem material (Sprite2D, TextureRect, etc.)
//
// Usage:
//   1. Select your Sprite2D (or other CanvasItem node)
//   2. In the Inspector → CanvasItem → Material → New ShaderMaterial
//   3. Shader → Load → pick this file
//   4. Tune the uniforms in the Inspector
//
// How it works:
//   - Samples the source texture in a box/diamond pattern (pixelated,
//     aligned to texel boundaries so the blur stays crisp and blocky)
//   - Multiplies sampled colour by glow_color and glow_strength
//   - Additively blends the glow under/over the original sprite

shader_type canvas_item;

// ── Uniforms ──────────────────────────────────────────────────────────────────

/// Colour tint of the glow (alpha channel is ignored – use glow_strength instead)
uniform vec4  glow_color    : source_color = vec4(1.0, 0.5, 0.1, 1.0);

/// How bright the glow is (1.0 = subtle, 3–5 = vivid)
uniform float glow_strength : hint_range(0.0, 14.0, 0.01) = 2.0;

/// Radius in texels – kept LOW on purpose so it stays pixel-art-clean
/// Values > 4 will start to look blurry; use 1–3 for authentic pixel glow
uniform int   glow_radius   : hint_range(1, 8) = 2;

/// Alpha threshold: pixels below this are treated as transparent (no glow)
uniform float alpha_threshold : hint_range(0.0, 1.0, 0.01) = 0.1;

/// When true the glow is added on TOP of the sprite (neon outline look).
/// When false the glow bleeds outward only from transparent areas (halo look).
uniform bool  glow_over_sprite = false;

// ── Helpers ───────────────────────────────────────────────────────────────────

// Round UV to the nearest texel centre so every sample lands on a whole pixel.
// This is the key trick that keeps the glow blocky instead of smooth.
vec2 snap(vec2 uv, vec2 texel_size) {
    return (floor(uv / texel_size) + 0.5) * texel_size;
}

// ── Fragment ──────────────────────────────────────────────────────────────────

void fragment() {
    vec2 ts = TEXTURE_PIXEL_SIZE; // size of one texel in UV space

    // Original pixel, snapped for crisp sampling
    vec4 original = texture(TEXTURE, snap(UV, ts));

    // ── Pixelated box blur (only counting opaque neighbours) ──────────────────
    float glow_acc = 0.0;
    float sample_count = 0.0;

    for (int x = -glow_radius; x <= glow_radius; x++) {
        for (int y = -glow_radius; y <= glow_radius; y++) {
            if (x == 0 && y == 0) continue; // skip self

            // Diamond / L-distance filter keeps the shape pixel-octagonal
            // rather than a round smear.  Remove the if() for a square halo.
            if (abs(x) + abs(y) > glow_radius + 1) continue;

            vec2 offset_uv = snap(UV + vec2(float(x), float(y)) * ts, ts);
            float neighbour_alpha = texture(TEXTURE, offset_uv).a;

            if (neighbour_alpha >= alpha_threshold) {
                glow_acc += neighbour_alpha;
            }
            sample_count += 1.0;
        }
    }

    // Normalise and apply strength (clamp so we don't blow out HDR)
    float glow_value = clamp(glow_acc / max(sample_count, 1.0) * glow_strength, 0.0, 1.0);

    // Build the glow colour
    vec4 glow = vec4(glow_color.rgb * glow_value, glow_value);

    // ── Composite ─────────────────────────────────────────────────────────────
    if (glow_over_sprite) {
        // Additive on top: bright neon outline / inner-glow feel
        COLOR = original + glow * (1.0 - original.a * 0.5);
    } else {
        // Halo: glow only where the sprite itself is transparent
        float sprite_mask = step(alpha_threshold, original.a);
        COLOR = mix(glow, original, sprite_mask);
    }
}
