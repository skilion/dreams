module dreams.demo;

import std.algorithm, std.conv, std.math, std.random;
import dreams.camera, dreams.editor, dreams.effects, dreams.entities;
import dreams.imm3d, dreams.noise, dreams.particles, dreams.skybox;
import dreams.view, dreams.world, dreams.world_renderer;
import audio, cstr, engine, graphics, input;
import log, matrix, renderer, vector;

private immutable wordFilename = "world.z";

private immutable Vec4f[4] fireworkColors = [
	Vec4f(1.0f, 0.2f, 0.2f, 0.8f),
	Vec4f(0.6f, 1.0f, 0.8f, 0.8f),
	Vec4f(0.9f, 0.8f, 0.1f, 0.8f),
	Vec4f(0.9f, 0.8f, 0.5f, 0.8f)
];

final class Demo: Engine
{
private:
	Xorshift rnd;
	GraphicsContext ctx;
	Font smallFont, defaultFont;
	Immediate3D imm;

	World world;
	WorldRenderer worldRenderer;
	Skybox skybox;

	Player player;
	FpsCamera freeCamera;
	ControlledFpsCamera camera;
	
	EffectSystem ef;
	ParticleManager pm;
	ParticleSystem fireworksParticleSystem;
	ParticleSystem rainParticleSystem;
	Emitter rainEmitter;

	enum State {
		edit,
		playing,
	}
	State state;

	// demo variables
	struct Firework { // simply an emitter with specific life
		Emitter* emitter;
		float delay, life;
	}
	Sound mainMusic;
	Source mainMusicSource;
	float cumulativeTime = 0;
	int demoState = 0;
	Firework[] fireworks;

	// editor variables
	enum EditMode {
		add,
		select,
		paint
	}
	Editor editor;
	EditMode editMode;
	ubyte textureId;
	bool selecting;
	byte ctrl; // true if ctrl is pressed
	uint[3] point; // where the player is pointing
	uint[3] selectionStart, selectionEnd;

public:
	this()
	{
		super("");
		rnd.seed(unpredictableSeed());
		ctx = new GraphicsContext(super.renderer);
		imm = new Immediate3D(super.renderer);
		worldRenderer = new WorldRenderer(super.renderer);
		ef = new EffectSystem();
		pm = new ParticleManager(imm);
		fireworksParticleSystem = new ParticleSystem(2000);
		rainParticleSystem = new ParticleSystem(300);

		fireworksParticleSystem.particleSize = Vec2f(0.5f, 0.5f);
		rainParticleSystem.particleSize = Vec2f(0.02f, 0.8f);
		rainEmitter.minSize = -20;
		rainEmitter.maxSize = 20;
		rainEmitter.rate = 500;
		rainEmitter.minDuration = 0.5f;
		rainEmitter.maxDuration = 0.5f;
		rainEmitter.velocity = Vec3f(0, -40, 0);
		rainEmitter.vibrationX = 0;
		rainEmitter.vibrationY = 0;
		rainEmitter.vibrationZ = 0;
		rainEmitter.weight = 1;
		rainEmitter.color = Vec4f(0.6f, 0.8f, 0.9f, 0.5f);
	}

	~this()
	{
		destroy(fireworksParticleSystem);
		destroy(rainParticleSystem);
		destroy(pm);
		destroy(ef);
		destroy(worldRenderer);
		destroy(imm);
		destroy(ctx);
	}

	override void init()
	{
		super.init();
		ctx.init();
		imm.init();
		worldRenderer.init();
		skybox.init(renderer);

		input.connect(&onKeyEvent);
		input.connect(&onMouseButtonEvent);
		input.connect(&freeCamera.onPointerMoveEvent);
		input.connect(&camera.onPointerMoveEvent);

		smallFont = ctx.createFont("FSEX300.ttf", 12, false);
		defaultFont = ctx.createFont("FSEX300.ttf", 16, false);

		mainMusic = new Sound("music.ogg", true);
		mainMusicSource = audio.getSource();
		mainMusicSource.setSound(mainMusic);

		//rainParticleSystem.particleTexture = renderer.loadTexture("rain.png", TextureFilter.trilinear, TextureWrap.clamp);
		pm.addParticleSystem(fireworksParticleSystem);
		pm.addParticleSystem(rainParticleSystem);

		// editor camera
		player.setFlag(Player.Flag.noclip);
		player.position = Vec3f(769.5f, 256, 1006);
		freeCamera.yaw = 0 * PI / 180;

		load(wordFilename);
		worldRenderer.setWorldRoot(world.root);
		editor = new Editor(world.root);

		// --------------------------
		setState(State.edit);
		skybox.texnum = 1;
		// --------------------------

		// start with a black screen
		if (state == State.playing) ef.push(new Blank(ctx, black, 1000));

		// run gc before starting
		core.memory.GC.collect();
	}

