module windows.wglext;

import gl.common;
import windows.glloader, windows.wgl, windows.windows;
import cstr, log;

package void loadWGLExtensions()
{
	scope (failure) return;
	wglGetExtensionsStringARB = cast(PFNWGLGETEXTENSIONSSTRINGARBPROC) glGetProcAddress("wglGetExtensionsStringARB");

	if (isWGLExtSupported("WGL_ARB_create_context")) {
		wglCreateContextAttribsARB = cast(PFNWGLCREATECONTEXTATTRIBSARBPROC) glGetProcAddress("wglCreateContextAttribsARB");
		WGL_ARB_create_context = true;
	}

	if (isWGLExtSupported("WGL_ARB_create_context_profile")) {
		WGL_ARB_create_context_profile = true;
	}

	if (isWGLExtSupported("WGL_ARB_multisample")) {
		WGL_ARB_multisample = true;
	}

	if (isWGLExtSupported("WGL_ARB_pixel_format")) {
		wglGetPixelFormatAttribivARB = cast(PFNWGLGETPIXELFORMATATTRIBIVARBPROC) glGetProcAddress("wglGetPixelFormatAttribivARB");
		wglGetPixelFormatAttribfvARB = cast(PFNWGLGETPIXELFORMATATTRIBFVARBPROC) glGetProcAddress("wglGetPixelFormatAttribfvARB");
		wglChoosePixelFormatARB = cast(PFNWGLCHOOSEPIXELFORMATARBPROC) glGetProcAddress("wglChoosePixelFormatARB");
		WGL_ARB_pixel_format = true;
	}

	if (isWGLExtSupported("WGL_EXT_swap_control")) {
		wglSwapIntervalEXT = cast(PFNWGLSWAPINTERVALEXTPROC) glGetProcAddress("wglSwapIntervalEXT");
		wglGetSwapIntervalEXT = cast(PFNWGLGETSWAPINTERVALEXTPROC) glGetProcAddress("wglGetSwapIntervalEXT");
		WGL_EXT_swap_control = true;
	}

	if (isWGLExtSupported("WGL_EXT_swap_control_tear")) {
		WGL_EXT_swap_control_tear = true;
	}
}

package void unloadWGLExtensions() nothrow
{
	WGL_ARB_create_context = false;
	WGL_ARB_create_context_profile = false;
	WGL_ARB_multisample = false;
	WGL_ARB_pixel_format = false;
	WGL_EXT_swap_control = false;
	WGL_EXT_swap_control_tear = false;
}

// extension must be a null terminated string
private bool isWGLExtSupported(const(char)* extension)
{
	auto extensionList = wglGetExtensionsStringARB(wglGetCurrentDC());
	if (isExtSupported(extension, extensionList)) {
		info("WGL Extension found: %s", cstr2dstr(extension));
		return true;
	}
	warning("WGL Extension not found: %s", cstr2dstr(extension));
	return false;
}

extern (Windows) __gshared nothrow:

// WGL_ARB_create_context
bool WGL_ARB_create_context = false;
enum WGL_CONTEXT_DEBUG_BIT_ARB = 0x00000001;
enum WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB = 0x00000002;
enum WGL_CONTEXT_MAJOR_VERSION_ARB = 0x2091;
enum WGL_CONTEXT_MINOR_VERSION_ARB = 0x2092;
enum WGL_CONTEXT_LAYER_PLANE_ARB = 0x2093;
enum WGL_CONTEXT_FLAGS_ARB = 0x2094;
enum ERROR_INVALID_VERSION_ARB = 0x2095;
alias HGLRC function(HDC hDC, HGLRC hShareContext, const(int*) attribList) PFNWGLCREATECONTEXTATTRIBSARBPROC;
PFNWGLCREATECONTEXTATTRIBSARBPROC wglCreateContextAttribsARB;

// WGL_ARB_create_context_profile
bool WGL_ARB_create_context_profile = false;
enum WGL_CONTEXT_PROFILE_MASK_ARB = 0x9126;
enum WGL_CONTEXT_CORE_PROFILE_BIT_ARB = 0x00000001;
enum WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB = 0x00000002;
enum ERROR_INVALID_PROFILE_ARB = 0x2096;

// WGL_ARB_extensions_string
alias const(char*) function(HDC hdc) PFNWGLGETEXTENSIONSSTRINGARBPROC;
PFNWGLGETEXTENSIONSSTRINGARBPROC wglGetExtensionsStringARB;

// WGL_ARB_multisample
bool WGL_ARB_multisample = false;
enum WGL_SAMPLE_BUFFERS_ARB = 0x2041;
enum WGL_SAMPLES_ARB = 0x2042;

