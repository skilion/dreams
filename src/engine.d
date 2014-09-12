module engine;

import core.thread;
import std.datetime, std.file, std.json;
import audio, input, log, renderer;

version (Windows)
{
	import windows.init;
	import windows.glwindow;
}
version (linux)
{
	import linux.init;
	import linux.glwindow;
}

class Engine
{
	JSONValue config;
	Input input;
	Audio audio;
	Renderer renderer;

	protected {
		/* engine stopwatches, all in milliseconds */
		long inputTime; // time spent parsing the input events
		long audioTime; // time spent updating the sounds playing
		long simulationTime; // time spent updating the game
		long renderingTime; // time spent rendering the game
		long frameTime; // total time spent on the frame

		int fps; // frame per second
	}

	private {
		OpenGLWindow window;
		bool running; // false if the engine is going to exit at the end of the frame
	}

public:
	this(string name)
	{
		input = new Input;
		audio = new Audio;
		window = new OpenGLWindow(this);
		renderer = new Renderer(window);
		window.title = name;
	}

	~this()
	{
		destroy(renderer);
		destroy(window);
		destroy(audio);
		destroy(input);
	}

	protected void init()
	{
		readConfig();
		try window.width = cast(int) (config.object["window"].object["width"].integer);
		catch window.width = 0;
		try window.height = cast(int) config["window"].object["height"].integer;
		catch window.height = 0;
		try window.fullscreen = config["window"].object["fullscreen"].type == JSON_TYPE.TRUE;
		catch window.fullscreen = true;

		audio.init();
		window.create();
		window.lockPointer();
		renderer.init();
	}

	protected void shutdown()
	{
		config = [
			"window": [
				"width":      JSONValue(window.width),
				"height":     JSONValue(window.height),
				"fullscreen": JSONValue(window.fullscreen)
			]
		];
		writeConfig();
		renderer.shutdown();
		window.destroy();
		audio.shutdown();
	}

	final void run(char[][] args)
	{
		info("Engine started");
		scope (exit) sysShutdown();
		sysInit();
		init();
		immutable auto oneSecond = TickDuration.from!"seconds"(1);
		immutable int simulationStep = 16;
		immutable float simulationStepFloat = simulationStep / 1000.0f;
		immutable auto simulationStepTick = TickDuration.from!"msecs"(simulationStep);

		int fpsCounter = 0;
		TickDuration lastFpsUpdateTime;
		TickDuration gameTime;
		lastFpsUpdateTime = gameTime = Clock.currSystemTick();

		StopWatch frameStopWatch;
		StopWatch inputStopWatch;
		StopWatch audioStopWatch;
		StopWatch simulationStopWatch;
		StopWatch renderingStopWatch;

		running = true;
		while (running) {
			frameStopWatch.reset();
			frameStopWatch.start();

			// poll the system events
			inputStopWatch.reset();
			inputStopWatch.start();
			window.pollEvents();
			inputStopWatch.stop();
			inputTime = inputStopWatch.peek().msecs();

			// audio update
			audioStopWatch.reset();
			audioStopWatch.start();
			audio.update();
			audioStopWatch.stop();
			audioTime = audioStopWatch.peek().msecs();

			// game simulation
			simulationStopWatch.reset();
			simulationStopWatch.start();
			auto realTime = Clock.currSystemTick();
			while (gameTime < realTime) {
				// the game time is advanced by a fixed time slice
				gameTime += simulationStepTick;
				update(simulationStepFloat);
			}
			simulationStopWatch.stop();
			simulationTime = simulationStopWatch.peek().msecs();

			// rendering
			renderer.beginFrame();
			renderingStopWatch.reset();
			renderingStopWatch.start();
			render();
			renderingStopWatch.stop();
			renderingTime = renderingStopWatch.peek().msecs();
			renderer.endFrame();

			// frames per second
			fpsCounter++;
			if (Clock.currSystemTick() - oneSecond >= lastFpsUpdateTime) {
				fps = fpsCounter;
				fpsCounter = 0;
				lastFpsUpdateTime = Clock.currSystemTick();
			}

			frameStopWatch.stop();
			frameTime = frameStopWatch.peek().msecs();

			Thread.yield();
			//Thread.sleep!"msecs"(5);
		}

		info("Engine stopped");
		shutdown();
	}

	final void exit()
	{
		running = false;
	}

	abstract protected void render();
	abstract protected void update(float time);

	private void readConfig()
	{
		scope (failure) {
			warning("Can't read the config file");
			return;
		}
		auto configText = readText("config.json");
		scope (failure) {
			warning("Can't parse the config file");
			return;
		}
		config = readText("config.json").parseJSON;
	}

	private void writeConfig()
	{
		try write("config.json", config.toPrettyString());
		catch warning("Can't write the config file");
	}
}
