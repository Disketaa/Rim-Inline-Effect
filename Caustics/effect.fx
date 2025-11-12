varying mediump vec2 vTex;
uniform mediump float seconds;

uniform lowp vec3 caustic_color;
uniform mediump float speed;
uniform mediump float horizontal_scale;
uniform mediump float vertical_scale;
uniform mediump float threshold;
uniform mediump float sharpness;
uniform mediump float pixel_size;
uniform mediump float glow_intensity;
uniform mediump float glow_threshold;
uniform mediump float opacity_variation;
uniform sampler2D samplerFront;

mediump float calculateCaustic(inout vec4 k_param, mat3 matrix_param, mediump float scale_param) {
    mat3 scaled_matrix = matrix_param * scale_param;
    k_param.xyw *= scaled_matrix;
    return mediump float(length(0.5 - fract(k_param.xyw)));
}

float simpleHash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = simpleHash(i);
    float b = simpleHash(i + vec2(1.0, 0.0));
    float c = simpleHash(i + vec2(0.0, 1.0));
    float d = simpleHash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void main(void) {
    vec2 screen_coord = c3_getLayoutPos(vTex);

    if (threshold >= 1.0 && glow_intensity <= 0.0) {
        gl_FragColor = texture2D(samplerFront, vTex);
        return;
    }

    vec2 current_coord = screen_coord;
    if (pixel_size > 0.0) {
        current_coord = floor(current_coord / pixel_size) * pixel_size;
    }

    mediump float current_time = seconds * speed;

    mediump mat3 caustic_matrix = mat3(-2.0, -1.0, 2.0, 3.0, -2.0, 1.0, 1.0, 2.0, 2.0);

    vec4 caustic_params = vec4(current_coord.x, current_coord.y, 0.0, current_time);
    vec2 scaled_coords = vec2(caustic_params.x / horizontal_scale, caustic_params.y / vertical_scale) / 100.0;
    caustic_params.xy = scaled_coords;

    float min_value_1 = min(calculateCaustic(caustic_params, caustic_matrix, 0.5), calculateCaustic(caustic_params, caustic_matrix, 0.4));
    float min_value_2 = min(min_value_1, calculateCaustic(caustic_params, caustic_matrix, 0.3));

    float caustic_intensity = 1.0 - pow(min_value_2, 7.0) * 25.0;
    float base_intensity = 1.0 - smoothstep(threshold, threshold + 0.3, caustic_intensity);
    float glow_layer = 1.0 - smoothstep(glow_threshold, glow_threshold + 0.6, caustic_intensity);
    glow_layer *= glow_intensity;

    if (sharpness > 0.0) {
        mediump float sharpness_cutoff = 0.5 + sharpness * 0.5;
        base_intensity = mix(base_intensity, step(sharpness_cutoff, base_intensity), sharpness);
        glow_layer = mix(glow_layer, step(sharpness_cutoff, glow_layer), sharpness);
    }

    lowp vec4 original_color = texture2D(samplerFront, vTex);

    float final_alpha = base_intensity * original_color.a;

    if (opacity_variation > 0.0) {
        float scale_factor = max(horizontal_scale, vertical_scale);
        float noise_scale = 0.005 / scale_factor;
        float noise = smoothNoise(current_coord * noise_scale + current_time * 0.05);
        float variation = mix(1.0, 1.0 - noise, opacity_variation);
        final_alpha *= variation;
    }

    lowp vec3 base_color = caustic_color * final_alpha;
    lowp vec3 glow_color = vec3(1.0, 1.0, 1.0) * glow_layer * final_alpha;
    lowp vec3 final_color = base_color + glow_color;

    gl_FragColor = vec4(final_color, final_alpha);
}