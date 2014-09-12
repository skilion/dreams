#version 110

attribute vec4 position;
attribute vec4 color;

uniform mat4 mvp;

varying vec4 fragColor;

void main()
{
	fragColor = color;
	gl_Position = mvp * position;
}
