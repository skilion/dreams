#version 110

uniform vec4 fixedColor;
uniform sampler2D texture;

varying vec4 fragColor;
varying vec2 fragTexcoord;

void main()
{
	vec4 sample = texture2D(texture, fragTexcoord);
	vec4 mixColor = fragColor * fixedColor;
	gl_FragColor = vec4(mixColor.rgb, mixColor.a * sample.r);
}
