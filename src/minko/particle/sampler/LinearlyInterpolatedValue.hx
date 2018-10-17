package minko.particle.sampler;
class LinearlyInterpolatedValue extends Sampler {
    private var _startValue:Float;
    private var _deltaValue:Float;
    private var _startTime:Float;
    private var _endTime:Float;
    private var _invDeltaTime:Float;

    public static function create(startValue, endValue, startTime = 0.0, endTime = 1.0) {
        var ptr = new LinearlyInterpolatedValue(startValue, endValue, startTime, endTime);

        return ptr;
    }
    public var startValue(get, null):Float;

    function get_startValue() {
        return _startValue;
    }

    public var endValue(get, null):Float;

    function get_endValue() {
        return _startValue + _deltaValue;
    }
    public var startTime(get, null):Float;

    function get_startTime() {
        return _startTime;
    }

    public var endTime(get, null):Float;

    function get_endTime() {
        return _endTime;
    }


    override public function value(time = 0.0) {
        var t = Math.max(0.0, Math.min(1.0, (time - _startTime) * _invDeltaTime));

        return _startValue + _deltaValue * t;
    }

    override function set_min(v) {
        return v;
    }

    override function get_min() {
        return startValue < endValue ? startValue : endValue;
    }

    override function set_max(v) {
        return v;
    }

    override function get_max() {
        return startValue < endValue ? endValue : startValue;
    }

    override public function setValue(v:Float, time:Float = 0):Float {

        return value(time);
    }

    public function new(startValue:Float, endValue:Float, startTime = 0.0, endTime = 1.0) {
        super();
        this._startValue = startValue;
        this._deltaValue = endValue - startValue;
        this._startTime = Math.min(startTime, endTime);
        this._endTime = Math.max(startTime, endTime);
        this._invDeltaTime = 0.0;
        _startTime = Math.max(0.0, Math.min(1.0, _startTime));
        _endTime = Math.max(0.0, Math.min(1.0, _endTime));
        _invDeltaTime = Math.abs(_endTime - _startTime) < 1e-3 ? 0.0 : 1.0 / (_endTime - _startTime);
    }
}
