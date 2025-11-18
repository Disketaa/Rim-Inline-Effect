%%FRAGMENTINPUT_STRUCT%%

%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;


struct ShaderParams {
	shadowcolor : vec3<f32>,
	shadowopacity : f32,
	shadowdistance : f32,
	shadowangle: f32
};

%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

%%C3PARAMS_STRUCT%%

%%C3_UTILITY_FUNCTIONS%%

//ported to wgsl by Federico Calchera

@fragment
fn main(input : FragmentInput) -> FragmentOutput
{	
	let front: vec4<f32> = textureSample(textureFront, samplerFront, input.fragUV);
	
	let layoutSize : vec2<f32> = abs(vec2(c3Params.layoutEnd.x - c3Params.layoutStart.x, (c3Params.layoutEnd.y - c3Params.layoutStart.y))); 
	let texelSize : vec2<f32> = abs(c3Params.srcOriginEnd - c3Params.srcOriginStart) / layoutSize;

	let angle: f32 = (180. - shaderParams.shadowangle) / 180. * 3.1415927;
	let actualWidth: vec2<f32> = shaderParams.shadowdistance * vec2<f32>(texelSize.x, -texelSize.y);
	var testPoint: vec2<f32> = input.fragUV + actualWidth * vec2<f32>(cos(angle), sin(angle));
	testPoint = c3_clampToSrc(testPoint);
	let testPointTex: vec4<f32> = textureSample(textureFront, samplerFront, testPoint);
	
	let color: vec4<f32> = vec4<f32>(shaderParams.shadowcolor, shaderParams.shadowopacity);

	var output : FragmentOutput;
	output.color = mix(mix(front, mix(front, color, color.a), testPointTex.a), front, front.a);
	return output;
}