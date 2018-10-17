package minko.particle.modifier;
import minko.particle.sampler.SamplerVec3;
@:generic
class ModifierVec31 {

    private var _x:SamplerVec3;

    public var x(get, set):SamplerVec3;

    function get_x() {
        return _x;
    }

    function set_x(value) {
        _x = value;
        return value;
    }

    public function new(__x:SamplerVec3) {
        this._x = __x;
    }

}
