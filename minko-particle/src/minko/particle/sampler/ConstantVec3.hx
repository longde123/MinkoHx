package minko.particle.sampler;
import glm.Vec3;
class ConstantVec3 extends SamplerVec3 {
    private var _value:Vec3;

    public static function create(value) {
        var sampler = new Constant(value);

        return sampler;
    }


    override function set_min(v) {
        return v;
    }

    override function get_min() {
        return _value;
    }

    override function set_max(v) {
        return v;
    }

    override function get_max() {
        return _value;
    }

    override public function value(time:Float = 0):Vec3 {

        return _value;
    }

    override public function setValue(v:Vec3, time:Float = 0):Vec3 {
        _value = v;
        return v;
    }

    public function new(value) {
        this._value = value;
    }
}