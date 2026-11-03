package minko.math;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.math.AbstractShape.ShapePosition;
import minko.utils.MathUtil;
@:expose("minko.math.Box")
class Box extends AbstractShape {
    private var _topRight:Vec3;
    private var _bottomLeft:Vec3;

    public function new() {

        super();
        this._topRight = new Vec3(0, 0, 0);
        this._bottomLeft = new Vec3(0, 0, 0);
    }


    public static function create() {
        return new Box();
    }

    public static function createbyVector3(topRight, bottomLeft) {
        var box = new Box();

        box._topRight = topRight;
        box._bottomLeft = bottomLeft;

        return box;
    }

    public static function merge(box1:Box, box2:Box, ?out:Box = null) {
        if (out == null) {
            out = create();
        }

        out.topRight = (new Vec3(Math.max(box1._topRight.x, box2._topRight.x), Math.max(box1._topRight.y, box2._topRight.y), Math.max(box1._topRight.z, box2._topRight.z)));

        out.bottomLeft = (new Vec3(Math.min(box1._bottomLeft.x, box2._bottomLeft.x), Math.min(box1._bottomLeft.y, box2._bottomLeft.y), Math.min(box1._bottomLeft.z, box2._bottomLeft.z)));

        return out;
    }

    public function mergeBox(box2) {
        return merge(this, box2, this);
    }
    public var topRight(get, set):Vec3;

    function get_topRight() {
        return _topRight;
    }

    function set_topRight(v) {
        _topRight = v;
        return v;
    }
    public var bottomLeft(get, set):Vec3;

    function get_bottomLeft() {
        return _bottomLeft;
    }

    function set_bottomLeft(v) {
        _bottomLeft = v;
        return v;
    }
    public var width(get, null):Float;

    function get_width() {
        return _topRight.x - _bottomLeft.x;
    }

    public var height(get, null):Float;

    function get_height() {
        return _topRight.y - _bottomLeft.y;
    }
    public var depth(get, null):Float;

    function get_depth() {
        return _topRight.z - _bottomLeft.z;
    }

    public function copyFrom(box:Box) {
        _topRight = box._topRight;
        _bottomLeft = box._bottomLeft;

        return this;
    }

    public function distance(position:Vec3) {
        var withinBounds = position.x > _bottomLeft.x && position.y > _bottomLeft.y && position.z > _bottomLeft.z && position.x < _topRight.x && position.y < _topRight.y && position.z < _topRight.z;

        if (withinBounds) {
            return 0.0 ;
        }

        var squareDistance = 0.0 ;

        for (i in ["x", "y", "z"]) {
            var position_i:Float = Reflect.field(position, i);
            var _bottomLeft_i:Float = Reflect.field(_bottomLeft, i);
            var _topRight_i:Float = Reflect.field(_topRight, i);
            if (position_i < _bottomLeft_i) {
                var delta = _bottomLeft_i - position_i;

                squareDistance += delta * delta;
            }
            else if (position_i > _topRight_i) {
                var delta = position_i - _topRight_i;

                squareDistance += delta * delta;
            }
        }

        return Math.sqrt(squareDistance);
    }

    public function intersectRay(ray:Ray):Null<Float> {
        var origins = [ray.origin.x, ray.origin.y, ray.origin.z];
        var directions = [ray.direction.x, ray.direction.y, ray.direction.z];
        var minimums = [
            Math.min(_bottomLeft.x, _topRight.x),
            Math.min(_bottomLeft.y, _topRight.y),
            Math.min(_bottomLeft.z, _topRight.z)
        ];
        var maximums = [
            Math.max(_bottomLeft.x, _topRight.x),
            Math.max(_bottomLeft.y, _topRight.y),
            Math.max(_bottomLeft.z, _topRight.z)
        ];
        var tMin = Math.NEGATIVE_INFINITY;
        var tMax = Math.POSITIVE_INFINITY;

        for (axis in 0...3) {
            var direction = directions[axis];
            if (Math.abs(direction) < 1e-12) {
                if (origins[axis] < minimums[axis] || origins[axis] > maximums[axis]) {
                    return null;
                }
                continue;
            }

            var t0 = (minimums[axis] - origins[axis]) / direction;
            var t1 = (maximums[axis] - origins[axis]) / direction;
            if (t0 > t1) {
                var tmp = t0;
                t0 = t1;
                t1 = tmp;
            }
            tMin = Math.max(tMin, t0);
            tMax = Math.min(tMax, t1);
            if (tMin > tMax) {
                return null;
            }
        }

        if (tMax < 0.0) {
            return null;
        }
        return tMin >= 0.0 ? tMin : 0.0;
    }

    override public function castRay(ray:Ray, distance) {
        return intersectRay(ray) != null;
    }


    public function getVertices() {
        var vertices = [
            (_topRight),
            new Vec3(_topRight.x - width, _topRight.y, _topRight.z),
            new Vec3(_topRight.x - width, _topRight.y, _topRight.z - depth),
            new Vec3(_topRight.x, _topRight.y, _topRight.z - depth),
            (_bottomLeft),
            new Vec3(_bottomLeft.x + width, _bottomLeft.y, _bottomLeft.z),
            new Vec3(_bottomLeft.x + width, _bottomLeft.y, _bottomLeft.z + depth),
            new Vec3(_bottomLeft.x, _bottomLeft.y, _bottomLeft.z + depth)
        ];

        return vertices;
    }

    override public function testBoundingBox(box:Box) {
        if (box.bottomLeft.x > this.topRight.x) {
            return ShapePosition.LEFT;
        }

        if (box.topRight.x < this.bottomLeft.x) {
            return ShapePosition.RIGHT;
        }

        if (box.bottomLeft.y > this.topRight.y) {
            return ShapePosition.BOTTOM;
        }

        if (box.topRight.y < this.bottomLeft.y) {
            return ShapePosition.TOP;
        }

        if (box.topRight.z < this.bottomLeft.z) {
            return ShapePosition.FAR;
        }

        if (box.bottomLeft.z > this.topRight.z) {
            return ShapePosition.NEAR;
        }

        if (this.bottomLeft.x > box.bottomLeft.x && this.bottomLeft.y > box.bottomLeft.y && this.bottomLeft.z > box.bottomLeft.z
        && this.topRight.x < box.topRight.x && this.topRight.y < box.topRight.y && this.topRight.z < box.topRight.z) {
            return ShapePosition.INSIDE;
        }

        return ShapePosition.AROUND;
    }

    override public function updateFromMatrix(matrix:Mat4) {
        var tmp:Vec4 = matrix * (new Vec4(_bottomLeft.x, _bottomLeft.y, _bottomLeft.z, 1));
        _bottomLeft = MathUtil.vec4_vec3(tmp);
        tmp = matrix * (new Vec4(_topRight.x, _topRight.y, _topRight.z, 1));
        _topRight = MathUtil.vec4_vec3(tmp);
    }


}
