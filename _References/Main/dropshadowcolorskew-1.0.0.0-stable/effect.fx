/////////////////////////////////////////////////////////
// DropShad effect
// chrisbrobs2016

precision mediump float;
varying mediump vec2 vTex;
uniform lowp sampler2D samplerFront;
uniform mediump float pixelWidth;
uniform mediump float pixelHeight;
uniform mediump float Rescalefactor;
uniform vec2 srcOriginStart;
uniform vec2 srcOriginEnd;
uniform vec2 pixelSize;
uniform float blurAmount;          
uniform float shadowOpacity;
uniform lowp float red;    //0 to 100
uniform lowp float green;  //0 to 100
uniform lowp float blue;   //0 to 100
uniform mediump float xSkew; // -100 to 100

void main(void)
{  
  float pixelWidth = pixelSize.x;
  float pixelHeight = pixelSize.y;
  float srcHeight = srcOriginEnd.y - srcOriginStart.y;

  lowp vec4 front = texture2D(samplerFront, vTex);

  vec2 uv = vTex;   

  lowp float dist = distance(uv.y, 0.5*srcHeight+srcOriginStart.y);
  
  float normalizedRescalefactor = Rescalefactor*srcHeight+srcOriginStart.y;

  float pixelWidthS = pixelWidth * normalizedRescalefactor;

  if (uv.y >= normalizedRescalefactor)
{
  float RescaleAmount = mix(srcOriginStart.y,srcOriginEnd.y,(uv.y-(normalizedRescalefactor))/(srcOriginEnd.y- normalizedRescalefactor));
  
  // Skew based on height, requires shadow to start at bottom, invert based on Y (skew less at bottom, more at top)
  float invertYNormalized = 1.0 - (uv.y-srcOriginStart.y)/(srcOriginEnd.y-srcOriginStart.y);
  uv.x = uv.x+invertYNormalized*xSkew;
  
  uv = clamp(uv,srcOriginStart,srcOriginEnd);

  vec2 pos = vec2(uv.x,(RescaleAmount));
  
  // add a blur to shadow

  vec4 sum = vec4(0.0);

    
  sum += texture2D(samplerFront, pos.xy)*0.120;
  sum += texture2D(samplerFront, vec2(pos.x, pos.y - (pixelHeight*blurAmount)))*0.110;
  sum += texture2D(samplerFront, vec2(pos.x + (pixelWidthS*blurAmount), pos.y-(pixelHeight*blurAmount)))*0.110;
  sum += texture2D(samplerFront, vec2(pos.x + (pixelWidthS*blurAmount), pos.y))*0.110;
  sum += texture2D(samplerFront, vec2(pos.x + (pixelWidthS*blurAmount), pos.y + (pixelHeight*blurAmount)))*0.110;
  sum += texture2D(samplerFront, vec2(pos.x, pos.y + (pixelHeight*blurAmount)))*0.110;
  sum += texture2D(samplerFront, vec2(pos.x - (pixelWidthS*blurAmount), pos.y + (pixelHeight*blurAmount)))*0.110;
  sum += texture2D(samplerFront, vec2(pos.x - (pixelWidthS*blurAmount), pos.y))*0.110;
  sum += texture2D(samplerFront, vec2(pos.x - (pixelWidthS*blurAmount), pos.y -(pixelHeight*blurAmount)))*0.110;
 

  sum += texture2D(samplerFront, pos.xy);
 
  vec4 shadcolor = sum * vec4(0.,0.,0.,shadowOpacity);


  // smooth shadow at player base..needs tweaking//
  
  float Alpha = 1.0 - smoothstep(0.5*srcHeight+srcOriginStart.y-0.02,0.5*srcHeight+srcOriginStart.y-0.01,dist);

    if (Alpha == 0.0){
       // discard;
      }

  vec4 shadcolorTint = (shadcolor + vec4(red, green, blue,Alpha)*shadcolor.a )* (1. - front.a)+ front;
          
  gl_FragColor = shadcolorTint;
   
}
else
{

  gl_FragColor = front*front.a;
}
}


