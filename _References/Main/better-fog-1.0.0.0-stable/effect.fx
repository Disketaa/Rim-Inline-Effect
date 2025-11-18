uniform lowp vec3 farColor;
uniform lowp float farDistance;
uniform lowp float farOpacity;
uniform lowp vec3 nearColor;
uniform lowp float nearDistance;
uniform lowp float nearOpacity;

/////////////////////////////////////////////////////////
// LinearFog

//The current foreground texture co-ordinate
varying mediump vec2 vTex;
//The foreground texture sampler, to be sampled at vTex
uniform lowp sampler2D samplerFront;
//The current foreground rectangle being rendered
uniform mediump vec2 srcStart;
uniform mediump vec2 srcEnd;
//The current foreground source rectangle being rendered
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
//The current foreground source rectangle being rendered, in layout 
uniform mediump vec2 layoutStart;
uniform mediump vec2 layoutEnd;
//The background texture sampler used for background - blending effects
uniform lowp sampler2D samplerBack;
uniform lowp sampler2D samplerDepth;
//The current background rectangle being rendered to, in texture co-ordinates, for background-blending effects
uniform mediump vec2 destStart;
uniform mediump vec2 destEnd;
//The time in seconds since the runtime started. This can be used for animated effects
uniform mediump float seconds;
//The size of a texel in the foreground texture in texture co-ordinates
uniform mediump vec2 pixelSize;
//The current layer scale as a factor (i.e. 1 is unscaled)
uniform mediump float layerScale;
//The current layer angle in radians.
uniform mediump float layerAngle;

lowp float unlerp(lowp float min, lowp float max, lowp float value)
{
	return  (value - min) / (max - min);
}

void main(void)
{
	lowp vec4 front = texture2D(samplerFront, vTex);
	
	mediump float zNear = 1.0;
	mediump float zFar = 10000.0;
	mediump vec2 n = (vTex - srcStart) / (srcEnd - srcStart);
	mediump float depth = texture2D(samplerDepth, mix(destStart, destEnd, n)).r;
	mediump float zLinear = zNear * zFar / (zFar + depthSample * (zNear - zFar));
	
	lowp float progress = clamp(unlerp(nearDistance, farDistance, zLinear), 0.0, 1.0);
	
	gl_FragColor = vec4(mix(mix(nearColor, front, nearOpacity), mix(farColor, front, farOpacity), progress), front.a);
}


