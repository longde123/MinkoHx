package minko.input;
import haxe.ds.IntMap;
import minko.signal.Signal2;
import minko.signal.Signal;
@:expose("minko.input.KeyType")
@:enum abstract KeyType(Int) from Int to Int {
    var TKeyCode = 0;
    var TScanCode = 1;
}
@:expose("minko.input.Key")
@:enum abstract Key(Int) from Int to Int {
// IDs are the same than the official DOM codes:
    // https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent

    var CANCEL = 3; // Cancel key.
    var HELP = 6; // Help key.
    var BACK_SPACE = 8; // Backspace key.
    var TAB = 9; // Tab key.
    var CLEAR = 12; // "5" key on Numpad when NumLock is unlocked. Or on Mac; clear key which is positioned at NumLock key.
    var RETURN = 13; // Return/enter key on the main keyboard.
    var ENTER = 14; // Reserved; but not used.  </code><code>Obsolete since Gecko 30 (Dropped; see bug&nbsp;969247.)
    var SHIFT = 16; // Shift key.
    var CONTROL = 17; // Control key.
    var ALT = 18; // Alt (Option on Mac) key.
    var PAUSE = 19; // Pause key.
    var CAPS_LOCK = 20; // Caps lock.
    var KANA = 21; // Linux support for this keycode was added in Gecko 4.0.
    //HANGUL = 21; // Linux support for this keycode was added in Gecko 4.0.
    var EISU = 22; // "英数" key on Japanese Mac keyboard.
    var JUNJA = 23; // Linux support for this keycode was added in Gecko 4.0.
    var FINAL = 24; // Linux support for this keycode was added in Gecko 4.0.
    //HANJA = 25; // Linux support for this keycode was added in Gecko 4.0.
    var KANJI = 25; // Linux support for this keycode was added in Gecko 4.0.
    var ESCAPE = 27; // Escape key.
    var CONVERT = 28; // Linux support for this keycode was added in Gecko 4.0.
    var NONCONVERT = 29; // Linux support for this keycode was added in Gecko 4.0.
    var ACCEPT = 30; // Linux support for this keycode was added in Gecko 4.0.
    var MODECHANGE = 31; // Linux support for this keycode was added in Gecko 4.0.
    var SPACE = 32; // Space bar.
    var PAGE_UP = 33; // Page Up key.
    var PAGE_DOWN = 34; // Page Down key.
    var END = 35; // End key.
    var HOME = 36; // Home key.
    var LEFT = 37; // Left arrow.
    var UP = 38; // Up arrow.
    var RIGHT = 39; // Right arrow.
    var DOWN = 40; // Down arrow.
    var SELECT = 41; // Linux support for this keycode was added in Gecko 4.0.
    var PRINT = 42; // Linux support for this keycode was added in Gecko 4.0.
    var EXECUTE = 43; // Linux support for this keycode was added in Gecko 4.0.
    var PRINTSCREEN = 44; // Print Screen key.
    var INSERT = 45; // Ins(ert) key.
    var DEL = 46; // Del(ete) key.
    var _0 = 48; // "0" key in standard key location.
    var _1 = 49; // "1" key in standard key location.
    var _2 = 50; // "2" key in standard key location.
    var _3 = 51; // "3" key in standard key location.
    var _4 = 52; // "4" key in standard key location.
    var _5 = 53; // "5" key in standard key location.
    var _6 = 54; // "6" key in standard key location.
    var _7 = 55; // "7" key in standard key location.
    var _8 = 56; // "8" key in standard key location.
    var _9 = 57; // "9" key in standard key location.
    var COLON = 58; // Colon (":") key.
    var SEMICOLON = 59; // Semicolon (";") key.
    var LESS_THAN = 60; // Less-than ("&lt;") key.
    var EQUALS = 61; // Equals ("=") key.
    var GREATER_THAN = 62; // Greater-than ("&gt;") key.
    var QUESTION_MARK = 63; // Question mark ("?") key.
    var AT = 64; // Atmark ("@") key.
    var A = 65; // "A" key.
    var B = 66; // "B" key.
    var C = 67; // "C" key.
    var D = 68; // "D" key.
    var E = 69; // "E" key.
    var F = 70; // "F" key.
    var G = 71; // "G" key.
    var H = 72; // "H" key.
    var I = 73; // "I" key.
    var J = 74; // "J" key.
    var K = 75; // "K" key.
    var L = 76; // "L" key.
    var M = 77; // "M" key.
    var N = 78; // "N" key.
    var O = 79; // "O" key.
    var P = 80; // "P" key.
    var Q = 81; // "Q" key.
    var R = 82; // "R" key.
    var S = 83; // "S" key.
    var T = 84; // "T" key.
    var U = 85; // "U" key.
    var V = 86; // "V" key.
    var W = 87; // "W" key.
    var X = 88; // "X" key.
    var Y = 89; // "Y" key.
    var Z = 90; // "Z" key.
    var WIN = 91; // Windows logo key on Windows. Or Super or Hyper key on Linux.
    var CONTEXT_MENU = 93; // Opening context menu key.
    var SLEEP = 95; // Linux support for this keycode was added in Gecko 4.0.
    var NUMPAD0 = 96; // "0" on the numeric keypad.
    var NUMPAD1 = 97; // "1" on the numeric keypad.
    var NUMPAD2 = 98; // "2" on the numeric keypad.
    var NUMPAD3 = 99; // "3" on the numeric keypad.
    var NUMPAD4 = 100; // "4" on the numeric keypad.
    var NUMPAD5 = 101; // "5" on the numeric keypad.
    var NUMPAD6 = 102; // "6" on the numeric keypad.
    var NUMPAD7 = 103; // "7" on the numeric keypad.
    var NUMPAD8 = 104; // "8" on the numeric keypad.
    var NUMPAD9 = 105; // "9" on the numeric keypad.
    var MULTIPLY = 106; // "*" on the numeric keypad.
    var ADD = 107; // "+" on the numeric keypad.
    var SEPARATOR = 108; // &nbsp;
    var SUBTRACT = 109; // "-" on the numeric keypad.
    var DECIMAL = 110; // Decimal point on the numeric keypad.
    var DIVIDE = 111; // "/" on the numeric keypad.
    var F1 = 112; // F1 key.
    var F2 = 113; // F2 key.
    var F3 = 114; // F3 key.
    var F4 = 115; // F4 key.
    var F5 = 116; // F5 key.
    var F6 = 117; // F6 key.
    var F7 = 118; // F7 key.
    var F8 = 119; // F8 key.
    var F9 = 120; // F9 key.
    var F10 = 121; // F10 key.
    var F11 = 122; // F11 key.
    var F12 = 123; // F12 key.
    var F13 = 124; // F13 key.
    var F14 = 125; // F14 key.
    var F15 = 126; // F15 key.
    var F16 = 127; // F16 key.
    var F17 = 128; // F17 key.
    var F18 = 129; // F18 key.
    var F19 = 130; // F19 key.
    var F20 = 131; // F20 key.
    var F21 = 132; // F21 key.
    var F22 = 133; // F22 key.
    var F23 = 134; // F23 key.
    var F24 = 135; // F24 key.
    var NUM_LOCK = 144; // Num Lock key.
    var SCROLL_LOCK = 145; // Scroll Lock key.
    var WIN_OEM_FJ_JISHO = 146; // An OEM specific key on Windows. This was used for "Dictionary" key on Fujitsu OASYS.
    var WIN_OEM_FJ_MASSHOU = 147; // An OEM specific key on Windows. This was used for "Unregister word" key on Fujitsu OASYS.
    var WIN_OEM_FJ_TOUROKU = 148; // An OEM specific key on Windows. This was used for "Register word" key on Fujitsu OASYS.
    var WIN_OEM_FJ_LOYA = 149; // An OEM specific key on Windows. This was used for "Left OYAYUBI" key on Fujitsu OASYS.
    var WIN_OEM_FJ_ROYA = 150; // An OEM specific key on Windows. This was used for "Right OYAYUBI" key on Fujitsu OASYS.
    var CIRCUMFLEX = 160; // Circumflex ("^") key.
    var EXCLAMATION = 161; // Exclamation ("!") key.
    var DOUBLE_QUOTE = 162; // Double quote (""") key.
    var HASH = 163; // Hash ("#") key.
    var DOLLAR = 164; // Dollar sign ("_") key.
    var PERCENT = 165; // Percent ("%") key.
    var AMPERSAND = 166; // Ampersand ("&amp;") key.
    var UNDERSCORE = 167; // Underscore ("_") key.
    var OPEN_PAREN = 168; // Open parenthesis ("(") key.
    var CLOSE_PAREN = 169; // Close parenthesis (")") key.
    var ASTERISK = 170; // Asterisk ("*") key.
    var PLUS = 171; // Plus ("+") key.
    var PIPE = 172; // Pipe ("|") key.
    var HYPHEN_MINUS = 173; // Hyphen-US/docs/Minus ("-") key.
    var OPEN_CURLY_BRACKET = 174; // Open curly bracket ("{") key.
    var CLOSE_CURLY_BRACKET = 175; // Close curly bracket ("}") key.
    var TILDE = 176; // Tilde ("~") key.
    var VOLUME_MUTE = 181; // Audio mute key.
    var VOLUME_DOWN = 182; // Audio volume down key
    var VOLUME_UP = 183; // Audio volume up key
    var COMMA = 188; // Comma (";") key.
    var PERIOD = 190; // Period (".") key.
    var SLASH = 191; // Slash ("/") key.
    var BACK_QUOTE = 192; // Back tick ("`") key.
    var OPEN_BRACKET = 219; // Open square bracket ("[") key.
    var BACK_SLASH = 220; // Back slash ("\") key.
    var CLOSE_BRACKET = 221; // Close square bracket ("]") key.
    var QUOTE = 222; // Quote (''') key.
    var META = 224; // Meta key on Linux; Command key on Mac.
    var ALTGR = 225; // AltGr key (Level 3 Shift key or Level 5 Shift key) on Linux.
    var WIN_ICO_HELP = 227; // An OEM specific key on Windows. This is (was?) used for Olivetti ICO keyboard.
    var WIN_ICO_00 = 228; // An OEM specific key on Windows. This is (was?) used for Olivetti ICO keyboard.
    var WIN_ICO_CLEAR = 230; // An OEM specific key on Windows. This is (was?) used for Olivetti ICO keyboard.
    var WIN_OEM_RESET = 233; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_JUMP = 234; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_PA1 = 235; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_PA2 = 236; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_PA3 = 237; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_WSCTRL = 238; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_CUSEL = 239; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_ATTN = 240; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_FINISH = 241; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_COPY = 242; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_AUTO = 243; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_ENLW = 244; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var WIN_OEM_BACKTAB = 245; // An OEM specific key on Windows. This was used for Nokia/Ericsson's device.
    var ATTN = 246; // Attn (Attension) key of IBM midrange computers; e.g.; AS/400.
    var CRSEL = 247; // CrSel (Cursor Selection) key of IBM 3270 keyboard layout.
    var EXSEL = 248; // ExSel (Extend Selection) key of IBM 3270 keyboard layout.
    var EREOF = 249; // Erase EOF key of IBM 3270 keyboard layout.
    var PLAY = 250; // Play key of IBM 3270 keyboard layout.
    var ZOOM = 251; // Zoom key.
    var PA1 = 253; // PA1 key of IBM 3270 keyboard layout.
    var WIN_OEM_CLEAR = 254; // Clear key; but we're not sure the meaning difference from DOM_VK_CLEAR.

    // Additional keys (specific to Minko and for native support of some keys)
    var CONTROL_RIGHT = 300; // Right control key
    var SHIFT_RIGHT = 301;
    // Right shift key
}
@:expose("minko.input.ScanCode")
@:enum abstract ScanCode(Int) from Int to Int {

    var UNKNOWN = 0;

    var A = 4;
    var B = 5;
    var C = 6;
    var D = 7;
    var E = 8;
    var F = 9;
    var G = 10;
    var H = 11;
    var I = 12;
    var J = 13;
    var K = 14;
    var L = 15;
    var M = 16;
    var N = 17;
    var O = 18;
    var P = 19;
    var Q = 20;
    var R = 21;
    var S = 22;
    var T = 23;
    var U = 24;
    var V = 25;
    var W = 26;
    var X = 27;
    var Y = 28;
    var Z = 29;

    var _1 = 30;
    var _2 = 31;
    var _3 = 32;
    var _4 = 33;
    var _5 = 34;
    var _6 = 35;
    var _7 = 36;
    var _8 = 37;
    var _9 = 38;
    var _0 = 39;

    var RETURN = 40;
    var ESCAPE = 41;
    var BACKSPACE = 42;
    var TAB = 43;
    var SPACE = 44;

    var MINUS = 45;
    var EQUALS = 46;
    var LEFTBRACKET = 47;
    var RIGHTBRACKET = 48;
    var BACKSLASH = 49;
    var NONUSHASH = 50;
    var SEMICOLON = 51;
    var APOSTROPHE = 52;
    var GRAVE = 53;
    var COMMA = 54;
    var PERIOD = 55;
    var SLASH = 56;

    var CAPSLOCK = 57;

    var F1 = 58;
    var F2 = 59;
    var F3 = 60;
    var F4 = 61;
    var F5 = 62;
    var F6 = 63;
    var F7 = 64;
    var F8 = 65;
    var F9 = 66;
    var F10 = 67;
    var F11 = 68;
    var F12 = 69;

    var PRINTSCREEN = 70;
    var SCROLLLOCK = 71;
    var PAUSE = 72;
    var INSERT = 73;
    var HOME = 74;
    var PAGEUP = 75;
    var DEL = 76;
    var END = 77;
    var PAGEDOWN = 78;
    var RIGHT = 79;
    var LEFT = 80;
    var DOWN = 81;
    var UP = 82;
    var NUMLOCKCLEAR = 83;
    var KP_DIVIDE = 84;
    var KP_MULTIPLY = 85;
    var KP_MINUS = 86;
    var KP_PLUS = 87;
    var KP_ENTER = 88;
    var KP_1 = 89;
    var KP_2 = 90;
    var KP_3 = 91;
    var KP_4 = 92;
    var KP_5 = 93;
    var KP_6 = 94;
    var KP_7 = 95;
    var KP_8 = 96;
    var KP_9 = 97;
    var KP_0 = 98;
    var KP_PERIOD = 99;
    var NONUSBACKSLASH = 100;
    var APPLICATION = 101;
    var POWER = 102;
    var KP_EQUALS = 103;
    var F13 = 104;
    var F14 = 105;
    var F15 = 106;
    var F16 = 107;
    var F17 = 108;
    var F18 = 109;
    var F19 = 110;
    var F20 = 111;
    var F21 = 112;
    var F22 = 113;
    var F23 = 114;
    var F24 = 115;
    var EXECUTE = 116;
    var HELP = 117;
    var MENU = 118;
    var SELECT = 119;
    var STOP = 120;
    var AGAIN = 121;
    var UNDO = 122;
    var CUT = 123;
    var COPY = 124;
    var PASTE = 125;
    var FIND = 126;
    var MUTE = 127;
    var VOLUMEUP = 128;
    var VOLUMEDOWN = 129;
    var KP_COMMA = 133;
    var KP_EQUALSAS400 = 134;
    var INTERNATIONAL1 = 135;
    var INTERNATIONAL2 = 136;
    var INTERNATIONAL3 = 137;
    var INTERNATIONAL4 = 138;
    var INTERNATIONAL5 = 139;
    var INTERNATIONAL6 = 140;
    var INTERNATIONAL7 = 141;
    var INTERNATIONAL8 = 142;
    var INTERNATIONAL9 = 143;
    var LANG1 = 144;
    var LANG2 = 145;
    var LANG3 = 146;
    var LANG4 = 147;
    var LANG5 = 148;
    var LANG6 = 149;
    var LANG7 = 150;
    var LANG8 = 151;
    var LANG9 = 152;
    var ALTERASE = 153;
    var SYSREQ = 154;
    var CANCEL = 155;
    var CLEAR = 156;
    var PRIOR = 157;
    var RETURN2 = 158;
    var SEPARATOR = 159;
    //OUT = 160;
    var OPER = 161;
    var CLEARAGAIN = 162;
    var CRSEL = 163;
    var EXSEL = 164;
    var KP_00 = 176;
    var KP_000 = 177;
    var THOUSANDSSEPARATOR = 178;
    var DECIMALSEPARATOR = 179;
    var CURRENCYUNIT = 180;
    var CURRENCYSUBUNIT = 181;
    var KP_LEFTPAREN = 182;
    var KP_RIGHTPAREN = 183;
    var KP_LEFTBRACE = 184;
    var KP_RIGHTBRACE = 185;
    var KP_TAB = 186;
    var KP_BACKSPACE = 187;
    var KP_A = 188;
    var KP_B = 189;
    var KP_C = 190;
    var KP_D = 191;
    var KP_E = 192;
    var KP_F = 193;
    var KP_XOR = 194;
    var KP_POWER = 195;
    var KP_PERCENT = 196;
    var KP_LESS = 197;
    var KP_GREATER = 198;
    var KP_AMPERSAND = 199;
    var KP_DBLAMPERSAND = 200;
    var KP_VERTICALBAR = 201;
    var KP_DBLVERTICALBAR = 202;
    var KP_COLON = 203;
    var KP_HASH = 204;
    var KP_SPACE = 205;
    var KP_AT = 206;
    var KP_EXCLAM = 207;
    var KP_MEMSTORE = 208;
    var KP_MEMRECALL = 209;
    var KP_MEMCLEAR = 210;
    var KP_MEMADD = 211;
    var KP_MEMSUBTRACT = 212;
    var KP_MEMMULTIPLY = 213;
    var KP_MEMDIVIDE = 214;
    var KP_PLUSMINUS = 215;
    var KP_CLEAR = 216;
    var KP_CLEARENTRY = 217;
    var KP_BINARY = 218;
    var KP_OCTAL = 219;
    var KP_DECIMAL = 220;
    var KP_HEXADECIMAL = 221;

    var LCTRL = 224;
    var LSHIFT = 225;
    var LALT = 226;
    var LGUI = 227;
    var RCTRL = 228;
    var RSHIFT = 229;
    var RALT = 230;
    var RGUI = 231;
    var MODE = 257;

    var AUDIONEXT = 258;
    var AUDIOPREV = 259;
    var AUDIOSTOP = 260;
    var AUDIOPLAY = 261;
    var AUDIOMUTE = 262;
    var MEDIASELECT = 263;
    var WWW = 264;
    var MAIL = 265;
    var CALCULATOR = 266;
    var COMPUTER = 267;
    var AC_SEARCH = 268;
    var AC_HOME = 269;
    var AC_BACK = 270;
    var AC_FORWARD = 271;
    var AC_STOP = 272;
    var AC_REFRESH = 273;
    var AC_BOOKMARKS = 274;

    var BRIGHTNESSDOWN = 275;
    var BRIGHTNESSUP = 276;
    var DISPLAYSWITCH = 277;
    var KBDILLUMTOGGLE = 278;
    var KBDILLUMDOWN = 279;
    var KBDILLUMUP = 280;
    var EJECT = 281;
    var SLEEP = 282;

    var APP1 = 283;
    var APP2 = 284;
}
@:expose("minko.input.KeyCode")
@:enum abstract KeyCode(Int) from Int to Int {

    var UNKNOWN = 0;
    var FIRST = 0;
    var BACKSPACE = 8;
    var TAB = 9;
    var CLEAR = 12;
    var RETURN = 13;
    var PAUSE = 19;
    var CANCEL = 24;
    var ESCAPE = 27;
    var FS = 28; // File separator
    var GS = 29; // Group separator
    var RS = 30; // Record separator
    var US = 31; // Unit separator
    var SPACE = 32;
    var EXCLAIM = 33;
    var QUOTEDBL = 34;
    var HASH = 35;
    var DOLLAR = 36;
    var PERCENT = 37;
    var AMPERSAND = 38;
    var QUOTE = 39;
    var LEFTPAREN = 40;
    var RIGHTPAREN = 41;
    var ASTERISK = 42;
    var PLUS = 43;
    var COMMA = 44;
    var MINUS = 45;
    var PERIOD = 46;
    var SLASH = 47;
    var _0 = 48;
    var _1 = 49;
    var _2 = 50;
    var _3 = 51;
    var _4 = 52;
    var _5 = 53;
    var _6 = 54;
    var _7 = 55;
    var _8 = 56;
    var _9 = 57;
    var COLON = 58;
    var SEMICOLON = 59;
    var LESS = 60;
    var EQUALS = 61;
    var GREATER = 62;
    var QUESTION = 63;
    var AT = 64;
    // 65 -> 90 = capital letters
    var LEFTBRACKET = 91;
    var BACKSLASH = 92;
    var RIGHTBRACKET = 93;
    var CARET = 94;
    var UNDERSCORE = 95;
    var BACKQUOTE = 96;
    var A = 97;
    var B = 98;
    var C = 99;
    var D = 100;
    var E = 101;
    var F = 102;
    var G = 103;
    var H = 104;
    var I = 105;
    var J = 106;
    var K = 107;
    var L = 108;
    var M = 109;
    var N = 110;
    var O = 111;
    var P = 112;
    var Q = 113;
    var R = 114;
    var S = 115;
    var T = 116;
    var U = 117;
    var V = 118;
    var W = 119;
    var X = 120;
    var Y = 121;
    var Z = 122;
    var LEFTCURLYBRACKET = 123;
    var PIPE = 124;
    var RIGHTCURLYBRACKET = 125;
    var TILDE = 126;
    var DEL = 127;
    var WORLD_0 = 160;
    var WORLD_1 = 161;
    var WORLD_2 = 162;
    var WORLD_3 = 163;
    var WORLD_4 = 164;
    var WORLD_5 = 165;
    var WORLD_6 = 166;
    var WORLD_7 = 167;
    var WORLD_8 = 168;
    var WORLD_9 = 169;
    var WORLD_10 = 170;
    var WORLD_11 = 171;
    var WORLD_12 = 172;
    var WORLD_13 = 173;
    var WORLD_14 = 174;
    var WORLD_15 = 175;
    var WORLD_16 = 176;
    var WORLD_17 = 177;
    var WORLD_18 = 178;
    var WORLD_19 = 179;
    var WORLD_20 = 180;
    var WORLD_21 = 181;
    var WORLD_22 = 182;
    var WORLD_23 = 183;
    var WORLD_24 = 184;
    var WORLD_25 = 185;
    var WORLD_26 = 186;
    var WORLD_27 = 187;
    var WORLD_28 = 188;
    var WORLD_29 = 189;
    var WORLD_30 = 190;
    var WORLD_31 = 191;
    var WORLD_32 = 192;
    var WORLD_33 = 193;
    var WORLD_34 = 194;
    var WORLD_35 = 195;
    var WORLD_36 = 196;
    var WORLD_37 = 197;
    var WORLD_38 = 198;
    var WORLD_39 = 199;
    var WORLD_40 = 200;
    var WORLD_41 = 201;
    var WORLD_42 = 202;
    var WORLD_43 = 203;
    var WORLD_44 = 204;
    var WORLD_45 = 205;
    var WORLD_46 = 206;
    var WORLD_47 = 207;
    var WORLD_48 = 208;
    var WORLD_49 = 209;
    var WORLD_50 = 210;
    var WORLD_51 = 211;
    var WORLD_52 = 212;
    var WORLD_53 = 213;
    var WORLD_54 = 214;
    var WORLD_55 = 215;
    var WORLD_56 = 216;
    var WORLD_57 = 217;
    var WORLD_58 = 218;
    var WORLD_59 = 219;
    var WORLD_60 = 220;
    var WORLD_61 = 221;
    var WORLD_62 = 222;
    var WORLD_63 = 223;
    var WORLD_64 = 224;
    var WORLD_65 = 225;
    var WORLD_66 = 226;
    var WORLD_67 = 227;
    var WORLD_68 = 228;
    var WORLD_69 = 229;
    var WORLD_70 = 230;
    var WORLD_71 = 231;
    var WORLD_72 = 232;
    var WORLD_73 = 233;
    var WORLD_74 = 234;
    var WORLD_75 = 235;
    var WORLD_76 = 236;
    var WORLD_77 = 237;
    var WORLD_78 = 238;
    var WORLD_79 = 239;
    var WORLD_80 = 240;
    var WORLD_81 = 241;
    var WORLD_82 = 242;
    var WORLD_83 = 243;
    var WORLD_84 = 244;
    var WORLD_85 = 245;
    var WORLD_86 = 246;
    var WORLD_87 = 247;
    var WORLD_88 = 248;
    var WORLD_89 = 249;
    var WORLD_90 = 250;
    var WORLD_91 = 251;
    var WORLD_92 = 252;
    var WORLD_93 = 253;
    var WORLD_94 = 254;
    var WORLD_95 = 255;

}
@:expose("minko.input.KeyMap")
class KeyMap {
    public static var keyToKeyCodeMap:IntMap<Int> = initializeKeyToKeyCodeMap();//<Keyboard.Key, Keyboard.KeyCode>();
    public static var keyToScanCodeMap:IntMap<Int> = initializeKeyToScanCodeMap();
    //<Keyboard.Key, Keyboard.ScanCode>();
    static public function initializeKeyToKeyCodeMap() {

        var keyToKeyCodeMap = new IntMap<Int>();
        keyToKeyCodeMap.set(Key.CANCEL, KeyCode.CANCEL);
        keyToKeyCodeMap.set(Key.BACK_SPACE, KeyCode.BACKSPACE);
        keyToKeyCodeMap.set(Key.TAB, KeyCode.TAB);
        keyToKeyCodeMap.set(Key.CLEAR, KeyCode.CLEAR);
        keyToKeyCodeMap.set(Key.RETURN, KeyCode.RETURN);

        keyToKeyCodeMap.set(Key.ESCAPE, KeyCode.ESCAPE);

        // Supported on Linux with Gecko 4.0
        keyToKeyCodeMap.set(Key.CONVERT, KeyCode.FS);
        keyToKeyCodeMap.set(Key.NONCONVERT, KeyCode.GS);
        keyToKeyCodeMap.set(Key.ACCEPT, KeyCode.RS);
        keyToKeyCodeMap.set(Key.MODECHANGE, KeyCode.US);

        keyToKeyCodeMap.set(Key.SPACE, KeyCode.SPACE);

        keyToKeyCodeMap.set(Key.DEL, KeyCode.DEL);
        keyToKeyCodeMap.set(Key._0, KeyCode._0);
        keyToKeyCodeMap.set(Key._1, KeyCode._1);
        keyToKeyCodeMap.set(Key._2, KeyCode._2);
        keyToKeyCodeMap.set(Key._3, KeyCode._3);
        keyToKeyCodeMap.set(Key._4, KeyCode._4);
        keyToKeyCodeMap.set(Key._5, KeyCode._5);
        keyToKeyCodeMap.set(Key._6, KeyCode._6);
        keyToKeyCodeMap.set(Key._7, KeyCode._7);
        keyToKeyCodeMap.set(Key._8, KeyCode._8);
        keyToKeyCodeMap.set(Key._9, KeyCode._9);
        keyToKeyCodeMap.set(Key.COLON, KeyCode.COLON);
        keyToKeyCodeMap.set(Key.SEMICOLON, KeyCode.SEMICOLON);
        keyToKeyCodeMap.set(Key.LESS_THAN, KeyCode.LESS);
        keyToKeyCodeMap.set(Key.EQUALS, KeyCode.EQUALS);
        keyToKeyCodeMap.set(Key.GREATER_THAN, KeyCode.GREATER);
        keyToKeyCodeMap.set(Key.QUESTION_MARK, KeyCode.QUESTION);
        keyToKeyCodeMap.set(Key.AT, KeyCode.AT);
        keyToKeyCodeMap.set(Key.A, KeyCode.A);
        keyToKeyCodeMap.set(Key.B, KeyCode.B);
        keyToKeyCodeMap.set(Key.C, KeyCode.C);
        keyToKeyCodeMap.set(Key.D, KeyCode.D);
        keyToKeyCodeMap.set(Key.E, KeyCode.E);
        keyToKeyCodeMap.set(Key.F, KeyCode.F);
        keyToKeyCodeMap.set(Key.G, KeyCode.G);
        keyToKeyCodeMap.set(Key.H, KeyCode.H);
        keyToKeyCodeMap.set(Key.I, KeyCode.I);
        keyToKeyCodeMap.set(Key.J, KeyCode.J);
        keyToKeyCodeMap.set(Key.K, KeyCode.K);
        keyToKeyCodeMap.set(Key.L, KeyCode.L);
        keyToKeyCodeMap.set(Key.M, KeyCode.M);
        keyToKeyCodeMap.set(Key.N, KeyCode.N);
        keyToKeyCodeMap.set(Key.O, KeyCode.O);
        keyToKeyCodeMap.set(Key.P, KeyCode.P);
        keyToKeyCodeMap.set(Key.Q, KeyCode.Q);
        keyToKeyCodeMap.set(Key.R, KeyCode.R);
        keyToKeyCodeMap.set(Key.S, KeyCode.S);
        keyToKeyCodeMap.set(Key.T, KeyCode.T);
        keyToKeyCodeMap.set(Key.U, KeyCode.U);
        keyToKeyCodeMap.set(Key.V, KeyCode.V);
        keyToKeyCodeMap.set(Key.W, KeyCode.W);
        keyToKeyCodeMap.set(Key.X, KeyCode.X);
        keyToKeyCodeMap.set(Key.Y, KeyCode.Y);
        keyToKeyCodeMap.set(Key.Z, KeyCode.Z);

        //keyToKeyCodeMap.set( Key::WIN_OEM_FJ_JISHO, KeyCode.WIN_OEM_FJ_JISHO );
        //keyToKeyCodeMap.set( Key::WIN_OEM_FJ_MASSHOU, KeyCode.WIN_OEM_FJ_MASSHOU );
        //keyToKeyCodeMap.set( Key::WIN_OEM_FJ_TOUROKU, KeyCode.WIN_OEM_FJ_TOUROKU );
        //keyToKeyCodeMap.set( Key::WIN_OEM_FJ_LOYA, KeyCode.WIN_OEM_FJ_LOYA );
        //keyToKeyCodeMap.set( Key::WIN_OEM_FJ_ROYA, KeyCode.WIN_OEM_FJ_ROYA );

        keyToKeyCodeMap.set(Key.CIRCUMFLEX, KeyCode.CARET);
        keyToKeyCodeMap.set(Key.EXCLAMATION, KeyCode.EXCLAIM);
        keyToKeyCodeMap.set(Key.DOUBLE_QUOTE, KeyCode.QUOTEDBL);
        keyToKeyCodeMap.set(Key.HASH, KeyCode.HASH);
        keyToKeyCodeMap.set(Key.DOLLAR, KeyCode.DOLLAR);
        keyToKeyCodeMap.set(Key.PERCENT, KeyCode.PERCENT);
        keyToKeyCodeMap.set(Key.AMPERSAND, KeyCode.AMPERSAND);
        keyToKeyCodeMap.set(Key.UNDERSCORE, KeyCode.UNDERSCORE);
        keyToKeyCodeMap.set(Key.OPEN_PAREN, KeyCode.LEFTPAREN);
        keyToKeyCodeMap.set(Key.CLOSE_PAREN, KeyCode.RIGHTPAREN);
        keyToKeyCodeMap.set(Key.ASTERISK, KeyCode.ASTERISK);
        keyToKeyCodeMap.set(Key.PLUS, KeyCode.PLUS);
        keyToKeyCodeMap.set(Key.PIPE, KeyCode.PIPE);
        keyToKeyCodeMap.set(Key.HYPHEN_MINUS, KeyCode.MINUS);
        keyToKeyCodeMap.set(Key.OPEN_CURLY_BRACKET, KeyCode.LEFTCURLYBRACKET);
        keyToKeyCodeMap.set(Key.CLOSE_CURLY_BRACKET, KeyCode.RIGHTCURLYBRACKET);
        keyToKeyCodeMap.set(Key.TILDE, KeyCode.TILDE);

        keyToKeyCodeMap.set(Key.COMMA, KeyCode.COMMA);
        keyToKeyCodeMap.set(Key.PERIOD, KeyCode.PERIOD);
        keyToKeyCodeMap.set(Key.SLASH, KeyCode.SLASH);
        keyToKeyCodeMap.set(Key.BACK_QUOTE, KeyCode.BACKQUOTE);
        keyToKeyCodeMap.set(Key.OPEN_BRACKET, KeyCode.LEFTBRACKET);
        keyToKeyCodeMap.set(Key.BACK_SLASH, KeyCode.BACKSLASH);
        keyToKeyCodeMap.set(Key.CLOSE_BRACKET, KeyCode.RIGHTBRACKET);
        keyToKeyCodeMap.set(Key.QUOTE, KeyCode.QUOTE);

        //keyToKeyCodeMap.set( Key::WIN_ICO_HELP, KeyCode.WIN_ICO_HELP );
        //keyToKeyCodeMap.set( Key::WIN_ICO_00, KeyCode.WIN_ICO_00 );
        //keyToKeyCodeMap.set( Key::WIN_ICO_CLEAR, KeyCode.WIN_ICO_CLEAR );
        //keyToKeyCodeMap.set( Key::WIN_OEM_RESET, KeyCode.WIN_OEM_RESET );
        //keyToKeyCodeMap.set( Key::WIN_OEM_JUMP, KeyCode.WIN_OEM_JUMP );
        //keyToKeyCodeMap.set( Key::WIN_OEM_PA1, KeyCode.WIN_OEM_PA1 );
        //keyToKeyCodeMap.set( Key::WIN_OEM_PA2, KeyCode.WIN_OEM_PA2 );
        //keyToKeyCodeMap.set( Key::WIN_OEM_PA3, KeyCode.WIN_OEM_PA3 );
        //keyToKeyCodeMap.set( Key::WIN_OEM_WSCTRL, KeyCode.WIN_OEM_WSCTRL );
        //keyToKeyCodeMap.set( Key::WIN_OEM_CUSEL, KeyCode.WIN_OEM_CUSEL );
        //keyToKeyCodeMap.set( Key::WIN_OEM_ATTN, KeyCode.WIN_OEM_ATTN );
        //keyToKeyCodeMap.set( Key::WIN_OEM_FINISH, KeyCode.WIN_OEM_FINISH );
        //keyToKeyCodeMap.set( Key::WIN_OEM_COPY, KeyCode.WIN_OEM_COPY );
        //keyToKeyCodeMap.set( Key::WIN_OEM_AUTO, KeyCode.WIN_OEM_AUTO );
        //keyToKeyCodeMap.set( Key::WIN_OEM_ENLW, KeyCode.WIN_OEM_ENLW );
        //keyToKeyCodeMap.set( Key::WIN_OEM_BACKTAB, KeyCode.WIN_OEM_BACKTAB );
        //keyToKeyCodeMap.set( Key::ATTN, KeyCode.ATTN );
        //keyToKeyCodeMap.set( Key::CRSEL, KeyCode.CRSEL );
        //keyToKeyCodeMap.set( Key::EXSEL, KeyCode.EXSEL );
        //keyToKeyCodeMap.set( Key::EREOF, KeyCode.EREOF );
        //keyToKeyCodeMap.set( Key::PLAY, KeyCode.PLAY );
        //keyToKeyCodeMap.set( Key::ZOOM, KeyCode.ZOOM );
        //keyToKeyCodeMap.set( Key::PA1, KeyCode.PA1 );
        //keyToKeyCodeMap.set( Key::WIN_OEM_CLEAR, KeyCode.WIN_OEM_CLEAR );
        return keyToKeyCodeMap;
    }

