module linux.glwindow;

import deimos.X11.X, deimos.X11.Xatom, deimos.X11.Xlib, deimos.X11.Xutil;
import gl.core, gl.ext;
import linux.glx, linux.glxext, linux.init, linux.keysym;
import std.string: toStringz;
import cstr, engine, input, log;

enum {
	_NET_WM_STATE_REMOVE = 0,  /* remove/unset property */
	_NET_WM_STATE_ADD    = 1,  /* add/set property */
	_NET_WM_STATE_TOGGLE = 2   /* toggle property  */
}

final class OpenGLWindow
{
private:
	Engine engine;
	GLXFBConfig fbConfig;
	XVisualInfo* visualInfo;
	Colormap colormap;
	Window window;
	GLXContext glContext;
	Cursor hiddenCursor;
	// bool active;
	// bool minimized;
	bool pointerLocked;

public:
	string title;
	int width;
	int height;
	int colorDepth;
	bool fullscreen;

	this(Engine engine)
	{
		this.engine = engine;
	}

	void create()
	{
		if (width <= 0 || height <= 0) {
			width = XDisplayWidth(display, screen);
			height = XDisplayHeight(display, screen);
		}
		if (colorDepth <= 0) {
			colorDepth = XDisplayPlanes(display, screen);
		}

		createWindow();
		createContext();
		makeCurrent();
		loadOpenGLExtensions();

		if (GLX_EXT_swap_control) {
			glXSwapIntervalEXT(display, window, GLX_EXT_swap_control_tear ? -1 : 1);
		} else if (GLX_SGI_swap_control) {
			glXSwapIntervalSGI(1); // NOTE: officially 0 is not supported
		}

		XColor color;
		char[1] data = [0];
		Pixmap bitmap = XCreateBitmapFromData(display, window, data.ptr, 1, 1);
		hiddenCursor = XCreatePixmapCursor(display, bitmap, bitmap, &color, &color, 0, 0);
		XFreePixmap(display, bitmap);
	}

	void destroy()
	{
		XFreeCursor(display, hiddenCursor);
		unloadOpenGLExtensions();
		destroyContext();
		destroyWindow();
	}

	void makeCurrent()
	{
		assert(window);
		glXMakeCurrent(display, cast(GLXDrawable) window, glContext);
	}

	void swapBuffers()
	{
		glXSwapBuffers(display, cast(GLXDrawable) window);
	}

	void resize(int width, int height)
	{
		assert(window);
		XWindowChanges changes;
		changes.width = width;
		changes.height = height;
		XConfigureWindow(display, window, CWWidth | CWHeight, &changes);
	}

	void enterFullscreen()
	{
		XEvent event;
		event.xclient.type = ClientMessage;
		event.xclient.window = window;
		event.xclient.message_type = _NET_WM_STATE;
		event.xclient.format = 32;
		event.xclient.data.l[0] = _NET_WM_STATE_ADD;
		event.xclient.data.l[1] = _NET_WM_STATE_FULLSCREEN;
		XSendEvent(display, XRootWindow(display, screen), False, SubstructureNotifyMask | SubstructureRedirectMask, &event);
	}

	void exitFullscreen()
	{
		XEvent event;
		event.xclient.type = ClientMessage;
		event.xclient.window = window;
		event.xclient.message_type = _NET_WM_STATE;
		event.xclient.format = 32;
		event.xclient.data.l[0] = _NET_WM_STATE_REMOVE;
		event.xclient.data.l[1] = _NET_WM_STATE_FULLSCREEN;
		XSendEvent(display, XRootWindow(display, screen), False, SubstructureNotifyMask | SubstructureRedirectMask, &event);
	}

	void lockPointer()
	{
		pointerLocked = true;
		XDefineCursor(display, window, hiddenCursor);
		centerPointer(display, window);
	}

	void unlockPointer()
	{
		pointerLocked = false;
		XUndefineCursor(display, window);
	}

