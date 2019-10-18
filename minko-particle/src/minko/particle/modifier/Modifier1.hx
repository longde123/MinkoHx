package minko.particle.modifier;
import minko.particle.sampler.Sampler;
@:generic
class Modifier1 {

    private var _x:Sampler;

    public var x(get, set):Sampler;

    function get_x() {
        return _x;
    }

    function set_x(value) {
        _x = value;
        return value;
    }

    public function new(__x:Sampler) {
        this._x = __x;
    }

}
