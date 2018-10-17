package minko.particle.shape;
import minko.utils.MathUtil;
class Cylinder extends EmitterShape {
    private var _height:Float;
    private var _radius:Float;
    private var _innerRadius:Float;

    public static function create(height, radius, innerRadius = 0) {
        var cylinder = new Cylinder(height, radius, innerRadius);

        return cylinder;
    }
    public var height(null, set):Float;
    public var radius(null, set):Float;
    public var innerRadius(null, set):Float;

    function set_height(value) {
        _height = value;
        return value;
    }

    function set_radius(value) {
        _radius = value;
        return value;
    }

    function set_innerRadius(value) {
        _innerRadius = value;
        return value;
    }

    public function new(height, radius, innerRadius) {
        super();
        this._height = height;
        this._radius = radius;
        this._innerRadius = innerRadius;
    }

    override public function initPosition(particle:ParticleData) {
        var theta = (MathUtil.rand01() * 2.0 - 1.0) * Math.PI;

        var cosTheta = Math.cos(theta);
        var sinTheta = Math.sin(theta);

        var r = _innerRadius + Math.sqrt(MathUtil.rand01()) * (_radius - _innerRadius);

        r = MathUtil.rand01() > .5 ? r : -r;

        particle.x = r * cosTheta;
        particle.y = MathUtil.rand01() * _height;
        particle.z = r * sinTheta;
    }
}
