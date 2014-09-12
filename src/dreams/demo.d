module dreams.demo;

import std.algorithm, std.conv, std.math;
import dreams.camera, dreams.effects, dreams.entities, dreams.imm3d, dreams.noise, dreams.particles;
import dreams.skybox, dreams.view, dreams.world, dreams.world_renderer;
import audio, cstr, engine, graphics, input;
import log, matrix, renderer, vector;

final class Demo: Engine
{
private:
	GraphicsContext ctx;
	Font smallFont;
	Font defaultFont;
	Immediate3D imm;

	World* world;
	WorldRenderer worldRenderer;
	Skybox skybox;

	Player player;
	FpsCamera camera;

	ParticleSystem ps;
	Effect currentEffect;

	enum State {
		edit,
		playing,
	}
	State state;

	// editor variables
	enum SelectionMode {
		add,
		fixedDistance,
		ray,
		paint
	};
	ubyte textureId;
	bool selecting;
	SelectionMode selectionMode;
	uint[3] selectionStart, selectionEnd;

	bool renderingComplete;

public:
	this()
	{
		super("d-voxel");
		ctx = new GraphicsContext(super.renderer);
		imm = new Immediate3D(super.renderer);
		worldRenderer = new WorldRenderer(super.renderer);
		ps = new ParticleSystem();
	}

	~this()
	{
		destroy(worldRenderer);
		destroy(ctx);
	}

	override void init()
	{
		super.init();
		imm.init();
		ctx.init();
		worldRenderer.init();
		skybox.init(renderer);
		smallFont = ctx.createFont("FSEX300.ttf", 12, false);
		defaultFont = ctx.createFont("FSEX300.ttf", 16, false);

		player.position = Vec3f(512, 130, 512);
		world = new World(5);
		enum uint a = 0;
		enum uint b = 1024;
		for (uint x = a; x < b; x++) {
			for (uint z = a; z < b; z++) {
				uint h = cast(uint) (128 * perlin(x / 128.0f, 0, z / 128.0f));
				//for (uint y = h; y < h; y++) {
					world.root.insertBlock(WorldBlock(1, h > 64 ? 17: 16), x, h, z);
				//}
			}
		}

		worldRenderer.setWorldRoot(world.root);

		Emitter* e = new Emitter;
		e.position = Vec3f(512, 130, 510);
		e.minSize = 0;
		e.maxSize = 1;
		e.rate = 100;
		e.minDuration = 4;
		e.maxDuration = 5;
		e.velocity = Vec3f(1, 3, 1);
		ps.addEmitter(e);
		ps.gravity = Vec3f(0, -2, 0);

		input.connect(&onKeyEvent);
		input.connect(&onMouseButtonEvent);
		input.connect(&camera.onPointerMoveEvent);
		setState(State.edit);

		//currentEffect = new Fade(ctx, black, transparent, 10);
		currentEffect = new StarField(ctx, 100, 60);
	}

	override void shutdown()
	{
		input.disconnect(&onKeyEvent);
		input.disconnect(&onMouseButtonEvent);
		input.disconnect(&camera.onPointerMoveEvent);
		skybox.shutdown();
		worldRenderer.shutdown();
		destroy(world);
		ctx.destroyFont(smallFont);
		ctx.shutdown();
		imm.shutdown();
		super.shutdown();
	}

	override void render()
	{
		int width, height; bool fullscreen;
		renderer.getDisplayMode(width, height, fullscreen);
		View view;
		view.fov = 60 * PI / 180;
		view.aspect = width / cast(float) height;
		view.near = 0.1;
		view.far = 1000;
		view.position = player.position;
		view.forward = player.forward;
		view.side = view.forward.cross(Vec3f(0, 1, 0)).normalize();
		view.up = view.side.cross(view.forward);
		view.computeViewProjectionMatrix();

		// world
		worldRenderer.setView(view);
		worldRenderer.render();
		skybox.render(view);

		// entities
		imm.setView(view);
		ps.draw(imm);
		imm.flush();

		// 2D effects
		currentEffect.draw();

		// editor
		if (state == State.edit) {
			// world limits
			imm.setColor(127, 0, 0);
			imm.drawWireframeBlock(0, 0, 0, 1024, 1024, 1024);
			// selection box
			imm.setColor(127, 127, 127);
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
			imm.drawWireframeBlock(a.x, a.y, a.z, b.x, b.y, b.z);
			imm.drawBasis(Vec3f(512, 512, 512));
		}

		// user interface
		//drawUI();

		ctx.flush();
		renderingComplete = true;
	}

