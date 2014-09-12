module windows.wgl;

import windows.glloader;
import windows.windows;

package void loadWGLFunctions()
{
	wglCreateContext = cast(PFNGLCREATECONTEXTPROC) glGetProcAddress("wglCreateContext");
	wglDeleteContext = cast(PFNGLDELETECONTEXTPROC) glGetProcAddress("wglDeleteContext");
	wglGetCurrentContext = cast(PFNGLGETCURRENTCONTEXTPROC) glGetProcAddress("wglGetCurrentContext");
	wglGetCurrentDC = cast(PFNGLGETCURRENTDCPROC) glGetProcAddress("wglGetCurrentDC");
	wglGetProcAddress = cast(PFNGLGETPROCADDRESSPROC) glGetProcAddress("wglGetProcAddress");
	wglMakeCurrent = cast(PFNGLMAKECURRENTPROC) glGetProcAddress("wglMakeCurrent");
}

extern (Windows) __gshared nothrow:

// WGL_VERSION_1_0
alias void* PROC;
alias HGLRC function(HDC hDc) PFNGLCREATECONTEXTPROC;
alias BOOL function(HGLRC oldContext) PFNGLDELETECONTEXTPROC;
alias HGLRC function() PFNGLGETCURRENTCONTEXTPROC;
alias HDC function() PFNGLGETCURRENTDCPROC;
alias PROC function(LPCSTR lpszProc) PFNGLGETPROCADDRESSPROC;
alias BOOL function(HDC hDc, HGLRC newContext) PFNGLMAKECURRENTPROC;
PFNGLCREATECONTEXTPROC wglCreateContext;
PFNGLDELETECONTEXTPROC wglDeleteContext;
PFNGLGETCURRENTCONTEXTPROC wglGetCurrentContext;
PFNGLGETCURRENTDCPROC wglGetCurrentDC;
PFNGLGETPROCADDRESSPROC wglGetProcAddress;
PFNGLMAKECURRENTPROC wglMakeCurrent;