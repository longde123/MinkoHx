#pragma include "common.glsl"

uniform vec4 uTint;

void main() {
    gl_FragColor = uTint * luminance(uTint.rgb);
}
