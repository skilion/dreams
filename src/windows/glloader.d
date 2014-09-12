module windows.glloader;

import windows.wgl;
import windows.windows;
import cstr, log;

private __gshared HMODULE libGL;

void* glGetProcAddress(const(char)* procName)
{
	void* procAddress;
	if (wglGetProcAddress)
	{
		procAddress = wglGetProcAddress(procName);
		if (procAddress)
		{
			return procAddress;
		}
	}
	if (libGL)
	{
		procAddress = GetProcAddress(libGL, procName);
	}
	if (!procAddress)
	{
		fatal("Can't get the address of %s", cstr2dstr(procName));
	}
	return procAddress;
}

package:

void loadLibGL()
{
	libGL = LoadLibraryA("Opengl32.dll");
	if (!libGL)
	{
		fatal("Can't load Opengl32.dll (error code %d)", GetLastError());
	}
}

void unloadLibGL() nothrow
{
	FreeLibrary(libGL);
	libGL = null;
}
