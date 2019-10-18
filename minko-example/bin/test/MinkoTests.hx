package test;
import minko.render.Effect;
import minko.AbstractCanvas;
import minko.file.AssetLibrary;
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

    static public function loadEffect(filename:String, assets:AssetLibrary = null) :Effect {
        var lib:AssetLibrary = assets!=null ? assets : AssetLibrary.create(MinkoTests.canvas.context);

        lib.loader.queue(filename);
        lib.loader.load();

        return lib.effect(filename);
    }

    public function new() {
    }
}
