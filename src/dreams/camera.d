module dreams.camera;

import std.math;
import vector, input;

// First person shooter camera
struct FpsCamera
{
	float sensibility = 0.01f;
	short deltaX = 0, deltaY = 0;
	float pitch = 0, yaw = 0;
	Vec3f forward = Vec3f(0, 0, -1); // normalized

	// connect this to receive pointer events
	void onPointerMoveEvent(const PointerMoveEvent* event)
	{
		deltaX += event.x;
		deltaY += event.y;
	}

	// compute the forward vector
	void update()
	{
		// pitch
		pitch += deltaY * -sensibility;
		immutable float maxPitch = PI_2 - float.epsilon;
		if (pitch > maxPitch) pitch = maxPitch;
		if (pitch < -maxPitch) pitch = -maxPitch;

		// yaw
		yaw += deltaX * -sensibility;
		if (yaw > PI * 2) yaw = 0;
		if (yaw < 0) yaw = PI * 2 - float.epsilon;

		deltaX = deltaY = 0;

		with (forward) {
			x = -sin(yaw) * cos(pitch);
			y = sin(pitch);
			z = -cos(yaw) * cos(pitch);
		}
	}
}

struct ControlledFpsCamera
{
	private	short deltaX, deltaY;
	private float addPitch = 0, addYaw = 0;
	private Vec3f[] path;

	float sensibility = 0.01f;
	float pitch = 0, yaw = 0;
	float targetPitch = 0, targetYaw = 0;
	float lockAngle = 80 * PI / 180;
	float speed = 10;

	Vec3f position = Vec3f(0, 0, 0);
	Vec3f forward = Vec3f(0, 0, -1); // normalized

	// connect this to receive pointer events
	void onPointerMoveEvent(const PointerMoveEvent* event)
	{
		deltaX += event.x;
		deltaY += event.y;
	}

	void addPathNode(const Vec3f position)
	{
		path ~= position;
	}

	void clearPath()
	{
		path.length = 0;
	}

	void update(float time)
	{
		pitch += deltaY * -sensibility;
		yaw += deltaX * -sensibility;
		deltaX = deltaY = 0;

		if (path.length > 0) {
			pitch += addPitch * time;
			yaw += addYaw * time;
			addPitch -= addPitch * time;
			addYaw -= addYaw * time;
			/*pitch += addPitch;
			yaw += addYaw;
			addPitch = 0;
			addYaw = 0;*/
			if (pitch > targetPitch + lockAngle) pitch = targetPitch + lockAngle;
			if (pitch < targetPitch - lockAngle) pitch = targetPitch - lockAngle;
			if (yaw > targetYaw + lockAngle) yaw = targetYaw + lockAngle;
			if (yaw < targetYaw - lockAngle) yaw = targetYaw - lockAngle;
			Vec3f delta = (path[0] - position);
			float m = delta.magnitude();
			delta /= m;
			if (m < 0.25f) { // path node reached
				if (path.length > 1) {
					// rotate to point the next target
					// probably not the optimal way to to this ...
					Vec3f d2 = (path[1] - path[0]).normalize();
					addPitch = asin(d2.y - delta.y);
					addYaw = acos(Vec2f(delta.z, delta.x).dot(Vec2f(d2.z, d2.x)));
					addYaw = copysign(addYaw, delta.z * d2.x - delta.x * d2.z);
					targetPitch += addPitch;
					targetYaw += addYaw;
				}
				path = path[1 .. $];
			} else {
				position += delta * speed * time;
			}
		}

		computeForwardVector();
	}

	private void computeForwardVector()
	{
		with (forward) {
			x = -sin(yaw) * cos(pitch);
			y = sin(pitch);
			z = -cos(yaw) * cos(pitch);
		}
	}
}
