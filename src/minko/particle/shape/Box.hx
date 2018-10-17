package minko.particle.shape;
import minko.utils.MathUtil;
class Box {
    private var _width:Float;
    private var _height:Float;
    private var _length:Float;
    private var _limitToSides:Bool;

    public static function create(width, height, length, limitToSides) {
        var box = new Box(width, height, length, limitToSides);

        return box;
    }
    public var width(null, set):Float;

    function set_width(value) {
        _width = value;
        return value;
    }
    public var length(null, set):Float;

    function set_length(value) {
        _length = value;
        return value;
    }
    public var limitToSides(null, set):Bool;

    function set_limitToSides(value) {
        _limitToSides = value;
        return value;
    }

    public function new(width, height, length, limitToSides) {
        super();
        this._width = width;
        this._height = height;
        this._length = length;
        this._limitToSides = limitToSides;
    }

    public function initPosition(particle:ParticleData) {
        if (_limitToSides) {
            particle.x = (MathUtil.rand01() < 0.5 ? -_width : _width) * 0.5;
            particle.y = (MathUtil.rand01() < 0.5 ? -_height : _height) * 0.5;
            particle.z = (MathUtil.rand01() < 0.5 - _length : _length) * 0.5;
        }
        else {
            particle.x = (MathUtil.rand01() - 0.5) * _width;
            particle.y = (MathUtil.rand01() - 0.5) * _height;
            particle.z = (MathUtil.rand01() - 0.5) * _length;
        }
    }

}
