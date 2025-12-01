shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float amp   : hint_range(0.0, 0.05) = 0.01;
uniform float freq  : hint_range(0.0, 30.0) = 12.0;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform float emission_strength : hint_range(0.0, 8.0) = 0.8;

void fragment() {
    vec2 uv = UV;
    uv += vec2(
        sin((uv.y + TIME * speed) * freq),
        sin((uv.x - TIME * speed) * freq)
    ) * amp;

    vec4 tex = texture(TEXTURE, uv);

    // Vertex color = node/sprite modulate (includes parent modulate)
    vec4 vtx = COLOR;
	
    // Fade must affect RGB when using additive blending
    float fade = vtx.a;
    vec3 rgb = tex.rgb * emission_strength * fade;
    COLOR = vec4(rgb, tex.a * fade);
}
