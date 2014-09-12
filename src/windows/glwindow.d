module windows.glwindow;

import gl.core;
import std.string: toStringz;
import windows.vkeys;
import windows.wgl;
import windows.wglext;
import windows.windows;
import cstr;
import engine;
import input;
import log;

private immutable DWORD fullscrWndStyle = WS_POPUP | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_VISIBLE;
private immutable DWORD normalWndStyle = WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_VISIBLE;

final class OpenGLWindow
{
	string title;
	int width;
	int height;
	int colorDepth;
	bool fullscreen;

private:
	Engine engine;
	HWND hWnd;
	HDC hDC;
	HGLRC hGLRC;
	bool active = false;
	bool pointerLocked = false;

public:
	this(Engine engine)
	{
		this.engine = engine;
	}

	void create()
	{
		HDC hScreenDC = GetDC(null);
		if (width <= 0 || height <= 0) {
			width = GetDeviceCaps(hScreenDC, HORZRES);
			height = GetDeviceCaps(hScreenDC, VERTRES);
			fullscreen = true;
		}
		if (colorDepth <= 0) {
			colorDepth = GetDeviceCaps(hScreenDC, BITSPIXEL);
		}
		ReleaseDC(null, hScreenDC);

		createWindow();
		createContext();
		makeCurrent();

		if (WGL_EXT_swap_control) {
			wglSwapIntervalEXT(WGL_EXT_swap_control_tear ? -1 : 1);
		}
	}

	void destroy()
	{
		destroyContext();
		destroyWindow();
	}

	void makeCurrent()
	{
		wglMakeCurrent(hDC, hGLRC);
	}

	void swapBuffers()
	{
		SwapBuffers(hDC);
	}

	void resize(int width, int height)
	{
		RECT rect;
		DWORD exstyle = GetWindowLongA(hWnd, GWL_EXSTYLE);
		DWORD style = GetWindowLongA(hWnd, GWL_STYLE);
		SetRect(&rect, 0, 0, width, height);
		AdjustWindowRectEx(&rect, style, FALSE, exstyle);
		width = rect.right - rect.left;
		height = rect.bottom - rect.top;
		SetWindowPos(hWnd, HWND_TOP, 0, 0, width, height, SWP_NOMOVE);
	}

	void lockPointer()
	{
		pointerLocked = true;
		SetActiveWindow(hWnd);
		centerCursor(hWnd);
		clipCursorWnd(hWnd);
	}

	void unlockPointer()
	{
		pointerLocked = false;
	}

	void pollEvents()
	{
		MSG msg;
		while (PeekMessageA(&msg, null, 0, 0, PM_REMOVE | PM_NOYIELD)) {
			if (msg.message == WM_QUIT) {
				engine.exit();
			}
			//TranslateMessage(&msg);
			DispatchMessageA(&msg);
		}
	}

private:
	void createWindow()
	{
		info("Creating a %dx%d window...", width, height);

		DWORD exstyle = 0;
		DWORD style = normalWndStyle;
		if (fullscreen) {
			exstyle = WS_EX_TOPMOST;
			style = fullscrWndStyle;
		}

		// adjust the window size
		RECT rect;
		SetRect(&rect, 0, 0, width, height);
		AdjustWindowRectEx(&rect, style, FALSE, exstyle);
		int adjustedWidth = rect.right - rect.left;
		int adjustedHeight = rect.bottom - rect.top;

		// create the window
		hWnd = CreateWindowExA(
			exstyle,
			glWndClassName,
			title.toStringz(),
			style,
			CW_USEDEFAULT, CW_USEDEFAULT,
			adjustedWidth,
			adjustedHeight,
			null,
			null,
			GetModuleHandleA(null),
			cast(LPVOID) this
		);

		if (!hWnd) {
			fatal("Can't create the window (error code %d)", GetLastError());
		}

		hDC = GetDC(hWnd);
		if (!hDC) {
			fatal("Can't retrieve the device context of the window(error code %d)", GetLastError());
		}
	}

	void destroyWindow()
	{
		ReleaseDC(hWnd, hDC);
		DestroyWindow(hWnd);
		hDC = null;
		hWnd = null;
	}

