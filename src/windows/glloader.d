module windows.glloader;

import windows.wgl, windows.windows;
import cstr, log;

private __gshared HMODULE libGL;

void* glGetProcAddress(const(char)* procName)
{
	void* procAddress = null;
	if (wglGetProcAddress) {
		procAddress = wglGetProcAddress(procName);
	}
	if (libGL && procAddress == null) {
		procAddress = GetProcAddress(libGL, procName);
	}
	if (procAddress == null) {
		fatal("Can't get the address of %s", cstr2dstr(procName));
	}
	return procAddress;
}

package void loadLibGL()
{
	libGL = LoadLibraryA("Opengl32.dll");
	if (!libGL) {
		fatal("Can't load Opengl32.dll (error code %d)", GetLastError());
	}
}

package void unloadLibGL() nothrow
{
	FreeLibrary(libGL);
	libGL = null;
}
