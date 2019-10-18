package minko.particle.sampler;
import glm.Vec3;
class SamplerVec3 {
    public function new() {
    }
    public var min(get, set):Vec3;

    function set_min(v) {
        return v;
    }

    function get_min() {
        return null;
    }

    public var max(get, set):Vec3;

    function set_max(v) {
        return v;
    }

    function get_max() {
        return null;
    }

    public function value(time:Float = 0):Vec3 {
        return null;
    }

    public function setValue(v:Vec3, time:Float = 0):Vec3 {
        return null;
    }
}