	override void shutdown()
	{
		pm.removeParticleSystem(rainParticleSystem);
		pm.removeParticleSystem(fireworksParticleSystem);
		renderer.destroyTexture(rainParticleSystem.particleTexture);
		destroy(editor);
		destroy(world);
		ctx.destroyFont(defaultFont);
		ctx.destroyFont(smallFont);
		input.disconnect(&onKeyEvent);
		input.disconnect(&onMouseButtonEvent);
		input.disconnect(&freeCamera.onPointerMoveEvent);
		input.disconnect(&camera.onPointerMoveEvent);
		skybox.shutdown();
		worldRenderer.shutdown();
		imm.shutdown();
		ctx.shutdown();
		super.shutdown();
	}

	override void render()
	{
		int width, height; bool fullscreen;
		renderer.getDisplayMode(width, height, fullscreen);
		View view;
		view.fov = 80 * PI / 180;
		view.aspect = width / cast(float) height;
		view.near = 0.1;
		view.far = 200;
		final switch (state) {
		case State.edit:
			view.position = player.position;
			view.forward = player.forward;
			break;
		case State.playing:
			view.position = camera.position;
			view.forward = camera.forward;
			break;
		}
		view.side = view.forward.cross(Vec3f(0, 1, 0)).normalize();
		view.up = view.side.cross(view.forward);
		view.computeViewProjectionMatrix();

		// world
		worldRenderer.setView(view);
		worldRenderer.render();
		skybox.render(view);

		// entities
		imm.setView(view);
		pm.draw();

		// 2D effects
		ef.draw();

		// editor
		if (state == State.edit) {
			// world limits
			imm.setColor(white);
			imm.drawWireframeBlock(0, 0, 0, 1024, 1024, 1024);
			// selection box
			Vec3f a, b;
			foreach (i; 0 .. 3) {
				if (selectionStart[i] < selectionEnd[i]) {
					a[i] = selectionStart[i] - 0.01f;
					b[i] = selectionEnd[i] + 1.01f;
				} else {
					a[i] = selectionEnd[i] - 0.01f;
					b[i] = selectionStart[i] + 1.01f;
				}
			}
			imm.setColor(blue);
			imm.drawWireframeBlock(a.x, a.y, a.z, b.x, b.y, b.z);
			imm.setColor(Vec4f(0.3f, 0.3f, 0.8f, 0.5f));
			imm.drawBlock(a.x, a.y, a.z, b.x, b.y, b.z);
			a += 0.51f;
			imm.drawBasis(a);
			// user interface
			drawUI();
		}
		imm.flush();
		ctx.flush();
	}

	override void update(float time)
	{
		final switch (state) {
		case State.edit:
			freeCamera.update();
			player.forward = freeCamera.forward;
			player.update(time, &world);
			break;
		case State.playing:
			demoManager(time);
			camera.update(time);
			break;
		}
		pm.update(time);
		ef.update(time);

		// update fireworks
		for (int i = 0; i < fireworks.length; i++) {
			if (fireworks[i].delay == -1000) { // ugly time hack
				if (fireworks[i].life <= 0) {
					fireworksParticleSystem.removeEmitter(fireworks[i].emitter);
					swap(fireworks[i], fireworks[$ - 1]);
					fireworks.length--;
					continue;
				}
				fireworks[i].life -= time;
			} else {
				fireworks[i].delay -= time;
				if (fireworks[i].delay <= 0) {
					fireworksParticleSystem.addEmitter(fireworks[i].emitter);
					fireworks[i].delay = -1000;
				}
			}
		}

		// set the rain emitter always over the camera
		rainEmitter.position = camera.position;
		rainEmitter.position.y += 20;

		if (state == State.edit) {
			// editor selection
			uint[3] face;
			world.rayCollisionTest(player.position, player.forward, 32, point, face);
			if (editMode == EditMode.add) point[] += face[];
			if (selecting) {
				selectionEnd = point;
			} else {
				if (editMode != EditMode.select) selectionStart = selectionEnd = point;
			}
		}
	}

