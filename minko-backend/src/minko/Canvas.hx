package minko;
import minko.AbstractCanvas.Flags;

#if js
@:expose("minko.Canvas")
typedef Canvas = WebCanvas;
#elseif hl
typedef Canvas = SDLCanvas;
#end

#if (js || hl)
class CanvasManager {
    static public function create(name,
                                  width = 800,
                                  height = 600,
                                  flags = Flags.RESIZABLE):Canvas {
        var canvas= new Canvas(name,
        width ,
        height ,
        flags );
        canvas.initialize();

        if (AbstractCanvas.defaultCanvas == null)
            AbstractCanvas.defaultCanvas = canvas;

        return canvas;
    }
}
#end
