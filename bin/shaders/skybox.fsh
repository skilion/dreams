#version 110

uniform sampler2D texture;

varying vec2 fragTexcoord;

void main()
{
	vec4 sample = texture2D(texture, fragTexcoord);
	gl_FragColor = sample;
	gl_FragDepth = 1.0;
}
