module linux.glx;

import deimos.X11.X, deimos.X11.Xlib, deimos.X11.Xutil;
import gl.core;
import linux.glloader;

package void loadGLXFunctions()
{
	// GLX_VERSION_1_0
	glXChooseVisual = cast(PFNGLXCHOOSEVISUALPROC) glGetProcAddress("glXChooseVisual");
	glXCreateContext = cast(PFNGLXCREATECONTEXTPROC) glGetProcAddress("glXCreateContext");
	glXDestroyContext = cast(PFNGLXDESTROYCONTEXTPROC) glGetProcAddress("glXDestroyContext");
	glXMakeCurrent = cast(PFNGLXMAKECURRENTPROC) glGetProcAddress("glXMakeCurrent");
	glXCopyContext = cast(PFNGLXCOPYCONTEXTPROC) glGetProcAddress("glXCopyContext");
	glXSwapBuffers = cast(PFNGLXSWAPBUFFERSPROC) glGetProcAddress("glXSwapBuffers");
	glXCreateGLXPixmap = cast(PFNGLXCREATEGLXPIXMAPPROC) glGetProcAddress("glXCreateGLXPixmap");
	glXDestroyGLXPixmap = cast(PFNGLXDESTROYGLXPIXMAPPROC) glGetProcAddress("glXDestroyGLXPixmap");
	glXQueryExtension = cast(PFNGLXQUERYEXTENSIONPROC) glGetProcAddress("glXQueryExtension");
	glXQueryVersion = cast(PFNGLXQUERYVERSIONPROC) glGetProcAddress("glXQueryVersion");
	glXIsDirect = cast(PFNGLXISDIRECTPROC) glGetProcAddress("glXIsDirect");
	glXGetConfig = cast(PFNGLXGETCONFIGPROC) glGetProcAddress("glXGetConfig");
	glXGetCurrentContext = cast(PFNGLXGETCURRENTCONTEXTPROC) glGetProcAddress("glXGetCurrentContext");
	glXGetCurrentDrawable = cast(PFNGLXGETCURRENTDRAWABLEPROC) glGetProcAddress("glXGetCurrentDrawable");
	glXWaitGL = cast(PFNGLXWAITGLPROC) glGetProcAddress("glXWaitGL");
	glXWaitX = cast(PFNGLXWAITXPROC) glGetProcAddress("glXWaitX");
	glXUseXFont = cast(PFNGLXUSEXFONTPROC) glGetProcAddress("glXUseXFont");

	// GLX_VERSION_1_1
	glXQueryExtensionsString = cast(PFNGLXQUERYEXTENSIONSSTRINGPROC) glGetProcAddress("glXQueryExtensionsString");
	glXQueryServerString = cast(PFNGLXQUERYSERVERSTRINGPROC) glGetProcAddress("glXQueryServerString");
	glXGetClientString = cast(PFNGLXGETCLIENTSTRINGPROC) glGetProcAddress("glXGetClientString");

	// GLX_VERSION_1_2
	glXGetCurrentDisplay = cast(PFNGLXGETCURRENTDISPLAYPROC) glGetProcAddress("glXGetCurrentDisplay");

	// GLX_VERSION_1_3
	glXGetFBConfigs = cast(PFNGLXGETFBCONFIGSPROC) glGetProcAddress("glXGetFBConfigs");
	glXChooseFBConfig = cast(PFNGLXCHOOSEFBCONFIGPROC) glGetProcAddress("glXChooseFBConfig");
	glXGetFBConfigAttrib = cast(PFNGLXGETFBCONFIGATTRIBPROC) glGetProcAddress("glXGetFBConfigAttrib");
	glXGetVisualFromFBConfig = cast(PFNGLXGETVISUALFROMFBCONFIGPROC) glGetProcAddress("glXGetVisualFromFBConfig");
	glXCreateWindow = cast(PFNGLXCREATEWINDOWPROC) glGetProcAddress("glXCreateWindow");
	glXDestroyWindow = cast(PFNGLXDESTROYWINDOWPROC) glGetProcAddress("glXDestroyWindow");
	glXCreatePixmap = cast(PFNGLXCREATEPIXMAPPROC) glGetProcAddress("glXCreatePixmap");
	glXDestroyPixmap = cast(PFNGLXDESTROYPIXMAPPROC) glGetProcAddress("glXDestroyPixmap");
	glXCreatePbuffer = cast(PFNGLXCREATEPBUFFERPROC) glGetProcAddress("glXCreatePbuffer");
	glXDestroyPbuffer = cast(PFNGLXDESTROYPBUFFERPROC) glGetProcAddress("glXDestroyPbuffer");
	glXQueryDrawable = cast(PFNGLXQUERYDRAWABLEPROC) glGetProcAddress("glXQueryDrawable");
	glXCreateNewContext = cast(PFNGLXCREATENEWCONTEXTPROC) glGetProcAddress("glXCreateNewContext");
	glXMakeContextCurrent = cast(PFNGLXMAKECONTEXTCURRENTPROC) glGetProcAddress("glXMakeContextCurrent");
	glXGetCurrentReadDrawable = cast(PFNGLXGETCURRENTREADDRAWABLEPROC) glGetProcAddress("glXGetCurrentReadDrawable");
	glXQueryContext = cast(PFNGLXQUERYCONTEXTPROC) glGetProcAddress("glXQueryContext");
	glXSelectEvent = cast(PFNGLXSELECTEVENTPROC) glGetProcAddress("glXSelectEvent");
	glXGetSelectedEvent = cast(PFNGLXGETSELECTEDEVENTPROC) glGetProcAddress("glXGetSelectedEvent");

	// GLX_VERSION_1_4
	scope (failure) return; //TODO
	glXGetProcAddress = cast(PFNGLXGETPROCADDRESSPROC) glGetProcAddress("glXGetProcAddress");
}