	void onKeyEvent(const KeyEvent* keyEvent)
	{
		if (state == State.playing) return; // nothing to do

		// free camera movement
		switch (keyEvent.symbol) {
		case KeySymbol.k_w:
			if (keyEvent.type == KeyEvent.Type.press) player.setFlag(Player.Flag.forward);
			else player.unsetFlag(Player.Flag.forward);
			break;
		case KeySymbol.k_s:
			if (keyEvent.type == KeyEvent.Type.press) player.setFlag(Player.Flag.backward);
			else player.unsetFlag(Player.Flag.backward);
			break;
		case KeySymbol.k_a:
			if (keyEvent.type == KeyEvent.Type.press) player.setFlag(Player.Flag.left);
			else player.unsetFlag(Player.Flag.left);
			break;
		case KeySymbol.k_d:
			if (keyEvent.type == KeyEvent.Type.press) player.setFlag(Player.Flag.right);
			else player.unsetFlag(Player.Flag.right);
			break;
		default:
		}

		switch (keyEvent.symbol) {
		case KeySymbol.k_e: // change edit mode
			if (keyEvent.type == KeyEvent.Type.press) {
				editMode++;
				if (editMode > EditMode.max) {
					editMode = EditMode.min;
				}
			}
			break;
		case KeySymbol.k_space: // increase speed
			if (keyEvent.type == KeyEvent.Type.press) {
				player.speed = 50;
			} else {
				player.speed = 10;
			}
			break;
		case KeySymbol.k_r: // fill with procedural content
			if (keyEvent.type == KeyEvent.Type.press) {
				uint[3] min, max;
				selectionToMinMax(min, max);
				editor.procedural(min, max, WorldBlock(1, textureId));
			}
			break;
		case KeySymbol.k_delete: // copy
			if (keyEvent.type == KeyEvent.Type.press) {
				uint[3] min, max;
				selectionToMinMax(min, max);
				editor.edit(min, max, WorldBlock());
			}
			break;
		case KeySymbol.k_c: // copy
			if (keyEvent.type == KeyEvent.Type.press && ctrl) {
				uint[3] min, max;
				selectionToMinMax(min, max);
				editor.copy(min, max);
			}
			break;
		case KeySymbol.k_v: // paste
			if (keyEvent.type == KeyEvent.Type.press && ctrl) {
				editor.paste(selectionStart);
			}
			break;
		case KeySymbol.k_z: // undo
		case KeySymbol.k_backspace: // undo
			if (keyEvent.type == KeyEvent.Type.press && ctrl) {
				editor.undo();
			}
			break;
		case KeySymbol.k_y: // redo
			if (keyEvent.type == KeyEvent.Type.press && ctrl) {
				editor.redo();
			}
			break;
		case KeySymbol.k_f2: // reset renderer
			if (keyEvent.type == KeyEvent.Type.press) {
				world.root.shrink();
				core.memory.GC.collect();
				worldRenderer.destroyAllMeshes();
			}
			break;
		case KeySymbol.k_f3: // toggle fly
			if (keyEvent.type == KeyEvent.Type.press) {
				player.flags ^= Player.Flag.noclip;
			}
			break;
		case KeySymbol.k_f5: // save
			if (keyEvent.type == KeyEvent.Type.release) {
				world.save(wordFilename);
				dev("world saved");
			}
			break;
		case KeySymbol.k_f8: // load
			if (keyEvent.type == KeyEvent.Type.release) {
				load(wordFilename);
				dev("world loaded");
			}
			break;
		/*case KeySymbol.k_f11: // new world
			if (keyEvent.type == KeyEvent.Type.release) {
				world = new World(5);
				worldRenderer.setWorldRoot(world.root);
				editor = new Editor(world.root);
			}
			break;*/
		case KeySymbol.k_lctrl:
			if (keyEvent.type == KeyEvent.Type.release) ctrl = false;
			else ctrl = true;
			break;
		default:
		}
	}

