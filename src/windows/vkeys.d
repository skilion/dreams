module windows.vkeys;

import windows.windows;
import input;

package:

KeySymbol[256] virtualKeyToKeySymbol;

static this()
{
	//Letters
	for (ubyte i = 0x41; i <= 0x5A; i++)
	{
		virtualKeyToKeySymbol[i] = cast(KeySymbol) (KeySymbol.k_a + i - 0x41);
	}

	//Numbers
	for (ubyte i = 0x30; i <= 0x39; i++)
	{
		virtualKeyToKeySymbol[i] = cast(KeySymbol) (KeySymbol.k_0 + i - 0x30);
	}

	//Numeric keypad
	/*for(ubyte i = VK_NUMPAD0; i <= VK_NUMPAD9; i++)
	{
		virtualKeyToKeySymbol[i] = cast(KeySymbol) (KeySymbol.kp_0 + i - VK_NUMPAD0);
	}*/

	//Function keys
	for (ubyte i = VK_F1; i <= VK_F12; i++)
	{
		virtualKeyToKeySymbol[i] = cast(KeySymbol) (KeySymbol.k_f1 + i - VK_F1);
	}

	virtualKeyToKeySymbol[VK_BACK] = KeySymbol.k_backspace;
	virtualKeyToKeySymbol[VK_TAB] = KeySymbol.k_tab;
	//virtualKeyToKeySymbol[VK_CLEAR] = KeySymbol.kp_clear;
	virtualKeyToKeySymbol[VK_RETURN] = KeySymbol.k_return;
	virtualKeyToKeySymbol[VK_PAUSE] = KeySymbol.k_pause;
	//virtualKeyToKeySymbol[VK_CAPITAL] = KeySymbol.k_capital;
	virtualKeyToKeySymbol[VK_ESCAPE] = KeySymbol.k_escape;
	virtualKeyToKeySymbol[VK_SPACE] = KeySymbol.k_space;
	virtualKeyToKeySymbol[VK_PRIOR] = KeySymbol.k_pageup;
	virtualKeyToKeySymbol[VK_NEXT] = KeySymbol.k_pagedown;
	virtualKeyToKeySymbol[VK_END] = KeySymbol.k_end;
	virtualKeyToKeySymbol[VK_HOME] = KeySymbol.k_home;
	virtualKeyToKeySymbol[VK_LEFT] = KeySymbol.k_left;
	virtualKeyToKeySymbol[VK_UP] = KeySymbol.k_up;
	virtualKeyToKeySymbol[VK_RIGHT] = KeySymbol.k_right;
	virtualKeyToKeySymbol[VK_DOWN] = KeySymbol.k_down;
	virtualKeyToKeySymbol[VK_INSERT] = KeySymbol.k_insert;
	virtualKeyToKeySymbol[VK_DELETE] = KeySymbol.k_delete;
	//virtualKeyToKeySymbol[VK_LWIN]		= KeySymbol.k_lsystem;
	//virtualKeyToKeySymbol[VK_RWIN]		= KeySymbol.k_rsystem;
	//virtualKeyToKeySymbol[VK_APPS]		= KeySymbol.k_application;
	//virtualKeyToKeySymbol[VK_MULTIPLY]	= KeySymbol.kp_multiply;
	//virtualKeyToKeySymbol[VK_ADD]		= KeySymbol.kp_add;
	//virtualKeyToKeySymbol[VK_SEPARATOR]	= KeySymbol.kp_separator;
	//virtualKeyToKeySymbol[VK_SUBTRACT]	= KeySymbol.kp_subtract;
	//virtualKeyToKeySymbol[VK_DECIMAL]	= KeySymbol.kp_decimal;
	//virtualKeyToKeySymbol[VK_DIVIDE]	= KeySymbol.kp_divide;
	//virtualKeyToKeySymbol[VK_NUMLOCK]	= KeySymbol.kp_numlock;
	virtualKeyToKeySymbol[VK_LSHIFT] = KeySymbol.k_lshift;
	virtualKeyToKeySymbol[VK_RSHIFT] = KeySymbol.k_rshift;
	virtualKeyToKeySymbol[VK_LCONTROL] = KeySymbol.k_lctrl;
	virtualKeyToKeySymbol[VK_RCONTROL] = KeySymbol.k_rctrl;
	virtualKeyToKeySymbol[VK_LMENU] = KeySymbol.k_lalt;
	virtualKeyToKeySymbol[VK_RMENU] = KeySymbol.k_ralt;
}
