shader_type canvas_item;

uniform vec4  tint_color : source_color = vec4(1.0, 1.0, 0.6, 1.0);
uniform float emission_strength : hint_range(0.0, 8.0) = 0.4;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR.rgb = tex.rgb * tint_color.rgb * emission_strength; // can be >1.0 for bloom
    COLOR.a   = tex.a;                                        // keep sprite alpha
}
