shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2  u_scroll = vec2(0.0);
uniform float u_scale  = 2.0;          // zoom of noise
uniform float u_coverage = 0.18;       // fraction of screen with clouds
uniform float u_softness = 0.06;       // feather at island edges
uniform float u_intensity = 0.35;      // opacity multiplier
uniform vec3  u_color_a = vec3(0.18, 0.28, 0.55);
uniform vec3  u_color_b = vec3(0.70, 0.25, 0.55);
uniform bool  u_debug = false;         // set true to see raw noise

// Precomputed noise texture
uniform sampler2D noise_tex : source_color;

void fragment() {
    vec2 uv = UV * u_scale + u_scroll;
    uv = fract(uv);

    float n = texture(noise_tex, uv).r;

    float thresh = 1.0 - clamp(u_coverage, 0.01, 0.99);
    float m = smoothstep(thresh - u_softness,
                         thresh + u_softness,
                         n);

    vec3 col = mix(u_color_a, u_color_b, n);

    if (u_debug) {
        COLOR = vec4(vec3(n), 1.0);
    } else {
        COLOR = vec4(col * m, m * u_intensity);
    }
}
