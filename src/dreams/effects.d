module dreams.effects;

import dreams.view;
import std.math, std.random;
import log, graphics, vector;

interface Effect
{
	void update(float time);
	void draw();
}

class Fade: Effect
{
	private GraphicsContext ctx;
	private Vec4f color0, color1;
	private float duration;
	private float time = 0;

	this(GraphicsContext ctx, Vec4f color0, Vec4f color1, float duration)
	{
		this.ctx = ctx;
		this.color0 = color0;
		this.color1 = color1;
		this.duration = duration;
	}

	void update(float time)
	{
		this.time += time;
	}

	void draw()
	{
		ctx.setColor(mix(color0, color1, fmin(time / duration, 1)));
		ctx.drawFilledRect(0, 0, int.max, int.max);
	}
}

class StarField: Effect
{
	private GraphicsContext ctx;
	private Xorshift rnd;
	private float duration; // no star is created if it's less than zero
	private static float maxTime = 3.0f; // max time needed to reach full brightness

	private struct Star {
		int size;
		float time;
		float x = float.max, y = float.max;
	}

	private Star[] stars;

	this(GraphicsContext ctx, uint count, float duration)
	{
		this.ctx = ctx;
		this.duration = duration;
		stars = new Star[count];
	}

	void update(float time)
	{
		int width, height;
		ctx.getSize(width, height);
		float w = width;
		float h = height;
		float halfWidth = w / 2;
		float halfHeight = h / 2;
		immutable float s = 0.01f; // slowing factor
		foreach (ref star; stars) {
			if (star.x < 0 || star.x > w || star.y < 0 || star.y > h) {
				if (duration >= 0) star = createStar(w, h);
			}
			star.time = fmax(0, star.time - time);
			star.x += (star.x - halfWidth) * s;
			star.y += (star.y - halfHeight) * s;
		}
		duration -= time;
	}

	void draw()
	{
		ctx.setColor(black);
		ctx.drawFilledRect(0, 0, int.max, int.max);
		foreach (ref star; stars) {
			ctx.setColor(mix(white, black, star.time * (1 / maxTime)));
			ctx.drawFilledRect(cast(int) star.x, cast(int) star.y, star.size, star.size);
		}
	}

	private Star createStar(float width, float height)
	{
		Star star;
		star.size = dice(rnd, 0, 40, 30, 20, 10);
		star.time = uniform!"[]"(maxTime - 1, maxTime, rnd);
		star.x = uniform!"[]"(0, width, rnd);
		star.y = uniform!"[]"(0, height, rnd);
		return star;
	}
}
