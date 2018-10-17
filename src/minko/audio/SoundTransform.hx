package minko.audio;
class SoundTransform {
    public static function create(volume = 1.0) {
        return new SoundTransform(volume);
    }
    public var volume(get, set):Float;

    function get_volume() {
        return _volume;
    }

    function set_volume(value) {
        if (value < 0.0) {
            _volume = 0.0;
        }
        else if (value > 1.0) {
            _volume = 1.0;
        }
        else {
            _volume = value;
        }

        return value;
    }
    public var left(get, set):Float;

    function get_left() {
        return _left;
    }

    function set_left(value) {
        if (value < 0.0) {
            _left = 0.0;
        }
        else if (value > 1.0) {
            _left = 1.0;
        }
        else {
            _left = value;
        }

        return value;
    }
    public var right(get, set):Float;

    function get_right() {
        return _right;
    }

    function set_right(value) {
        if (value < 0.0) {
            _right = 0.0;
        }
        else if (value > 1.0) {
            _right = 1.0;
        }
        else {
            _right = value;
        }

        return value;
    }

    public function new(volume) {
        this._left = 1.0;
        this._right = 1.0;
        this._volume = volume;
    }

    public function dispose() {
    }

    private var _left:Float;
    private var _right:Float;
    private var _volume:Float;

}