	void pollEvents()
	{
		XEvent xevent;
		while (XPending(display)) {
			XNextEvent(display, &xevent);
			switch (xevent.type) {
			case KeyPress:
			case KeyRelease:
				XKeyEvent *xkey = &xevent.xkey;
				KeyEvent keyEvent;
				KeySym keysym;
				int length = XLookupString(xkey, cast(char*) &keyEvent.utfCode, 1, &keysym, null);
				if (length != 1) keyEvent.utfCode = dchar.init;
				keyEvent.type = (xkey.type == KeyPress) ? KeyEvent.Type.press : KeyEvent.Type.release;
				keyEvent.symbol = translateKeySym(keysym);
				keyEvent.scanCode = cast(ubyte) xkey.keycode;
				/*
				if ((xevent.xkey.state & Mod1Mask) && (xevent.type == KeyRelease)) {
					switch(keySym)
					{
					case XK_Return:
						//if(render->isFullscreen()) {
						info("ALT+ENTER");
						//setFullscreen(false);
						//XIconifyWindow(display, mainWindow, screen); // send FocusIn !
						//XLowerWindow(display, mainWindow); //does not work everywere
						//}
						return;
					default:
					}
				}
				*/
				engine.input.emit(&keyEvent);
				break;

			case ButtonPress:
			case ButtonRelease:
				XButtonEvent* xbutton = &xevent.xbutton;
				if (xbutton.type == ButtonRelease && (xbutton.button == Button4 || xbutton.button == Button5)) {
					// do not send double mouse scroll events
					break;
				}
				auto event = MouseButtonEvent();
				final switch (xbutton.type)
				{
				case ButtonPress:
					event.type = MouseButtonEvent.Type.press;
					break;
				case ButtonRelease:
					event.type = MouseButtonEvent.Type.release;
					break;
				}
				final switch (xbutton.button)
				{
				case Button1:
					event.button = MouseButton.left;
					break;
				case Button2:
					event.button = MouseButton.middle;
					break;
				case Button3:
					event.button = MouseButton.right;
					break;
				case Button4:
					event.button = MouseButton.scrollUp;
					break;
				case Button5:
					event.button = MouseButton.scrollDown;
					break;
				}
				engine.input.emit(&event);
				break;

			case MotionNotify:
				XMotionEvent* xmotion = &xevent.xmotion;
				auto event = PointerMoveEvent(xmotion.x, xmotion.y);
				if (pointerLocked) {
					if (!hasFocus(xmotion.display, xmotion.window)) break;
					XWindowAttributes windowAttr;
					XGetWindowAttributes(xmotion.display, xmotion.window, &windowAttr);
					event.x -= windowAttr.width / 2;
					event.y -= windowAttr.height / 2;
					if (event.x == 0 && event.y == 0) break;
					centerPointer(xmotion.display, xmotion.window);
				}
				engine.input.emit(&event);
				break;

			case ClientMessage:
				XClientMessageEvent* xclient = &xevent.xclient;
				if (xclient.data.l[0] == WM_DELETE_WINDOW) {
					engine.exit();
				}
				break;

			case LeaveNotify:
				XCrossingEvent* xcrossing = &xevent.xcrossing;
				if (pointerLocked && hasFocus(xcrossing.display, xcrossing.window)) {
					// restore the pointer position after it left the window
					centerPointer(xcrossing.display, xcrossing.window);
				}
				break;

			case FocusIn:
				//active = true;
				break;

			case FocusOut:
				//active = false;
				break;

			case KeymapNotify:
				XRefreshKeyboardMapping(&xevent.xmapping);
				break;

			case ConfigureNotify:
				XConfigureEvent* xconfigure = &xevent.xconfigure;
				this.width = xconfigure.width;
				this.height = xconfigure.height;
				glViewport(0, 0, xconfigure.width, xconfigure.height);
				break;

			default:
				break;
			}
		}
	}