    static public function initializeKeyToScanCodeMap() {

        var keyToScanCodeMap = new IntMap<Int>();
        keyToScanCodeMap.set(Key.HELP, ScanCode.HELP);

        keyToScanCodeMap.set(Key.SCROLL_LOCK, ScanCode.SCROLLLOCK);

        keyToScanCodeMap.set(Key.KANA, ScanCode.LANG1);
        //keyToScanCodeMap.set(Key::HANGUL, ScanCode.LANG1 );
        keyToScanCodeMap.set(Key.EISU, ScanCode.LANG1);
        keyToScanCodeMap.set(Key.JUNJA, ScanCode.LANG1);
        keyToScanCodeMap.set(Key.FINAL, ScanCode.LANG1);
        //keyToScanCodeMap.set(Key::HANJA, ScanCode.LANG1);
        keyToScanCodeMap.set(Key.KANJI, ScanCode.LANG1);

        keyToScanCodeMap.set(Key.SHIFT, ScanCode.LSHIFT);
        keyToScanCodeMap.set(Key.CONTROL, ScanCode.LCTRL);
        keyToScanCodeMap.set(Key.ALT, ScanCode.LALT);
        keyToScanCodeMap.set(Key.PAUSE, ScanCode.PAUSE);
        keyToScanCodeMap.set(Key.CAPS_LOCK, ScanCode.CAPSLOCK);

        keyToScanCodeMap.set(Key.PAGE_UP, ScanCode.PAGEUP);
        keyToScanCodeMap.set(Key.PAGE_DOWN, ScanCode.PAGEDOWN);
        keyToScanCodeMap.set(Key.END, ScanCode.END);
        keyToScanCodeMap.set(Key.HOME, ScanCode.HOME);
        keyToScanCodeMap.set(Key.LEFT, ScanCode.LEFT);
        keyToScanCodeMap.set(Key.UP, ScanCode.UP);
        keyToScanCodeMap.set(Key.RIGHT, ScanCode.RIGHT);
        keyToScanCodeMap.set(Key.DOWN, ScanCode.DOWN);
        keyToScanCodeMap.set(Key.SELECT, ScanCode.SELECT);
        //keyToScanCodeMap.set(Key::PRINT, ScanCode.PRINT );
        keyToScanCodeMap.set(Key.EXECUTE, ScanCode.EXECUTE);
        keyToScanCodeMap.set(Key.PRINTSCREEN, ScanCode.PRINTSCREEN);
        keyToScanCodeMap.set(Key.INSERT, ScanCode.INSERT);

        keyToScanCodeMap.set(Key.META, ScanCode.RGUI);
        keyToScanCodeMap.set(Key.ALTGR, ScanCode.RALT);
        keyToScanCodeMap.set(Key.WIN, ScanCode.LGUI);
        keyToScanCodeMap.set(Key.CONTEXT_MENU, ScanCode.APPLICATION);
        keyToScanCodeMap.set(Key.SLEEP, ScanCode.SLEEP);
        keyToScanCodeMap.set(Key.NUMPAD0, ScanCode.KP_0);
        keyToScanCodeMap.set(Key.NUMPAD1, ScanCode.KP_1);
        keyToScanCodeMap.set(Key.NUMPAD2, ScanCode.KP_2);
        keyToScanCodeMap.set(Key.NUMPAD3, ScanCode.KP_3);
        keyToScanCodeMap.set(Key.NUMPAD4, ScanCode.KP_4);
        keyToScanCodeMap.set(Key.NUMPAD5, ScanCode.KP_5);
        keyToScanCodeMap.set(Key.NUMPAD6, ScanCode.KP_6);
        keyToScanCodeMap.set(Key.NUMPAD7, ScanCode.KP_7);
        keyToScanCodeMap.set(Key.NUMPAD8, ScanCode.KP_8);
        keyToScanCodeMap.set(Key.NUMPAD9, ScanCode.KP_9);
        keyToScanCodeMap.set(Key.MULTIPLY, ScanCode.KP_MULTIPLY);
        keyToScanCodeMap.set(Key.ADD, ScanCode.KP_PLUS);
        keyToScanCodeMap.set(Key.SEPARATOR, ScanCode.SEPARATOR);
        keyToScanCodeMap.set(Key.SUBTRACT, ScanCode.KP_MINUS);
        keyToScanCodeMap.set(Key.DECIMAL, ScanCode.KP_DECIMAL);
        keyToScanCodeMap.set(Key.DIVIDE, ScanCode.KP_DIVIDE);

        keyToScanCodeMap.set(Key.F1, ScanCode.F1);
        keyToScanCodeMap.set(Key.F2, ScanCode.F2);
        keyToScanCodeMap.set(Key.F3, ScanCode.F3);
        keyToScanCodeMap.set(Key.F4, ScanCode.F4);
        keyToScanCodeMap.set(Key.F5, ScanCode.F5);
        keyToScanCodeMap.set(Key.F6, ScanCode.F6);
        keyToScanCodeMap.set(Key.F7, ScanCode.F7);
        keyToScanCodeMap.set(Key.F8, ScanCode.F8);
        keyToScanCodeMap.set(Key.F9, ScanCode.F9);
        keyToScanCodeMap.set(Key.F10, ScanCode.F10);
        keyToScanCodeMap.set(Key.F11, ScanCode.F11);
        keyToScanCodeMap.set(Key.F12, ScanCode.F12);
        keyToScanCodeMap.set(Key.F13, ScanCode.F13);
        keyToScanCodeMap.set(Key.F14, ScanCode.F14);
        keyToScanCodeMap.set(Key.F15, ScanCode.F15);
        keyToScanCodeMap.set(Key.F16, ScanCode.F16);
        keyToScanCodeMap.set(Key.F17, ScanCode.F17);
        keyToScanCodeMap.set(Key.F18, ScanCode.F18);
        keyToScanCodeMap.set(Key.F19, ScanCode.F19);
        keyToScanCodeMap.set(Key.F20, ScanCode.F20);
        keyToScanCodeMap.set(Key.F21, ScanCode.F21);
        keyToScanCodeMap.set(Key.F22, ScanCode.F22);
        keyToScanCodeMap.set(Key.F23, ScanCode.F23);
        keyToScanCodeMap.set(Key.F24, ScanCode.F24);
        keyToScanCodeMap.set(Key.NUM_LOCK, ScanCode.NUMLOCKCLEAR);

        keyToScanCodeMap.set(Key.VOLUME_MUTE, ScanCode.MUTE);
        keyToScanCodeMap.set(Key.VOLUME_DOWN, ScanCode.VOLUMEDOWN);
        keyToScanCodeMap.set(Key.VOLUME_UP, ScanCode.VOLUMEUP);

        // Additional keys
        keyToScanCodeMap.set(Key.CONTROL_RIGHT, ScanCode.RCTRL);
        keyToScanCodeMap.set(Key.SHIFT_RIGHT, ScanCode.RSHIFT);

        return keyToScanCodeMap;

    }
}
@:expose("minko.input.Keyboard")
class Keyboard {
    public static function create() {
        return new Keyboard();
    }
    static public var NUM_KEYS = 350;


