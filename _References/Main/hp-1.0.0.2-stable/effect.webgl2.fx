#version 300 es
/////////////////////////////////////////////////////////
// hp_fx spokoinbli

in mediump vec2 vTex;
out lowp vec4 outColor;

#ifdef GL_FRAGMENT_PRECISION_HIGH
#define highmedp highp
#else
#define highmedp mediump
#endif

precision lowp float;
uniform lowp sampler2D samplerFront;
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
uniform mediump float width;
uniform mediump float height;
uniform mediump float positionY;
uniform mediump float opacity;
uniform mediump float progress;
uniform mediump float progressMax;
uniform mediump float opacityBg;
uniform mediump float outlineBg;
uniform mediump vec3 colorHp;
uniform mediump vec3 colorBg;

void main( void ) {
   vec2 uv = (vTex-srcOriginStart) / (srcOriginEnd - srcOriginStart);

   float m = progress - progressMax * floor(progress/progressMax);
   float w =  (1.-width)/2.;
   float x =  uv.x ;
   float y =  uv.y ;
   outColor = texture(samplerFront, vTex);
   if(x > w-outlineBg  && x <   1.-w+outlineBg  && y > positionY-outlineBg && y < positionY+height+outlineBg) 
	
		 outColor = vec4(vec3(colorBg)*opacityBg, opacityBg);
		
   if(x > w  && x - w  < (m/progressMax)*(1.-(w*2.)) && y > positionY && y < positionY+height) 
		 
	  outColor = vec4(vec3(colorHp)*opacity, opacity);
	
}