	private void createWindow()
	{
		info("Creating a %dx%d window...", width, height);
		Window rootWindow = XRootWindow(display, screen);

		// TODO: test GLX 1.3
		if (glXChooseFBConfig) {
			int[15] attribList = [
				GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
				GLX_RENDER_TYPE, GLX_RGBA_BIT,
				GLX_X_RENDERABLE, True,
				GLX_X_VISUAL_TYPE, GLX_TRUE_COLOR,
				GLX_DOUBLEBUFFER, True,
				GLX_DEPTH_SIZE, 16,
				GLX_STENCIL_SIZE, 8,
				None
			];
			int nelements;
			GLXFBConfig *fbc = glXChooseFBConfig(display, screen, attribList.ptr, &nelements);
			if (!fbc) {
				fatal("Could not retrieve a compatible framebuffer config");
			}
			fbConfig = *fbc;
			XFree(fbc);
			visualInfo = cast(XVisualInfo*) glXGetVisualFromFBConfig(display, fbConfig);
		} else {
			int[] attribList = [
				GLX_RGBA, True,
				GLX_DOUBLEBUFFER, True,
				GLX_DEPTH_SIZE, 16,
				GLX_STENCIL_SIZE, 4,
				None
			];
			visualInfo = cast(XVisualInfo*) glXChooseVisual(display, screen, attribList.ptr);
			if (!visualInfo) {
				fatal("Could not find a compatible visual");
			}
		}

		colormap = XCreateColormap(display, rootWindow, visualInfo.visual, AllocNone);
		if (!colormap) {
			fatal("Could not create a colormap with the specified visual");
		}

		int x = (DisplayWidth(display, screen) - width) / 2;
		int y = (DisplayHeight(display, screen) - height) / 2;

		XSetWindowAttributes attributes;
		attributes.background_pixel = XBlackPixel(display, screen);
		attributes.colormap = colormap;
		attributes.event_mask = KeyPressMask | KeyReleaseMask | PointerMotionMask |
			ButtonPressMask | ButtonReleaseMask | LeaveWindowMask | FocusChangeMask |
			KeymapStateMask | StructureNotifyMask;

		window = XCreateWindow(
			display,
			rootWindow,
			x, y, width, height, 0,
			visualInfo.depth,
			InputOutput,
			visualInfo.visual,
			CWBackPixel | CWColormap | CWEventMask,
			&attributes
		);

		if (errorLevel > 0) {
			fatal("Could not create the window");
		}

		if (fullscreen) {
			XChangeProperty(
				display,
				window,
				_NET_WM_STATE,
				XA_ATOM,
				32,
				PropModeReplace,
				cast(ubyte*) &_NET_WM_STATE_FULLSCREEN,
				1
			);
		}
		XStoreName(display, window, cast(char*) title.toStringz());
		XSetWMProtocols(display, window, &WM_DELETE_WINDOW, 1);
		XMapWindow(display, window);
	}

	private void destroyWindow()
	{
		if (window) {
			XDestroyWindow(display, window);
			window = None;
		}
		if (colormap) {
			XFreeColormap(display, colormap);
			colormap = None;
		}
		if (visualInfo) {
			XFree(visualInfo);
			visualInfo = null;
		}
		fbConfig = null;
	}

	private void createContext()
	{
		info("Creating a GLX rendering context...");

		if (GLX_ARB_create_context) {
			//TODO
			int[5] attribList = [
				GLX_CONTEXT_MAJOR_VERSION_ARB, 2,
				GLX_CONTEXT_MINOR_VERSION_ARB, 0,
				//GLX_CONTEXT_FLAGS_ARB, GLX_CONTEXT_DEBUG_BIT_ARB// | GLX_CONTEXT_FORWARD_COMPATIBLE_BIT,
				//GLX_CONTEXT_PROFILE_MASK_ARB, GLX_CONTEXT_CORE_PROFILE_BIT,
				None
			];
			glContext = glXCreateContextAttribsARB(display, fbConfig, null, True, attribList.ptr);
		} else {
			if (glXCreateNewContext) {  // TODO: test GLX 1.3
				glContext = glXCreateNewContext(display, fbConfig, GLX_RGBA_TYPE, null, True);
			} else {
				glContext = glXCreateContext(display, visualInfo, null, True);
			}
		}
		if (!glContext || errorLevel > 0) {
			fatal("Can't create a GLX rendering context");
		}
		if (!glXIsDirect(display, glContext)) {
			warning("The GLX context does not support direct rendering");
		}
	}

