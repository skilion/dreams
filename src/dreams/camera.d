module dreams.camera;

import std.math;
import vector;
import input;

// First person shooter camera
struct FpsCamera
{
	float sensibility = 0.01f;
	short deltaX = 0, deltaY = 0;
	float pitch = 0, yaw = 0;
	Vec3f forward = Vec3f(0, 0, -1); // normalized

	// Connect this to receive pointer events
	void onPointerMoveEvent(const PointerMoveEvent* event)
	{
		deltaX += event.x;
		deltaY += event.y;
	}

	// Compute the forward vector
	void update()
	{
		// Pitch
		pitch += deltaY * -sensibility;
		immutable float maxPitch = PI_2 - float.epsilon;
		if (pitch > maxPitch) pitch = maxPitch;
		if (pitch < -maxPitch) pitch = -maxPitch;

		// Yaw
		yaw += deltaX * -sensibility;
		if (yaw > PI * 2) yaw = 0;
		if (yaw < 0) yaw = PI * 2 - float.epsilon;

		deltaX = deltaY = 0;

		with (forward)
		{
			x = -sin(yaw) * cos(pitch);
			y = sin(pitch);
			z = -cos(yaw) * cos(pitch);
		}
	}
}
