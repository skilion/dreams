module main;

version (Windows)
{
	import core.runtime;
	import core.sys.windows.windows;
	import cstr;
	import std.algorithm;
	import std.array;
	import std.string: toStringz;
	import log;
	//pragma (lib, "Winmm.lib");

	extern (Windows):
	LPTSTR GetCommandLineA();
	//UINT timeBeginPeriod(UINT);
	//UINT timeEndPeriod(UINT);
	int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
	{
		//try
		{
			Runtime.initialize();
			//timeBeginPeriod(0);
			start(GetCommandLineA().cstr2dstr.splitter(" ").filter!"a.length > 0".array);
			//timeEndPeriod(0);
			Runtime.terminate();
		}
		/*catch (Throwable t)
		{
			string str = t.toString();
			auto msg = message(t.file, t.line, Logger.Message.Level.error, str);
			gLogger.log(msg);
			gLogger.flush();
			MessageBoxA(null, str.toStringz(), "Error", MB_ICONEXCLAMATION);
			return 1;
		}*/

		return 0;
	}
}
else
{
	void main(char[][] args)
	{
		start(args);
	}
}

import dreams.demo;

void start(char[][] args)
{
	debug {
		import std.math;
		FloatingPointControl fpctrl;
		fpctrl.enableExceptions(FloatingPointControl.severeExceptions);
	}
	//import core.memory;
	//GC.reserve(300 * 2^^20);
	//GC.disable();
	auto demo = new Demo();
	demo.run(args);
}