// WGL_ARB_pixel_format
bool WGL_ARB_pixel_format = false;
enum WGL_NUMBER_PIXEL_FORMATS_ARB = 0x2000;
enum WGL_DRAW_TO_WINDOW_ARB = 0x2001;
enum WGL_DRAW_TO_BITMAP_ARB = 0x2002;
enum WGL_ACCELERATION_ARB = 0x2003;
enum WGL_NEED_PALETTE_ARB = 0x2004;
enum WGL_NEED_SYSTEM_PALETTE_ARB = 0x2005;
enum WGL_SWAP_LAYER_BUFFERS_ARB = 0x2006;
enum WGL_SWAP_METHOD_ARB = 0x2007;
enum WGL_NUMBER_OVERLAYS_ARB = 0x2008;
enum WGL_NUMBER_UNDERLAYS_ARB = 0x2009;
enum WGL_TRANSPARENT_ARB = 0x200A;
enum WGL_TRANSPARENT_RED_VALUE_ARB = 0x2037;
enum WGL_TRANSPARENT_GREEN_VALUE_ARB = 0x2038;
enum WGL_TRANSPARENT_BLUE_VALUE_ARB = 0x2039;
enum WGL_TRANSPARENT_ALPHA_VALUE_ARB = 0x203A;
enum WGL_TRANSPARENT_INDEX_VALUE_ARB = 0x203B;
enum WGL_SHARE_DEPTH_ARB = 0x200C;
enum WGL_SHARE_STENCIL_ARB = 0x200D;
enum WGL_SHARE_ACCUM_ARB = 0x200E;
enum WGL_SUPPORT_GDI_ARB = 0x200F;
enum WGL_SUPPORT_OPENGL_ARB = 0x2010;
enum WGL_DOUBLE_BUFFER_ARB = 0x2011;
enum WGL_STEREO_ARB = 0x2012;
enum WGL_PIXEL_TYPE_ARB = 0x2013;
enum WGL_COLOR_BITS_ARB = 0x2014;
enum WGL_RED_BITS_ARB = 0x2015;
enum WGL_RED_SHIFT_ARB = 0x2016;
enum WGL_GREEN_BITS_ARB = 0x2017;
enum WGL_GREEN_SHIFT_ARB = 0x2018;
enum WGL_BLUE_BITS_ARB = 0x2019;
enum WGL_BLUE_SHIFT_ARB = 0x201A;
enum WGL_ALPHA_BITS_ARB = 0x201B;
enum WGL_ALPHA_SHIFT_ARB = 0x201C;
enum WGL_ACCUM_BITS_ARB = 0x201D;
enum WGL_ACCUM_RED_BITS_ARB = 0x201E;
enum WGL_ACCUM_GREEN_BITS_ARB = 0x201F;
enum WGL_ACCUM_BLUE_BITS_ARB = 0x2020;
enum WGL_ACCUM_ALPHA_BITS_ARB = 0x2021;
enum WGL_DEPTH_BITS_ARB = 0x2022;
enum WGL_STENCIL_BITS_ARB = 0x2023;
enum WGL_AUX_BUFFERS_ARB = 0x2024;
enum WGL_NO_ACCELERATION_ARB = 0x2025;
enum WGL_GENERIC_ACCELERATION_ARB = 0x2026;
enum WGL_FULL_ACCELERATION_ARB = 0x2027;
enum WGL_SWAP_EXCHANGE_ARB = 0x2028;
enum WGL_SWAP_COPY_ARB = 0x2029;
enum WGL_SWAP_UNDEFINED_ARB = 0x202A;
enum WGL_TYPE_RGBA_ARB = 0x202B;
enum WGL_TYPE_COLORINDEX_ARB = 0x202C;
alias BOOL function(HDC hdc, int iPixelFormat, int iLayerPlane, UINT nAttributes, const(int*) piAttributes, int* piValues) PFNWGLGETPIXELFORMATATTRIBIVARBPROC;
alias BOOL function(HDC hdc, int iPixelFormat, int iLayerPlane, UINT nAttributes, const(int*) piAttributes, FLOAT* pfValues) PFNWGLGETPIXELFORMATATTRIBFVARBPROC;
alias BOOL function(HDC hdc, const(int*) piAttribIList, const(FLOAT)* pfAttribFList, UINT nMaxFormats, int* piFormats, UINT* nNumFormats) PFNWGLCHOOSEPIXELFORMATARBPROC;
PFNWGLGETPIXELFORMATATTRIBIVARBPROC wglGetPixelFormatAttribivARB;
PFNWGLGETPIXELFORMATATTRIBFVARBPROC wglGetPixelFormatAttribfvARB;
PFNWGLCHOOSEPIXELFORMATARBPROC wglChoosePixelFormatARB;

// WGL_EXT_swap_control
bool WGL_EXT_swap_control = false;
alias BOOL function(int interval) PFNWGLSWAPINTERVALEXTPROC;
alias int function() PFNWGLGETSWAPINTERVALEXTPROC;
PFNWGLSWAPINTERVALEXTPROC wglSwapIntervalEXT;
PFNWGLGETSWAPINTERVALEXTPROC wglGetSwapIntervalEXT;

// WGL_EXT_swap_control_tear
bool WGL_EXT_swap_control_tear = false;
