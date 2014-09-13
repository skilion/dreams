module dreams.effects;

import dreams.view;
import std.math, std.random;
import log, graphics, vector;

interface Effect
{
	bool update(float time); // returns false if the effect is finished
	void draw();
}

class Blank: Effect
{
	private GraphicsContext ctx;
	private Vec4f color;
	private float duration;

	this(GraphicsContext ctx, Vec4f color, float duration)
	{
		this.ctx = ctx;
		this.color = color;
		this.duration = duration;
	}

	bool update(float time)
	{
		duration -= time;
		return duration >= 0;
	}

	void draw()
	{
		ctx.setColor(color);
		ctx.drawFilledRect(0, 0, int.max, int.max);
	}
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

	bool update(float time)
	{
		this.time += time;
		return this.time <= duration;
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
	private float change; // if duration < change, all stars become colorful
	private static float minTime = 2.0f;
	private static float maxTime = 3.0f; // max time needed to reach full brightness

	private struct Star {
		int size;
		float time = 0;
		float x = -1, y = -1;
	}

	private Star[] stars;

	this(GraphicsContext ctx, uint count, float duration, float change)
	{
		assert(change < duration);
		this.ctx = ctx;
		this.duration = duration;
		this.change = change;
		stars = new Star[count];
	}

	bool update(float time)
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
		return duration >= 0;
	}

	void draw()
	{
		ctx.setColor(black);
		ctx.drawFilledRect(0, 0, int.max, int.max);
		foreach (ref star; stars) {
			if (duration > change) ctx.setColor(mix(white, black, star.time * (1 / maxTime)));
			else {
				immutable float s = 0.01f; // slowing factor
				float a = star.x * s;// * star.size;
				float b = star.y * s;// * star.size;
				float c = star.x * star.y * s * s;// * star.size;
				ctx.setColor(Vec4f(fabs(sin(a)), fabs(sin(b)), fabs(sin(c)), 1.0f));
			}
			ctx.drawFilledRect(cast(int) star.x, cast(int) star.y, star.size, star.size);
		}
	}

	private Star createStar(float width, float height)
	{
		Star star;
		star.size = dice(rnd, 0, 40, 30, 20, 10);
		star.time = uniform!"[]"(minTime, maxTime, rnd);
		star.x = uniform!"[]"(0, width, rnd);
		star.y = uniform!"[]"(0, height, rnd);
		return star;
	}
}

final class EffectSystem
{
	private Effect[] effects;

	this()
	{
		effects.reserve(16);
	}

	void push(Effect effect)
	{
		effects ~= effect;
	}

	void clear()
	{
		effects.length = 0;
	}

	void update(float time)
	{
		if (effects.length > 0) {
			if (!effects[0].update(time)) {
				effects = effects [1 .. $];
			}
		}
	}

	void draw()
	{
		if (effects.length > 0) {
			effects[0].draw();
		}
	}
}
