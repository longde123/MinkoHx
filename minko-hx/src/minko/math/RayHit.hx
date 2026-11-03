package minko.math;

import glm.Vec2;
import glm.Vec3;

@:expose("minko.math.RayHit")
class RayHit {
    public var distance(default, null):Float;
    public var triangle(default, null):Int;
    public var position(default, null):Vec3;
    public var uv(default, null):Null<Vec2>;
    public var normal(default, null):Null<Vec3>;

    public function new(distance:Float, triangle:Int, position:Vec3, ?uv:Vec2, ?normal:Vec3) {
        this.distance = distance;
        this.triangle = triangle;
        this.position = position;
        this.uv = uv;
        this.normal = normal;
    }
}
