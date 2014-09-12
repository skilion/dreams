/*
  Frustum culling functions
*/

module dreams.culling;

import std.math;
import vector;

struct RadarTest
{
private:
	Vec3f position;
	Vec3f forward, side, up;
	float aspect;
	float near, far;
	float tang;
	float rfactorX, rfactorY;

public:
	void set(const ref Vec3f position, const ref Vec3f forward, const ref Vec3f side, const ref Vec3f up, float aspect, float near, float far, float fov)
	{
		this.position = position;
		this.forward = forward;
		this.side = side;
		this.up = up;
		this.aspect = aspect;
		this.near = near;
		this.far = far;
		tang = tan(fov * 0.5f);
		rfactorY = 1 / cos(fov * 0.5f);
		rfactorX = 1 / cos(atan(tang * aspect));
	}

	bool sphereTest(Vec3f center, float radius)
	{
		center -= position;

		float projz = center.dot(forward);
		if (projz + radius < near || projz - radius > far) {
			return false;
		}

		float projy = center.dot(up);
		float height = projz * tang;
		float radius2 = radius * rfactorY;
		if (projy + radius2 < -height || projy - radius2 > height) {
			return false;
		}

		float projx = center.dot(side);
		float width = height * aspect;
		float radius3 = radius * rfactorX;
		if (projx + radius3 < -width || projx - radius3 > width) {
			return false;
		}

		return true;
	}
}
