module dreams.particles;

import dreams.view, dreams.imm3d;
import std.algorithm, std.math, std.random;
import log, matrix, vector;

struct Emitter
{
	Vec3f position;
	float minSize;
	float maxSize;
	float rate;
	
	// particles properties
	float minDuration, maxDuration;
	Vec3f velocity;
	float vibrationX; // randomize the initial velocity [0 .. 1]
	float vibrationY; // randomize the initial velocity [0 .. 1]
	float vibrationZ; // randomize the initial velocity [0 .. 1]
	float weight;
	float size;
	Vec4f color;

	// increased over time, when it exceed 1 a new particle is created
	private float generation = 0;
}

struct Particle
{
	float duration;
	Vec3f velocity;
	Vec3f position;
	float weight, size;
	byte[4] color;
}

final class ParticleSystem
{
private:
	Xorshift rnd; // fast source of random data
	Emitter*[] emitters;
	Particle[] particles;
	immutable int maxParticles;

public:
	Vec3f gravity = Vec3f(0, -9.81, 0);

	this()
	{
		rnd.seed(unpredictableSeed());
		maxParticles = 6000;
		particles.reserve(maxParticles);
	}

	void init()
	{
	}

	void shutdown()
	{
	}

	void addEmitter(Emitter* emitter)
	{
		emitters ~= emitter;
		emitter.generation = 0;
	}

	void removeEmitter(Emitter* emitter)
	{
		for (int i = 0; i < emitters.length; i++) {
			if (emitters[i] == emitter) {
				swap(emitters[i], emitters[$ - 1]);
				emitters.length--;
				return;
			}
		}
		assert(0, "ParticleSystem.removeEmitter: The specified emitter has not been found");
	}

	void update(float time)
	{
		// update particles
		for (int i = 0; i < particles.length; i++) {
			if (particles[i].duration <= 0) {
				swap(particles[i], particles[$ - 1]);
				particles.length--;
				continue;
			}
			particles[i].duration -= time;
			particles[i].velocity += gravity * particles[i].weight * time;
			particles[i].position += particles[i].velocity * time;
		}
		// create new particles from the emitters
		if (particles.length >= maxParticles) {
			dev("ParticleSystem.update: Max number of particles reached");
			return;
		}
		for (int i = 0; i < emitters.length; i++) {
			emitters[i].generation += emitters[i].rate * time;
			while (emitters[i].generation > 1) {
				particles ~= createParticle(emitters[i]);
				emitters[i].generation -= 1;
				if (particles.length >= maxParticles) return;
			}
		}
	}

	void draw(Immediate3D imm)
	{
		imm.setTexture(0);
		foreach (ref particle; particles) {
			imm.setColor(particle.color);
			imm.drawBillboard(particle.position, particle.size, particle.size);
		}
	}

	private Particle createParticle(const Emitter* emitter)
	{
		Particle p;
		p.duration = uniform!"[]"(emitter.minDuration, emitter.maxDuration, rnd);
		p.velocity = emitter.velocity;
		p.velocity = rotXMat3f(uniform!"[]"(-PI, PI, rnd) * emitter.vibrationX) * p.velocity;
		p.velocity = rotYMat3f(uniform!"[]"(-PI, PI, rnd) * emitter.vibrationY) * p.velocity;
		p.velocity = rotZMat3f(uniform!"[]"(-PI, PI, rnd) * emitter.vibrationZ) * p.velocity;
		p.position = randomPoint(emitter.position, emitter.minSize, emitter.maxSize);
		p.weight = emitter.weight;
		p.size = emitter.size;
		p.color[0] = cast(byte) (emitter.color[0] * byte.max);
		p.color[1] = cast(byte) (emitter.color[1] * byte.max);
		p.color[2] = cast(byte) (emitter.color[2] * byte.max);
		p.color[3] = cast(byte) (emitter.color[3] * byte.max);
		return p;
	}

	private Vec3f randomPoint(const ref Vec3f point, float min, float max)
	{
		Vec3f p = point;
		p.x = point.x + uniform!"[]"(min, max, rnd);
		p.y = point.y + uniform!"[]"(min, max, rnd);
		p.z = point.z + uniform!"[]"(min, max, rnd);
		return p;
	}

	/*private Vec3f randomVector()
	{
		float a = uniform!"[]"(-PI, PI, rnd);
		float b = uniform!"[]"(0, 2 * PI, rnd);
		float c0 = cos(a), s0 = sin(a);
		float c1 = cos(b), s1 = sin(b);
		return Vec3f(c0 * c1, s0, c0 * s1);
	}*/
}
