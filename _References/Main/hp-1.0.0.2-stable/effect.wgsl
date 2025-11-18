/////////////////////////////////////////////////////////
// hp_fx spokoinbli
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

struct ShaderParams {
 colorHp: vec3<f32>,
 progress: f32,
 outlineBg: f32,
 width : f32,
 height : f32,
 colorBg: vec3<f32>,
 positionY : f32,

 opacity: f32,
 opacityBg: f32,
 progressMax: f32
 
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

fn sdRoundRect(p: vec2<f32>, s: vec2<f32>, r: f32) -> f32 {
	let d = abs(p) - s + r;
	return min(max(d.x, d.y), 0.0) + length(max(d, vec2<f32>(0.0))) - r;
} */


@fragment
fn main(input : FragmentInput) -> FragmentOutput
{
   var uv : vec2<f32> = (input.fragUV - c3Params.srcOriginStart) / (c3Params.srcOriginEnd - c3Params.srcOriginStart);
   var color : vec4<f32>= textureSample(textureFront, samplerFront, input.fragUV);
   var output : FragmentOutput;
   var m : f32 = shaderParams.progress - shaderParams.progressMax * floor(shaderParams.progress/shaderParams.progressMax);

   var w : f32 =  (1.-shaderParams.width)/2.;
   var x : f32 =  uv.x ;
   var y : f32 =  uv.y ;

   output.color = color;

   if (x >= w-shaderParams.outlineBg  && x <=  1.-w+shaderParams.outlineBg  && y >= shaderParams.positionY-shaderParams.outlineBg && y <= shaderParams.positionY+shaderParams.height+shaderParams.outlineBg) { 
	
   output.color = vec4<f32>(vec3<f32>(shaderParams.colorBg)*shaderParams.opacityBg, shaderParams.opacityBg);
   
   }
   if(x >= w  && x - w  <= (m/shaderParams.progressMax)*(1.-(w*2.)) && y >= shaderParams.positionY && y <= shaderParams.positionY+shaderParams.height) {
		 
    output.color =  vec4<f32>(vec3<f32>(shaderParams.colorHp)*shaderParams.opacity, shaderParams.opacity);
  
   }
 
 return output;
}
