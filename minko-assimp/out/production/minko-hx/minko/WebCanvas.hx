package minko;
import js.html.webgl.GL;
import minko.AbstractCanvas.Flags;
import minko.Canvas.Event;
import minko.Canvas.EventKind;
import minko.file.Options;
import minko.input.Keyboard;
import minko.input.Mouse;
import minko.input.Keyboard;
import minko.input.Touch;
import minko.net.WebHTTPProtocol;
import minko.render.GlContext;
@:expose("minko.WebCanvas")
class WebCanvas extends AbstractCanvas {
    static public function create(name,
                                  width = 800,
                                  height = 600,
                                  flags = Flags.RESIZABLE):WebCanvas {
        var canvas = new WebCanvas(name, width, height, flags);

        canvas.initialize();

        if (AbstractCanvas.defaultCanvas == null)
            AbstractCanvas.defaultCanvas = canvas;

        return canvas;

    }
    var events:Array<Event>;

    public function new(name, width, height, flags) {
        super(name, width, height, flags);
        events = [];
    }

    override public function initialize() :Void{
        Options.registerDefaultProtocol("file", function() return new WebHTTPProtocol());
        initializeInputs();
        initializeWindow();
        initializeContext();
    }

    public function initializeInputs() {
        Stage.getInstance().addEventTarget(onEvent);
        // Stage.getInstance().addResizeEvent(onResize);
    }

    public function initializeWindow() {
        _keyboard = Keyboard.create();
        _mouse = Mouse.create(this);
        _touch = Touch.create(this);

    }

    public function initializeContext() {
        _backend = WebBackend.create();
        _backend.initialize(this);
        var context:GlContext = GlContext.create();
        if (context == null) {
            throw ("Could not create context");
        }
        var antiAlias = 0;
        var canvas:js.html.CanvasElement = @:privateAccess Stage.getInstance().canvas;
       //  var gl =   canvas.getContext("webgl2");
       // var gl = canvas.getContextWebGL({alpha:false, stencil:true, antialias:antiAlias > 0});
        var gl = canvas.getContextWebGL({alpha:false, stencil:true, antialias:false});
        if (gl == null) throw "Could not acquire GL context";
        @:privateAccess context.gl = gl;
        var reg = ~/[0-9]+\.[0-9]+/;
        var version : String = gl.getParameter(GL.SHADING_LANGUAGE_VERSION);
//        gl.getExtension("OES_standard_derivatives");
//        gl.getExtension("EXT_shader_texture_lod");
        if( reg.match(version) ) {
            var glES = Std.parseFloat(reg.matched(0));
            var version2 = Math.round( Std.parseFloat(reg.matched(0)) * 100 );
            trace(glES,version2);
        }
        context.initialize();
        _context = context;

    }

    function onResize() {
        this.width = Stage.getInstance().width;
        this.height = Stage.getInstance().height;
        _context.configureViewport(x, y, width, height);
        _resized.execute(this, width, height);
    }

    function onEvent(e:Event) {
        events.push(e);
    }

    function stepEvent() {
        var ee:Array<Event> = events.concat([]);
        events = [];
        var executeMouseMove = false;
        var mouseDX = 0;
        var mouseDY = 0;
        for (e in ee) {
            var kind = e.kind;
            switch( kind ) {
                case EventKind.EPush:
                    _mouse.x = Math.floor(e.relX);
                    _mouse.y = Math.floor(e.relY);
                    switch (e.button)
                    {
                        case 0:
                            _mouse.leftButtonDown.execute(_mouse);
                            break;
                        case 1:
                            _mouse.rightButtonDown.execute(_mouse);
                            break;
                        case 2:
                            _mouse.middleButtonDown.execute(_mouse);
                            break;
                    }
                case EventKind.ERelease:
                    _mouse.x = Math.floor(e.relX);
                    _mouse.y = Math.floor(e.relY);
                    switch (e.button)
                    {
                        case 0:
                            _mouse.leftButtonUp.execute(_mouse);
                            break;
                        case 1:
                            _mouse.rightButtonUp.execute(_mouse);
                            break;
                        case 2:
                            _mouse.middleButtonUp.execute(_mouse);
                            break;
                    }
                case EventKind.EReleaseOutside:
                case EventKind.EMove:
                    var dX:Int = Math.floor(e.relX) - mouse.x;
                    var dY:Int = Math.floor(e.relY) - mouse.y;
                    mouse.x = Math.floor(e.relX);
                    mouse.y = Math.floor(e.relY);
                    mouseDX += dX;
                    mouseDY += dY;
                    executeMouseMove = true;
                case EventKind.EOver:
                case EventKind.EOut:
                case EventKind.EFocus:
                case EventKind.EFocusLost:
                case EventKind.ECheck:

                case EventKind.EWheel:
                    _mouse.wheel.execute(_mouse, e.wheelDelta, e.wheelDelta);
                case EventKind.EKeyDown:
                    var keyCode = e.keyCode;
                    _keyboard.setKeyboardState(keyCode, 1);
                    _keyboard.keyDown.execute(_keyboard);

                    for (i in 0... Keyboard.NUM_KEYS) {
                        var code:Key = (i);
                        if (!_keyboard.hasKeyDownSignal(code))
                            continue;
                        if (KeyMap.keyToKeyCodeMap.exists(code) && KeyMap.keyToKeyCodeMap.get(code) == keyCode)
                            _keyboard.getKeyDown(code).execute(_keyboard, i);
                    }
                case EventKind.EKeyUp:
                    var keyCode = e.keyCode;
                    _keyboard.setKeyboardState(keyCode, 0);
                    _keyboard.keyUp.execute(_keyboard);

                    for (i in 0... Keyboard.NUM_KEYS) {
                        var code:Key = (i);
                        if (!_keyboard.hasKeyUpSignal(code))
                            continue;
                        if (KeyMap.keyToKeyCodeMap.exists(code) && KeyMap.keyToKeyCodeMap.get(code) == keyCode)
                            _keyboard.getKeyUp(code).execute(_keyboard, i);
                    }
                    for (i in 0... Keyboard.NUM_KEYS) {
                        var code:Key = (i);
                        if (_keyboard.hasKeyUpSignal(code))
                            _keyboard.getKeyUp(code).execute(_keyboard, i);
                    }
                case EventKind.ETextInput:
                    var c = e.charCode;
                    _keyboard.textInput.execute(_keyboard, c);
            }
            if (executeMouseMove) {
                _mouse.move.execute(_mouse, mouseDX, mouseDY);
            }
        }
    }

