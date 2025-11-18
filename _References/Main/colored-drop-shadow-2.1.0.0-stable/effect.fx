uniform lowp vec3 shadowcolor;
uniform lowp float shadowopacity;
uniform lowp float shadowdistance;
uniform lowp float shadowangle;
/////////////////////////////////////////////////////////
// DropShadow

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

#define PI 3.14159265359

#define  clampX(x,a,b)  min(max(x,min(a,b)),max(a,b))

void main(void)
{
	mediump float angle = (180.0 - shadowangle)/180.0 * PI;
    mediump vec2 layoutSize = abs(vec2(layoutEnd.x-layoutStart.x,(layoutEnd.y-layoutStart.y))); 
    mediump vec2 texelSize = abs(srcOriginEnd-srcOriginStart)/layoutSize;
	mediump vec2 actualWidth = shadowdistance * texelSize;
	mediump vec2 testPoint = vTex + actualWidth * vec2(cos(angle), sin(angle));
	testPoint = clampX( testPoint, srcOriginStart, srcOriginEnd );
	mediump vec4 testPointTex = texture2D(samplerFront, testPoint);
	lowp float a = testPointTex.a;
	mediump vec4 tex0 = texture2D( samplerFront, vTex );
	mediump vec4 color = vec4(shadowcolor, shadowopacity);
	//if(a < 0.005) {
		
	//} else {
		//TEXTURE
	//	gl_FragColor = vec4(mix(color.rgb, tex0.rgb, tex0.a), tex0.a + shadowopacity);
	//}
	gl_FragColor = mix(mix(tex0, mix(tex0, color, color.a), testPointTex.a), tex0, tex0.a);
	
}