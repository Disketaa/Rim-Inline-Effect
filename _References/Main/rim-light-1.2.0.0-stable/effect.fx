/////////////////////////////////////////////////////////
// RimLight
// By Richard Lems, modified by Federico Calchera
/////////////////////////////////////////////////////////

uniform mediump float s; // size
uniform mediump float d; // intensity
uniform mediump float angl; // angle in degrees
uniform lowp vec3 clr; // color

//The current foreground texture co-ordinate
varying mediump vec2 vTex;
//The foreground texture sampler, to be sampled at vTex
uniform lowp sampler2D samplerFront;
//The current foreground source rectangle being rendered
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
//The current foreground source rectangle being rendered, in layout 
uniform mediump vec2 layoutStart;
uniform mediump vec2 layoutEnd;
//default precision
precision mediump float;

void main(void)
{	
	//rotate angle if flipped on spritesheet and convert to radians
   float angle = radians(angl * (1.0 - 2.0 * float(srcOriginStart.y > srcOriginEnd.y)));
    
    // multiply the size with the texel size 
	vec2 layoutSize = abs(vec2(layoutEnd.x - layoutStart.x, (layoutEnd.y - layoutStart.y))); 
	vec2 texelSize = abs(srcOriginEnd - srcOriginStart) / layoutSize;
	vec2 size = texelSize * s;
	
	// calculate the outline value using the sprite texture and angle uniform
	float outline = texture2D(samplerFront, vTex + vec2(cos(angle) * size.x, sin(angle) * size.y)).a;
	
	// "invert"
	outline = 1.0 - outline;
	
	// get sprite texture
	vec4 front = texture2D(samplerFront, vTex);
	
	// clip to sprite alpha
	float rim = outline * front.a * d;
	
	// add everything together
	gl_FragColor = front + vec4(rim * clr, 0.0);
}