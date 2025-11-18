// ============================================================
// Drop Shadow Effect - WebGPU Shader (WGSL)
// ============================================================
// Creates a drop shadow effect with customizable:
// - Position (distance + angle)
// - Color (HSV color space)
// - Blur (Vogel's spiral adaptive sampling)
// ============================================================

// ============================================================
// Constants
// ============================================================
const PI : f32 = 3.14159265;
const TWO_PI : f32 = 6.28318531;
const DEG_TO_RAD : f32 = PI / 180.0;
const GOLDEN_ANGLE : f32 = 2.39996323;  // (3 - sqrt(5)) * PI for Vogel's spiral distribution
const MIN_ALPHA : f32 = 0.001;          // Threshold for transparent pixels

// ============================================================
// Construct 3 Built-in Bindings
// ============================================================
%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

// ============================================================
// Effect Parameters
// ============================================================
// NOTE: Order must match addon.json parameters array
struct ShaderParams {
	distance : f32,      // Shadow offset distance (pixels)
	angle : f32,         // Shadow direction (degrees, clockwise from left)
	opacity : f32,       // Shadow opacity [0-1]
	hue : f32,           // Shadow color hue [0-360]
	saturation : f32,    // Shadow color saturation [0-1]
	brightness : f32,    // Shadow color brightness [0-1]
	blurRadius : f32,    // Blur radius (pixels)
	blurQuality : f32    // Blur quality [0-1]
}
%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

// ============================================================
// Construct 3 Template Variables
// ============================================================
// These are replaced by Construct 3 at runtime with actual structs and functions
%%C3PARAMS_STRUCT%%
%%FRAGMENTINPUT_STRUCT%%
%%FRAGMENTOUTPUT_STRUCT%%
%%C3_UTILITY_FUNCTIONS%%

// ============================================================
// Helper Functions
// ============================================================

// Gaussian weight function for blur
// Uses continuous exponential formula: exp(-dist^2 / (2 * sigma^2))
// Input: dist = distance from center, sigma = standard deviation
// Output: Gaussian weight for the sample
fn getGaussianWeight(dist : f32, sigma : f32) -> f32 {
	let sigmaSq = sigma * sigma;
	return exp(-(dist * dist) / (2.0 * sigmaSq));
}

// Convert HSV color to RGB
// Input: c.x = hue [0-1], c.y = saturation [0-1], c.z = value/brightness [0-1]
// Output: RGB color [0-1]
fn hsv2rgb(c : vec3<f32>) -> vec3<f32> {
	// Fast path for grayscale (saturation = 0)
	if (c.y < 0.001) {
		return vec3<f32>(c.z);
	}

	let K = vec4<f32>(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	let p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, vec3<f32>(0.0), vec3<f32>(1.0)), c.y);
}

