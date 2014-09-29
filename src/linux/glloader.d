module linux.glloader;

import core.sys.posix.dlfcn;
import linux.glx, linux.glxext;
import cstr, log;

private void* libGL;

void* glGetProcAddress(const(char)* procName)
{
	void* procAddress = null;
	if (glXGetProcAddress) {
		procAddress = glXGetProcAddress(cast(const(ubyte)*) procName);
	} else if (glXGetProcAddressARB) {
		procAddress = glXGetProcAddressARB(cast(const(ubyte)*) procName);
	}
	if (libGL && procAddress == null) {
		procAddress = dlsym(libGL, procName);
	}
	if (procAddress == null) {
		fatal("Could not get the address of %s", cstr2dstr(procName));
	}
	return procAddress;
}

package void loadLibGL()
{
	libGL = dlopen("libGL.so", RTLD_LAZY | RTLD_GLOBAL);
	if (!libGL) fatal(cstr2dstr(dlerror()));
}

package void unloadLibGL()
{
	if (libGL) dlclose(libGL);
	libGL = null;
}
