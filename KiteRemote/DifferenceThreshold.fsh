varying highp vec2 textureCoordinate;
varying highp vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform highp float threshold;

void main()
{
    lowp vec3 currentImageColor = texture2D(inputImageTexture, textureCoordinate).rgb;
    lowp vec3 lowPassImageColor = texture2D(inputImageTexture2, textureCoordinate2).rgb;
    
    mediump float colorDistance = distance(currentImageColor, lowPassImageColor); // * 0.57735
    lowp float movementThreshold = step(threshold, colorDistance);
    
    gl_FragColor = movementThreshold * vec4(currentImageColor, 1.0);
}
