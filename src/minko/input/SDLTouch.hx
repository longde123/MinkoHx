package minko.input;
import minko.input.Touch.TouchPoint;
class SDLTouch extends Touch {
    public static inline var SWIPE_PRECISION = 0.05;
    public static inline var TAP_MOVE_THRESHOLD = 10.0;
    public static inline var TAP_DELAY_THRESHOLD = 300.0;
    public static inline var DOUBLE_TAP_DELAY_THRESHOLD = 400.0;
    public static inline var LONG_HOLD_DELAY_THRESHOLD = 1000.0;


    function set_lastTouchDownX(v) {
        _lastTouchDownX = v;
        return v;
    }

    function set_lastTouchDownY(v) {
        _lastTouchDownY = v;
        return v;
    }

    function set_lastTapX(v) {
        _lastTapX = v;
        return v;
    }

    function set_lastTapY(v) {
        _lastTapY = v;
        return v;
    }

    function set_lastTapTime(v) {
        _lastTapTime = v;
        return v;

    }

    function set_lastTouchDownTime(v) {
        _lastTouchDownTime = v;
        return v;
    }

    function get_lastTouchDownX() {
        return _lastTouchDownX;
    }

    function get_lastTouchDownY() {
        return _lastTouchDownY;
    }

    function get_lastTouchDownTime() {
        return _lastTouchDownTime;
    }

    function get_lastTapX() {
        return _lastTapX;
    }

    function get_lastTapY() {
        return _lastTapY;
    }

    function get_lastTapTime() {
        return _lastTapTime;
    }
    public var lastTouchDownX(get, set):Float;
    public var lastTouchDownY(get, set):Float;
    public var lastTouchDownTime(get, set):Float;

    public var lastTapX(get, set):Float;
    public var lastTapY(get, set):Float;
    public var lastTapTime(get, set):Float;
    private var _lastTouchDownX:Float;
    private var _lastTouchDownY:Float;
    private var _lastTouchDownTime:Float;

    private var _lastTapX:Float;
    private var _lastTapY:Float;
    private var _lastTapTime:Float;

    public public function new(canvas) {
        this.Touch = canvas;
        this._lastTouchDownTime = -1.0;
        this._lastTapTime = -1.0;
        this._lastTouchDownX = 0.0;
        this._lastTouchDownY = 0.0;
        this._lastTapX = 0.0;
        this._lastTapY = 0.0;
    }

    public function create(canvas) {
        return new SDLTouch(canvas);
    }

    override public function addTouch(identifier:Int, x:Float, y:Float, dX:Float, dY:Float) {
        if (_touches.exists(identifier) != false) {
            updateTouch(identifier, x, y, dX, dY);
        }
        else {
            _identifiers.push(identifier);

            _touches.set(identifier, new TouchPoint(x, y, dX, dY));
        }
    }

    override public function updateTouch(identifier:Int, x:Float, y:Float, dX:Float, dY:Float) {
        if (_touches.exists(identifier) == false) {
            addTouch(identifier, x, y, dX, dY);
        }
        else {
            var touchPoint:TouchPoint = _touches.get(identifier);
            touchPoint.x = x;
            touchPoint.y = y;
            touchPoint.dX = dX;
            touchPoint.dY = dY;
        }
    }

    override public function removeTouch(identifier) {
        if (_touches.exists(identifier) != false) {
            _touches.remove(identifier);
            _identifiers.remove(identifier)
        }
    }
}
