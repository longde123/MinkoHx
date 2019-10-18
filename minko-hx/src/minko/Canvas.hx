package minko;
import minko.AbstractCanvas.Flags;
enum EventKind {
    EPush;
    ERelease;
    EMove;
    EOver;
    EOut;
    EWheel;
    EFocus;
    EFocusLost;
    EKeyDown;
    EKeyUp;
    EReleaseOutside;
    ETextInput;
    /**
		Used to check if we are still on the interactive if no EMove was triggered this frame.
	**/
    ECheck;
}

class Event {

    public var kind:EventKind;
    public var relX:Float;
    public var relY:Float;
    public var relZ:Float;
    /**
		Will propagate the event to other interactives that are below the current one.
	**/
    public var propagate:Bool;
    /**
		Will cancel the default behavior for this event as if it had happen outside of the interactive zone.
	**/
    public var cancel:Bool;
    public var button:Int = 0;
    public var touchId:Int;
    public var keyCode:Int;
    public var charCode:Int;
    public var wheelDelta:Float;

    public function new(k, x = 0., y = 0.) {
        kind = k;
        this.relX = x;
        this.relY = y;
    }

    public function toString() {
        return kind + "[" + Std.int(relX) + "," + Std.int(relY) + "]" + switch( kind ) {
            case EventKind.EPush, EventKind.ERelease, EventKind.EReleaseOutside: ",button=" + button;
            case EventKind.EMove, EventKind.EOver, EventKind.EOut, EventKind.EFocus, EventKind.EFocusLost, EventKind.ECheck: "";
            case EventKind.EWheel: ",wheelDelta=" + wheelDelta;
            case EventKind.EKeyDown, EventKind.EKeyUp: ",keyCode=" + keyCode;
            case EventKind.ETextInput: ",charCode=" + charCode;
        }
    }

}

#if js
@:expose("minko.Canvas")
typedef Canvas =WebCanvas;
#end

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
