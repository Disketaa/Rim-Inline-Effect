// ============================================================
// Drop Shadow Effect - WebGL Shader (GLSL ES 1.0)
// ============================================================
// Creates a drop shadow effect with customizable:
// - Position (distance + angle)
// - Color (HSV color space)
// - Blur (adaptive quality levels)
// ============================================================

#ifdef GL_ES
precision highp float;
#endif

// ============================================================
// Constants
// ============================================================
const float PI = 3.14159265;
const float DEG_TO_RAD = PI / 180.0;
const float MIN_ALPHA = 0.001;  // Threshold for transparent pixels

// ============================================================
// Construct 3 Built-in Uniforms
// ============================================================
varying mediump vec2 vTex;              // Texture coordinates
uniform lowp sampler2D samplerFront;    // Source texture
uniform mediump vec2 srcOriginStart;    // Texture coordinate bounds
uniform mediump vec2 srcOriginEnd;
uniform mediump vec2 layoutStart;       // Layout coordinate bounds
uniform mediump vec2 layoutEnd;

// ============================================================
// Effect Parameters
// ============================================================
uniform mediump float uDistance;        // Shadow offset distance (pixels)
uniform mediump float uAngle;           // Shadow direction (degrees, clockwise from left)
uniform lowp float uOpacity;            // Shadow opacity [0-1]
uniform mediump float uHue;             // Shadow color hue [0-360]
uniform lowp float uSaturation;         // Shadow color saturation [0-1]
uniform lowp float uBrightness;         // Shadow color brightness [0-1]
uniform mediump float uBlurRadius;      // Blur radius (pixels)
uniform lowp float uBlurQuality;        // Blur quality [0-1]

// ============================================================
// Helper Functions
// ============================================================

