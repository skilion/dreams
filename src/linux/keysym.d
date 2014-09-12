module linux.keysym;

import deimos.X11.X;
import deimos.X11.keysym;
import input;

package:

KeySymbol translateKeySym(KeySym keysym)
{
	//Letters
	if (keysym >= XK_a && keysym <= XK_z)
	{
		return cast(KeySymbol) (KeySymbol.k_a + keysym - XK_a);
	}
	if (keysym >= XK_A && keysym <= XK_A)
	{
		return cast(KeySymbol) (KeySymbol.k_a + keysym - XK_A);
	}
	//Numbers
	if (keysym >= XK_0 && keysym <= XK_9)
	{
		return cast(KeySymbol) (KeySymbol.k_0 + keysym - XK_0);
	}
	/*
	//Numeric keypad
	if (keysym >= XK_KP_0 && keysym <= XK_KP_9)
	{
		return cast(KeySymbol) (KeySymbol.KP_0 + keysym - XK_KP_0);
	}
	*/
	//Function keys
	if (keysym >= XK_F1 && keysym <= XK_F12)
	{
		return cast(KeySymbol) (KeySymbol.k_f1 + keysym - XK_F1);
	}

	switch (keysym)
	{
	//case XK_ISO_Level3_Shift:	return KeySymbol.k_ralt; //it alt gr
	case XK_BackSpace:		return KeySymbol.k_backspace;
	case XK_Tab:			return KeySymbol.k_tab;
	//case XK_Clear:			return KeySymbol.k_clear;
	case XK_Return:			return KeySymbol.k_return;
	case XK_Pause:			return KeySymbol.k_pause;
	case XK_Escape:			return KeySymbol.k_escape;
	case XK_space:			return KeySymbol.k_space;
	case XK_Left:			return KeySymbol.k_left;
	case XK_Up:				return KeySymbol.k_up;
	case XK_Right:			return KeySymbol.k_right;
	case XK_Down:			return KeySymbol.k_down;
	case XK_Page_Up:		return KeySymbol.k_pageup;
	case XK_Page_Down:		return KeySymbol.k_pagedown;
	case XK_End:			return KeySymbol.k_end;
	case XK_Home:			return KeySymbol.k_home;
	case XK_Insert:			return KeySymbol.k_insert;
	case XK_Delete:			return KeySymbol.k_delete;
	//case XK_Caps_Lock:		return KeySymbol.k_capital;
	/*
	case XK_Num_Lock:		return KeySymbol.k_numlock;
	case XK_KP_Space:		return KeySymbol.k_space;
	case XK_KP_Enter:		return KeySymbol.k_enter;
	case XK_KP_Home:		return KeySymbol.k_home;
	case XK_KP_Left:		return KeySymbol.k_left;
	case XK_KP_Up:			return KeySymbol.k_up;
	case XK_KP_Right:		return KeySymbol.k_right;
	case XK_KP_Down:		return KeySymbol.k_down;
	case XK_KP_Prior:		return KeySymbol.k_prior;
	case XK_KP_Next:		return KeySymbol.k_next;
	case XK_KP_End:			return KeySymbol.k_end;
	case XK_KP_Insert:		return KeySymbol.k_insert;
	case XK_KP_Delete:		return KeySymbol.k_delete;
	case XK_KP_Multiply:	return KeySymbol.k_multiply;
	case XK_KP_Add:			return KeySymbol.k_add;
	case XK_KP_Subtract:	return KeySymbol.k_subtract;
	case XK_KP_Decimal:		return KeySymbol.k_decimal;
	case XK_KP_Divide:		return KeySymbol.k_divide;
	*/
	case XK_Control_L:		return KeySymbol.k_lctrl;
	case XK_Control_R:		return KeySymbol.k_rctrl;
	case XK_Shift_L:		return KeySymbol.k_lshift;
	case XK_Shift_R:		return KeySymbol.k_rshift;
	case XK_Alt_L:			return KeySymbol.k_lalt;
	case XK_Alt_R:			return KeySymbol.k_ralt;
	default:
	}

	return KeySymbol.k_unknow;
}
