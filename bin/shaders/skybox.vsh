#version 110

attribute vec4 position;
attribute vec2 texcoord;

uniform mat4 mvp;

varying vec2 fragTexcoord;

void main()
{
	fragTexcoord = texcoord;
	gl_Position = mvp * position;
}