    static private var _keyToName:Array<String> = initializeKeyNames();

    private var _keyDown:IntMap<Signal2<Keyboard, Int>> ;
    private var _keyUp:IntMap<Signal2<Keyboard, Int>> ;

    private var _down:Signal<Keyboard>;
    private var _up:Signal<Keyboard>;

    private var _textInput:Signal2<Keyboard, Int>;

    public static function getKeyName(key:Int):String {
        return _keyToName[ key];
    }

    public var keyDown(get, null):Signal<Keyboard>;

    function get_keyDown() {
        return _down;
    }

    public var textInput(get, null):Signal2<Keyboard, Int>;

    function get_textInput() {
        return _textInput;
    }

    public function getKeyDown(key:Int):Signal2<Keyboard, Int> {
        var index:Int = key;

        if (!_keyDown.exists(index)) {
            _keyDown.set(index, new Signal2<Keyboard, Int>());
        }

        return _keyDown.get(index);
    }

    public var keyUp(get, null):Signal<Keyboard>;

    function get_keyUp() {
        return _up;
    }

    public function getKeyUp(key:Int):Signal2<Keyboard, Int> {
        var index:Int = key;

        if (!_keyUp.exists(index)) {
            _keyUp.set(index, new Signal2<Keyboard, Int>());
        }

        return _keyUp.get(index);
    }

