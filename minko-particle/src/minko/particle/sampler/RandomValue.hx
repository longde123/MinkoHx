package minko.particle.sampler;
import minko.utils.MathUtil;
class RandomValue extends Sampler {
    private var _min:Float;
    private var _delta:Float;

    public static function create(min, max) {
        var sampler = new RandomValue(min, max);

        return sampler;
    }


    override function set_min(v) {
        _min = v;
        return v;
    }

    override function get_min() {
        return _min;
    }

    override function set_max(v) {
        _delta = v - _min;
        return v;
    }

    override function get_max() {
        return _min + _delta;
    }

    override public function value(v = 0) {
        return _min + _delta * MathUtil.rand01();
    }

    override public function setValue(v:Float, time:Float = 0):Float {
        v = _min + _delta * MathUtil.rand01();
        return v;
    }

    public function new(min, max) {
        this._min = min;
        this._delta = max - min;

    }
}
