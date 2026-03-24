#include <flutter/runtime_effect.glsl>

// ─── Uniforms ────────────────────────────────────────────────────────────────
uniform float u_time;       // elapsed seconds
uniform vec2  u_resolution; // canvas size in logical pixels
uniform vec2  u_mouse;      // pointer position in logical pixels
uniform float u_intensity;  // 0.0 = idle, 1.0 = full hover distortion

uniform sampler2D u_texture; // child widget snapshot

out vec4 fragColor;

// ─── Simplex-style hash (no texture LUT, GPU-friendly) ──────────────────────
vec2 hash22(vec2 p) {
    vec3 a = fract(p.xyx * vec3(443.897, 441.423, 437.195));
    a += dot(a, a.yzx + 19.19);
    return fract((a.xx + a.yz) * a.zy) * 2.0 - 1.0;
}

// ─── Gradient noise (2D) ────────────────────────────────────────────────────
float gradientNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f); // Hermite smoothstep

    float a = dot(hash22(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0));
    float b = dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// ─── Layered noise (2 octaves — cheap but organic) ──────────────────────────
float liquidNoise(vec2 p, float t) {
    float n  = gradientNoise(p * 3.0 + t * 0.4) * 0.5;
          n += gradientNoise(p * 6.0 - t * 0.6) * 0.25;
    return n;
}

// ─── Ripple from mouse position ─────────────────────────────────────────────
vec2 ripple(vec2 uv, vec2 mouse, float t) {
    vec2 delta = uv - mouse;
    float dist = length(delta);

    // Concentric wave that decays with distance
    float wave = sin(dist * 25.0 - t * 4.0) * exp(-dist * 4.0);

    // Push pixels along the radial direction
    vec2 dir = dist > 0.001 ? normalize(delta) : vec2(0.0);
    return dir * wave * 0.015;
}

// ─── Main ───────────────────────────────────────────────────────────────────
void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / u_resolution;

    // Normalised mouse (0-1 range)
    vec2 mouse = u_mouse / u_resolution;

    // ── Ambient liquid displacement (always-on, subtle) ──
    vec2 noiseOffset = vec2(
        liquidNoise(uv, u_time),
        liquidNoise(uv + vec2(5.2, 1.3), u_time + 10.0)
    );
    vec2 ambientDisplace = noiseOffset * 0.006;

    // ── Mouse-driven ripple (scales with intensity) ──
    vec2 rippleDisplace = ripple(uv, mouse, u_time) * u_intensity;

    // ── Extra noise boost on hover ──
    vec2 hoverDisplace = noiseOffset * 0.012 * u_intensity;

    // Combine
    vec2 displaced = uv + ambientDisplace + rippleDisplace + hoverDisplace;

    // Clamp to avoid sampling outside bounds
    displaced = clamp(displaced, 0.0, 1.0);

    fragColor = texture(u_texture, displaced);
}
