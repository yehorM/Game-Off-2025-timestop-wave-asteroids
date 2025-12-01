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

float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p){
    vec2 i = floor(p), f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}
float fbm(vec2 p){
    float v = 0.0, a = 0.5;
    for (int i=0;i<4;i++){ v += a*noise(p); p *= 2.0; a *= 0.5; }
    return v;
}

void fragment(){
    // scroll is already in UV space
    vec2 uv = (UV + u_scroll) * u_scale;

    float n = fbm(uv);                               // 0..1
    // Turn noise into sparse "islands"
    float thresh = 1.0 - clamp(u_coverage, 0.01, 0.99);
    float m = smoothstep(thresh - u_softness,        // feathered mask
                         thresh + u_softness, n);

    vec3 col = mix(u_color_a, u_color_b, n);

    if (u_debug) {
        COLOR = vec4(vec3(n), 1.0);                 // grayscale preview
    } else {
        COLOR = vec4(col * m, m * u_intensity);     // translucent fog
    }
}
