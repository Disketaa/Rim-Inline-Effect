uniform lowp vec3 rim_color;
uniform mediump float blending;
uniform mediump float opacity;
uniform mediump float amount;
uniform mediump float angle;

varying mediump vec2 vTex;
uniform lowp sampler2D samplerFront;
uniform mediump vec2 pixelSize;

void main(void)
{
    if (opacity == 0.0) {
        mediump vec4 front = texture2D(samplerFront, vTex);
        gl_FragColor = front;
        return;
    }

    mediump vec4 front = texture2D(samplerFront, vTex);

    if (front.a == 0.0) {
        gl_FragColor = front;
        return;
    }

    mediump float angle_rad = radians(angle);
    mediump vec2 offset = vec2(cos(angle_rad), sin(angle_rad)) * pixelSize * amount;
    mediump vec4 offset_sample = texture2D(samplerFront, vTex + offset);
    mediump float inline_alpha = front.a * (1.0 - offset_sample.a) * opacity;

    mediump vec3 normal_blend = mix(front.rgb, rim_color, inline_alpha);
    mediump vec3 additive_blend = front.rgb + rim_color * inline_alpha;
    mediump vec3 result_rgb = mix(normal_blend, additive_blend, blending);

    gl_FragColor = vec4(result_rgb, front.a);
}