	void onMouseButtonEvent(const MouseButtonEvent* event)
	{
		if (state == State.playing) return;

		switch (event.button) {
		case MouseButton.left:
			if (event.type == MouseButtonEvent.Type.press) {
				selecting = true;
				if (editMode == EditMode.select) {
					selectionStart = selectionEnd = point;
				}
			} else {
				selecting = false;
				if (editMode == EditMode.add || editMode == EditMode.paint) {
					uint[3] min, max;
					selectionToMinMax(min, max);
					editor.edit(min, max, WorldBlock(1, textureId));
				}
			}
			break;
		case MouseButton.middle:
			textureId = world.root.getBlock(point[0], point[1], point[2]).tex;
			break;
		case MouseButton.scrollUp:
			if (textureId < 255) textureId++;
			break;
		case MouseButton.scrollDown:
			if (textureId > 0) textureId--;
			break;
		default:
		}
	}

	private void setState(State state)
	{
		this.state = state;
		if (state == State.playing) {
			demoState = 0;
		}
	}

	/*
		Launches the correct events at the right time
	*/
	void demoManager(float time)
	{
		if (demoState == 0) {
			immutable float sec = 122; // DEV: jump to precise moment
			mainMusicSource.seekTime(sec);
			cumulativeTime = sec;
			mainMusicSource.play();
		}
		cumulativeTime += time;
		if (cumulativeTime <= 8.8f) {
			if (demoState != 1) {
				demoState = 1;
				ef.clear();
				ef.push(new Blank(ctx, black, 0.1f));
				ef.push(new Fade(ctx, black, white, 0.5f));
				ef.push(new Fade(ctx, white, black, 3.8f));
				ef.push(new Fade(ctx, black, white, 0.5f));
				ef.push(new Fade(ctx, white, black, 4.0f));
				// begin preloading chunks
				camera.position = Vec3f(135.5f, 516, 0.5f);
				camera.yaw = 180 * PI / 180;
			}
		} else if (cumulativeTime <= 17.5f) {
			if (demoState != 2) {
				demoState = 2;
				ef.clear();
				immutable c1 = Vec4f(0, 0.6f, 0.85f, 1.0f);
				immutable c2 = Vec4f(0.1f, 0.7f, 0.3f, 1.0f);
				ef.push(new Fade(ctx, black, c1, 0.8f));
				ef.push(new Fade(ctx, c1, black, 3.5f));
				ef.push(new Fade(ctx, black, c2, 0.5f));
				ef.push(new Fade(ctx, c2, black, 4.0f));
				ef.push(new Blank(ctx, black, 1000));
			}
		} else if (cumulativeTime <= 34) {
			if (demoState != 3) {
				demoState = 3;
				ef.clear();
				ef.push(new Fade(ctx, black, white, 0.5f));
				ef.push(new Fade(ctx, white, black, 0.5f));
				ef.push(new StarField(ctx, 100, 17, 7.8f));
			}
		} else if (cumulativeTime <= 85.8f) {
			if (demoState != 4) {
				demoState = 4;
				ef.clear();
				ef.push(new Fade(ctx, black, white, 0.5f));
				ef.push(new Fade(ctx, white, transparent, 0.5f));
				skybox.texnum = 0;
				camera.position = Vec3f(135.5f, 516, 0.5f);
				camera.yaw = camera.targetYaw = 180 * PI / 180;
				camera.clearPath();
				camera.addPathNode(Vec3f(135.5f, 516, 355));
				camera.addPathNode(Vec3f(143, 516, 372));
				camera.addPathNode(Vec3f(149, 516, 376));
				camera.addPathNode(Vec3f(159, 516, 380.5f));
				camera.addPathNode(Vec3f(305, 516, 380.5f));
			}
		} else if (cumulativeTime <= 86.4f) {
			if (demoState != 5) {
				demoState = 5;
				ef.clear();
				ef.push(new Fade(ctx, transparent, black, 0.5f));
				ef.push(new Blank(ctx, black, 1000));
			}
		} else if (cumulativeTime <= 122) {
			if (demoState != 6) {
				demoState = 6;
				ef.clear();
				ef.push(new Fireflies(ctx, 18));
				ef.push(new Fireflies2(ctx, Vec4f(1, 0.8f, 0.5f, 1), Vec2f(25, 25), 1));
				ef.push(new Fireflies2(ctx, Vec4f(1, 0.5f, 0.15f, 1), Vec2f(-50, -50), 1));
				ef.push(new Blank(ctx, black, 2.5f));
				ef.push(new Fireflies2(ctx, Vec4f(0.7f, 0.9f, 0.1f, 1), Vec2f(25, -25), 1));
				ef.push(new Fireflies2(ctx, Vec4f(0.1f, 0.7f, 0.3f, 1), Vec2f(-50, 50), 1));
				ef.push(new Blank(ctx, black, 2.3f));
				ef.push(new Fireflies2(ctx, Vec4f(0.6f, 0.85f, 0.9f, 1), Vec2f(25, 25), 1));
				ef.push(new Fireflies2(ctx, Vec4f(0, 0.6f, 0.9f, 1), Vec2f(-50, -50), 1));
				ef.push(new Blank(ctx, black, 2.2f));
				ef.push(new Fireflies2(ctx, Vec4f(1, 0.6f, 0.1f, 1), Vec2f(25, -25), 1));
				ef.push(new Fireflies2(ctx, Vec4f(0.95f, 0.25f, 0.15f, 1), Vec2f(-50, 50), 1));
				ef.push(new Blank(ctx, black, 1000));
				// begin preloading chunks for the next event
				camera.position = Vec3f(769.5f, 256, 1006);
				camera.yaw = camera.targetYaw = 0;
			}
		} else if (cumulativeTime <= 126.5f) {
			if (demoState != 7) {
				demoState = 7;
				ef.clear();
				ef.push(new Fade(ctx, black, transparent, 0.5f));
				skybox.texnum = 1;
				camera.position = Vec3f(769.5f, 256, 1006);
				camera.yaw = camera.targetYaw = 0;
				camera.clearPath();
				camera.addPathNode(Vec3f(769.5f, 256, 980));
				camera.addPathNode(Vec3f(770.0f, 260, 920));
				camera.addPathNode(Vec3f(769.5f, 260, 800));
				camera.addPathNode(Vec3f(769.5f, 256, 750));
				camera.addPathNode(Vec3f(769.5f, 256, 400));
			}
		} else if (cumulativeTime <= 131) {
			if (demoState != 8) {
				demoState++;
				launchFireworks(Vec3f(670, 250, 800), Vec3f(870, 300, 900), 10);
			}
		} else if (cumulativeTime <= 135) {
			if (demoState != 9) {
				demoState++;
				launchFireworks(Vec3f(670, 250, 720), Vec3f(870, 300, 880), 10);
			}
		} else if (cumulativeTime <= 139.5f) {
			if (demoState != 10) {
				demoState++;
				launchFireworks(Vec3f(670, 250, 750), Vec3f(870, 300, 850), 10);
			}
		} else if (cumulativeTime <= 144) {
			if (demoState != 11) {
				demoState++;
				launchFireworks(Vec3f(670, 260, 650), Vec3f(870, 310, 850), 10);
			}
		} else if (cumulativeTime <= 157.2f) {
			if (demoState != 12) {
				demoState++;
				launchFireworks(Vec3f(670, 260, 600), Vec3f(870, 310, 800), 10);
			}
		} else if (cumulativeTime <= 175) {
			if (demoState != 13) {
				demoState++;
				rainParticleSystem.addEmitter(&rainEmitter);
			}
		} else if (cumulativeTime <= 200) {
			if (demoState != 14) {
				demoState++;
				ef.push(new Fade(ctx, black, white, 1.0f));
			}
		}
	}

