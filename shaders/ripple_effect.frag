#include <flutter/runtime_effect.glsl>

// ─── Uniforms ──────────────────────────────────────────────────────────────────
uniform float u_time;         // seconds since first ripple
uniform vec2  u_resolution;   // widget size in logical pixels
uniform float u_amplitude;    // max UV displacement (e.g. 0.03)
uniform float u_frequency;    // wave oscillation frequency (e.g. 12.0)
uniform float u_decay;        // exponential decay rate (e.g. 3.0)

// Per-ripple origin (normalised 0..1) and start time.
// Inactive slots use start_time < 0.
uniform vec2  u_origin0;
uniform float u_start0;
uniform vec2  u_origin1;
uniform float u_start1;
uniform vec2  u_origin2;
uniform float u_start2;

// Sampler for the child widget snapshot.
uniform sampler2D u_texture;

// Color tint applied to the ripple highlights (RGBA, premultiplied alpha).
uniform vec4 u_tint;

out vec4 fragColor;

// ─── Ripple displacement for a single origin ────────────────────────────────
vec2 rippleDisplacement(vec2 uv, vec2 origin, float startTime, float aspect) {
    if (startTime < 0.0) return vec2(0.0);

    float age = u_time - startTime;
    if (age < 0.0) return vec2(0.0);

    // Distance from the ripple origin, corrected for aspect ratio.
    vec2 delta = uv - origin;
    delta.x *= aspect;
    float dist = length(delta);

    // Ripple propagation speed (normalised units per second).
    float speed = 0.6;
    float wavefront = age * speed;

    // Only affect pixels the wavefront has reached, with a soft leading edge.
    float reach = smoothstep(wavefront - 0.05, wavefront, dist);
    float behind = 1.0 - reach;

    // Sine-based concentric wave.
    float wave = sin((dist - wavefront) * u_frequency * 6.2831853)
               * u_amplitude
               * behind;

    // Exponential fade-out over time.
    wave *= exp(-u_decay * age);

    // Fade near the origin so the epicentre stays clean.
    wave *= smoothstep(0.0, 0.04, dist);

    // Direction of displacement (radial outward).
    vec2 dir = dist > 0.001 ? normalize(delta) : vec2(0.0);

    return dir * wave;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / u_resolution;
    float aspect = u_resolution.x / u_resolution.y;

    // Accumulate displacement from up to 3 simultaneous ripples.
    vec2 displacement = vec2(0.0);
    displacement += rippleDisplacement(uv, u_origin0, u_start0, aspect);
    displacement += rippleDisplacement(uv, u_origin1, u_start1, aspect);
    displacement += rippleDisplacement(uv, u_origin2, u_start2, aspect);

    // Clamp total displacement to avoid extreme warping.
    displacement = clamp(displacement, vec2(-0.08), vec2(0.08));

    // Sample the child texture at the displaced coordinate.
    vec2 sampleUV = clamp(uv + displacement, 0.0, 1.0);
    vec4 color = texture(u_texture, sampleUV);

    // Apply a subtle colour tint proportional to displacement magnitude.
    float intensity = length(displacement) / u_amplitude;
    color.rgb += u_tint.rgb * u_tint.a * intensity * 0.35;

    fragColor = color;
}
