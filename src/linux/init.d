module linux.init;

import deimos.X11.X,deimos.X11.Xlib;
import gl.core;
import linux.glloader, linux.glx, linux.glxext;
import cstr, log;

package {
	int errorLevel;  // incremented for every X error
	Display *display;
	int screen;
	Atom WM_DELETE_WINDOW;
	Atom _NET_WM_STATE;
	Atom _NET_WM_STATE_FULLSCREEN;
}

void sysInit()
{
	initXWindow();
	loadLibGL();
	loadGLXFunctions();

	int errorBase, eventBase;
	if (!glXQueryExtension(display, &errorBase, &eventBase)) {
		fatal("X server does not support the GLX extension (base error %d, base event %d)", errorBase, eventBase);
	}

	/*int major, minor;
	glXQueryVersion(display, &major, &minor);
	if (major * 10 + minor < 11)
	{
		fatal("GLX version 1.1 or higher is required (available is %d.%d)", major, minor);
	}*/

	info("GLX server vendor: %s", cstr2dstr(glXQueryServerString(display, screen, GLX_VENDOR)));
	info("GLX server version: %s", cstr2dstr(glXQueryServerString(display, screen, GLX_VERSION)));

	info("GLX client vendor: %s", cstr2dstr(glXGetClientString(display, GLX_VENDOR)));
	info("GLX client version: %s", cstr2dstr(glXGetClientString(display, GLX_VERSION)));

	loadGLXExtensions(); // TODO: specify version
	loadOpenGLFunctions();

	//XF86VidModeQueryVersion(display, &maj, &min);
	//out(" XF86 VideoMode extension version: %i.%i", maj, min);
}

void sysShutdown()
{
	unloadGLXExtensions();
	shutdownXWindow();
	unloadLibGL();
}

private:

extern (C) int errorHandler(Display* display, XErrorEvent* event) nothrow
{
	errorLevel++;
	char[128] buffer;
	XGetErrorText(display, event.error_code, buffer.ptr, buffer.length);
	scope (failure) return 0;
	info(
		"X Server error: %s, request code %s, minor code %s",
		cstr2dstr(buffer.ptr),
		event.request_code,
		event.minor_code
	);
	return 0;
}

void initXWindow()
{
	XSetErrorHandler(&errorHandler);

	display = XOpenDisplay(null);
	if (!display) fatal("Can't open the X display");
	screen = XDefaultScreen(display);

	//Enable synchronous behavior
	debug XSynchronize(display, True);

	info("X server vendor: %s", cstr2dstr(XServerVendor(display)));
	info("X server release: %s", XVendorRelease(display));


	WM_DELETE_WINDOW = XInternAtom(display, cast(char*) "WM_DELETE_WINDOW", False);
	_NET_WM_STATE = XInternAtom(display, cast(char*) "_NET_WM_STATE", False);
	_NET_WM_STATE_FULLSCREEN = XInternAtom(display, cast(char*) "_NET_WM_STATE_FULLSCREEN", False);
	if (WM_DELETE_WINDOW == None) warning("The window manager does not support WM_DELETE_WINDOW");
	if (_NET_WM_STATE == None) warning("The window manager does not support _NET_WM_STATE");
	if (_NET_WM_STATE_FULLSCREEN == None) warning("The window manager does not support _NET_WM_STATE_FULLSCREEN");

	//XF86VidModeQueryVersion(display, &maj, &min);
	//out(" XF86 VideoMode extension version: %i.%i", maj, min);
}

void shutdownXWindow()
{
	if (display) XCloseDisplay(display);
	XSetErrorHandler(null);
	display = null;
}
