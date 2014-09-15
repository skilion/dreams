module dreams.particles;

import dreams.view, dreams.imm3d;
import std.algorithm, std.random;
import log, vector;

struct Emitter
{
	Vec3f position;
	float minSize;
	float maxSize;
	float rate;

	float minDuration; // duration of each particle
	float maxDuration;
	Vec3f velocity; // initial particles velocity

	private float generation; // increased over time, when it exceed 1  a new particle is created
}

struct Particle
{
	float duration;
	Vec3f velocity;
	Vec3f position;
	byte[4] color;
}

final class ParticleSystem
{
	private auto rnd = Xorshift(1); // source of random data
	private Emitter*[] emitters;
	private Particle[] particles;

	Vec3f gravity;
	immutable int maxParticles;

	this()
	{
		maxParticles = 1000;
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
		assert(emitters.length > 0, "ParticleSystem.removeEmitter: The system does not contain any emitter");
		for (int i = 0; i < emitters.length; i++) {
			if (emitters[i] == emitter) {
				swap(emitters[i], emitters[$ - 1]);
				emitters.length--;
				return;
			}
		}
		assert(0, "ParticleSystem.removeEmitter: The emitter has not been found");
	}

	void update(float time)
	{
		// update particles
		for (int i = 0; i < particles.length; i++) {
			if (particles[i].duration <= 0) {
				swap(particles[i], particles[$ - 1]);
				particles.length--;
			}
			particles[i].duration -= time;
			particles[i].velocity += gravity * time;
			particles[i].position += particles[i].velocity * time;
		}
		// create new particles from the emitters
		if (particles.length >= maxParticles) {
			//dev("ParticleSystem.update: Max number of particles reached");
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
			imm.drawBillboard(particle.position, 0.05, 0.05);
		}
	}

	private Particle createParticle(const Emitter* emitter)
	{
		Particle p;
		p.duration = uniform!"[]"(emitter.minDuration, emitter.maxDuration, rnd);
		p.velocity = emitter.velocity;
		p.position = randomPoint(emitter.position, emitter.minSize, emitter.maxSize);
		p.color = [127, 0, 0, 127];
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
}
