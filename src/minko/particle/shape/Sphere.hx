package minko.particle.shape;
import minko.utils.MathUtil;
class Sphere extends EmitterShape {
    private var _radius:Float;
    private var _innerRadius:Float;

    public static function create(radius, innerRadius = 0) {
        var sphere = new Sphere(radius, innerRadius);

        return sphere;
    }
    public var radius(null, set):Float;
    public var innerRadius(null, set):Float;

    function set_radius(value) {
        _radius = value;
        return value;
    }

    function set_innerRadius(value) {
        _innerRadius = value;
        return value;
    }

    public function new(radius, innerRadius) {
        super();
        this._radius = radius;
        this._innerRadius = innerRadius;
    }

    override public function initPosition(particle:ParticleData) {
        var u = MathUtil.rand01();
        var sqrt1mu2 = Math.sqrt(1.0 - u * u);

        var theta = (MathUtil.rand01() * 2.0 - 1.0) * Math.PI;

        var cosTheta = Math.cos(theta);
        var sinTheta = Math.sin(theta);

        var r = _innerRadius + Math.sqrt(MathUtil.rand01()) * (_radius - _innerRadius);

        r = MathUtil.rand01() > 0.5 ? r : -r;

        particle.x = r * sqrt1mu2 * cosTheta;
        particle.y = r * sqrt1mu2 * sinTheta;
        particle.z = r * u;
    }
}
