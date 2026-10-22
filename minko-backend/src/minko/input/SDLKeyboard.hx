package minko.input;

import haxe.ds.IntMap;
import minko.input.Keyboard.Key;
import minko.input.Keyboard.KeyMap;
import minko.input.Keyboard.ScanCode;

class SDLKeyboard extends Keyboard {
    public static var scanCodeToKey:IntMap<Int> = initializeScanCodeMap();

    static function initializeScanCodeMap():IntMap<Int> {
        var m = new IntMap<Int>();

        // Letters and digits use contiguous SDL scancodes.
        for (i in 0...26) m.set(ScanCode.A + i, Key.A + i);
        m.set(ScanCode._1, Key._1);
        m.set(ScanCode._2, Key._2);
        m.set(ScanCode._3, Key._3);
        m.set(ScanCode._4, Key._4);
        m.set(ScanCode._5, Key._5);
        m.set(ScanCode._6, Key._6);
        m.set(ScanCode._7, Key._7);
        m.set(ScanCode._8, Key._8);
        m.set(ScanCode._9, Key._9);
        m.set(ScanCode._0, Key._0);

        m.set(ScanCode.RETURN, Key.RETURN);
        m.set(ScanCode.ESCAPE, Key.ESCAPE);
        m.set(ScanCode.BACKSPACE, Key.BACK_SPACE);
        m.set(ScanCode.TAB, Key.TAB);
        m.set(ScanCode.SPACE, Key.SPACE);
        m.set(ScanCode.MINUS, Key.HYPHEN_MINUS);
        m.set(ScanCode.EQUALS, Key.EQUALS);
        m.set(ScanCode.LEFTBRACKET, Key.OPEN_BRACKET);
        m.set(ScanCode.RIGHTBRACKET, Key.CLOSE_BRACKET);
        m.set(ScanCode.BACKSLASH, Key.BACK_SLASH);
        m.set(ScanCode.SEMICOLON, Key.SEMICOLON);
        m.set(ScanCode.APOSTROPHE, Key.QUOTE);
        m.set(ScanCode.GRAVE, Key.BACK_QUOTE);
        m.set(ScanCode.COMMA, Key.COMMA);
        m.set(ScanCode.PERIOD, Key.PERIOD);
        m.set(ScanCode.SLASH, Key.SLASH);
        m.set(ScanCode.CAPSLOCK, Key.CAPS_LOCK);

        m.set(ScanCode.F1, Key.F1);
        m.set(ScanCode.F2, Key.F2);
        m.set(ScanCode.F3, Key.F3);
        m.set(ScanCode.F4, Key.F4);
        m.set(ScanCode.F5, Key.F5);
        m.set(ScanCode.F6, Key.F6);
        m.set(ScanCode.F7, Key.F7);
        m.set(ScanCode.F8, Key.F8);
        m.set(ScanCode.F9, Key.F9);
        m.set(ScanCode.F10, Key.F10);
        m.set(ScanCode.F11, Key.F11);
        m.set(ScanCode.F12, Key.F12);
        m.set(ScanCode.F13, Key.F13);
        m.set(ScanCode.F14, Key.F14);
        m.set(ScanCode.F15, Key.F15);
        m.set(ScanCode.F16, Key.F16);
        m.set(ScanCode.F17, Key.F17);
        m.set(ScanCode.F18, Key.F18);
        m.set(ScanCode.F19, Key.F19);
        m.set(ScanCode.F20, Key.F20);
        m.set(ScanCode.F21, Key.F21);
        m.set(ScanCode.F22, Key.F22);
        m.set(ScanCode.F23, Key.F23);
        m.set(ScanCode.F24, Key.F24);

        m.set(ScanCode.PRINTSCREEN, Key.PRINTSCREEN);
        m.set(ScanCode.SCROLLLOCK, Key.SCROLL_LOCK);
        m.set(ScanCode.PAUSE, Key.PAUSE);
        m.set(ScanCode.INSERT, Key.INSERT);
        m.set(ScanCode.HOME, Key.HOME);
        m.set(ScanCode.PAGEUP, Key.PAGE_UP);
        m.set(ScanCode.DEL, Key.DEL);
        m.set(ScanCode.END, Key.END);
        m.set(ScanCode.PAGEDOWN, Key.PAGE_DOWN);
        m.set(ScanCode.RIGHT, Key.RIGHT);
        m.set(ScanCode.LEFT, Key.LEFT);
        m.set(ScanCode.DOWN, Key.DOWN);
        m.set(ScanCode.UP, Key.UP);

        m.set(ScanCode.NUMLOCKCLEAR, Key.NUM_LOCK);
        m.set(ScanCode.KP_DIVIDE, Key.DIVIDE);
        m.set(ScanCode.KP_MULTIPLY, Key.MULTIPLY);
        m.set(ScanCode.KP_MINUS, Key.SUBTRACT);
        m.set(ScanCode.KP_PLUS, Key.ADD);
        m.set(ScanCode.KP_ENTER, Key.RETURN);
        m.set(ScanCode.KP_1, Key.NUMPAD1);
        m.set(ScanCode.KP_2, Key.NUMPAD2);
        m.set(ScanCode.KP_3, Key.NUMPAD3);
        m.set(ScanCode.KP_4, Key.NUMPAD4);
        m.set(ScanCode.KP_5, Key.NUMPAD5);
        m.set(ScanCode.KP_6, Key.NUMPAD6);
        m.set(ScanCode.KP_7, Key.NUMPAD7);
        m.set(ScanCode.KP_8, Key.NUMPAD8);
        m.set(ScanCode.KP_9, Key.NUMPAD9);
        m.set(ScanCode.KP_0, Key.NUMPAD0);
        m.set(ScanCode.KP_PERIOD, Key.DECIMAL);

        m.set(ScanCode.LCTRL, Key.CONTROL);
        m.set(ScanCode.LSHIFT, Key.SHIFT);
        m.set(ScanCode.LALT, Key.ALT);
        m.set(ScanCode.LGUI, Key.WIN);
        m.set(ScanCode.RCTRL, Key.CONTROL_RIGHT);
        m.set(ScanCode.RSHIFT, Key.SHIFT_RIGHT);
        m.set(ScanCode.RALT, Key.ALTGR);
        m.set(ScanCode.RGUI, Key.META);

        // Fill the remaining keys from the engine's existing DOM -> scancode map.
        for (key in KeyMap.keyToScanCodeMap.keys()) {
            var scan = KeyMap.keyToScanCodeMap.get(key);
            if (!m.exists(scan)) m.set(scan, key);
        }
        return m;
    }

    public static function create() {
        return new SDLKeyboard();
    }

    var _keyboardState:IntMap<Int>;

    public function new() {
        super();
        _keyboardState = new IntMap<Int>();
    }

    override public function setKeyboardState(key, state) {
        _keyboardState.set(key, state);
    }

    override public function keyIsDown(keyCode:Int):Bool {
        return _keyboardState.exists(keyCode) && _keyboardState.get(keyCode) != 0;
    }
}
