
// Sample WebGL 1 shader. This just outputs a red color
// to indicate WebGL 1 is in use.

#ifdef GL_FRAGMENT_PRECISION_HIGH
#define highmedp highp
#else
#define highmedp mediump
#endif

precision lowp float;

varying mediump vec2 vTex;
uniform lowp sampler2D samplerFront;
uniform mediump vec2 srcStart;
uniform mediump vec2 srcEnd;
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
uniform mediump vec2 layoutStart;
uniform mediump vec2 layoutEnd;
uniform lowp sampler2D samplerBack;
uniform lowp sampler2D samplerDepth;
uniform mediump vec2 destStart;
uniform mediump vec2 destEnd;
uniform highmedp float seconds;
uniform mediump vec2 pixelSize;
uniform mediump float layerScale;
uniform mediump float layerAngle;
uniform mediump float devicePixelRatio;
uniform mediump float zNear;
uniform mediump float zFar;

uniform lowp float uAngle;
uniform lowp float uIntensity;
uniform lowp vec3 uColor;
uniform lowp float uSize;
uniform lowp float uProgress;
uniform lowp float uHardness;

/* Uniforms are:
uAngle: angle of the shine, 0.0-360.0
uIntensity: how hard to mix the shine with the image, 0.0-1.0
uColor: the color of the shine, vec3
uSize: the size of the shine in percent based on diameter, 0.0-1.0
uProgress: the progress of the shine, 0.0-1.0
uHardness: how hard the shine is, 0 is smooth, 1 is a hard edge , 0.0-1.0
 */

void main(void)
{
	mediump vec4 image = texture2D(samplerFront, vTex);
	mediump float angle = srcOriginEnd.y < srcOriginStart.y ? -uAngle : uAngle;
	mediump float radAngle = radians(angle);
	mediump float size = uSize * 0.5;

	//get diameter of the circle around the srcStart size
	mediump vec2 srcSize = srcOriginEnd - srcOriginStart;
	mediump float srcRadius = length(srcSize)/2.0;
	mediump vec2 srcCenter = srcOriginStart + (srcSize/2.0);

	// get center position of the shine at the angle
	mediump vec2 shineDir = vec2(cos(radAngle), sin(radAngle));
	mediump float shineRange = uSize * srcRadius;
	mediump vec2 shineStart = srcCenter - (srcRadius + (uSize * 2.0) * srcRadius) * shineDir;
	mediump vec2 shineEnd = srcCenter + (srcRadius + (uSize * 2.0) * srcRadius) * shineDir;

	// get position of the shine
	mediump vec2 shinePos = shineStart + (uProgress * (shineEnd - shineStart));
	mediump vec2 diff = vTex - shinePos;
	mediump float projection = dot(diff, shineDir);
	mediump float shine =
						smoothstep(-shineRange * 0.5 - size, -shineRange * 0.5 - size * uHardness + 0.001, projection)
					- smoothstep(shineRange * 0.5 + size * uHardness - 0.001, shineRange * 0.5 + size, projection);

	// now, we mix the final color with the shine color and use the size and hardness value to determine if vTex is
	// inside the shine or not, and how smooth it is

	gl_FragColor = vec4(mix(image.rgb, uColor, image.a * uIntensity * shine), image.a);
}