module dreams.particles;

import dreams.view, dreams.imm3d;
import std.algorithm, std.math, std.random;
import log, matrix, renderer, vector;

struct Emitter
{
	Vec3f position;
	float minSize;
	float maxSize;
	float rate;
	
	// particles properties
	float minDuration, maxDuration;
	Vec3f velocity;
	float vibrationX; // randomize the initial velocity around the X axis [0 .. 1]
	float vibrationY; // randomize the initial velocity around the Y axis [0 .. 1]
	float vibrationZ; // randomize the initial velocity around the Z axis [0 .. 1]
	float weight; // influence of the gravity of the particle system
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
	Vec2f particleSize = Vec2f(0.1f, 0.1f);
	Texture particleTexture;

	this(int maxParticles)
	{
		rnd.seed(unpredictableSeed());
		this.maxParticles = maxParticles;
		particles.reserve(maxParticles);
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
				assumeSafeAppend(emitters);
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
				assumeSafeAppend(particles);
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
		imm.setTexture(particleTexture);
		foreach (ref particle; particles) {
			imm.setColor(particle.color);
			imm.drawBillboard(particle.position, particleSize.x, particleSize.y);
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

final class ParticleManager
{
	private Immediate3D imm;
	private ParticleSystem[] systems;

	this(Immediate3D imm)
	{
		this.imm = imm;
	}

	void addParticleSystem(ParticleSystem system)
	{
		systems ~= system;
	}

	void removeParticleSystem(ParticleSystem system)
	{
		for (int i = 0; i < systems.length; i++) {
			if (systems[i] == system) {
				swap(systems[i], systems[$ - 1]);
				systems = systems[0 .. $ - 1];
				assumeSafeAppend(systems);
				return;
			}
		}
		assert(0, "ParticleManager.removeParticleSystem: The specified system has not been found");
	}

	void update(float time)
	{
		foreach (system; systems) {
			system.update(time);
		}
	}

	void draw()
	{
		foreach (system; systems) {
			system.draw(imm);
		}
	}

}
