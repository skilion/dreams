module zfile;

import std.c.string: memcpy;
import std.stdio, std.zlib;

final class ZInFile
{
	private File file;
	private UnCompress u;
	private static immutable chunk = 32 * 2 ^^ 10;
	private void[chunk] src = void;
	private const(void)[] extracted;

	this(string filename)
	{
		open(filename);
	}

	~this()
	{
		close();
	}

	void open(string filename)
	{
		file.open(filename, "rb");
		u = new UnCompress();
	}

	void close()
	{
		if (file.isOpen()) {
			file.close();
			destroy(u);
		}
	}

	T[] rawRead(T)(T[] buffer)
	{
		size_t read, size = buffer.length * T.sizeof;
		while (read < size) {
			size_t remaining = size - read;
			if (remaining > extracted.length) {
				memcpy((cast(void*) buffer.ptr) + read, extracted.ptr, extracted.length);
				read += extracted.length;
				extract();
				if (extracted.length == 0) break;
			} else {
				memcpy((cast(void*) buffer.ptr) + read, extracted.ptr, remaining);
				extracted = extracted[remaining .. $];
				return buffer;
			}
		}
		return buffer[0 .. read / T.sizeof];
	}

	private void extract()
	{
		auto read = file.rawRead(src);
		if (read.length > 0) {
			extracted = u.uncompress(read.dup); // HACK: see https://issues.dlang.org/show_bug.cgi?id=3191
		} else {
			extracted = u.flush();
		}
	}
}

final class ZOutFile
{
	private File file;
	private Compress c;

	this(string filename)
	{
		open(filename);
	}

	~this()
	{
		close();
	}

	void open(string filename)
	{
		file.open(filename, "wb");
		c = new Compress(9);
	}

	void close()
	{
		if (file.isOpen()) {
			file.rawWrite(c.flush());
			file.close();
			destroy(c);
		}
	}

	void rawWrite(T)(in T[] buffer)
	{
		file.rawWrite(c.compress(buffer));
	}
}

unittest
{
	import std.file;

	auto zout = new ZOutFile("__test");
	foreach (i; 0 .. 1000) {
		zout.rawWrite("aaaa");
	}
	zout.close();

	auto zin = new ZInFile("__test");
	char[4] str;
	foreach (i; 0 .. 1000) {
		zin.rawRead(str);
		assert(str == "aaaa");
	}
	zin.close();

	remove("__test");
}
