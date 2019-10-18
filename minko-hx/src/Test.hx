package ;
import minko.system.Platform;
import minko.signal.Signal3;

@:expose
class Test  extends Platform{
    public var _enterFrame:Signal3<Float, Float, Float>;
    public function new() {
    }
}
