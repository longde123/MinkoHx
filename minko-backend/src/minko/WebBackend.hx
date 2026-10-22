package minko;
@:expose("minko.WebBackend")
class WebBackend extends AbstractBackend {
    public var currentCanvas:AbstractCanvas ;
    public var canvasHidden:Int;

    static public function create() {
        return new WebBackend();
    }

    public function new() {
        super();
    }

    override public function initialize(canvas) {
        // Nothing, because we already have the browser.
    }

    override public function swapBuffers(canvas) {
    }

    override public function run(canvas:AbstractCanvas) {
        currentCanvas = canvas;

        setLoop(emscriptenMainLoop);
    }

    override public function wait(canvas, ms) {
        // Nothing, because emscripten_set_main_loop calls step on a timer.
    }


    public function emscriptenMainLoop() {

        currentCanvas.step( );
    }
    static var loopFunc:Void -> Void;

    // JS
    static var loopInit = false;

    public static function getCurrentLoop():Void -> Void {
        return loopFunc;
    }

    public static function setLoop(f:Void -> Void):Void {
        if (!loopInit) {
            loopInit = true;
            browserLoop();
        }
        loopFunc = f;
    }

    static function browserLoop() {
        var window:Dynamic = js.Browser.window;
        var rqf:Dynamic = window.requestAnimationFrame ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame;
        rqf(browserLoop);
        if (loopFunc != null) loopFunc();
    }


}
