#version 110

uniform mat4 mvp;

attribute vec4 position;
attribute vec4 normal;
attribute vec2 texcoord;
attribute vec4 color;

varying vec2 fragTexcoord;
varying vec4 fragColor;

void main()
{
	fragTexcoord = texcoord;
	fragColor = color;
	gl_Position = mvp * position;
}
