module windows.windows;

public import core.sys.windows.windows;

package extern (Windows) nothrow:

/*enum VK_OEM_1 == 0xBA;
enum VK_OEM_PLUS == 0xBB;
enum VK_OEM_COMMA == 0xBC;
enum VK_OEM_MINUS == 0xBD;
enum VK_OEM_PERIOD == 0xBE;
enum VK_OEM_2 == 0xBF;
enum VK_OEM_3 == 0xC0;
enum VK_OEM_4 == 0xDB;
enum VK_OEM_5 == 0xDC;
enum VK_OEM_6 == 0xDD;
enum VK_OEM_7 == 0xDE;
enum VK_OEM_8 == 0xDF;
enum VK_OEM_AX == 0xE1;
enum VK_OEM_102 == 0xE2;*/

enum KF_EXTENDED = 0x0100;
enum KF_MENUMODE = 0x1000;
enum KF_UP = 0x8000;

enum WM_MOUSEWHEEL = 0x020A;
enum WM_POWERBROADCAST = 0x0218;
enum WM_ENTERSIZEMOVE = 0x0231;
enum WM_EXITSIZEMOVE = 0x0232;

enum PBT_APMQUERYSUSPEND = 0x0000;
enum BROADCAST_QUERY_DENY = 0x424D5144;

enum SC_SCREENSAVE = 0xF140;
enum SC_MONITORPOWER = 0xF170;

/* Flags for ChangeDisplaySettings */
enum: int {
	CDS_UPDATEREGISTRY = 0x00000001,
	CDS_TEST = 0x00000002,
	CDS_FULLSCREEN = 0x00000004,
	CDS_GLOBAL = 0x00000008,
	CDS_SET_PRIMARY = 0x00000010,
	CDS_VIDEOPARAMETERS = 0x00000020,
	CDS_RESET = 0x40000000,
	CDS_RESET_EX = 0x20000000,
	CDS_NORESET = 0x10000000
}

/* Return values for ChangeDisplaySettings */
enum: int {
	DISP_CHANGE_SUCCESSFUL =  0,
	DISP_CHANGE_RESTART =  1,
	DISP_CHANGE_FAILED = -1,
	DISP_CHANGE_BADMODE = -2,
	DISP_CHANGE_NOTUPDATED = -3,
	DISP_CHANGE_BADFLAGS = -4,
	DISP_CHANGE_BADPARAM = -5,
	DISP_CHANGE_BADDUALVIEW= -6
}

/*
 * Window field offsets for GetWindowLong()
 */
version(Win32)
{
	enum: int {
		GWL_WNDPROC = -4,
		GWL_HINSTANCE = -6,
		GWL_HWNDPARENT = -8,
		GWL_USERDATA = -21
	}
}
enum: int {
	GWL_STYLE = -16,
	GWL_EXSTYLE = -20,
	GWL_ID = -12,
	GWLP_WNDPROC = -4,
	GWLP_HINSTANCE = -6,
	GWLP_HWNDPARENT = -8,
	GWLP_USERDATA = -21,
	GWLP_ID = -12
}

/*
 * SetWindowPos Flags
 */
enum {
	SWP_NOSIZE = 0x0001,
	SWP_NOMOVE = 0x0002,
	SWP_NOZORDER = 0x0004,
	SWP_NOREDRAW = 0x0008,
	SWP_NOACTIVATE = 0x0010,
	SWP_FRAMECHANGED = 0x0020,  /* The frame changed: send WM_NCCALCSIZE */
	SWP_SHOWWINDOW = 0x0040,
	SWP_HIDEWINDOW = 0x0080,
	SWP_NOCOPYBITS = 0x0100,
	SWP_NOOWNERZORDER = 0x0200,  /* Don't do owner Z ordering */
	SWP_NOSENDCHANGING = 0x0400,  /* Don't send WM_WINDOWPOSCHANGING */
	SWP_DEFERERASE = 0x2000,
	SWP_ASYNCWINDOWPOS = 0x4000
}

enum: HWND {
	HWND_TOP = cast(HWND) 0,
	HWND_BOTTOM = cast(HWND) 1,
	HWND_TOPMOST = cast(HWND) -1,
	HWND_NOTOPMOST = cast(HWND) -2
}

struct CREATESTRUCTA
{
	LPVOID lpCreateParams;
	HINSTANCE hInstance;
	HMENU hMenu;
	HWND hwndParent;
	int cy;
	int cx;
	int y;
	int x;
	LONG style;
	LPCSTR lpszName;
	LPCSTR lpszClass;
	DWORD dwExStyle;
}
alias CREATESTRUCTA* LPCREATESTRUCTA;

enum: DWORD {
	ES_SYSTEM_REQUIRED = 0x00000001,
	ES_DISPLAY_REQUIRED = 0x0000000,
	ES_USER_PRESENT = 0x00000004,
	ES_AWAYMODE_REQUIRED = 0x00000040,
	ES_CONTINUOUS = 0x8000000
}
alias DWORD EXECUTION_STATE;
alias DWORD* PEXECUTION_STATE;

struct POINTL
{
	LONG x;
	LONG y;
}
alias POINTL* PPOINTL;

int GET_X_LPARAM(LPARAM lp)
{
	return cast(int) cast(short) LOWORD(lp);
}

int GET_Y_LPARAM(LPARAM lp)
{
	return cast(int) cast(short) HIWORD(lp);
}

enum WHEEL_DELTA = 120;
short GET_WHEEL_DELTA_WPARAM(WPARAM wParam)
{
	return cast(short) HIWORD(wParam);
}

LONG ChangeDisplaySettingsA(DEVMODEA* lpDevMode, DWORD dwFlags);
BOOL DestroyWindow(HWND hWnd);
BOOL GetKeyboardState(PBYTE lpKeyState);
//LONG_PTR GetWindowLongPtr(HWND hWnd, int nIndex);
LONG GetWindowLongA(HWND hWnd, int nIndex);
BOOL KillTimer(HWND hWnd, UINT_PTR uIDEvent);
BOOL SetRect(LPRECT lprc, int xLeft, int yTop, int xRight, int yBottom);
UINT_PTR SetTimer(HWND hWnd, UINT_PTR nIDEvent, UINT uElapse, TIMERPROC lpTimerFunc);
EXECUTION_STATE SetThreadExecutionState(EXECUTION_STATE esFlags);
LONG SetWindowLongA(HWND hWnd, int nIndex, LONG dwNewLong);
BOOL SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags);
//LONG_PTR SetWindowLongPtrA(HWND hWnd, int nIndex, LONG_PTR dwNewLong);
int ToUnicode(UINT wVirtKey, UINT wScanCode, const BYTE *lpKeyState, LPWSTR pwszBuff, int cchBuff, UINT wFlags);
BOOL UnregisterClassA(LPCTSTR lpClassName, HINSTANCE hInstance);
