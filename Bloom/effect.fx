uniform mediump float intensity;
uniform mediump float brightness;
uniform mediump float falloff;
uniform mediump float threshold;
uniform mediump float samples;

varying mediump vec2 vTex;
uniform lowp sampler2D samplerFront;

const highp mat2 ANGLE_MAT = mat2(-0.7373688, -0.6754904, 0.6754904, -0.7373688);

mediump float luminance(mediump vec3 rgb) {
    const mediump vec3 WEIGHTS = vec3(0.2126, 0.7152, 0.0722);
    return dot(rgb, WEIGHTS);
}

void main(void) {
    mediump vec4 blur = vec4(0.0);
    mediump float totalWeight = 0.0;

    mediump float radius = intensity * 10.0;
    mediump float scale = radius * inversesqrt(samples);

    highp vec2 point = vec2(scale, 0.0);
    ivec2 textureSize2d = textureSize(samplerFront, 0);
    mediump vec2 texelSize = 1.0 / vec2(textureSize2d);
    mediump float rad = 1.0;

    for (int i = 0; i < int(samples); i++) {
        point *= ANGLE_MAT;
        rad += 1.0 / rad;

        mediump vec2 coord = vTex + point * (rad - 1.0) * texelSize;

        mediump vec4 sampleColor;
        if (coord.x >= 0.0 && coord.x <= 1.0 && coord.y >= 0.0 && coord.y <= 1.0) {
            sampleColor = texture2D(samplerFront, coord);
        } else {
            sampleColor = vec4(0.0);
        }

        mediump float lum = luminance(sampleColor.rgb);
         mediump float bloomFactor = smoothstep(threshold, threshold + falloff, lum);

        mediump vec4 bloomSample = vec4(sampleColor.rgb * bloomFactor, bloomFactor) * brightness;
        mediump float weight = 1.0 / rad;

        blur += bloomSample * weight;
        totalWeight += weight;
    }

    blur /= totalWeight;
    mediump vec4 originalColor = texture2D(samplerFront, vTex);

    gl_FragColor = originalColor + blur;
}