    public function keyIsDown(key:Int) {
        return false;
    }

    public function hasKeyDownSignal(key:Int) {
        return _keyDown.exists(key);
    }

    public function hasKeyUpSignal(key:Int) {
        return _keyUp.exists(key);
    }

    public function new() {
        this._down = new Signal<Keyboard>();
        this._up = new Signal<Keyboard>();
        this._textInput = new Signal2<Keyboard, Int>();
        this._keyDown = new IntMap<Signal2<Keyboard, Int>>() ;
        this._keyUp = new IntMap<Signal2<Keyboard, Int>>() ;
    }

    public function setKeyboardState(key:Int, state:Int):Void {

    }

    private static function initializeKeyNames():Array<String>{
        var names = new Array<String>();

        names[3] = "CANCEL";
        names[6] = "HELP";
        names[8] = "BACK_SPACE";
        names[9] = "TAB";
        names[12] = "CLEAR";
        names[13] = "RETURN";
        names[14] = "ENTER";
        names[16] = "SHIFT";
        names[17] = "CONTROL";
        names[18] = "ALT";
        names[19] = "PAUSE";
        names[20] = "CAPS_LOCK";
        names[21] = "KANA";
        //names[21] = "HANGUL";
        names[22] = "EISU";
        names[23] = "JUNJA";
        names[24] = "FINAL";
        //names[25] = "HANJA";
        names[25] = "KANJI";
        names[27] = "ESCAPE";
        names[28] = "CONVERT";
        names[29] = "NONCONVERT";
        names[30] = "ACCEPT";
        names[31] = "MODECHANGE";
        names[32] = "SPACE";
        names[33] = "PAGE_UP";
        names[34] = "PAGE_DOWN";
        names[35] = "END";
        names[36] = "HOME";
        names[37] = "LEFT";
        names[38] = "UP";
        names[39] = "RIGHT";
        names[40] = "DOWN";
        names[41] = "SELECT";
        names[42] = "PRINT";
        names[43] = "EXECUTE";
        names[44] = "PRINTSCREEN";
        names[45] = "INSERT";
        names[46] = "DELETE";
        names[48] = "_0";
        names[49] = "_1";
        names[50] = "_2";
        names[51] = "_3";
        names[52] = "_4";
        names[53] = "_5";
        names[54] = "_6";
        names[55] = "_7";
        names[56] = "_8";
        names[57] = "_9";
        names[58] = "COLON";
        names[59] = "SEMICOLON";
        names[60] = "LESS_THAN";
        names[61] = "EQUALS";
        names[62] = "GREATER_THAN";
        names[63] = "QUESTION_MARK";
        names[64] = "AT";
        names[65] = "A";
        names[66] = "B";
        names[67] = "C";
        names[68] = "D";
        names[69] = "E";
        names[70] = "F";
        names[71] = "G";
        names[72] = "H";
        names[73] = "I";
        names[74] = "J";
        names[75] = "K";
        names[76] = "L";
        names[77] = "M";
        names[78] = "N";
        names[79] = "O";
        names[80] = "P";
        names[81] = "Q";
        names[82] = "R";
        names[83] = "S";
        names[84] = "T";
        names[85] = "U";
        names[86] = "V";
        names[87] = "W";
        names[88] = "X";
        names[89] = "Y";
        names[90] = "Z";
        names[91] = "WIN";
        names[93] = "CONTEXT_MENU";
        names[95] = "SLEEP";
        names[96] = "NUMPAD0";
        names[97] = "NUMPAD1";
        names[98] = "NUMPAD2";
        names[99] = "NUMPAD3";
        names[100] = "NUMPAD4";
        names[101] = "NUMPAD5";
        names[102] = "NUMPAD6";
        names[103] = "NUMPAD7";
        names[104] = "NUMPAD8";
        names[105] = "NUMPAD9";
        names[106] = "MULTIPLY";
        names[107] = "ADD";
        names[108] = "SEPARATOR";
        names[109] = "SUBTRACT";
        names[110] = "DECIMAL";
        names[111] = "DIVIDE";
        names[112] = "F1";
        names[113] = "F2";
        names[114] = "F3";
        names[115] = "F4";
        names[116] = "F5";
        names[117] = "F6";
        names[118] = "F7";
        names[119] = "F8";
        names[120] = "F9";
        names[121] = "F10";
        names[122] = "F11";
        names[123] = "F12";
        names[124] = "F13";
        names[125] = "F14";
        names[126] = "F15";
        names[127] = "F16";
        names[128] = "F17";
        names[129] = "F18";
        names[130] = "F19";
        names[131] = "F20";
        names[132] = "F21";
        names[133] = "F22";
        names[134] = "F23";
        names[135] = "F24";
        names[144] = "NUM_LOCK";
        names[145] = "SCROLL_LOCK";
        names[146] = "WIN_OEM_FJ_JISHO";
        names[147] = "WIN_OEM_FJ_MASSHOU";
        names[148] = "WIN_OEM_FJ_TOUROKU";
        names[149] = "WIN_OEM_FJ_LOYA";
        names[150] = "WIN_OEM_FJ_ROYA";
        names[160] = "CIRCUMFLEX";
        names[161] = "EXCLAMATION";
        names[162] = "DOUBLE_QUOTE";
        names[163] = "HASH";
        names[164] = "DOLLAR";
        names[165] = "PERCENT";
        names[166] = "AMPERSAND";
        names[167] = "UNDERSCORE";
        names[168] = "OPEN_PAREN";
        names[169] = "CLOSE_PAREN";
        names[170] = "ASTERISK";
        names[171] = "PLUS";
        names[172] = "PIPE";
        names[173] = "HYPHEN_MINUS";
        names[174] = "OPEN_CURLY_BRACKET";
        names[175] = "CLOSE_CURLY_BRACKET";
        names[176] = "TILDE";
        names[181] = "VOLUME_MUTE";
        names[182] = "VOLUME_DOWN";
        names[183] = "VOLUME_UP";
        names[188] = "COMMA";
        names[190] = "PERIOD";
        names[191] = "SLASH";
        names[192] = "BACK_QUOTE";
        names[219] = "OPEN_BRACKET";
        names[220] = "BACK_SLASH";
        names[221] = "CLOSE_BRACKET";
        names[222] = "QUOTE";
        names[224] = "META";
        names[225] = "ALTGR";
        names[227] = "WIN_ICO_HELP";
        names[228] = "WIN_ICO_00";
        names[230] = "WIN_ICO_CLEAR";
        names[233] = "WIN_OEM_RESET";
        names[234] = "WIN_OEM_JUMP";
        names[235] = "WIN_OEM_PA1";
        names[236] = "WIN_OEM_PA2";
        names[237] = "WIN_OEM_PA3";
        names[238] = "WIN_OEM_WSCTRL";
        names[239] = "WIN_OEM_CUSEL";
        names[240] = "WIN_OEM_ATTN";
        names[241] = "WIN_OEM_FINISH";
        names[242] = "WIN_OEM_COPY";
        names[243] = "WIN_OEM_AUTO";
        names[244] = "WIN_OEM_ENLW";
        names[245] = "WIN_OEM_BACKTAB";
        names[246] = "ATTN";
        names[247] = "CRSEL";
        names[248] = "EXSEL";
        names[249] = "EREOF";
        names[250] = "PLAY";
        names[251] = "ZOOM";
        names[253] = "PA1";
        names[254] = "WIN_OEM_CLEAR";

        // Additional keys (specific to Minko and for native support of some keys)
        names[300] = "CONTROL_RIGHT";
        names[301] = "SHIFT_RIGHT";

        return names;
    }

}
