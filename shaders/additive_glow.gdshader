shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float emission_strength : hint_range(0.0, 10.0) = 3.5;

// 3-stop warm ramp
uniform vec4 c_hot   : source_color = vec4(1.0, 0.95, 0.30, 1.0); // yellow
uniform vec4 c_warm  : source_color = vec4(1.0, 0.55, 0.10, 1.0); // orange
uniform vec4 c_red   : source_color = vec4(1.0, 0.15, 0.00, 1.0); // red

// spatial ramp along the flame (0 at base, 1 at tip)
uniform bool  base_on_right = true;
uniform float mid : hint_range(0.0,1.0) = 0.55;   // where orange peaks
uniform float falloff : hint_range(0.0,2.0) = 0.7;

// time animation (yellow->orange->red bias)
uniform float period = 0.6;           // seconds for one cycle
uniform float anim_amount : hint_range(0.0,1.0) = 0.8; // how strongly it pushes toward red
uniform float heat : hint_range(0.0,1.0) = 0.0;  // script-driven bias toward red
uniform float t0 = 0.0;               // per-instance start time (set for bullets)

void fragment() {
    vec4 tex = texture(TEXTURE, UV) * COLOR;
    float mask = tex.a;
    if (mask <= 0.0) { discard; }

    // spatial ramp along UV.x
    float u = base_on_right ? (1.0 - UV.x) : UV.x;

    vec3 ramp;
    if (u < mid) {
        float t = smoothstep(0.0, mid, u);
        ramp = mix(c_hot.rgb, c_warm.rgb, t);  // yellow -> orange
    } else {
        float t = smoothstep(mid, 1.0, u);
        ramp = mix(c_warm.rgb, c_red.rgb, t);  // orange -> red
    }

    // time-driven bias toward red (warm flicker)
    float w = 0.5 + 0.5 * sin( (TIME - t0) * (6.2831853 / max(period, 0.0001)) );
    float toward_red = clamp(heat + anim_amount * w, 0.0, 1.0);
    vec3 col = mix(ramp, c_red.rgb, toward_red);

    // brightness falloff toward tip
    float fade = pow(1.0 - u, falloff);

    vec3 emission = col * emission_strength * mask * fade;
    COLOR = vec4(emission, mask);
}
