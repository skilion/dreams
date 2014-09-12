#version 110

attribute vec4 position;
attribute vec2 texcoord;
attribute vec4 color;

uniform mat4 mvp;

varying vec4 fragColor;
varying vec2 fragTexcoord;

void main()
{
	fragColor = color;
	fragTexcoord = texcoord;
	gl_Position = mvp * position;
}