// Gaussian weight lookup table for blur kernels
// Uses pre-calculated weights for 10 quality levels (3x3 to 11x11)
// Input: distSq = squared distance from center, kernelRadius = quality level
// Output: Gaussian weight for the sample
float getGaussianWeight(float distSq, float kernelRadius) {
	// Quality Level 1: 3x3 kernel (sigma=0.5)
	if (kernelRadius < 1.25) {
		if (distSq < 0.5) return 1.000;
		if (distSq < 1.5) return 0.1353;
		return 0.0183;
	}

	// Quality Level 2: 4x4 kernel (sigma=0.75)
	if (kernelRadius < 1.75) {
		if (distSq < 0.5) return 1.000;
		if (distSq < 1.5) return 0.4111;
		if (distSq < 2.5) return 0.1687;
		if (distSq < 4.5) return 0.0285;
		return 0.0117;
	}

	// Quality Level 3: 5x5 kernel (sigma=1.0)
	if (kernelRadius < 2.25) {
		if (distSq < 0.5) return 1.000;
		if (distSq < 1.5) return 0.6065;
		if (distSq < 3.0) return 0.3679;
		if (distSq < 4.5) return 0.1353;
		if (distSq < 6.5) return 0.0821;
		if (distSq < 8.5) return 0.0183;
		if (distSq < 9.5) return 0.0111;
		if (distSq < 11.5) return 0.0067;
		return 0.0015;
	}

	// Quality Level 4: 6x6 kernel (sigma=1.25)
	if (kernelRadius < 2.75) {
		if (distSq < 0.5) return 1.000;
		if (distSq < 1.5) return 0.7261;
		if (distSq < 2.5) return 0.5273;
		if (distSq < 4.5) return 0.2780;
		if (distSq < 5.5) return 0.2019;
		if (distSq < 8.5) return 0.0773;
		if (distSq < 9.5) return 0.0561;
		if (distSq < 10.5) return 0.0408;
		if (distSq < 13.5) return 0.0156;
		if (distSq < 16.5) return 0.0060;
		return 0.0032;
	}

	// Quality Level 5: 7x7 kernel (sigma=1.5)
	if (kernelRadius < 3.25) {
		if (distSq < 0.5) return 1.000;
		if (distSq < 1.5) return 0.8007;
		if (distSq < 3.0) return 0.6412;
		if (distSq < 4.5) return 0.4111;
		if (distSq < 6.5) return 0.3292;
		if (distSq < 8.5) return 0.1687;
		if (distSq < 9.5) return 0.1353;
		if (distSq < 11.5) return 0.1083;
		if (distSq < 14.5) return 0.0695;
		if (distSq < 16.5) return 0.0183;
		if (distSq < 17.5) return 0.0150;
		if (distSq < 19.0) return 0.0122;
		if (distSq < 22.5) return 0.0079;
		if (distSq < 25.5) return 0.0033;
		if (distSq < 27.5) return 0.0027;
		if (distSq < 30.5) return 0.0018;
		if (distSq < 33.0) return 0.0009;
		if (distSq < 35.0) return 0.0006;
		return 0.0003;
	}

	// Quality Level 6: 8x8 kernel (sigma=1.75)
	if (kernelRadius < 3.75) {
		if (distSq < 0.5) return 1.000;
		if (distSq < 1.5) return 0.8495;
		if (distSq < 2.5) return 0.7214;
		if (distSq < 4.5) return 0.5205;
		if (distSq < 5.5) return 0.4421;
		if (distSq < 8.5) return 0.2707;
		if (distSq < 9.5) return 0.2300;
		if (distSq < 10.5) return 0.1954;
		if (distSq < 13.5) return 0.1197;
		if (distSq < 16.5) return 0.0733;
		if (distSq < 17.5) return 0.0623;
		if (distSq < 18.5) return 0.0529;
		if (distSq < 20.5) return 0.0381;
		if (distSq < 25.5) return 0.0168;
		if (distSq < 26.5) return 0.0143;
		if (distSq < 29.5) return 0.0088;
		if (distSq < 32.5) return 0.0054;
		if (distSq < 34.5) return 0.0039;
		if (distSq < 37.5) return 0.0024;
		if (distSq < 41.5) return 0.0012;
		if (distSq < 45.5) return 0.0006;
		return 0.0003;
	}

	// Quality Level 7: 9x9 kernel (sigma=2.0)
	if (kernelRadius < 4.25) {
		if (distSq < 0.5) return 1.000;
		if (distSq < 1.5) return 0.8825;
		if (distSq < 3.0) return 0.7788;
		if (distSq < 4.5) return 0.6065;
		if (distSq < 6.5) return 0.5353;
		if (distSq < 8.5) return 0.3679;
		if (distSq < 9.5) return 0.3247;
		if (distSq < 11.5) return 0.2865;
		if (distSq < 14.5) return 0.1972;
		if (distSq < 16.5) return 0.1353;
		if (distSq < 17.5) return 0.1194;
		if (distSq < 19.0) return 0.1054;
		if (distSq < 22.5) return 0.0821;
		if (distSq < 27.0) return 0.0439;
		return 0.0183;
	}

	// Quality Level 8: 10x10 kernel (sigma=2.25)
	if (kernelRadius < 4.75) {
		if (distSq < 0.5) return 1.000;
		if (distSq < 1.5) return 0.9061;
		if (distSq < 2.5) return 0.8210;
		if (distSq < 4.5) return 0.6738;
		if (distSq < 5.5) return 0.6103;
		if (distSq < 8.5) return 0.4538;
		if (distSq < 9.5) return 0.4111;
		if (distSq < 10.5) return 0.3725;
		if (distSq < 13.5) return 0.2768;
		if (distSq < 16.5) return 0.2058;
		if (distSq < 17.5) return 0.1863;
		if (distSq < 18.5) return 0.1687;
		if (distSq < 20.5) return 0.1388;
		if (distSq < 25.5) return 0.0846;
		if (distSq < 26.5) return 0.0766;
		if (distSq < 29.5) return 0.0571;
		if (distSq < 32.5) return 0.0425;
		if (distSq < 34.5) return 0.0347;
		if (distSq < 37.5) return 0.0285;
		if (distSq < 41.5) return 0.0192;
		if (distSq < 45.5) return 0.0117;
		if (distSq < 50.5) return 0.0079;
		if (distSq < 53.5) return 0.0054;
		if (distSq < 58.5) return 0.0033;
		if (distSq < 61.5) return 0.0024;
		if (distSq < 65.5) return 0.0016;
		if (distSq < 68.5) return 0.0012;
		if (distSq < 73.5) return 0.0007;
		if (distSq < 81.0) return 0.0004;
		return 0.0003;
	}

	// Quality Level 9-10: 11x11 kernel (sigma=2.5, highest quality)
	if (distSq < 0.5) return 1.000;
	if (distSq < 1.5) return 0.9231;
	if (distSq < 3.0) return 0.8521;
	if (distSq < 4.5) return 0.7261;
	if (distSq < 6.5) return 0.6703;
	if (distSq < 8.5) return 0.5273;
	if (distSq < 9.5) return 0.4868;
	if (distSq < 11.5) return 0.4493;
	if (distSq < 14.5) return 0.3535;
	if (distSq < 16.5) return 0.2780;
	if (distSq < 17.5) return 0.2567;
	if (distSq < 19.0) return 0.2369;
	if (distSq < 22.5) return 0.2019;
	if (distSq < 27.0) return 0.1353;
	if (distSq < 30.5) return 0.0983;
	if (distSq < 33.5) return 0.0773;
	if (distSq < 36.5) return 0.0657;
	if (distSq < 39.5) return 0.0518;
	if (distSq < 42.5) return 0.0408;
	if (distSq < 47.5) return 0.0273;
	if (distSq < 51.5) return 0.0183;
	return 0.0100;
}

