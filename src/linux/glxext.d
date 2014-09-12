module linux.glxext;

import core.stdc.string;
import cstr;
import deimos.X11.X;
import deimos.X11.Xlib;
import deimos.X11.Xutil;
import gl.core;
import gl.ext;
import linux.glx;
import linux.init: display, screen;
import linux.glloader;
import log;

package void loadGLXExtensions()
{
	scope (failure) GLX_ARB_get_proc_address = false;
	if (isGLXExtSupported("GLX_ARB_get_proc_address"))
	{
		glXGetProcAddressARB = cast(PFNGLXGETPROCADDRESSARBPROC) glGetProcAddress("glXGetProcAddressARB");
		GLX_ARB_get_proc_address = true;
	}

	scope (failure) GLX_ARB_create_context = false;
	if (isGLXExtSupported("GLX_ARB_create_context"))
	{
		glXCreateContextAttribsARB = cast(PFNGLXCREATECONTEXTATTRIBSARBPROC) glGetProcAddress("glXCreateContextAttribsARB");
		GLX_ARB_create_context = true;
	}

	scope (failure) GLX_ARB_create_context_profile = false;
	if (isGLXExtSupported("GLX_ARB_create_context_profile"))
	{
		GLX_ARB_create_context_profile = true;
	}

	scope (failure) GLX_ARB_multisample = false;
	if (isGLXExtSupported("GLX_ARB_multisample"))
	{
		GLX_ARB_multisample = true;
	}

	scope (failure) GLX_EXT_swap_control = false;
	if (isGLXExtSupported("GLX_EXT_swap_control"))
	{
		glXSwapIntervalEXT = cast(PFNGLXSWAPINTERVALEXTPROC) glGetProcAddress("glXSwapIntervalEXT");
		GLX_EXT_swap_control = true;
	}

	scope (failure) GLX_EXT_swap_control_tear = false;
	if (isGLXExtSupported("GLX_EXT_swap_control_tear"))
	{
		GLX_EXT_swap_control_tear = true;
	}

	scope (failure) GLX_SGI_swap_control = false;
	if (isGLXExtSupported("GLX_SGI_swap_control"))
	{
		glXSwapIntervalSGI = cast(PFNGLXSWAPINTERVALSGIPROC) glGetProcAddress("glXSwapIntervalSGI");
		GLX_SGI_swap_control = true;
	}
}

package void unloadGLXExtensions() nothrow
{
	GLX_ARB_get_proc_address = false;
	GLX_ARB_create_context = false;
	GLX_ARB_create_context_profile = false;
	GLX_ARB_multisample  = false;
	GLX_EXT_swap_control = false;
	GLX_EXT_swap_control_tear = false;
	GLX_SGI_swap_control = false;
}

/*
  ext must be a null terminated string
*/
private bool isGLXExtSupported(const(char)* ext)
{
	if (isExtPresent(ext, glXQueryExtensionsString(display, screen)))
	{
		info("GLX Extension found: %s", cstr2dstr(ext));
		return true;
	}
	warning("GLX Extension not found: %s", cstr2dstr(ext));
	return false;
}

extern (C) __gshared nothrow:

// GLX_ARB_create_context
bool GLX_ARB_create_context = false;
enum GLX_CONTEXT_DEBUG_BIT_ARB = 0x00000001;
enum GLX_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB = 0x00000002;
enum GLX_CONTEXT_MAJOR_VERSION_ARB = 0x2091;
enum GLX_CONTEXT_MINOR_VERSION_ARB = 0x2092;
enum GLX_CONTEXT_FLAGS_ARB = 0x2094;
alias GLXContext function(Display* dpy, GLXFBConfig config, GLXContext share_context, Bool direct, const(int*) attrib_list) PFNGLXCREATECONTEXTATTRIBSARBPROC;
PFNGLXCREATECONTEXTATTRIBSARBPROC glXCreateContextAttribsARB;

// GLX_ARB_create_context_profile
bool GLX_ARB_create_context_profile = false;
enum GLX_CONTEXT_CORE_PROFILE_BIT_ARB = 0x00000001;
enum GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB = 0x00000002;
enum GLX_CONTEXT_PROFILE_MASK_ARB = 0x9126;

// GLX_ARB_get_proc_address
bool GLX_ARB_get_proc_address = false;
alias __GLXextFuncPtr function(const(GLubyte)* procName) PFNGLXGETPROCADDRESSARBPROC;
PFNGLXGETPROCADDRESSARBPROC glXGetProcAddressARB;

// GLX_ARB_multisample
bool GLX_ARB_multisample  = false;
enum GLX_SAMPLE_BUFFERS_ARB = 100000;
enum GLX_SAMPLES_ARB = 100001;

// GLX_EXT_swap_control
bool GLX_EXT_swap_control = false;
enum GLX_SWAP_INTERVAL_EXT = 0x20F1;
enum GLX_MAX_SWAP_INTERVAL_EXT = 0x20F2;
alias void function(Display* dpy, GLXDrawable drawable, int interval) PFNGLXSWAPINTERVALEXTPROC;
PFNGLXSWAPINTERVALEXTPROC glXSwapIntervalEXT;

// GLX_EXT_swap_control_tear
bool GLX_EXT_swap_control_tear = false;
enum GLX_LATE_SWAPS_TEAR_EXT = 0x20F3;

// GLX_SGI_swap_control
bool GLX_SGI_swap_control = false;
alias int function(int interval) PFNGLXSWAPINTERVALSGIPROC;
PFNGLXSWAPINTERVALSGIPROC glXSwapIntervalSGI;
