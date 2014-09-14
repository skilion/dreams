#version 110

uniform sampler2D texture;

varying vec2 fragTexcoord;
varying vec4 fragColor;

void main()
{
	vec4 sample = texture2D(texture, fragTexcoord);
	gl_FragColor = fragColor * sample;
}
