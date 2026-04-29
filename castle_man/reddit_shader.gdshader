shader_type canvas_item;
render_mode unshaded;

uniform int NumDivisions = 32;

void fragment() {
    // Quantize UV to stepped value based on number of divisions.
    // The 0.5 added ensures we sample from the centre of the "pixel"
    vec2 st = (vec2(ivec2(UV * float(NumDivisions))) + 0.5) / float(NumDivisions);

    // Sample the texture at the quantized UV using highest LOD (0.0)
    // to avoid filtering artifacts on discontinuities
    COLOR = textureLod(TEXTURE, st, 0.0);
}