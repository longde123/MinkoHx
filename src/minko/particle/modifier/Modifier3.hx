package minko.particle.modifier;
import minko.particle.sampler.Sampler;
class Modifier3 {
    private var _x:Sampler;
    private var _y:Sampler;
    private var _z:Sampler;
    public var x(get, set):Sampler;
    public var y(get, set):Sampler;
    public var z(get, set):Sampler;

    function get_x() {
        return _x;
    }

    function get_y() {
        return _y;
    }

    function get_z() {
        return _z;
    }

    function set_x(value) {
        _x = value;
        return value
    }

    function set_y(value) {
        _y = value;
        return value;
    }

    function set_z(value) {

        _z = value;
        return value;
    }

    public function new(x, y, z) {
        this._x = x;
        this._y = y;
        this._z = z;

    }
}
