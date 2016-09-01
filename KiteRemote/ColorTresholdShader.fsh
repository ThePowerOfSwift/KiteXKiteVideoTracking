varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform mediump float red;
uniform mediump float redGreen;
uniform mediump float redBlue;
//uniform mediump float threshold;

precision mediump float;

void main()
{
    float redGreenRatio, redBlueRatio;
    vec4 pixelColor, maskedColor, coordinateColor;
    
    pixelColor = texture2D(inputImageTexture, textureCoordinate);
    redGreenRatio = pixelColor.r / pixelColor.g;
    redBlueRatio = pixelColor.r / pixelColor.b;
    
    if (pixelColor.r > red && redGreenRatio > redGreen && redBlueRatio > redBlue) {
        gl_FragColor = vec4(pixelColor.r, 0, pixelColor.b, 1); //pixelColor;
    } else {
        gl_FragColor = vec4(0.0);
    }
}