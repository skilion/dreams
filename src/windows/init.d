module windows.init;

import gl.core, gl.ext;
import windows.glloader, windows.glwindow;
import windows.wgl, windows.wglext;
import windows.windows;
import log;

void sysInit()
{
	hInstance = GetModuleHandleA(null);
	SetThreadExecutionState(ES_CONTINUOUS | ES_AWAYMODE_REQUIRED | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED);
	loadLibGL();
	loadWGLFunctions();
	createDummyOpenGLContext();
	loadOpenGLFunctions();
	loadOpenGLExtensions();
	loadWGLExtensions();
	destroyDummyOpenGLContext();
	registerWndClass(hInstance);
}

void sysShutdown()
{
	unregisterWndClass(hInstance);
	unloadWGLExtensions();
	unloadOpenGLExtensions();
	unloadLibGL();
	SetThreadExecutionState(ES_CONTINUOUS);
}

private:

HINSTANCE hInstance;
HWND hWnd;
HDC hDC;
HGLRC hGLRC;

bool createDummyOpenGLContext()
{
	hWnd = CreateWindowExA(0, "STATIC", null, 0, 0, 0, 0, 0, null, null, null, null);
	if (!hWnd) {
		fatal("Can't create the dummy window (error code %d)", GetLastError());
	}
	hDC = GetDC(hWnd);
	PIXELFORMATDESCRIPTOR pfd;
	pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
	pfd.nVersion = 1;
	pfd.dwFlags	= PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL;
	int pixelFormat = ChoosePixelFormat(hDC, &pfd);
	if (!pixelFormat) {
		fatal("Can't find an appropriate pixel format for the dummy window (error code %d)", GetLastError());
		return false;
	}
	if (!SetPixelFormat(hDC, pixelFormat, &pfd)) {
		fatal("Can't set the specified pixel format for the dummy window (error code %d)", GetLastError());
		return false;
	}
	hGLRC = wglCreateContext(hDC);
	if (!hGLRC) {
		fatal("Can't create a new OpenGL render context for the dummy window (error code %d)", GetLastError());
		return false;
	}
	if (!wglMakeCurrent(hDC, hGLRC)) {
		fatal("Can't set active the OpenGL render context of the dummy window (error code %d)", GetLastError());
		return false;
	}

	return true;
}

void destroyDummyOpenGLContext()
{
	wglMakeCurrent(null, null);
	wglDeleteContext(hGLRC);
	ReleaseDC(hWnd, hDC);
	DestroyWindow(hWnd);
	hWnd = null;
	hDC = null;
	hGLRC = null;
}
