module engine;

import core.thread, core.time;
import std.datetime, std.file, std.json;
import std.datetime.stopwatch: StopWatch;
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
		MonoTime gameTime;
		bool running; // false if the engine is going to exit at the end of the frame
		bool suspended;
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

	protected void init(char[][] args)
	{
		readConfig();
		try window.width = cast(int) (config.object["window"].object["width"].integer);
		catch (Throwable) window.width = 0;
		try window.height = cast(int) config["window"].object["height"].integer;
		catch (Throwable) window.height = 0;
		try window.fullscreen = config["window"].object["fullscreen"].type == JSONType.true_;
		catch (Throwable) window.fullscreen = true;

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
		init(args);
		immutable auto oneSecond = dur!"seconds"(1);
		immutable int simulationStep = 16;
		immutable float simulationStepFloat = simulationStep / 1000.0f;
		immutable auto simulationStepTick = dur!"msecs"(simulationStep);

		int fpsCounter = 0;
		MonoTime lastFpsUpdateTime;
		lastFpsUpdateTime = gameTime = MonoTime.currTime;

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
			inputTime = inputStopWatch.peek().total!"msecs";

			if (!suspended) {
				// audio update
				audioStopWatch.reset();
				audioStopWatch.start();
				audio.update();
				audioStopWatch.stop();
				audioTime = audioStopWatch.peek().total!"msecs";

				// game simulation
				simulationStopWatch.reset();
				simulationStopWatch.start();
				auto realTime = MonoTime.currTime;
				while (gameTime < realTime) {
					// the game time is advanced by a fixed time slice
					gameTime += simulationStepTick;
					update(simulationStepFloat);
				}
				simulationStopWatch.stop();
				simulationTime = simulationStopWatch.peek().total!"msecs";

				// rendering
				renderer.beginFrame();
				renderingStopWatch.reset();
				renderingStopWatch.start();
				render();
				renderingStopWatch.stop();
				renderingTime = renderingStopWatch.peek().total!"msecs";
				renderer.endFrame();
			}

			// frames per second
			fpsCounter++;
			if (MonoTime.currTime - oneSecond >= lastFpsUpdateTime) {
				fps = fpsCounter;
				fpsCounter = 0;
				lastFpsUpdateTime = MonoTime.currTime;
			}

			frameStopWatch.stop();
			frameTime = frameStopWatch.peek().total!"msecs";

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

	final void suspend()
	{
		suspended = true;
		audio.suspend();
	}

	final void resume()
	{
		if (suspended) {
			suspended = false;
			audio.resume();
			gameTime = MonoTime.currTime; // forget about the suspended time
		}
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
		catch (Throwable) warning("Can't write the config file");
	}
}
