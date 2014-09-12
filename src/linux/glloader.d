module linux.glloader;

import core.sys.posix.dlfcn;
import linux.glx;
import linux.glxext;
import cstr;
import log;

private void* libGL;

void* glGetProcAddress(const(char)* procName)
{
	void* procAddress;
	if (glXGetProcAddress)
	{
		procAddress = glXGetProcAddress(cast(const(ubyte)*) procName);
	}
	else if (glXGetProcAddressARB)
	{
		procAddress = glXGetProcAddressARB(cast(const(ubyte)*) procName);
	}
	else if (libGL)
	{
		procAddress = dlsym(libGL, procName);
	}

	if (!procAddress)
	{
		fatal("Could not get the address of %s", cstr2dstr(procName));
	}

	return procAddress;
}

package:

void loadLibGL()
{
	libGL = dlopen("libGL.so", RTLD_LAZY | RTLD_GLOBAL);
	if (!libGL) fatal(cstr2dstr(dlerror()));
}

void unloadLibGL()
{
	if (libGL) dlclose(libGL);
	libGL = null;
}