	void createContext()
	{
		info("Creating an OpenGL rendering context...");

		PIXELFORMATDESCRIPTOR pfd;
		pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
		pfd.nVersion = 1;
		pfd.dwFlags = PFD_DOUBLEBUFFER | PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL; //PFD_GENERIC_ACCELERATED
		pfd.iPixelType = PFD_TYPE_RGBA;
		pfd.cColorBits = 32;
		pfd.cDepthBits = 16;
		pfd.cStencilBits = 8;
		pfd.iLayerType = PFD_MAIN_PLANE;

		int pixelFormat;
		if (WGL_ARB_pixel_format) {
			int[17] attribIList = [
				WGL_DRAW_TO_WINDOW_ARB, GL_TRUE,
				WGL_ACCELERATION_ARB, WGL_FULL_ACCELERATION_ARB, //WGL_NO_ACCELERATION_ARB, WGL_GENERIC_ACCELERATION_ARB
				WGL_SUPPORT_OPENGL_ARB, GL_TRUE,
				WGL_DOUBLE_BUFFER_ARB, GL_TRUE,
				WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
				WGL_COLOR_BITS_ARB, colorDepth,
				WGL_DEPTH_BITS_ARB, 16,
				WGL_STENCIL_BITS_ARB, 8,
				0
			];
			/*
			if(multisamples > 0) {
				if(wgl_arb_multisample) {
					attributes[n++] = WGL_SAMPLE_BUFFERS_ARB;
					attributes[n++] = 1;
					attributes[n++] = WGL_SAMPLES_ARB;
					attributes[n++] = multisamples;
				} else {
					debugf("Multisampling is not supported by your videocard");
					multisamples = 0;
				}
			}
			*/
			uint numFormats;
			wglChoosePixelFormatARB(hDC, attribIList.ptr, null, 1, &pixelFormat, &numFormats);
		} else {
			pixelFormat = ChoosePixelFormat(hDC, &pfd);
		}

		if (pixelFormat == 0) {
			fatal("Can't find an appropriate pixel format (error code %d)", GetLastError());
		}

		if (!SetPixelFormat(hDC, pixelFormat, &pfd)) {
			fatal("Can't set the specified pixel format (error code %d)", GetLastError());
		}

		if (WGL_ARB_create_context) {
			//TODO
			int[7] attribList = [
				WGL_CONTEXT_MAJOR_VERSION_ARB, 2,
				WGL_CONTEXT_MINOR_VERSION_ARB, 0,
				WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_DEBUG_BIT_ARB/* | WGL_CONTEXT_FORWARD_COMPATIBLE_BIT*/,
				//WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT,
				0
			];
			hGLRC = wglCreateContextAttribsARB(hDC, null, attribList.ptr);
		} else {
			hGLRC = wglCreateContext(hDC);
		}

		if (!hGLRC) {
			fatal("Can't create a new OpenGL rendering context (error code %d)", GetLastError());
		}
	}

	void destroyContext()
	{
		wglMakeCurrent(null, null);
		wglDeleteContext(hGLRC);
		hGLRC = null;
	}

	void enterFullscreen() nothrow
	{
		SetWindowLongA(hWnd, GWL_EXSTYLE, WS_EX_TOPMOST);
		SetWindowLongA(hWnd, GWL_STYLE, WS_POPUP | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_VISIBLE);
		DEVMODEA dm;
		dm.dmSize       = DEVMODEA.sizeof;
		dm.dmFields     = DM_PELSWIDTH | DM_PELSHEIGHT | DM_BITSPERPEL;
		dm.dmPelsWidth  = width;
		dm.dmPelsHeight = height;
		dm.dmBitsPerPel = colorDepth;
		if (ChangeDisplaySettingsA(&dm, CDS_FULLSCREEN) != DISP_CHANGE_SUCCESSFUL) {
			//warning("Can't set the requested display mode");
		}
	}

	void exitFullscreen() nothrow
	{
		SetWindowLongA(hWnd, GWL_EXSTYLE, 0);
		SetWindowLongA(hWnd, GWL_STYLE, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_VISIBLE);
		ChangeDisplaySettingsA(null, 0);
	}
}

package:

private immutable char* glWndClassName = "OpenGLWindowClass";

