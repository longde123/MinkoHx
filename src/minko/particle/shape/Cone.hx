package minko.particle.shape;
import minko.utils.MathUtil;
class Cone extends EmitterShape {
    private var _angle:Float;
    private var _baseRadius:Float;
    private var _length:Float;
    private var _innerRadius:Float;

    public static function create(angle, baseRadius, length = 0, innerRadius = 0) {
        var cone = new Cone(angle, baseRadius, length, innerRadius);

        return cone;
    }


    public var angle(null, set):Float;
    public var baseRadius(null, set):Float;
    public var length(null, set):Float;
    public var innerRadius(null, set):Float;

    function set_angle(value) {
        _angle = value;
        return value;
    }

    function set_baseRadius(value) {
        _baseRadius = value;
        return value;
    }

    function set_length(value) {
        _length = value;
        return value;
    }

    function set_innerRadius(value) {
        _innerRadius = value;
        return value;
    }

    public function new(angle, baseRadius, length, innerRadius) {
        super();
        this._angle = angle;
        this._baseRadius = baseRadius;
        this._length = length;
        this._innerRadius = innerRadius;
    }

    override public function initPosition(particle:ParticleData) {
        initParticle_(particle, false);
    }

    override public function initPositionAndDirection(particle:ParticleData) {
        initParticle_(particle, true);
    }

    function initParticle_(particle:ParticleData, direction:Bool) {
        var theta = (MathUtil.rand01() * 2.0 - 1.0) * Math.PI;

        var cosTheta = Math.cos(theta);
        var sinTheta = Math.sin(theta);

        var r = _innerRadius + Math.sqrt(MathUtil.rand01()) * (_baseRadius - _innerRadius);

        r = MathUtil.rand01() > .5 ? r : -r;

        particle.x = r * cosTheta;
        particle.y = 0;
        particle.z = r * sinTheta;

        var angle = _angle * r / _baseRadius;
        var height = MathUtil.rand01() * _length * Math.cos(angle);

        r += height * Math.tan(angle);

        if (direction) {
            particle.startvx = r * cosTheta - particle.x;
            particle.startvy = height;
            particle.startvz = r * sinTheta - particle.z;
        }

        particle.x = r * cosTheta;
        particle.y = height;
        particle.z = r * sinTheta;
    }
}