// Convert HSV color to RGB
// Input: c.x = hue [0-1], c.y = saturation [0-1], c.z = value/brightness [0-1]
// Output: RGB color [0-1]
vec3 hsv2rgb(vec3 c) {
	// Fast path for grayscale (saturation = 0)
	if (c.y < 0.001) {
		return vec3(c.z);
	}

	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// ============================================================
// Main Fragment Shader
// ============================================================
void main(void) {
	// ========== Step 1: Setup ==========
	// Cache frequently used parameters
	float distance = uDistance;
	float blurRadius = uBlurRadius;
	float blurQuality = clamp(uBlurQuality, 0.0, 1.0);

	// Calculate texel size for coordinate conversion
	// layoutSize = size in layout pixels (unaffected by editor zoom)
	// texelSize = conversion factor from layout pixels to texture coordinates
	vec2 layoutSize = abs(layoutEnd - layoutStart);
	vec2 texelSize = abs(srcOriginEnd - srcOriginStart) / layoutSize;

	// ========== Step 2: Calculate Shadow Offset ==========
	// Shadow direction system (clockwise):
	//   0° = left, 90° = down, 180° = right, 270° = up
	// Note: offset is sampling direction (opposite of shadow direction)
	// WebGL uses inverted Y coordinates compared to WebGPU, so negate sin component
	float angleRad = -uAngle * DEG_TO_RAD;
	vec2 offset = distance * vec2(cos(angleRad), -sin(angleRad)) * texelSize;

	// ========== Step 3: Sample Shadow Alpha with Blur ==========
	vec4 shadow;

	if (blurRadius < 0.1 || blurQuality <= 0.0) {
		// No blur: single sample at offset position
		shadow = texture2D(samplerFront, vTex + offset);
	}
	else {
		// Apply Gaussian blur with adaptive quality
		// Select kernel size based on quality parameter (10 levels)
		float kernelRadius;
		if (blurQuality >= 0.9) {
			kernelRadius = 5.0;  // 11x11 (highest quality)
		}
		else if (blurQuality >= 0.8) {
			kernelRadius = 4.5;  // 10x10
		}
		else if (blurQuality >= 0.7) {
			kernelRadius = 4.0;  // 9x9
		}
		else if (blurQuality >= 0.6) {
			kernelRadius = 3.5;  // 8x8
		}
		else if (blurQuality >= 0.5) {
			kernelRadius = 3.0;  // 7x7
		}
		else if (blurQuality >= 0.4) {
			kernelRadius = 2.5;  // 6x6
		}
		else if (blurQuality >= 0.3) {
			kernelRadius = 2.0;  // 5x5
		}
		else if (blurQuality >= 0.2) {
			kernelRadius = 1.5;  // 4x4
		}
		else {
			kernelRadius = 1.0;  // 3x3 (lowest quality)
		}

		// Perform weighted blur sampling
		shadow = vec4(0.0);
		float totalWeight = 0.0;

		vec2 blurStep = blurRadius * texelSize;
		vec2 baseCoord = vTex + offset;

		// Grid sampling with Gaussian weights
		// GLSL ES 1.0 requires constant loop bounds, so we use fixed maximum (11x11)
		// and skip samples outside the selected kernel radius
		for (float i = -5.0; i <= 5.0; i += 1.0) {
			for (float j = -5.0; j <= 5.0; j += 1.0) {
				// Skip samples outside the selected kernel radius
				float distSq = i * i + j * j;
				if (distSq > kernelRadius * kernelRadius) {
					continue;
				}

				vec2 sampleCoord = baseCoord + vec2(i, j) * blurStep;
				vec4 sample = texture2D(samplerFront, sampleCoord);

				float weight = getGaussianWeight(distSq, kernelRadius);

				shadow.a += sample.a * weight;
				totalWeight += weight;
			}
		}

		// Normalize by total weight
		shadow.a /= max(totalWeight, 0.0001);
	}

	// ========== Step 4: Apply Shadow Color and Opacity ==========
	shadow.a *= uOpacity;

	// Sample original pixel
	vec4 front = texture2D(samplerFront, vTex);

	// Early exit optimization: skip if shadow is transparent
	if (shadow.a < MIN_ALPHA) {
		gl_FragColor = front;
		return;
	}

	// Apply HSV color to shadow
	shadow.rgb = hsv2rgb(vec3(
		mod(mod(uHue, 360.0) + 360.0, 360.0) / 360.0,  // Normalize hue to [0-1]
		clamp(uSaturation, 0.0, 1.0),
		clamp(uBrightness, 0.0, 1.0)
	));

	// ========== Step 5: Composite ==========
	// Blend shadow with foreground using double-mixing algorithm
	// First mix: blend shadow color into foreground based on shadow alpha
	vec4 shadowColor = mix(front, shadow, shadow.a);
	// Second mix: blend result back to foreground based on foreground alpha
	gl_FragColor = mix(shadowColor, front, front.a);
}