	override void update(float time)
	{
		ps.update(time);
		currentEffect.update(time);

		camera.update();
		player.forward = camera.forward;
		player.update(time, world);

		if (state == State.edit) {
			// selection box
			if (selecting) {
				final switch (selectionMode) {
					case SelectionMode.add:
						break;
					case SelectionMode.paint:
						uint[3] point, face;
						if (world.rayCollisionTest(player.position, player.forward, 64, point, face)) {
							selectionEnd = point;
						}
						break;
					case SelectionMode.ray:
					case SelectionMode.fixedDistance:
						selectionEnd = getFixedPointingPosition();
						break;
				}
			} else {
				final switch (selectionMode) {
				case SelectionMode.add:
				case SelectionMode.ray:
				case SelectionMode.paint:
					uint[3] point, face;
					world.rayCollisionTest(player.position, player.forward, 64, point, face);
					if (selectionMode != SelectionMode.paint) point[] += face[];
					selectionStart = selectionEnd = point;
					break;
				case SelectionMode.fixedDistance:
					selectionStart = selectionEnd = getFixedPointingPosition();
					break;
				}
			}
		}
	}

	void onKeyEvent(const KeyEvent* keyEvent)
	{
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

		if (state == State.edit) {
			switch (keyEvent.symbol) {
			case KeySymbol.k_e: // change selection mode
				if (keyEvent.type == KeyEvent.Type.press) {
					selectionMode++;
					if (selectionMode > SelectionMode.max) {
						selectionMode = SelectionMode.min;
					}
				}
				break;
			case KeySymbol.k_f2: // reset renderer
				if (keyEvent.type == KeyEvent.Type.press) {
					import core.memory;
					GC.collect();
					worldRenderer.destroyAllMeshes();
				}
				break;
			case KeySymbol.k_f3: // toggle fly
				if (keyEvent.type == KeyEvent.Type.press) {
					player.flags ^= Player.Flag.fly;
				}
				break;
			case KeySymbol.k_f5: // save
				if (keyEvent.type == KeyEvent.Type.release) {
					world.save("world.raw");
				}
				break;
			case KeySymbol.k_f8: // load
				if (keyEvent.type == KeyEvent.Type.release) {
					load("world.raw");
				}
				break;
			case KeySymbol.k_f11: // new world
				if (keyEvent.type == KeyEvent.Type.release) {
					world = new World(5);
					worldRenderer.setWorldRoot(world.root);
				}
				break;
			default:
			}
		}
	}

	void onMouseButtonEvent(const MouseButtonEvent* event)
	{
		if (state == State.edit) {
			if (event.button == MouseButton.left) {
				if (event.type == MouseButtonEvent.Type.press) {
					selecting = true;
				} else {
					uint[3] min, max;
					selectionToMinMax(min, max);
					for (uint x = min[0]; x <= max[0]; x++) {
						for (uint y = min[1]; y <= max[1]; y++) {
							for (uint z = min[2]; z <= max[2]; z++) {
								world.root.insertBlock(WorldBlock(1, textureId), x, y, z);
							}
						}
					}
					selecting = false;
				}
			}
			if (event.button == MouseButton.right) {
				if (event.type == MouseButtonEvent.Type.press) {
					selecting = true;
				} else {
					uint[3] min, max;
					selectionToMinMax(min, max);
					for (uint x = min[0]; x <= max[0]; x++) {
						for (uint y = min[1]; y <= max[1]; y++) {
							for (uint z = min[2]; z <= max[2]; z++) {
								world.root.insertBlock(WorldBlock(0), x, y, z);
							}
						}
					}
					selecting = false;
				}
			}
			if (event.button == MouseButton.scrollUp) {
				if (textureId < 255) textureId++;
			}
			if (event.button == MouseButton.scrollDown) {
				if (textureId > 0) textureId--;
			}
		}
	}

	private void setState(State state)
	{
		final switch (state) {
		case State.edit:
			player.setFlag(Player.Flag.fly);
			break;
		case State.playing:
			player.unsetFlag(Player.Flag.fly);
			break;
		}
	}

	private void load(string filename)
	{
		auto file = File(filename, "rb");
		world.load(file);
		worldRenderer.destroyAllMeshes();
		worldRenderer.setWorldRoot(world.root);
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
		drawUIStringSmall("E = change pointing mode (" ~ to!string(selectionMode) ~ ")", 0, 0);
		drawUIStringSmall("F2 = reset renderer    F3 = toggle fly", 0, 25);
		drawUIStringSmall("F5 = save    F8 = load", 0, 50);
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

	// retrun the fixed position the player is pointing at
	private uint[3] getFixedPointingPosition()
	{
		Vec3f p = player.position + player.forward * 5;
		return world.floatToUintCoord(p);
	}

	private void selectionToMinMax(out uint[3] min, out uint[3] max)
	{
		foreach (i; 0 .. 3) {
			if (selectionStart[i] < selectionEnd[i]) {
				min[i] = selectionStart[i];
				max[i] = selectionEnd[i];
			} else {
				min[i] = selectionEnd[i];
				max[i] = selectionStart[i];
			}
		}
	}
}
