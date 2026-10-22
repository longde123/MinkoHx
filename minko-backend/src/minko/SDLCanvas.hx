package minko;

import minko.AbstractCanvas.Flags;
import minko.CanvasEvent.Event;
import minko.CanvasEvent.EventKind;
import minko.audio.SDLAudio;
import minko.input.Keyboard;
import minko.input.Keyboard.Key;
import minko.input.Keyboard.KeyMap;
import minko.input.SDLKeyboard;
import minko.input.SDLMouse;
import minko.input.SDLTouch;
import minko.input.Touch;
import minko.render.SDLGLContext;
import sdl.Event.EventType;
import sdl.Event.WindowStateChange;
import sdl.Sdl;
import sdl.Window;

class SDLCanvas extends AbstractCanvas {
    var _window:Window;
    var _events:Array<Event>;
    var _disposed:Bool;

    static public function create(name,
                                  width = 800,
                                  height = 600,
                                  flags = Flags.RESIZABLE):SDLCanvas {
        var canvas = new SDLCanvas(name, width, height, flags);
        canvas.initialize();
        if (AbstractCanvas.defaultCanvas == null) AbstractCanvas.defaultCanvas = canvas;
        return canvas;
    }

    public function new(name, width, height, flags) {
        super(name, width, height, flags);
        _events = [];
        _disposed = false;
    }

    override public function initialize() {
        Sdl.init();
        Timer.smoothFactor = 0;
        initializeInputs();
        initializeWindow();
        initializeContext();
    }

    public function initializeInputs() {
        _mouse = SDLMouse.create(this);
        _keyboard = SDLKeyboard.create();
        _touch = SDLTouch.create(this);
    }

    public function initializeWindow() {
        var sdlFlags = 0;
        if ((_flags & (1 << 0)) != 0) sdlFlags |= Window.SDL_WINDOW_FULLSCREEN;
        if ((_flags & (1 << 1)) != 0) sdlFlags |= Window.SDL_WINDOW_RESIZABLE;
        if ((_flags & (1 << 2)) != 0) sdlFlags |= Window.SDL_WINDOW_HIDDEN;

        Sdl.setGLOptions(3, 2, 24, 8, Sdl.DOUBLE_BUFFER | Sdl.GL_COMPATIBILITY_PROFILE, 1);
        _window = new Window(_name, width, height, Window.SDL_WINDOWPOS_CENTERED, Window.SDL_WINDOWPOS_CENTERED, sdlFlags);
        _window.vsync = true;

        width = _window.width;
        height = _window.height;
    }

    public function initializeContext() {
        _backend = SDLBackend.create();
        _backend.initialize(this);

        var context = SDLGLContext.create(width, height);
        context.initialize();
        _context = context;
        _context.configureViewport(0, 0, width, height);
    }

    override public function step() {
        SDLAudio.update();
        stepEvent();
        super.step();
    }

    public function stepEvent() {
        var events = _events;
        _events = [];

        var executeMouseMove = false;
        var mouseDX = 0;
        var mouseDY = 0;

        for (e in events) {
            switch (e.kind) {
                case EventKind.EPush:
                    _mouse.x = Math.floor(e.relX);
                    _mouse.y = Math.floor(e.relY);
                    switch (e.button) {
                        case 0: _mouse.leftButtonDown.execute(_mouse);
                        case 1: _mouse.rightButtonDown.execute(_mouse);
                        case 2: _mouse.middleButtonDown.execute(_mouse);
                    }
                case EventKind.ERelease:
                    _mouse.x = Math.floor(e.relX);
                    _mouse.y = Math.floor(e.relY);
                    switch (e.button) {
                        case 0: _mouse.leftButtonUp.execute(_mouse);
                        case 1: _mouse.rightButtonUp.execute(_mouse);
                        case 2: _mouse.middleButtonUp.execute(_mouse);
                    }
                case EventKind.EReleaseOutside, EventKind.EMove:
                    mouseDX += Math.floor(e.relX) - _mouse.x;
                    mouseDY += Math.floor(e.relY) - _mouse.y;
                    _mouse.x = Math.floor(e.relX);
                    _mouse.y = Math.floor(e.relY);
                    executeMouseMove = true;
                case EventKind.EWheel:
                    _mouse.wheel.execute(_mouse, e.wheelDelta, e.wheelDelta);
                case EventKind.EKeyDown:
                    var keyCode = e.keyCode;
                    _keyboard.setKeyboardState(keyCode, 1);
                    _keyboard.keyDown.execute(_keyboard);
                    for (i in 0...Keyboard.NUM_KEYS) {
                        var code:Int = i;
                        if (!_keyboard.hasKeyDownSignal(code)) continue;
                        if (KeyMap.keyToKeyCodeMap.exists(code) && KeyMap.keyToKeyCodeMap.get(code) == keyCode) {
                            _keyboard.getKeyDown(code).execute(_keyboard, i);
                        }
                    }
                case EventKind.EKeyUp:
                    var keyCode = e.keyCode;
                    _keyboard.setKeyboardState(keyCode, 0);
                    _keyboard.keyUp.execute(_keyboard);
                    for (i in 0...Keyboard.NUM_KEYS) {
                        var code:Int = i;
                        if (!_keyboard.hasKeyUpSignal(code)) continue;
                        if (KeyMap.keyToKeyCodeMap.exists(code) && KeyMap.keyToKeyCodeMap.get(code) == keyCode) {
                            _keyboard.getKeyUp(code).execute(_keyboard, i);
                        }
                    }
                case EventKind.ETextInput:
                    _keyboard.textInput.execute(_keyboard, e.charCode);
                default:
            }
        }

        if (executeMouseMove) {
            _mouse.move.execute(_mouse, mouseDX, mouseDY);
        }
    }

