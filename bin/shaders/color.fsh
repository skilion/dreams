#version 110

uniform vec4 fixedColor;

varying vec4 fragColor;

void main()
{
	gl_FragColor = fragColor * fixedColor;
}
