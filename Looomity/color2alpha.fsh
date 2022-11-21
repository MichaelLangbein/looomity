uniform sampler2D colorSampler;
varying vec2 uv;

void main() {
    vec4 oldColor = texture2D(colorSampler, uv);
    float whiteness = (oldColor.x + oldColor.y + oldColor.z) / 3.0;
    vec4 newColor = vec4(oldColor.xyz, whiteness);
    gl_FragColor = newColor;
}