	private void load(string filename)
	{
		world.load(filename);
		worldRenderer.destroyAllMeshes();
		worldRenderer.setWorldRoot(world.root);
		destroy(editor);
		editor = new Editor(world.root);
	}

	private void drawUI()
	{
		if (state == State.edit) drawEditorUI();
		ctx.pushClipRect(10, 30, 1000, 1000);
		drawUIStringSmall(itoa(super.fps), 0, 0);
		drawUIStringSmall("rendering time: " ~ to!string(super.renderingTime), 0, 18);
		drawUIStringSmall("frame time: " ~ to!string(super.frameTime), 0, 18 * 2);
		drawUIStringSmall("chunk mesh mem: " ~ to!string(worldRenderer.chunkMeshMem / (2 ^^ 20)), 0, 18 * 3);
		drawUIStringSmall("chunk mesh count: " ~ to!string(worldRenderer.chunkMeshCount), 0, 18 * 4);
		drawUIStringSmall(to!string(player.position.array), 0, 18 * 5);
		ctx.popClipRect();
	}

	private void drawEditorUI()
	{
		ctx.pushClipRect(10, 10, 1000, 1000);
		drawUIString("EDIT MODE", 0, 0);
		ctx.popClipRect();
		int width, height; bool fullscreen;
		renderer.getDisplayMode(width, height, fullscreen);
		// help
		ctx.pushClipRect(10, height - 90, 1000, 90);
		drawUIStringSmall("E = change edit mode (" ~ to!string(editMode) ~ ")", 0, 0);
		drawUIStringSmall("SPACE = increase speed    R = fill with procedural", 0, 25);
		drawUIStringSmall("F2 = reset renderer    F3 = toggle fly    F5 = save    F8 = load", 0, 50);
		ctx.popClipRect();
		// texture
		immutable float tileSize = 16 / 256.0f;
		float s = textureId % 16 * tileSize;
		float t = textureId / 16 * tileSize;
		ctx.pushClipRect(width - 100, height - 100, 100, 100);
		ctx.setColor(orange);
		ctx.drawFilledRect(0, 0, 90, 90);
		ctx.setColor(white);
		ctx.setTexture(worldRenderer.worldTexture);
		ctx.drawTexturedRect(1, 1, 88, 88, s, t, s + tileSize, t + tileSize);
		drawUIStringSmall(itoa(textureId), 3, 3);
		ctx.popClipRect();
	}

