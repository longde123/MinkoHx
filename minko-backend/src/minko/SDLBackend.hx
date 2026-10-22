package minko;

import sdl.Sdl;

class SDLBackend extends AbstractBackend {
    var _canvas:SDLCanvas;

    static public function create() {
        return new SDLBackend();
    }

    public function new() {
        super();
    }

    override public function initialize(canvas) {
        _canvas = cast canvas;
    }

    override public function run(canvas:AbstractCanvas) {
        _canvas = cast canvas;
        var error:Dynamic = null;
        try {
            while (canvas.active) {
                if (!Sdl.processEvents(_canvas.handleEvent)) break;
                if (!canvas.active) break;
                canvas.step();
            }
        }
        catch (e:Dynamic) {
            error = e;
        }
        if (_canvas != null) _canvas.disposeWindow();
        if (error != null) throw error;
    }

    override public function swapBuffers(canvas) {
        if (_canvas != null) _canvas.presentWindow();
    }
}
