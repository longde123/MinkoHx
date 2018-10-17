package minko.input;
import haxe.ds.IntMap;
import minko.signal.Signal2;
import minko.signal.Signal3;
import minko.signal.Signal4;
import minko.signal.Signal;
class TouchPoint {
    public var x:Float;
    public var y:Float;
    public var dX:Float;
    public var dY:Float;

    public function new(x, y, dX, dY) {
        this.x = x;
        this.y = y;
        this.dX = dX;
        this.dY = dY;
    }
}
class Touch {
    public static function create(canvas:AbstractCanvas) {
        return new Touch(canvas);
    }
    private var _canvas:AbstractCanvas;

    private var _touches:IntMap<TouchPoint> ; // identifier to x/y dx/dy

    private var _identifiers:Array<Int>;

    private var _touchMove:Signal4<Touch, Int, Float, Float>;
    private var _touchDown:Signal4<Touch, Int, Float, Float>;
    private var _touchUp:Signal4<Touch, Int, Float, Float>;

    // Gestures
    private var _swipeRight:Signal<Touch> ;
    private var _swipeLeft:Signal<Touch> ;
    private var _swipeUp:Signal<Touch> ;
    private var _swipeDown:Signal<Touch> ;
    private var _pinchZoom:Signal2<Touch, Float>;
    private var _tap:Signal3<Touch, Float, Float>;
    private var _doubleTap:Signal3<Touch, Float, Float>;
    private var _longHold:Signal3<Touch, Float, Float>;
    public var touches(get, null):IntMap<TouchPoint>;

    function get_touches() {
        return _touches;
    }
    public var identifiers(get, null):Array<Int>;

    function get_identifiers() {
        return _identifiers;
    }
    public var numTouches(get, null):Int;

    function get_numTouches() {
        return _identifiers.length;
    }

    public function touch(identifier):TouchPoint {
        return _touches.get(identifier);
    }
    public var touchMove(get, null):Signal4<Touch, Int, Float, Float>;

    function get_touchMove() {
        return _touchMove;
    }
    public var touchDown(get, null):Signal4<Touch, Int, Float, Float>;

    function get_touchDown() {
        return _touchDown;
    }

    public var touchUp(get, null):Signal4<Touch, Int, Float, Float>;

    function get_touchUp() {
        return _touchUp;
    }
    public var swipeLeft(get, null):Signal<Touch>;

    function get_swipeLeft() {
        return _swipeLeft;
    }

    public var swipeRight(get, null):Signal<Touch>;

    function get_swipeRight() {
        return _swipeRight;
    }

    public var swipeUp(get, null):Signal<Touch>;

    function get_swipeUp() {
        return _swipeUp;
    }

    public var swipeDown(get, null):Signal<Touch>;

    function get_swipeDown() {
        return _swipeDown;
    }

    public var pinchZoom(get, null):Signal2<Touch, Float>;

    function get_pinchZoom() {
        return _pinchZoom;
    }

    public var tap(get, null):Signal3<Touch, Float, Float>;

    function get_tap() {
        return _tap;
    }

    public var doubleTap(get, null):Signal3<Touch, Float, Float>;

    function get_doubleTap() {
        return _doubleTap;
    }

    public var longHold(get, null):Signal3<Touch, Float, Float>;

    function get_longHold() {
        return _longHold;
    }

    public var averageX(get, null):Float;

    function get_averageX() {
        var x = 0.0 ;
        var l = numTouches ;

        for (i in 0... l) {
            x += _touches.get(_identifiers[i]).x;
        }

        x /= l;

        return x;
    }

    public var averageY(get, null):Float;

    function get_averageY() {
        var y = 0.0 ;
        var l = numTouches;

        for (i in 0... l) {
            y += _touches.get(_identifiers[i]).y;
        }

        y /= l;

        return y;
    }

    public var averageDX(get, null):Float;

    function get_averageDX() {
        var x = 0.0 ;
        var l = numTouches ;

        for (i in 0...l) {
            x += _touches.get(_identifiers[i]).dX;
        }

        x /= l;

        return x;
    }

    public var averageDY(get, null):Float;

    function get_averageDY() {
        var y = 0.0 ;
        var l = numTouches ;

        for (i in 0... l) {
            y += _touches.get(_identifiers[i]).dY;
        }

        y /= l;

        return y;
    }

    public function resetDeltas() {
        var l = numTouches ;

        for (i in 0... l) {
            _touches.get(_identifiers[i]).dX = 0;
            _touches.get(_identifiers[i]).dY = 0;
        }
    }

    public function new(canvas:AbstractCanvas) {
        this._canvas = canvas;
        this._touches = new IntMap< TouchPoint>();
        this._touchMove = new Signal4<Touch, Int, Float, Float>();
        this._touchDown = new Signal4<Touch, Int, Float, Float>();
        this._touchUp = new Signal4<Touch, Int, Float, Float>();
        this._pinchZoom = new Signal2<Touch, Float>();
        this._swipeLeft = new Signal<Touch>();
        this._swipeRight = new Signal<Touch>();
        this._swipeUp = new Signal<Touch>();
        this._swipeDown = new Signal<Touch>();
        this._tap = new Signal3<Touch, Float, Float>();
        this._doubleTap = new Signal3<Touch, Float, Float>();
        this._longHold = new Signal3<Touch, Float, Float>();
    }

    public function addTouch(identifier:Int, x:Float, y:Float, dX:Float, dY:Float) {

    }

    public function updateTouch(identifier:Int, x:Float, y:Float, dX:Float, dY:Float) {

    }

    public function removeTouch(identifier) {

    }

}