	private void drawUIString(const(char)[] str, int x, int y)
	{
		ctx.setColor(black);
		ctx.drawString(defaultFont, str, x, y);
		ctx.setColor(white);
		ctx.drawString(defaultFont, str, x + 1, y + 1);
	}

	private void drawUIStringSmall(const(char)[] str, int x, int y)
	{
		ctx.setColor(black);
		ctx.drawString(smallFont, str, x, y);
		ctx.setColor(white);
		ctx.drawString(smallFont, str, x + 1, y + 1);
	}

	private void selectionToMinMax(out uint[3] min, out uint[3] max)
	{
		foreach (i; 0 .. 3) {
			if (selectionStart[i] < selectionEnd[i]) {
				min[i] = selectionStart[i];
				max[i] = selectionEnd[i] + 1;
			} else {
				min[i] = selectionEnd[i];
				max[i] = selectionStart[i] + 1;
			}
		}
	}

	private void launchFireworks(Vec3f min, Vec3f max, int count)
	{
		for (int i = 0; i < count; i++) {
			createFirework(
				Vec3f(
					uniform(min[0], max[0], rnd),
					uniform(min[1], max[1], rnd),
					uniform(min[2], max[2], rnd)
				)
			);
		}
	}

	private void createFirework(Vec3f position)
	{
		auto e = new Emitter;
		e.position = position;
		e.minSize = 0;
		e.maxSize = 0.1;
		e.rate = 1000;
		int n = uniform(0, 2, rnd);
		e.minDuration = 2.5f;
		e.maxDuration = 4;
		switch (uniform(0, 2, rnd)) {
		case 0:
			e.velocity = Vec3f(20, 0, 0);
			e.vibrationX = 1;
			e.vibrationY = 1;
			e.vibrationZ = 1;
			e.weight = 0;
			break;
		default:
			e.velocity = Vec3f(0, 25, 0);
			e.vibrationX = 0.3f;
			e.vibrationY = 1;
			e.vibrationZ = 0;
			e.weight = 1;
			break;
		}
		e.color = fireworkColors[uniform(0, fireworkColors.length, rnd)];
		fireworks ~= Firework(e, uniform01(rnd), 0.1f);
	}
}
