module log;

import std.conv: to;
import std.datetime;
import std.stdio;
import std.string: format;

__gshared Logger gLogger;

static this()
{
	gLogger = new StdoutLogger;
}

void dev(string file = __FILE__, int line = __LINE__, Args...)(const(char)[] fmt, Args args)
{
	Logger.Message msg = message(file, line, Logger.Message.Level.development, fmt, args);
	gLogger.log(msg);
}

void info(string file = __FILE__, int line = __LINE__, Args...)(const(char)[] fmt, Args args)
{
	Logger.Message msg = message(file, line, Logger.Message.Level.info, fmt, args);
	gLogger.log(msg);
}

void warning(string file = __FILE__, int line = __LINE__, Args...)(const(char)[] fmt, Args args)
{
	Logger.Message msg = message(file, line, Logger.Message.Level.warning, fmt, args);
	gLogger.log(msg);
}

void error(string file = __FILE__, int line = __LINE__, Args...)(const(char)[] fmt, Args args)
{
	Logger.Message msg = message(file, line, Logger.Message.Level.error, fmt, args);
	gLogger.log(msg);
}

void fatal(string file = __FILE__, int line = __LINE__, Args...)(const(char)[] fmt, Args args)
{
	Logger.Message msg = message(file, line, Logger.Message.Level.fatal, fmt, args);
	gLogger.log(msg);
	gLogger.flush();
	throw new Exception(msg.message);
}

/*
  Logger interface
*/
interface Logger
{
	struct Message
	{
		enum Level
		{
			development,
			info,
			warning,
			error,
			fatal,
		}

		string file;
		int line;
		Level level;
		SysTime time;
		string message;
	}

	void log(const ref Message msg);
	void flush();
}

Logger.Message message(Args...)(string file, int line, Logger.Message.Level level, const(char)[] fmt, Args args)
{
	Logger.Message msg;
	msg.file = file;
	msg.line = line;
	msg.level = level;
	msg.time = Clock.currTime();
	msg.message = format(fmt, args);
	return msg;
}

private:

version (Windows)
{
	import core.sys.windows.windows;
	enum STD_OUTPUT_HANDLE = cast(DWORD) -11;
	enum
	{
		FOREGROUND_BLUE	= 1,
		FOREGROUND_GREEN = 2,
		FOREGROUND_RED = 4,
		FOREGROUND_INTENSITY = 8
	}
	enum FOREGROUND_WHITE = FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED;
	extern (Windows) nothrow BOOL SetConsoleTextAttribute(HANDLE hConsoleOutput, WORD wAttributes);
	extern (Windows) nothrow HANDLE GetStdHandle(DWORD nStdHandle);
}

class StdoutLogger: Logger
{
	void log(const ref Message msg)
	{
		version (linux)
		{
			string colorCode;
			with (Logger.Message.Level)
			final switch (msg.level)
			{
			case fatal:
			case error:
				colorCode = "\x1B[1;31m"; // light red
				break;
			case warning:
				colorCode = "\x1B[0;31m"; // red
				break;
			case info:
				colorCode = "\x1B[0m";
				break;
			case development:
				colorCode = "\x1B[0;32m"; // green
				break;
			}
			write(colorCode);
		}
		version (Windows)
		{
			WORD textAttrib;
			with (Logger.Message.Level)
			final switch (msg.level)
			{
			case fatal:
			case error:
				textAttrib = FOREGROUND_RED | FOREGROUND_INTENSITY;
				break;
			case warning:
				textAttrib = FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_INTENSITY;
				break;
			case info:
				textAttrib = FOREGROUND_WHITE;
				break;
			case development:
				textAttrib = FOREGROUND_WHITE | FOREGROUND_INTENSITY;
				break;
			}
			SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), textAttrib);
		}
		writeln(msg.message);
		version (linux) write("\x1B[0m");
		version (Windows) SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_WHITE);
	}

	void flush()
	{
		stdout.flush();
	}

}

class FileLogger: Logger
{
	File file;

	this()
	{
		file.open("engine.log", "w");
	}

	~this()
	{
		file.close();
	}

	void log(const ref Message msg)
	{
		file.write("[", msg.time.toSimpleString(), level2str(msg.level), "] ");
		file.write(msg.message);
		file.writeln(" (", msg.file, ":", to!string(msg.line), ")");
	}

	void flush()
	{
		file.flush();
	}
}

string level2str(Logger.Message.Level level) pure nothrow
{
	with (Logger.Message.Level)
	final switch (level)
	{
	case development: return "DEVEL";
	case info:        return "INFO ";
	case warning:     return "WARN ";
	case error:       return "ERROR";
	case fatal:       return "FATAL";
	}
}
