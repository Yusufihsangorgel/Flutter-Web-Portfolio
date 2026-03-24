// Film grain fragment shader — procedural, cinema-quality noise overlay.
//
// Uniforms:
//   u_time       – elapsed seconds (drives temporal variation)
//   u_resolution – viewport width & height in logical pixels
//   u_intensity  – grain opacity multiplier (0.0 = invisible, 1.0 = full)
//   u_grain_size – controls grain coarseness (1.0 = fine, 4.0+ = coarse)

#include <flutter/runtime_effect.glsl>

uniform float u_time;
uniform vec2  u_resolution;
uniform float u_intensity;
uniform float u_grain_size;

out vec4 fragColor;

// ---------------------------------------------------------------------------
// Hash-based pseudo-random functions (no sin-based artifacts on GPU)
// ---------------------------------------------------------------------------

// Single-output hash from a 2D coordinate.
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Two-output hash from a 2D coordinate (for multi-layer grain).
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// ---------------------------------------------------------------------------
// Value noise — smooth random field for organic-looking grain
// ---------------------------------------------------------------------------

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Hermite interpolation for smooth blending between cells.
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// ---------------------------------------------------------------------------
// Multi-octave fractal noise (fBm) — layered detail
// ---------------------------------------------------------------------------

float fbm(vec2 p, int octaves) {
    float value     = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < octaves; i++) {
        value     += amplitude * valueNoise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Quantise coordinates by grain size to create coarser grains.
    // grain_size 1.0 = pixel-level, 2.0+ = blocky / coarse.
    float gs = max(u_grain_size, 1.0);
    vec2 uv = floor(fragCoord / gs) * gs;

    // Temporal seed — changes every ~3 frames at 60 fps for subtle flicker
    // without strobing. The floor() snaps time to discrete steps.
    float timeSeed = floor(u_time * 20.0);

    // --- Layer 1: fine high-frequency hash grain -------------------------
    float fineGrain = hash12(uv + timeSeed * 17.31);

    // --- Layer 2: organic mid-frequency value noise ----------------------
    // Offset by a different time multiplier so layers don't correlate.
    vec2 noiseCoord = uv * 0.03 + timeSeed * 3.73;
    float organicGrain = valueNoise(noiseCoord);

    // --- Layer 3: low-frequency fbm for large-scale density variation ----
    vec2 fbmCoord = uv * 0.005 + timeSeed * 0.41;
    float densityMask = fbm(fbmCoord, 3);

    // Blend layers:
    //   - Fine grain provides the primary texture.
    //   - Organic noise modulates it for clumping (film emulsion look).
    //   - Density mask creates natural brightness variation across frame.
    float grain = fineGrain;
    grain = mix(grain, organicGrain, 0.35);
    grain *= 0.7 + 0.3 * densityMask;

    // Centre around 0.5 and apply contrast curve to approximate real film
    // grain's characteristic distribution (more mid-tones, fewer extremes).
    grain = grain - 0.5;
    grain = sign(grain) * pow(abs(grain), 0.8);
    grain = grain * 0.5 + 0.5;

    // Edge darkening — subtle vignette so grain is softer at screen edges.
    vec2 center = fragCoord / u_resolution - 0.5;
    float vignette = 1.0 - dot(center, center) * 0.5;

    // Final alpha is modulated by intensity, vignette, and the grain value.
    // Output is monochrome (white grain on transparent) so it composites
    // naturally over any background colour.
    float alpha = grain * u_intensity * vignette;

    // Clamp to sane range.
    alpha = clamp(alpha, 0.0, 1.0);

    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