	private void destroyContext()
	{
		glXMakeCurrent(display, None, null);
		glXDestroyContext(display, glContext);
		glContext = null;
	}
}

private void centerPointer(Display* display, Window window)
{
	XWindowAttributes windowAttr;
	XGetWindowAttributes(display, window, &windowAttr);
	int x = windowAttr.width / 2;
	int y = windowAttr.height / 2;
	XWarpPointer(display, None, window, 0, 0, 0, 0, x, y);
}

private bool hasFocus(Display* display, Window window)
{
	Window focusWindow;
	int revertMode;
	XGetInputFocus(display, &focusWindow, &revertMode);
	return window == focusWindow;
}

/*
void LinuxSystem::setWindow(Display *display, Window window)
{
	this->display = display;
	this->mainWindow = window;

	screen = DefaultScreen(display);
	rootWindow = RootWindow(display, screen);

	Memory::memset(&desktopMode, 0, sizeof(XF86VidModeModeInfo));
	Memory::memset(&fullscreenMode, 0, sizeof(XF86VidModeModeInfo));

	if(render->isFullscreen()) {
		int modeCount, bestMode = -1;
		XF86VidModeModeInfo **modes;
		XF86VidModeGetAllModeLines(display, screen, &modeCount, &modes);

		//First mode is desktop mode
		desktopMode = **modes;

		Vec2i resolution;
		resolution = render->getResolution();

		for(int i = 0; i < modeCount; i++) {
			if((modes[i]->hdisplay == resolution.x) && (modes[i]->vdisplay == resolution.y)) {
				bestMode = i;
			}
		}

		if(bestMode < 0) {
			out("Can't find the desired fullscreen mode");
			//Todo stop app
		} else {
			fullscreenMode = *(modes[bestMode]);
		}

		XFree(modes);
	}

	//Create an invisible cursor
	XColor color;
	char empty[] = {0};
	Pixmap bitmap = XCreateBitmapFromData(display, window, empty, 1, 1);
	cursors[CURSOR_NONE] = XCreatePixmapCursor(display, bitmap, bitmap, &color, &color, 0, 0);

	//Load sysyems curosors
	cursors[CURSOR_ARROW]		= XCreateFontCursor(display, XC_left_ptr);
	cursors[CURSOR_HAND]		= XCreateFontCursor(display, XC_hand1);
	cursors[CURSOR_SIZENESW]	= XCreateFontCursor(display, XC_left_ptr);
	cursors[CURSOR_SIZENS]		= XCreateFontCursor(display, XC_sb_v_double_arrow);
	cursors[CURSOR_SIZENWSE]	= XCreateFontCursor(display, XC_top_left_arrow);
	cursors[CURSOR_SIZEWE]		= XCreateFontCursor(display, XC_left_ptr);

	//for(unsigned i = 0; i < CURSOR_LAST; i++) XFreeCursor(display, cursors[i]);
}

void LinuxSystem::setFullscreen(bool fullscreen)
{
	if(fullscreen) {
		//XF86VidModeSwitchToMode(display, screen, &fullscreenMode);
		//XF86VidModeSetViewPort(display, screen, 0, 0);
		//XFlush(display);

		//XGrabKeyboard(display, mainWindow, True, GrabModeAsync, GrabModeAsync, CurrentTime);
		//XGrabPointer(display, mainWindow, True, ButtonPressMask, GrabModeAsync, GrabModeAsync, mainWindow, None, CurrentTime);
		//XWarpPointer(display, None, mainWindow, 0, 0, 0, 0, 0, 0);
	} else {
		//XUngrabPointer(display, CurrentTime);
		//XUngrabKeyboard(display, CurrentTime);

		//XF86VidModeSwitchToMode(display, screen, &desktopMode);
		//XF86VidModeSetViewPort(display, screen, 0, 0);
		//XFlush(display);
	}
}
*/
