/////////////////////////////////////////////////////////
// Minimal sample WebGPU shader. This just outputs a blue
// color to indicate WebGPU is in use (rather than one of
// the WebGL shader variants).

%%FRAGMENTINPUT_STRUCT%%
/* input struct contains the following fields:
fragUV : vec2<f32>
fragPos : vec4<f32>
fn c3_getBackUV(fragPos : vec2<f32>, texBack : texture_2d<f32>) -> vec2<f32>
fn c3_getDepthUV(fragPos : vec2<f32>, texDepth : texture_depth_2d) -> vec2<f32>
*/
%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

//%//%SAMPLERBACK_BINDING%//% var samplerBack : sampler;
//%//%TEXTUREBACK_BINDING%//% var textureBack : texture_2d<f32>;

//%//%SAMPLERDEPTH_BINDING%//% var samplerDepth : sampler;
//%//%TEXTUREDEPTH_BINDING%//% var textureDepth : texture_depth_2d;

/* Uniforms are:
uAngle: angle of the shine, 0.0-360.0
uIntensity: how hard to mix the shine with the image, 0.0-1.0
uColor: the color of the shine, vec4
uSize: the size of the shine in percent based on diameter, 0.0-1.0
uProgress: the progress of the shine, 0.0-1.0
uHardness: how hard the shine is, 0 is smooth, 1 is a hard edge , 0.0-1.0
 */

struct ShaderParams {
	  uAngle : f32,
  uIntensity : f32,
  uColor : vec3<f32>,
  uSize : f32,
  uProgress : f32,
  uHardness : f32
};
%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;
/* gets replaced with:

struct ShaderParams {

	floatParam : f32,
	colorParam : vec3<f32>,
	// etc.

};

%//%SHADERPARAMS_BINDING%//% var<uniform> shaderParams : ShaderParams;
*/


%%C3PARAMS_STRUCT%%
/* c3Params struct contains the following fields:
srcStart : vec2<f32>,
srcEnd : vec2<f32>,
srcOriginStart : vec2<f32>,
srcOriginEnd : vec2<f32>,
layoutStart : vec2<f32>,
layoutEnd : vec2<f32>,
destStart : vec2<f32>,
destEnd : vec2<f32>,
devicePixelRatio : f32,
layerScale : f32,
layerAngle : f32,
seconds : f32,
zNear : f32,
zFar : f32,
isSrcTexRotated : u32
fn c3_srcToNorm(p : vec2<f32>) -> vec2<f32>
fn c3_normToSrc(p : vec2<f32>) -> vec2<f32>
fn c3_srcOriginToNorm(p : vec2<f32>) -> vec2<f32>
fn c3_normToSrcOrigin(p : vec2<f32>) -> vec2<f32>
fn c3_clampToSrc(p : vec2<f32>) -> vec2<f32>
fn c3_clampToSrcOrigin(p : vec2<f32>) -> vec2<f32>
fn c3_getLayoutPos(p : vec2<f32>) -> vec2<f32>
fn c3_srcToDest(p : vec2<f32>) -> vec2<f32>
fn c3_clampToDest(p : vec2<f32>) -> vec2<f32>
fn c3_linearizeDepth(depthSample : f32) -> f32
*/

//%//%C3_UTILITY_FUNCTIONS%//%
/*
fn c3_premultiply(c : vec4<f32>) -> vec4<f32>
fn c3_unpremultiply(c : vec4<f32>) -> vec4<f32>
fn c3_grayscale(rgb : vec3<f32>) -> f32
fn c3_getPixelSize(t : texture_2d<f32>) -> vec2<f32>
fn c3_RGBtoHSL(color : vec3<f32>) -> vec3<f32>
fn c3_HSLtoRGB(hsl : vec3<f32>) -> vec3<f32>
*/

@fragment
fn main(input : FragmentInput) -> FragmentOutput
{
	let image = textureSample(textureFront, samplerFront, input.fragUV);
	let radAngle = select(radians(shaderParams.uAngle), radians(90.0 + shaderParams.uAngle), c3Params.isSrcTexRotated != 0);
	let size = shaderParams.uSize * 0.5;

	// Get diameter of the circle around the srcStart size
	let srcSize = c3Params.srcOriginEnd - c3Params.srcOriginStart;
	let srcRadius = length(srcSize) / 2.0;
	let srcCenter = c3Params.srcOriginStart + (srcSize / 2.0);

	// Get center position of the shine at the angle
	let shineDir = vec2<f32>(cos(radAngle), sin(radAngle));
	let shineRange = shaderParams.uSize * srcRadius;
	let shineStart = srcCenter - (srcRadius + (shaderParams.uSize * 2.0) * srcRadius) * shineDir;
	let shineEnd = srcCenter + (srcRadius + (shaderParams.uSize * 2.0) * srcRadius) * shineDir;

	// Get position of the shine
	let shinePos = shineStart + (shaderParams.uProgress * (shineEnd - shineStart));
	let diff = input.fragUV - shinePos;
	let projection = dot(diff, shineDir);
	let shine = smoothstep(-shineRange * 0.5 - size, -shineRange * 0.5 - size * shaderParams.uHardness + 0.001, projection)
				- smoothstep(shineRange * 0.5 + size * shaderParams.uHardness - 0.001, shineRange * 0.5 + size, projection);

	var output : FragmentOutput;
	output.color = vec4<f32>(mix(image.rgb, shaderParams.uColor,  image.a * shaderParams.uIntensity * shine), image.a);
	return output;
}
