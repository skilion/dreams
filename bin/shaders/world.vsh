#version 110

uniform mat4 mvp;

attribute vec4 position;
attribute vec4 normal;
attribute vec2 texcoord;

varying vec2 fragTexcoord;

void main()
{
	fragTexcoord = texcoord;
	gl_Position = mvp * position;
}