    override public function step() {
        stepEvent();
        super.step();
    }
}
class Stage {

    var resizeEvents:List<Void -> Void>;
    var eventTargets:List<Event -> Void>;

    public var width(get, never):Int;
    public var height(get, never):Int;
    public var mouseX(get, never):Int;
    public var mouseY(get, never):Int;
    public var mouseLock(get, set):Bool;
    public var vsync(get, set):Bool;

    var curMouseX:Float = 0.;
    var curMouseY:Float = 0.;

    var canvas:js.html.CanvasElement;
    var element:js.html.EventTarget;
    var canvasPos:{ var width(default, never):Float; var height(default, never):Float; var left(default, never):Float; var top(default, never):Float; };
    var timer:haxe.Timer;

    var curW:Int;
    var curH:Int;

    function new(?canvas:js.html.CanvasElement):Void {
        eventTargets = new List();
        resizeEvents = new List();

        element = canvas == null ? js.Browser.window : canvas;
        if (canvas == null) {
            canvas = cast js.Browser.document.getElementById("webgl");
            if (canvas == null) throw "Missing canvas #webgl";
        }
        this.canvas = canvas;
        canvasPos = canvas.getBoundingClientRect();
        element.addEventListener("mousedown", onMouseDown);
        element.addEventListener("mousemove", onMouseMove);
        element.addEventListener("mouseup", onMouseUp);
        element.addEventListener("mousewheel", onMouseWheel);
        element.addEventListener("touchstart", onTouchStart);
        element.addEventListener("touchmove", onTouchMove);
        element.addEventListener("touchend", onTouchEnd);
        element.addEventListener("keydown", onKeyDown);
        element.addEventListener("keyup", onKeyUp);
        element.addEventListener("keypress", onKeyPress);
        if (element == canvas) {
            canvas.setAttribute("tabindex", "1"); // allow focus
            canvas.style.outline = 'none';
        } else {
            canvas.addEventListener("mousedown", function(e) {
                onMouseDown(e);
                e.stopPropagation();
                e.preventDefault();
            });
            canvas.oncontextmenu = function(e) {
                e.stopPropagation();
                e.preventDefault();
                return false;
            };
        }
        curW = this.width;
        curH = this.height;
        timer = new haxe.Timer(100);
        timer.run = checkResize;
    }

    function checkResize() {
        canvasPos = canvas.getBoundingClientRect();
        var cw = this.width, ch = this.height;
        if (curW != cw || curH != ch) {
            curW = cw;
            curH = ch;
            onResize(null);
        }
    }

    public function dispose() {
        timer.stop();
    }

    public dynamic function onClose():Bool {
        return true;
    }

    public function event(e:Event):Void {
        for (et in eventTargets)
            et(e);
    }

    public function addEventTarget(et:Event -> Void):Void {
        eventTargets.add(et);
    }

    public function removeEventTarget(et:Event -> Void):Void {
        eventTargets = eventTargets.filter(function(e) {
            return !Reflect.compareMethods(e, et);
        });

    }

    public function addResizeEvent(f:Void -> Void):Void {
        resizeEvents.push(f);
    }

