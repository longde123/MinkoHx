package minko.input;

import minko.signal.Signal3;
import minko.signal.Signal4;
@:expose("minko.input.Button")
@:enum abstract Button(Int) from Int to Int
{
    var Nothing = -1;
    var DPadUp = 0;
    var DPadDown = 1;
    var DPadLeft = 2;
    var DPadRight = 3;
    var Start = 4;
    var Select = 5;
    var L3 = 6;
    var R3 = 7;
    var LB = 8;
    var RB = 9;
    var A = 10;
    var B = 11;
    var X = 12;
    var Y = 13;
    var Home = 14;
    var LT = 15; // Not a button (axis)
    var RT = 16;
    // Not a button (axis)
}
@:expose("minko.input.Joystick")
class Joystick {
    private var _canvas:AbstractCanvas;

    private var _joystickAxisMotion:Signal4<Joystick, Int, Int, Int> ;
    private var _joystickHatMotion:Signal4<Joystick, Int, Int, Int> ;
    private var _joystickButtonDown:Signal3<Joystick, Int, Int> ;
    private var _joystickButtonUp:Signal3<Joystick, Int, Int> ;

    private var _joystickId:Int;
    public var joystickId(get, null):Int;

    function get_joystickId() {
        return _joystickId;
    }

    public var joystickAxisMotion(get, null):Signal4<Joystick, Int, Int, Int> ;

    function get_joystickAxisMotion() {
        return _joystickAxisMotion;
    }

    public var joystickHatMotion(get, null):Signal4<Joystick, Int, Int, Int> ;

    function get_joystickHatMotion() {
        return _joystickHatMotion;
    }


    public var joystickButtonDown(get, null):Signal3<Joystick, Int, Int > ;

    function get_joystickButtonDown() {
        return _joystickButtonDown;
    }

    public var joystickButtonUp(get, null):Signal3<Joystick, Int, Int > ;

    function get_joystickButtonUp() {
        return _joystickButtonUp;
    }

    public function new(canvas:AbstractCanvas, joystickId:Int) {

        this._canvas = canvas;
        this._joystickAxisMotion = new Signal4<Joystick, Int, Int, Int>();
        this._joystickHatMotion = new Signal4<Joystick, Int, Int, Int>();
        this._joystickButtonUp = new Signal3<Joystick, Int, Int >();
        this._joystickButtonDown = new Signal3<Joystick, Int, Int >();
        this._joystickId = joystickId;
    }

}