extern (C) __gshared nothrow:

// GLX_VERSION_1_0
struct __GLXcontextRec;
alias __GLXcontextRec* GLXContext;
alias XID GLXDrawable;
alias XID GLXPixmap;
enum GLX_EXTENSION_NAME = "GLX";
enum GLX_PbufferClobber = 0;
enum GLX_BufferSwapComplete = 1;
enum __GLX_NUMBER_EVENTS = 17;
enum GLX_BAD_SCREEN = 1;
enum GLX_BAD_ATTRIBUTE = 2;
enum GLX_NO_EXTENSION = 3;
enum GLX_BAD_VISUAL = 4;
enum GLX_BAD_CONTEXT = 5;
enum GLX_BAD_VALUE = 6;
enum GLX_BAD_ENUM = 7;
enum GLX_USE_GL = 1;
enum GLX_BUFFER_SIZE = 2;
enum GLX_LEVEL = 3;
enum GLX_RGBA = 4;
enum GLX_DOUBLEBUFFER = 5;
enum GLX_STEREO = 6;
enum GLX_AUX_BUFFERS = 7;
enum GLX_RED_SIZE = 8;
enum GLX_GREEN_SIZE = 9;
enum GLX_BLUE_SIZE = 10;
enum GLX_ALPHA_SIZE = 11;
enum GLX_DEPTH_SIZE = 12;
enum GLX_STENCIL_SIZE = 13;
enum GLX_ACCUM_RED_SIZE = 14;
enum GLX_ACCUM_GREEN_SIZE = 15;
enum GLX_ACCUM_BLUE_SIZE = 16;
enum GLX_ACCUM_ALPHA_SIZE = 17;
alias XVisualInfo* function(Display* dpy, int screen, int* attribList) PFNGLXCHOOSEVISUALPROC;
alias GLXContext function(Display* dpy, XVisualInfo* vis, GLXContext shareList, Bool direct) PFNGLXCREATECONTEXTPROC;
alias void function(Display* dpy, GLXContext ctx) PFNGLXDESTROYCONTEXTPROC;
alias Bool function(Display* dpy, GLXDrawable drawable, GLXContext ctx) PFNGLXMAKECURRENTPROC;
alias void function(Display* dpy, GLXContext src, GLXContext dst, ulong mask) PFNGLXCOPYCONTEXTPROC;
alias void function(Display* dpy, GLXDrawable drawable) PFNGLXSWAPBUFFERSPROC;
alias GLXPixmap function(Display* dpy, XVisualInfo* visual, Pixmap pixmap) PFNGLXCREATEGLXPIXMAPPROC;
alias void function(Display* dpy, GLXPixmap pixmap) PFNGLXDESTROYGLXPIXMAPPROC;
alias Bool function(Display* dpy, int* errorb, int* event) PFNGLXQUERYEXTENSIONPROC;
alias Bool function(Display* dpy, int* maj, int* min_) PFNGLXQUERYVERSIONPROC;
alias Bool function(Display* dpy, GLXContext ctx) PFNGLXISDIRECTPROC;
alias int function(Display* dpy, XVisualInfo* visual, int attrib, int* value) PFNGLXGETCONFIGPROC;
alias GLXContext function() PFNGLXGETCURRENTCONTEXTPROC;
alias GLXDrawable function() PFNGLXGETCURRENTDRAWABLEPROC;
alias void function() PFNGLXWAITGLPROC;
alias void function() PFNGLXWAITXPROC;
alias void function(Font font, int first, int count, int list) PFNGLXUSEXFONTPROC;
PFNGLXCHOOSEVISUALPROC glXChooseVisual;
PFNGLXCREATECONTEXTPROC glXCreateContext;
PFNGLXDESTROYCONTEXTPROC glXDestroyContext;
PFNGLXMAKECURRENTPROC glXMakeCurrent;
PFNGLXCOPYCONTEXTPROC glXCopyContext;
PFNGLXSWAPBUFFERSPROC glXSwapBuffers;
PFNGLXCREATEGLXPIXMAPPROC glXCreateGLXPixmap;
PFNGLXDESTROYGLXPIXMAPPROC glXDestroyGLXPixmap;
PFNGLXQUERYEXTENSIONPROC glXQueryExtension;
PFNGLXQUERYVERSIONPROC glXQueryVersion;
PFNGLXISDIRECTPROC glXIsDirect;
PFNGLXGETCONFIGPROC glXGetConfig;
PFNGLXGETCURRENTCONTEXTPROC glXGetCurrentContext;
PFNGLXGETCURRENTDRAWABLEPROC glXGetCurrentDrawable;
PFNGLXWAITGLPROC glXWaitGL;
PFNGLXWAITXPROC glXWaitX;
PFNGLXUSEXFONTPROC glXUseXFont;