    public function removeResizeEvent(f:Void -> Void):Void {
        resizeEvents = resizeEvents.filter(function(e) {
            return !Reflect.compareMethods(e, f);
        });

    }

    function onResize(e:Dynamic):Void {
        for (r in resizeEvents)
            r();
    }

    public function resize(width:Int, height:Int):Void {
    }

    public function setFullScreen(v:Bool):Void {
    }

    public function setCurrent() {
        inst = this;
    }

    static var inst:Stage = null;

    public static function getInstance():Stage {
        if (inst == null) inst = new Stage();
        return inst;
    }

    function get_width() {
        return Math.round(canvasPos.width * js.Browser.window.devicePixelRatio);
    }

    function get_height() {
        return Math.round(canvasPos.height * js.Browser.window.devicePixelRatio);
    }

    function get_mouseX() {
        return Math.round((curMouseX - canvasPos.left) * js.Browser.window.devicePixelRatio);
    }

    function get_mouseY() {
        return Math.round((curMouseY - canvasPos.top) * js.Browser.window.devicePixelRatio);
    }

    function get_mouseLock():Bool {
        return false;
    }

    function set_mouseLock(v:Bool):Bool {
        if (v) throw "Not implemented";
        return false;
    }

    function get_vsync():Bool return true;

    function set_vsync(b:Bool):Bool {
        if (!b) throw "Can't disable vsync on this platform";
        return true;
    }
/*
 0：主按键被按下，通常指鼠标左键 or the un-initialized state
1：辅助按键被按下，通常指鼠标滚轮 or the middle button (if present)
2：次按键被按下，通常指鼠标右键
3：第四个按钮被按下，通常指浏览器后退按钮
4：第五个按钮被按下，通常指浏览器的前进按钮
*/
    function onMouseDown(e:js.html.MouseEvent) {
        var ev = new Event(EventKind.EPush, mouseX, mouseY);
        ev.button = switch( e.button ) {
            case 1: 2;
            case 2: 1;
            case x: x;
        };
        event(ev);
    }

    function onMouseUp(e:js.html.MouseEvent) {
        var ev = new Event(EventKind.ERelease, mouseX, mouseY);
        ev.button = switch( e.button ) {
            case 1: 2;
            case 2: 1;
            case x: x;
        };
        event(ev);
    }

    function onMouseMove(e:js.html.MouseEvent) {
        curMouseX = e.clientX;
        curMouseY = e.clientY;
        event(new Event(EventKind.EMove, mouseX, mouseY));
    }

    function onMouseWheel(e:js.html.MouseEvent) {
        var ev = new Event(EventKind.EWheel, mouseX, mouseY);
        ev.wheelDelta = untyped -e.wheelDelta / 30.0;
        event(ev);
    }

    function onTouchStart(e:js.html.TouchEvent) {
        e.preventDefault();
        var x, y, ev;
        for (touch in e.changedTouches) {
            x = Math.round((touch.clientX - canvasPos.left) * js.Browser.window.devicePixelRatio);
            y = Math.round((touch.clientY - canvasPos.top) * js.Browser.window.devicePixelRatio);
            ev = new Event(EventKind.EPush, x, y);
            ev.touchId = touch.identifier;
            event(ev);
        }
    }

    function onTouchMove(e:js.html.TouchEvent) {
        e.preventDefault();
        var x, y, ev;
        for (touch in e.changedTouches) {
            x = Math.round((touch.clientX - canvasPos.left) * js.Browser.window.devicePixelRatio);
            y = Math.round((touch.clientY - canvasPos.top) * js.Browser.window.devicePixelRatio);
            ev = new Event(EventKind.EMove, x, y);
            ev.touchId = touch.identifier;
            event(ev);
        }
    }

    function onTouchEnd(e:js.html.TouchEvent) {
        e.preventDefault();
        var x, y, ev;
        for (touch in e.changedTouches) {
            x = Math.round((touch.clientX - canvasPos.left) * js.Browser.window.devicePixelRatio);
            y = Math.round((touch.clientY - canvasPos.top) * js.Browser.window.devicePixelRatio);
            ev = new Event(EventKind.ERelease, x, y);
            ev.touchId = touch.identifier;
            event(ev);
        }
    }

    function onKeyUp(e:js.html.KeyboardEvent) {
        var ev = new Event(EventKind.EKeyUp, mouseX, mouseY);
        ev.keyCode = e.keyCode;
        event(ev);
    }

    function onKeyDown(e:js.html.KeyboardEvent) {
        var ev = new Event(EventKind.EKeyDown, mouseX, mouseY);
        ev.keyCode = e.keyCode;
        event(ev);
    }

    function onKeyPress(e:js.html.KeyboardEvent) {
        var ev = new Event(EventKind.ETextInput, mouseX, mouseY);
        ev.charCode = e.charCode;
        event(ev);
    }

}