package minko.math;
import glm.Vec3;
class Ray {
    public function new() {
        _origin = new Vec3();
        _direction = new Vec3(0.0, 0.0, -1.0);
    }
    private var _origin:Vec3;
    private var _direction:Vec3;

    public static function createbyVector3(origin, direction) {
        var ray = new Ray();
        ray.setRay(origin, direction);
        return ray;
    }

    public static function create() {
        return new Ray();
    }
    public var direction(get, set):Vec3;

    function get_direction() {
        return _direction;
    }

    function set_direction(value) {
        _direction = value;
        return value;
    }
    public var origin(get, set):Vec3;

    function get_origin() {
        return _origin;
    }

    function set_origin(value) {
        _origin = value;
        return value;
    }

    public function setRay(origin, direction) {
        this._origin = origin;
        this._direction = direction;
    }


}
