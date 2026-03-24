// Chromatic Aberration Fragment Shader
// Separates RGB channels with directional UV offsets to create
// a cinematic color-fringing effect driven by mouse/scroll input.

#include <flutter/runtime_effect.glsl>

// Time in seconds — can drive subtle animation on the offset.
uniform float u_time;

// Output resolution in pixels (width, height).
uniform vec2 u_resolution;

// Aberration strength (0.0 = none, ~3.0–8.0 = visible fringing).
uniform float u_offset;

// Normalised direction vector for the offset (e.g. mouse delta or scroll axis).
uniform vec2 u_direction;

// The child-widget texture captured via scene snapshot.
uniform sampler2D u_texture;

out vec4 fragColor;

void main() {
    // FlutterFragCoord gives pixel position in the output surface.
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / u_resolution;

    // Normalise direction so magnitude is controlled solely by u_offset.
    vec2 dir = length(u_direction) > 0.001 ? normalize(u_direction) : vec2(1.0, 0.0);

    // Per-pixel offset in UV space.
    vec2 offsetUV = (dir * u_offset) / u_resolution;

    // Sample each channel at a different UV position.
    float r = texture(u_texture, uv + offsetUV).r;
    float g = texture(u_texture, uv).g;
    float b = texture(u_texture, uv - offsetUV).b;

    // Preserve the original alpha from the centre sample so
    // transparent regions stay transparent.
    float a = texture(u_texture, uv).a;

    fragColor = vec4(r, g, b, a);
}
