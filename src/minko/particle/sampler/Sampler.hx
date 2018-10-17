package minko.particle.sampler;
@:generic
class Sampler {

    public function new() {
    }
    public var min(get, set):Float;

    function set_min(v) {
        return v;
    }

    function get_min() {
        return null;
    }

    public var max(get, set):Float;

    function set_max(v) {
        return v;
    }

    function get_max() {
        return null;
    }

    public function value(time:Float = 0.0):Float {
        return null;
    }

    public function setValue(v:Float, time:Float = 0):Float {
        return null;
    }
}
