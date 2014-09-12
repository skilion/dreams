module game.aabox;

import vector;

struct Aabox
{
	Vec3f min;
	Vec3f max;

	void set(const ref Vec3f center, float extent)
	{
		min = center - extent;
		max = center + extent;
	}

	bool collisionTest(const ref Aabox aabox)
	{
		return (
			min.x <= aabox.max.x &&
			max.x >= aabox.min.x &&
			min.y <= aabox.max.y &&
			max.y >= aabox.min.y &&
			min.z <= aabox.max.z &&
			max.z >= aabox.min.z
		);
	}
}
