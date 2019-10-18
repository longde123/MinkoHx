package minko.audio;
import minko.component.AbstractScript;
import minko.scene.Node;
@:expose
class PositionalSound extends AbstractScript {

    public var audibilityCurve(get, set):Float -> Float;

    function get_audibilityCurve() {
        return _audibilityCurve;
    }

    function set_audibilityCurve(value) {
        _audibilityCurve = value;
        return value;
    }

    public static function create(channel:SoundChannel, camera:Node) {
        var p = new PositionalSound(channel, camera);

        return p;
    }


    public function new(channel:SoundChannel, camera:Node) {
        super();
        this._channel = channel;
        this._camera = camera;
        this._audibilityCurve = PositionalSound.defaultAudibilityCurve;
    }

    private static function defaultAudibilityCurve(distance:Float) {
        return (10.0 / (4.0 * Math.PI * distance));
    }

    private var _channel:SoundChannel;
    private var _camera:Node;
    private var _audibilityCurve:Float -> Float;

}

