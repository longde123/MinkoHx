package test;
import minko.AbstractCanvas;
class MinkoTests {
    static var _canvas:AbstractCanvas;
    static public var canvas(get, set):AbstractCanvas;

    static function get_canvas() {
        return _canvas;
    }

    static function set_canvas(v) {
        _canvas = v;
        return v;
    }

    public function new() {
    }
}