    public function handleEvent(e:sdl.Event):Bool {
        switch (e.type) {
            case EventType.Quit:
                quit();
                return true;
            case EventType.WindowState:
                switch (e.state) {
                    case WindowStateChange.Resize:
                        onResize();
                    case WindowStateChange.Close:
                        quit();
                    case WindowStateChange.Blur:
                        resetInputs();
                    case WindowStateChange.Minimize:
                        _suspended.execute(this);
                    case WindowStateChange.Restore:
                        _resumed.execute(this);
                    default:
                }
            case EventType.MouseMove:
                _events.push(new Event(EventKind.EMove, e.mouseX, e.mouseY));
            case EventType.MouseDown:
                var event = new Event(EventKind.EPush, e.mouseX, e.mouseY);
                event.button = mapButton(e.button);
                _events.push(event);
            case EventType.MouseUp:
                var event = new Event(EventKind.ERelease, e.mouseX, e.mouseY);
                event.button = mapButton(e.button);
                _events.push(event);
            case EventType.MouseWheel:
                var event = new Event(EventKind.EWheel, e.mouseX, e.mouseY);
                event.wheelDelta = -e.wheelDelta;
                _events.push(event);
            case EventType.KeyDown:
                var key = SDLKeyboard.scanCodeToKey.get(e.scanCode);
                if (key != null) {
                    if (key == Key.ESCAPE) {
                        quit();
                        return true;
                    }
                    var event = new Event(EventKind.EKeyDown, _mouse.x, _mouse.y);
                    event.keyCode = key;
                    _events.push(event);
                }
            case EventType.KeyUp:
                var key = SDLKeyboard.scanCodeToKey.get(e.scanCode);
                if (key != null) {
                    var event = new Event(EventKind.EKeyUp, _mouse.x, _mouse.y);
                    event.keyCode = key;
                    _events.push(event);
                }
            case EventType.TextInput:
                var event = new Event(EventKind.ETextInput, _mouse.x, _mouse.y);
                event.charCode = e.keyCode;
                _events.push(event);
            case EventType.TouchDown:
                var x = e.mouseX / 10000.0 * width;
                var y = e.mouseY / 10000.0 * height;
                _touch.addTouch(e.reference, x, y, 0, 0);
                _touch.touchDown.execute(_touch, e.reference, x, y);
            case EventType.TouchMove:
                var x = e.mouseX / 10000.0 * width;
                var y = e.mouseY / 10000.0 * height;
                var previous = _touch.touch(e.reference);
                var dx = previous == null ? 0.0 : x - previous.x;
                var dy = previous == null ? 0.0 : y - previous.y;
                _touch.updateTouch(e.reference, x, y, dx, dy);
                _touch.touchMove.execute(_touch, e.reference, x, y);
            case EventType.TouchUp:
                var x = e.mouseX / 10000.0 * width;
                var y = e.mouseY / 10000.0 * height;
                _touch.removeTouch(e.reference);
                _touch.touchUp.execute(_touch, e.reference, x, y);
            default:
        }
        return true;
    }

    inline function mapButton(button:Int):Int {
        return switch (button) {
            case 1: 0;
            case 2: 2;
            case 3: 1;
            default: button - 1;
        };
    }

    function onResize() {
        if (_window == null) return;
        var w = _window.width;
        var h = _window.height;
        if (w != width || h != height) {
            width = w;
            height = h;
            if (_context != null) _context.configureViewport(0, 0, w, h);
            _resized.execute(this, w, h);
        }
    }

    public function presentWindow() {
        if (_window != null) _window.present();
    }

    public function disposeWindow() {
        if (_disposed) return;
        _disposed = true;
        if (_window != null) {
            _window.destroy();
            _window = null;
        }
        SDLAudio.dispose();
        Sdl.quit();
    }

    override public function quit() {
        _active = false;
    }
}
