package minko.audio;
import minko.signal.Signal;
@:expose
class SoundChannel {
    public var complete(get, null):Signal<SoundChannel>;

    function get_complete() {
        return _complete;
    }
    public var sound(get, null):Sound;

    function get_sound() {
        return _sound;
    }
    public var transform(get, set):SoundTransform;

    function set_transform(value) {
        _transform = value;

        return value;
    }

    function get_transform() {
        return _transform;
    }

    public function stop() {

    }

    public var playing(get, null):Bool;

    function get_playing() {
        return false;
    }

    public function dispose() {
    }

    public function new(sound:Sound) {
        this._complete = new Signal<SoundChannel>();
        this._sound = sound;
        this._transform = null;
    }

    var _complete:Signal<SoundChannel>;
    var _sound:Sound;
    var _transform:SoundTransform;

}
