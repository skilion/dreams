module input;

import signals;

enum KeySymbol
{
	k_unknow,
	k_backspace,
	k_tab,
	k_return,
	k_pause,
	k_escape,
	k_space,
	k_0, k_1, k_2, k_3, k_4, k_5, k_6, k_7, k_8, k_9,
	k_a, k_b, k_c, k_d, k_e, k_f, k_g, k_h, k_i, k_j, k_k, k_l, k_m,
	k_n, k_o, k_p, k_q, k_r, k_s, k_t, k_u, k_v, k_w, k_x, k_y, k_z,
	/*
	kp_0, kp_1, kp_2, kp_3, kp_4, kp_5, kp_6, kp_7, kp_8, kp_9,
	kp_add,
	kp_divide,
	kp_decimal,
	kp_numlock,
	kp_multiply,
	kp_subtract,
	kp_clear,
	//kp_separator,
	*/
	k_left,
	k_up,
	k_right,
	k_down,
	k_f1, k_f2, k_f3, k_f4, k_f5, k_f6, k_f7, k_f8, k_f9, k_f10, k_f11, k_f12,
	k_pageup,
	k_pagedown,
	k_end,
	k_home,
	k_insert,
	k_delete,
	k_lctrl,
	k_rctrl,
	k_lshift,
	k_rshift,
	k_lalt,
	k_ralt,
}

immutable string[KeySymbol.max + 1] keySymbolToString =
[
	"unknow",
	"backspace",
	"tab",
	"return",
	"pause",
	"escape",
	"space",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
	"N", "O", "P", "Q", "R", "S", "O", "U", "V", "W", "X", "Y", "Z",
	"left arrow",
	"up arrow",
	"right arrow",
	"down arrow",
	"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
	"page up",
	"page down",
	"end",
	"home",
	"insert",
	"delete",
	"left ctrl",
	"right ctrl",
	"left shift",
	"right shift",
	"left alt",
	"right alt"
];

struct KeyEvent
{
	enum Type
	{
		press,
		release
	}

	Type type;
	KeySymbol symbol;
	ubyte scanCode;
	dchar utfCode;
}

enum MouseButton
{
	left,
	middle,
	right,
	scrollUp,
	scrollDown
}

immutable string[MouseButton.max + 1] mouseButtonToString =
[
	"left",
	"middle",
	"right",
	"scroll wheel up",
	"scroll wheel down"
];

struct MouseButtonEvent
{
	enum Type
	{
		press,
		release
	}

	Type type;
	MouseButton button;
	int x, y; // pointer position
}

struct PointerMoveEvent
{
	int x, y;
}

final class Input
{
	mixin Signal!(const KeyEvent*);
	mixin Signal!(const MouseButtonEvent*);
	mixin Signal!(const PointerMoveEvent*);
}
