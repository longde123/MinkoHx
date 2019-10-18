package minko.input;

import haxe.ds.IntMap;
import minko.input.Keyboard.Key;
import minko.input.Keyboard.KeyMap;
import minko.input.Keyboard.KeyType;
class SDLKeyboard extends Keyboard {
    public static function create() {
        return new SDLKeyboard();
    }
    public var _keyboardState:IntMap<Int>;

    public function new() {
        super();
        _keyboardState = new IntMap<Int>();
    }

    override public function setKeyboardState(key, state) {
        _keyboardState.set(key, state);
    }

    override public function keyIsDown(keyCode_second) {

        return _keyboardState.exists(keyCode_second) && _keyboardState.get(keyCode_second) != 0;


    }


}
