shader_type canvas_item;

uniform float outline_width = 2.0;
uniform vec4  outline_color = vec4(1.0, 0.9, 0.3, 1.0);
uniform float emission_strength : hint_range(0.0, 8.0) = 0.6;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (tex.a < 0.1) {
        float outline = 0.0;
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                vec2 offset = vec2(float(x), float(y)) * outline_width * TEXTURE_PIXEL_SIZE;
                outline = max(outline, texture(TEXTURE, UV + offset).a);
            }
        }
        COLOR = vec4(outline_color.rgb, outline * outline_color.a * emission_strength);
    } else {
        discard;
    }
}