// ============================================================
// Main Fragment Shader
// ============================================================
@fragment
fn main(input : FragmentInput) -> FragmentOutput
{
	// ========== Early Exit Optimizations ==========
	// Skip processing if shadow would be invisible
	if (shaderParams.opacity <= 0.0 || (shaderParams.distance <= 0.0 && shaderParams.blurRadius < 0.1)) {
		var output : FragmentOutput;
		output.color = textureSampleLevel(textureFront, samplerFront, input.fragUV, 0.0);
		return output;
	}

	// Sample original pixel
	let frontPixel = textureSampleLevel(textureFront, samplerFront, input.fragUV, 0.0);

	// Skip if pixel is fully opaque (shadow is behind, won't be visible)
	if (frontPixel.a > 0.99) {
		var output : FragmentOutput;
		output.color = frontPixel;
		return output;
	}

	// ========== Step 1: Setup ==========
	// Cache frequently used parameters
	let distance = shaderParams.distance;
	let blurRadius = shaderParams.blurRadius;
	let blurQuality = clamp(shaderParams.blurQuality, 0.0, 1.0);

	// Calculate texel size for coordinate conversion
	// layoutSize = size in layout pixels (unaffected by editor zoom)
	// texelSize = conversion factor from layout pixels to texture coordinates
	let layoutSize = abs(c3Params.layoutEnd - c3Params.layoutStart);
	let texelSize = abs(c3Params.srcOriginEnd - c3Params.srcOriginStart) / layoutSize;

	// ========== Step 2: Calculate Shadow Offset ==========
	// Shadow direction system (clockwise):
	//   0° = left, 90° = down, 180° = right, 270° = up
	// Note: offset is sampling direction (opposite of shadow direction)
	let angleRad = -shaderParams.angle * DEG_TO_RAD;
	let offset = distance * vec2<f32>(cos(angleRad), sin(angleRad)) * texelSize;

	// ========== Step 3: Sample Shadow Alpha with Blur ==========
	var shadow : vec4<f32>;

	if (blurRadius < 0.1 || blurQuality <= 0.0) {
		// No blur: single sample at offset position
		shadow = textureSampleLevel(textureFront, samplerFront, input.fragUV + offset, 0.0);
	}
	else {
		// Apply Gaussian blur using Vogel's spiral distribution
		// Vogel's spiral provides better sample distribution than regular grids

		// Select sample count based on quality parameter (10 levels)
		var totalSamples : u32;
		if (blurQuality >= 0.9) {
			totalSamples = 256u;  // 11x11 (highest quality)
		}
		else if (blurQuality >= 0.8) {
			totalSamples = 192u;  // 10x10
		}
		else if (blurQuality >= 0.7) {
			totalSamples = 128u;  // 9x9
		}
		else if (blurQuality >= 0.6) {
			totalSamples = 96u;   // 8x8
		}
		else if (blurQuality >= 0.5) {
			totalSamples = 64u;   // 7x7
		}
		else if (blurQuality >= 0.4) {
			totalSamples = 48u;   // 6x6
		}
		else if (blurQuality >= 0.3) {
			totalSamples = 32u;   // 5x5
		}
		else if (blurQuality >= 0.2) {
			totalSamples = 24u;   // 4x4
		}
		else {
			totalSamples = 16u;   // 3x3 (lowest quality)
		}

		// Calculate Gaussian sigma for weighting
		let sigma = blurRadius * 0.5;

		// Perform weighted spiral sampling
		shadow = vec4<f32>(0.0);
		var totalWeight : f32 = 0.0;
		let sqrtTotalSamples = sqrt(f32(totalSamples));
		let baseCoord = input.fragUV + offset;

		// Loop through spiral samples
		const MAX_LOOP_ITERATIONS : u32 = 256u;
		for (var i : u32 = 0u; i < MAX_LOOP_ITERATIONS; i = i + 1u) {
			if (i >= totalSamples) { break; }

			// Calculate sample position using Vogel's spiral formula
			// angle = golden angle * index (evenly distributes samples)
			// radius = sqrt(index) normalized (fills circle uniformly)
			let angle = f32(i) * GOLDEN_ANGLE;
			let t = sqrt(f32(i) + 0.5) / sqrtTotalSamples;
			let radius = t * blurRadius;

			// Convert to texture coordinates and sample
			let spiralOffset = radius * vec2<f32>(cos(angle), sin(angle));
			let sampleCoord = baseCoord + spiralOffset * texelSize;
			let sample = textureSampleLevel(textureFront, samplerFront, sampleCoord, 0.0);

			// Apply Gaussian weight based on distance from center
			let weight = getGaussianWeight(radius, sigma);
			shadow.a += sample.a * weight;
			totalWeight += weight;
		}

		// Normalize by total weight
		shadow.a /= max(totalWeight, 0.0001);
	}

	// ========== Step 4: Apply Shadow Color and Opacity ==========
	shadow.a *= shaderParams.opacity;

	// Early exit optimization: skip if shadow is transparent
	if (shadow.a < MIN_ALPHA) {
		var output : FragmentOutput;
		output.color = frontPixel;
		return output;
	}

	// Apply HSV color to shadow
	shadow = vec4<f32>(
		hsv2rgb(vec3<f32>(
			(shaderParams.hue % 360.0 + 360.0) % 360.0 / 360.0,  // Normalize hue to [0-1]
			clamp(shaderParams.saturation, 0.0, 1.0),
			clamp(shaderParams.brightness, 0.0, 1.0)
		)),
		shadow.a
	);

	// ========== Step 5: Composite ==========
	// Blend shadow with foreground using double-mixing algorithm
	// First mix: blend shadow color into foreground based on shadow alpha
	let shadowColor = mix(frontPixel, shadow, shadow.a);
	// Second mix: blend result back to foreground based on foreground alpha
	var result : vec4<f32> = mix(shadowColor, frontPixel, frontPixel.a);

	var output : FragmentOutput;
	output.color = result;
	return output;
}