void registerWndClass(HINSTANCE hInstance)
{
	WNDCLASSEXA wc;
	wc.cbSize = WNDCLASSEXA.sizeof;
	wc.style = CS_VREDRAW | CS_HREDRAW | CS_OWNDC;
	wc.lpfnWndProc = &WndProc;
	wc.hInstance = hInstance;
	wc.hIcon = LoadIconA(hInstance, cast(LPSTR) 101);
	wc.hbrBackground = GetStockObject(BLACK_BRUSH);
	wc.hCursor = LoadCursorA(null, IDC_ARROW);
	wc.lpszClassName = glWndClassName;

	if (!RegisterClassExA(&wc)) {
		fatal("Can't register the window class (error code %d)", GetLastError());
	}
}

void unregisterWndClass(HINSTANCE hInstance)
{
	UnregisterClassA(glWndClassName, hInstance);
}

private:

extern (Windows) LRESULT WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
{
	auto window = cast(OpenGLWindow) cast(void*) GetWindowLongA(hWnd, GWL_USERDATA);
	auto engine = window ? window.engine : null;

	switch (message)
	{
	case WM_CREATE:
		// save the pointer to the OpenGLWindow instance
		auto createstruct = cast(LPCREATESTRUCTA) lParam;
		SetWindowLongA(hWnd, GWL_USERDATA, cast(LONG) createstruct.lpCreateParams);
		return 0;

	/*
	case WM_MOVE:
		return 0;
	*/

	case WM_SIZE:
		int width = LOWORD(lParam);
		int height = HIWORD(lParam);
		glViewport(0, 0, width, height);
		window.width = width;
		window.height = height;
		return 0;

	case WM_ACTIVATE:
		switch (LOWORD(wParam)) {
		case WA_INACTIVE:
			window.active = false;
			ClipCursor(null);
			if (window.fullscreen) {
				window.exitFullscreen();
				ShowWindow(hWnd, SW_MINIMIZE);
			}
			break;
		case WA_ACTIVE:
		case WA_CLICKACTIVE:
			window.active = true;
			if (window.fullscreen) {
				window.enterFullscreen();
				ShowWindow(hWnd, SW_RESTORE);
			}
			break;
		default:
		}

		return 0;

	/*
	case WM_PAINT:
		HDC hdc;
		RECT rect;
		PAINTSTRUCT ps;
		GetClientRect(hWnd, &rect);
		hdc = BeginPaint(hWnd, &ps);
		SetBkMode(hdc, TRANSPARENT);
		SetTextColor(hdc, RGB(255, 255, 255));
		TextOut(hdc, 5, rect.bottom - 21, "Loading...", 10);
		SetTextColor(hdc, RGB(0, 0, 0));
		TextOut(hdc, 6, rect.bottom - 20, "Loading...", 10);
		EndPaint(hWnd, &ps);
		return 0;
		break;
	*/

	case WM_CLOSE:
		PostQuitMessage(0);
		return 0;

	case WM_KEYDOWN:
	case WM_KEYUP:
	case WM_SYSKEYDOWN:
	case WM_SYSKEYUP:
		if (message == WM_SYSKEYDOWN && wParam == VK_F4) break;  // alt + F4
		ushort keyFlags = HIWORD(lParam);
		ubyte scanCode = (lParam >> 16) & 0xFF;
		bool isExtended = (keyFlags & KF_EXTENDED) != 0;
		switch (wParam) {
		case VK_SHIFT:
			wParam = (scanCode == 0x36) ? VK_RSHIFT : VK_LSHIFT;
			break;
		case VK_CONTROL:
			wParam = isExtended ? VK_RCONTROL : VK_LCONTROL;
			break;
		case VK_MENU:
			wParam = isExtended ? VK_RMENU : VK_LMENU;
			break;
		default:
		}

		BYTE[256] keyboardState;
		GetKeyboardState(keyboardState.ptr);

		KeyEvent keyEvent;
		keyEvent.symbol = virtualKeyToKeySymbol[wParam & 0xFF];

		if (keyFlags & KF_UP) {
			keyEvent.type = KeyEvent.Type.release;
		} else {
			keyEvent.type = KeyEvent.Type.press;
		}

		keyEvent.utfCode = 0;
		int length = ToUnicode(
			wParam,
			scanCode,
			keyboardState.ptr,
			cast(LPWSTR) &keyEvent.utfCode,
			1,
			(keyFlags & KF_MENUMODE) != 0
		);
		if (length != 1) keyEvent.utfCode = dchar.init;

		keyEvent.scanCode = scanCode;
		Input input = window.engine.input;
		scope (failure) {
			MessageBoxA(null, "KeyEvent", "Error", MB_ICONEXCLAMATION);
			return 0;
		}
		input.emit(&keyEvent);
		return 0;

	case WM_MOUSEMOVE:
		if (!window.active) break;
		auto event = PointerMoveEvent(GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam));
		if (window.pointerLocked) {
			RECT rect;
			GetClientRect(hWnd, &rect);
			event.x -= rect.right / 2;
			event.y -= rect.bottom / 2;
			if (event.x == 0 && event.y == 0) {
				return 0;
			}
			centerCursor(hWnd);
			clipCursorWnd(hWnd);
		}
		scope (failure) {
			MessageBoxA(null, "PointerMoveEvent", "Error", MB_ICONEXCLAMATION);
			return 0;
		}
		engine.input.emit(&event);
		return 0;

	case WM_LBUTTONDOWN:
	case WM_LBUTTONUP:
	case WM_MBUTTONDOWN:
	case WM_MBUTTONUP:
	case WM_RBUTTONDOWN:
	case WM_RBUTTONUP:
		MouseButtonEvent.Type type;
		MouseButton button;
		if (message == WM_LBUTTONDOWN) {
			type = MouseButtonEvent.Type.press;
			button = MouseButton.left;
		} else if  (message == WM_LBUTTONUP) {
			type = MouseButtonEvent.Type.release;
			button = MouseButton.left;
		} else if (message == WM_MBUTTONDOWN) {
			type = MouseButtonEvent.Type.press;
			button = MouseButton.middle;
		} else if (message == WM_MBUTTONUP) {
			type = MouseButtonEvent.Type.release;
			button = MouseButton.middle;
		} else if (message == WM_RBUTTONDOWN) {
			type = MouseButtonEvent.Type.press;
			button = MouseButton.right;
		} else if (message == WM_RBUTTONUP) {
			type = MouseButtonEvent.Type.release;
			button = MouseButton.right;
		}
		auto event = MouseButtonEvent(type, button);
		event.x = GET_X_LPARAM(lParam);
		event.y = GET_Y_LPARAM(lParam);
		Input input = window.engine.input;
		scope (failure) {
			MessageBoxA(null, "MouseButtonEvent", "Error", MB_ICONEXCLAMATION);
			return 0;
		}
		input.emit(&event);
		return 0;

	case WM_MOUSEWHEEL:
		Input input = window.engine.input;
		auto event = MouseButtonEvent(MouseButtonEvent.Type.press);
		event.x = GET_X_LPARAM(lParam);
		event.y = GET_Y_LPARAM(lParam);
		short delta = GET_WHEEL_DELTA_WPARAM(wParam) / WHEEL_DELTA;
		scope (failure) return 0;
		if (delta > 0) {
			event.button = MouseButton.scrollUp;
			while (delta-- > 0) input.emit(&event);
		} else if (delta < 0) {
			event.button = MouseButton.scrollDown;
			while (delta++ < 0) input.emit(&event);
		}
		return 0;

	case WM_POWERBROADCAST:
		// Windows XP and 2003 only
		if (wParam == PBT_APMQUERYSUSPEND) {
			return BROADCAST_QUERY_DENY;
		}
		break;

	case WM_ENTERSIZEMOVE:
		//SetTimer(hWnd, 100, 15, &TimerProc);
		scope (failure) return 0;
		engine.audio.suspend();
		return 0;

	case WM_EXITSIZEMOVE:
		//KillTimer(hWnd, 100);
		scope (failure) return 0;
		engine.audio.resume();
		return 0;

	default:
	}

	return DefWindowProcA(hWnd, message, wParam, lParam);
}

/*
VOID TimerProc(HWND hWnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime)
{
	scope (failure) {
		scope (failure) return;
		KillTimer(hWnd, idEvent);
		return;
	}
	gEngine.frame();
}
*/

void centerCursor(HWND hWnd) nothrow
{
	RECT rect;
	GetClientRect(hWnd, &rect);
	MapWindowPoints(hWnd, null, cast(LPPOINT) &rect, 2);
	SetCursorPos((rect.left + rect.right) / 2, (rect.top + rect.bottom) / 2);
}

void clipCursorWnd(HWND hWnd) nothrow
{
	RECT rect;
	GetClientRect(hWnd, &rect);
	MapWindowPoints(hWnd, null, cast(LPPOINT) &rect, 2);
	ClipCursor(&rect);
}
