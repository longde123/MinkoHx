package minko.input;
import minko.signal.Signal3;
import minko.signal.Signal;
@:expose("minko.input.Mouse")
class Mouse {
    private var _canvas:AbstractCanvas;

    private var _x:Int;
    private var _y:Int;

    private var _dX:Int;
    private var _dY:Int;

    private var _leftButtonIsDown:Bool;
    private var _rightButtonIsDown:Bool;
    private var _middleButtonIsDown:Bool;

    private var _mouseMove:Signal3<Mouse, Int, Int> ;
    private var _mouseWheel:Signal3<Mouse, Float, Float> ;
    private var _mouseLeftButtonDown:Signal<Mouse>;
    private var _mouseLeftButtonUp:Signal<Mouse>;
    private var _mouseLeftClick:Signal<Mouse>;
    private var _mouseRightButtonDown:Signal<Mouse>;
    private var _mouseRightButtonUp:Signal<Mouse>;
    private var _mouseRightClick:Signal<Mouse>;
    private var _mouseMiddleButtonDown:Signal<Mouse>;
    private var _mouseMiddleButtonUp:Signal<Mouse>;
    private var _mouseMiddleClick:Signal<Mouse>;

    private var _slots:Array<Dynamic>;

    private var _lastMouseLeftDownX:Int;
    private var _lastMouseLeftDownY:Int;

    private var _lastMouseRightDownX:Int;
    private var _lastMouseRightDownY:Int;

    private var _lastMouseMiddleDownX:Int;
    private var _lastMouseMiddleDownY:Int;

    public static function create(canvas:AbstractCanvas) {
        return new Mouse(canvas);
    }

    public var x(get, set):Int;

    function get_x() {
        return _x;
    }

    public var y(get, set):Int;

    function get_y() {
        return _y;
    }

    function set_x(v) {
        _x = v;
        return v;
    }

    function set_y(v) {
        _y = v;
        return v;
    }
    public var dX(get, set):Int;

    function get_dX() {
        return _dX;
    }

    public var dY(get, set):Int;

    function get_dY() {
        return _dY;
    }

    function set_dX(v) {
        _dX = v;
        return v;
    }

    function set_dY(v) {
        _dY = v;
        return v;
    }

    public var leftButtonIsDown(get, null):Bool;

    function get_leftButtonIsDown() {
        return _leftButtonIsDown;
    }

    public var rightButtonIsDown(get, null):Bool;

    function get_rightButtonIsDown() {
        return _rightButtonIsDown;
    }

    public var middleButtonIsDown(get, null):Bool;

    function get_middleButtonIsDown() {
        return _middleButtonIsDown;
    }

    public var normalizedX(get, null):Float;

    function get_normalizedX() {
        return 2.0 * (_x / _canvas.width - 0.5);
    }

    public var normalizedY(get, null):Float;

    function get_normalizedY() {
        return 2.0 * ( _y / _canvas.height - .5 );
    }
    public var move(get, null):Signal3<Mouse, Int, Int>;

    function get_move() {
        return _mouseMove;
    }
    public var wheel(get, null):Signal3<Mouse, Float, Float>;

    function get_wheel() {
        return _mouseWheel;
    }
    public var leftButtonDown(get, null):Signal<Mouse> ;

    function get_leftButtonDown() {
        return _mouseLeftButtonDown;
    }
    public var leftButtonUp(get, null):Signal<Mouse> ;

    function get_leftButtonUp() {
        return _mouseLeftButtonUp;
    }
    public var leftButtonClick(get, null):Signal<Mouse> ;

    function get_leftButtonClick() {
        return _mouseLeftClick;
    }
    public var rightButtonDown(get, null):Signal<Mouse> ;

    function get_rightButtonDown() {
        return _mouseRightButtonDown;
    }
    public var rightButtonUp(get, null):Signal<Mouse> ;

    function get_rightButtonUp() {
        return _mouseRightButtonUp;
    }
    public var rightButtonClick(get, null):Signal<Mouse> ;

    function get_rightButtonClick() {
        return _mouseRightClick;
    }
    public var middleButtonDown(get, null):Signal<Mouse> ;

    function get_middleButtonDown() {
        return _mouseMiddleButtonDown;
    }
    public var middleButtonUp(get, null):Signal<Mouse> ;

    function get_middleButtonUp() {
        return _mouseMiddleButtonUp;
    }
    public var middleButtonClick(get, null):Signal<Mouse> ;

    function get_middleButtonClick() {
        return _mouseMiddleClick;
    }


    public static inline var CLICK_MOVE_THRESHOLD = 5;

    public function new(canvas:AbstractCanvas) {
        this._canvas = canvas;
        this._x = 0;
        this._y = 0;
        this._dX = 0;
        this._dY = 0;
        this._leftButtonIsDown = false;
        this._rightButtonIsDown = false;
        this._middleButtonIsDown = false;
        this._mouseMove = new Signal3<Mouse, Int, Int>();
        this._mouseWheel = new Signal3<Mouse, Float, Float>();
        this._mouseLeftButtonDown = new Signal<Mouse>();
        this._mouseLeftButtonUp = new Signal<Mouse>();
        this._mouseLeftClick = new Signal<Mouse>();
        this._mouseRightButtonDown = new Signal<Mouse>();
        this._mouseRightButtonUp = new Signal<Mouse>();
        this._mouseRightClick = new Signal<Mouse>();
        this._mouseMiddleButtonDown = new Signal<Mouse>();
        this._mouseMiddleButtonUp = new Signal<Mouse>();
        this._mouseMiddleClick = new Signal<Mouse>();
        _slots = [];
        _slots.push(_mouseLeftButtonDown.connect(function(mouse) {
            _leftButtonIsDown = true;
            _lastMouseLeftDownX = x;
            _lastMouseLeftDownY = y;
        }));
        _slots.push(_mouseLeftButtonUp.connect(function(mouse) {
            _leftButtonIsDown = false;
            var dX = Math.abs(x - _lastMouseLeftDownX);
            var dY = Math.abs(y - _lastMouseLeftDownY);
            if (dX < CLICK_MOVE_THRESHOLD && dY < CLICK_MOVE_THRESHOLD) {
                leftButtonClick.execute(mouse);
            }
        }));

        _slots.push(_mouseRightButtonDown.connect(function(mouse) {
            _rightButtonIsDown = true;
            _lastMouseRightDownX = x;
            _lastMouseRightDownY = y;
        }));
        _slots.push(_mouseRightButtonUp.connect(function(mouse) {
            _rightButtonIsDown = false;
            var dX = Math.abs(x - _lastMouseRightDownX);
            var dY = Math.abs(y - _lastMouseRightDownY);
            if (dX < CLICK_MOVE_THRESHOLD && dY < CLICK_MOVE_THRESHOLD) {
                rightButtonClick.execute(mouse);
            }
        }));

        _slots.push(_mouseMiddleButtonDown.connect(function(mouse) {
            _middleButtonIsDown = true;
            _lastMouseMiddleDownX = x;
            _lastMouseMiddleDownY = y;
        }));
        _slots.push(_mouseMiddleButtonUp.connect(function(mouse) {
            _middleButtonIsDown = false;
            var dX = Math.abs(x - _lastMouseMiddleDownX);
            var dY = Math.abs(y - _lastMouseMiddleDownY);
            if (dX < CLICK_MOVE_THRESHOLD && dY < CLICK_MOVE_THRESHOLD) {
                middleButtonClick.execute(mouse);
            }
        }));
    }
}
