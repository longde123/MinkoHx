package minko.particle.sampler;
class Constant extends Sampler {
    private var _value:Float;

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

    override public function value(time:Float = 0):Float {

        return _value;
    }

    override public function setValue(v:Float, time:Float = 0):Float {
        _value = v;
        return v;
    }

    public function new(value) {
        super();
        this._value = value;

    }
}