// GLX_VERSION_1_1
enum GLX_VENDOR = 0x1;
enum GLX_VERSION = 0x2;
enum GLX_EXTENSIONS = 0x3;
alias const(char)* function(Display* dpy, int screen) PFNGLXQUERYEXTENSIONSSTRINGPROC;
alias const(char)* function(Display* dpy, int screen, int name) PFNGLXQUERYSERVERSTRINGPROC;
alias const(char)* function(Display* dpy, int name) PFNGLXGETCLIENTSTRINGPROC;
PFNGLXQUERYEXTENSIONSSTRINGPROC glXQueryExtensionsString;
PFNGLXQUERYSERVERSTRINGPROC glXQueryServerString;
PFNGLXGETCLIENTSTRINGPROC glXGetClientString;

// GLX_VERSION_1_2
alias Display* function() PFNGLXGETCURRENTDISPLAYPROC;
PFNGLXGETCURRENTDISPLAYPROC glXGetCurrentDisplay;

// GLX_VERSION_1_3
struct __GLXFBConfigRec;
alias __GLXFBConfigRec* GLXFBConfig;
alias XID GLXWindow;
alias XID GLXPbuffer;
enum GLX_WINDOW_BIT = 0x00000001;
enum GLX_PIXMAP_BIT = 0x00000002;
enum GLX_PBUFFER_BIT = 0x00000004;
enum GLX_RGBA_BIT = 0x00000001;
enum GLX_COLOR_INDEX_BIT = 0x00000002;
enum GLX_PBUFFER_CLOBBER_MASK = 0x08000000;
enum GLX_FRONT_LEFT_BUFFER_BIT = 0x00000001;
enum GLX_FRONT_RIGHT_BUFFER_BIT = 0x00000002;
enum GLX_BACK_LEFT_BUFFER_BIT = 0x00000004;
enum GLX_BACK_RIGHT_BUFFER_BIT = 0x00000008;
enum GLX_AUX_BUFFERS_BIT = 0x00000010;
enum GLX_DEPTH_BUFFER_BIT = 0x00000020;
enum GLX_STENCIL_BUFFER_BIT = 0x00000040;
enum GLX_ACCUM_BUFFER_BIT = 0x00000080;
enum GLX_CONFIG_CAVEAT = 0x20;
enum GLX_X_VISUAL_TYPE = 0x22;
enum GLX_TRANSPARENT_TYPE = 0x23;
enum GLX_TRANSPARENT_INDEX_VALUE = 0x24;
enum GLX_TRANSPARENT_RED_VALUE = 0x25;
enum GLX_TRANSPARENT_GREEN_VALUE = 0x26;
enum GLX_TRANSPARENT_BLUE_VALUE = 0x27;
enum GLX_TRANSPARENT_ALPHA_VALUE = 0x28;
enum GLX_DONT_CARE = 0xFFFFFFFF;
enum GLX_NONE = 0x8000;
enum GLX_SLOW_CONFIG = 0x8001;
enum GLX_TRUE_COLOR = 0x8002;
enum GLX_DIRECT_COLOR = 0x8003;
enum GLX_PSEUDO_COLOR = 0x8004;
enum GLX_STATIC_COLOR = 0x8005;
enum GLX_GRAY_SCALE = 0x8006;
enum GLX_STATIC_GRAY = 0x8007;
enum GLX_TRANSPARENT_RGB = 0x8008;
enum GLX_TRANSPARENT_INDEX = 0x8009;
enum GLX_VISUAL_ID = 0x800B;
enum GLX_SCREEN = 0x800C;
enum GLX_NON_CONFORMANT_CONFIG = 0x800D;
enum GLX_DRAWABLE_TYPE = 0x8010;
enum GLX_RENDER_TYPE = 0x8011;
enum GLX_X_RENDERABLE = 0x8012;
enum GLX_FBCONFIG_ID = 0x8013;
enum GLX_RGBA_TYPE = 0x8014;
enum GLX_COLOR_INDEX_TYPE = 0x8015;
enum GLX_MAX_PBUFFER_WIDTH = 0x8016;
enum GLX_MAX_PBUFFER_HEIGHT = 0x8017;
enum GLX_MAX_PBUFFER_PIXELS = 0x8018;
enum GLX_PRESERVED_CONTENTS = 0x801B;
enum GLX_LARGEST_PBUFFER = 0x801C;
enum GLX_WIDTH = 0x801D;
enum GLX_HEIGHT = 0x801E;
enum GLX_EVENT_MASK = 0x801F;
enum GLX_DAMAGED = 0x8020;
enum GLX_SAVED = 0x8021;
enum GLX_WINDOW = 0x8022;
enum GLX_PBUFFER = 0x8023;
enum GLX_PBUFFER_HEIGHT = 0x8040;
enum GLX_PBUFFER_WIDTH = 0x8041;
alias GLXFBConfig* function(Display* dpy, int screen, int* nelements) PFNGLXGETFBCONFIGSPROC;
alias GLXFBConfig* function(Display* dpy, int screen, const(int*) attrib_list, int* nelements) PFNGLXCHOOSEFBCONFIGPROC;
alias int function(Display* dpy, GLXFBConfig config, int attribute, int* value) PFNGLXGETFBCONFIGATTRIBPROC;
alias XVisualInfo* function(Display* dpy, GLXFBConfig config) PFNGLXGETVISUALFROMFBCONFIGPROC;
alias GLXWindow function(Display* dpy, GLXFBConfig config, Window win_, const(int*) attrib_list) PFNGLXCREATEWINDOWPROC;
alias void function(Display* dpy, GLXWindow win_) PFNGLXDESTROYWINDOWPROC;
alias GLXPixmap function(Display* dpy, GLXFBConfig config, Pixmap pixmap, const(int*) attrib_list) PFNGLXCREATEPIXMAPPROC;
alias void function(Display* dpy, GLXPixmap pixmap) PFNGLXDESTROYPIXMAPPROC;
alias GLXPbuffer function(Display* dpy, GLXFBConfig config, const(int*) attrib_list) PFNGLXCREATEPBUFFERPROC;
alias void function(Display* dpy, GLXPbuffer pbuf) PFNGLXDESTROYPBUFFERPROC;
alias void function(Display* dpy, GLXDrawable draw, int attribute, uint* value) PFNGLXQUERYDRAWABLEPROC;
alias GLXContext function(Display* dpy, GLXFBConfig config, int render_type, GLXContext share_list, Bool direct) PFNGLXCREATENEWCONTEXTPROC;
alias Bool function(Display* dpy, GLXDrawable draw, GLXDrawable read, GLXContext ctx) PFNGLXMAKECONTEXTCURRENTPROC;
alias GLXDrawable function() PFNGLXGETCURRENTREADDRAWABLEPROC;
alias int function(Display* dpy, GLXContext ctx, int attribute, int* value) PFNGLXQUERYCONTEXTPROC;
alias void function(Display* dpy, GLXDrawable draw, ulong event_mask) PFNGLXSELECTEVENTPROC;
alias void function(Display* dpy, GLXDrawable draw, ulong* event_mask) PFNGLXGETSELECTEDEVENTPROC;
PFNGLXGETFBCONFIGSPROC glXGetFBConfigs;
PFNGLXCHOOSEFBCONFIGPROC glXChooseFBConfig;
PFNGLXGETFBCONFIGATTRIBPROC glXGetFBConfigAttrib;
PFNGLXGETVISUALFROMFBCONFIGPROC glXGetVisualFromFBConfig;
PFNGLXCREATEWINDOWPROC glXCreateWindow;
PFNGLXDESTROYWINDOWPROC glXDestroyWindow;
PFNGLXCREATEPIXMAPPROC glXCreatePixmap;
PFNGLXDESTROYPIXMAPPROC glXDestroyPixmap;
PFNGLXCREATEPBUFFERPROC glXCreatePbuffer;
PFNGLXDESTROYPBUFFERPROC glXDestroyPbuffer;
PFNGLXQUERYDRAWABLEPROC glXQueryDrawable;
PFNGLXCREATENEWCONTEXTPROC glXCreateNewContext;
PFNGLXMAKECONTEXTCURRENTPROC glXMakeContextCurrent;
PFNGLXGETCURRENTREADDRAWABLEPROC glXGetCurrentReadDrawable;
PFNGLXQUERYCONTEXTPROC glXQueryContext;
PFNGLXSELECTEVENTPROC glXSelectEvent;
PFNGLXGETSELECTEDEVENTPROC glXGetSelectedEvent;

// GLX_VERSION_1_4
alias void function() __GLXextFuncPtr;
enum GLX_SAMPLE_BUFFERS = 100000;
enum GLX_SAMPLES = 100001;
alias __GLXextFuncPtr function(const(GLubyte)* procName) PFNGLXGETPROCADDRESSPROC;
PFNGLXGETPROCADDRESSPROC glXGetProcAddress;
