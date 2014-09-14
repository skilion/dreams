module dreams.entities;

import dreams.world;
import std.math;
import log, renderer, vector;

private immutable float g = 4 * 9.81; // gravity
private immutable float maxFallingTime = 1 / (0.015 * g); // minumum falling time that will break the game physics

struct Player
{
	enum Flag: uint {
		forward  = 0b000001,
		backward = 0b000010,
		left     = 0b000100,
		right    = 0b001000,
		noclip   = 0b010000
	}

	uint flags;
	float speed = 10;
	Vec3f position = Vec3f(0, 0, 0);
	Vec3f forward = Vec3f(0, 0, -1); // normalized
	float fallingTime = 0;

	void update(float time, World* world)
	{
		Vec3f distance = computeVelocity() * time;

		Vec3f newPosition = position;
		if (flags & Flag.noclip) {
			newPosition += distance;
		} else {
			// collision test with the world
			float d = 0.5f;
			WorldBlock b0, b1, b2, b3;
			// x
			if (distance.x != 0) {
				newPosition.x += distance.x;
				d = copysign(d, distance.x);
				b0 = world.getBlock(newPosition + Vec3f(d, 0.3f, 0));
				b1 = world.getBlock(newPosition + Vec3f(d, -0.7f, 0));
				b2 = world.getBlock(newPosition + Vec3f(d, -1.7f, 0));
				b3 = world.getBlock(newPosition + Vec3f(d, -2.7f, 0));
				if (b1.isOpaque() || b2.isOpaque() || b3.isOpaque()) {
					newPosition.x = position.x;
					// pass over obstacles
					if (b0.isTransparent() && b1.isTransparent() && b2.isTransparent() && b3.isOpaque()) {
						distance.y += 0.2f;
					}
				}
			}
			// z
			if (distance.z != 0) {
				newPosition.z += distance.z;
				d = copysign(d, distance.z);
				b0 = world.getBlock(newPosition + Vec3f(0, 0.3f, d));
				b1 = world.getBlock(newPosition + Vec3f(0, -0.7f, d));
				b2 = world.getBlock(newPosition + Vec3f(0, -1.7f, d));
				b3 = world.getBlock(newPosition + Vec3f(0, -2.7f, d));
				if (b1.isOpaque() || b2.isOpaque() || b3.isOpaque()) {
					newPosition.z = position.z;
					// pass over obstacles
					if (b0.isTransparent() && b1.isTransparent() && b2.isTransparent() && b3.isOpaque()) {
						distance.y += 0.2f;
					}
				}
			}
			// y
			newPosition.y += distance.y;
			b0 = world.getBlock(newPosition + Vec3f(0, 0, 0));
			b1 = world.getBlock(newPosition + Vec3f(0, -2.7f, 0));
			if (b0.isOpaque() || b1.isOpaque()) {
				newPosition.y = position.y;
				fallingTime = 0;
			} else {
				if (distance.y <= 0) {
					fallingTime += time;
					fallingTime = fmin(fallingTime, maxFallingTime);
				}
			}
		}

		// update position
		position = newPosition;

	}

	void setFlag(Flag flag)
	{
		flags |= flag;
	}

	void unsetFlag(Flag flag)
	{
		flags &= ~flag;
	}

	private Vec3f computeVelocity()
	{
		auto velocity = Vec3f(0, 0, 0);

		Vec3f forward;
		if ((flags & Flag.noclip)) {
			forward = this.forward;
		} else {
			forward.x = this.forward.dot(Vec3f(1, 0, 0));
			forward.y = 0;
			forward.z = this.forward.dot(Vec3f(0, 0, 1));
			forward.normalize();
			// gravity
			velocity += Vec3f(0, -g * fallingTime, 0);
		}

		immutable auto up = Vec3f(0, 1, 0);
		Vec3f v = Vec3f(0, 0, 0);
		if (flags & Flag.forward) {
			v += forward * speed;
		}
		if (flags & Flag.backward) {
			v -= forward * speed;
		}
		if (flags & Flag.left) {
			v += up.cross(forward).normalize() * speed;
		}
		if (flags & Flag.right) {
			v += forward.cross(up).normalize() * speed;
		}
		velocity += v;

		return velocity;
	}
}
