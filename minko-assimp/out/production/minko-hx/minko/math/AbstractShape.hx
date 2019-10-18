package minko.math;
import glm.Mat4;
@:expose("minko.math.ShapePosition")
@:enum abstract ShapePosition(Int) from Int to Int{

    var AROUND = -2;
    var INSIDE = -1;
    var LEFT = 0;
    var TOP = 1;
    var RIGHT = 2;
    var BOTTOM = 3;
    var NEAR = 4;
    var FAR = 5;
}
@:expose("minko.math.PlanePosition")
@:enum abstract PlanePosition(Int) from Int to Int{

    var LEFT = 0;
    var TOP = 1;
    var RIGHT = 2;
    var BOTTOM = 3;
    var NEAR = 4;
    var FAR = 5;
}
typedef BoundingBoxPlane = Tuple<ShapePosition, PlanePosition>;
@:expose("minko.math.AbstractShape")
class AbstractShape {
    public function new() {
    }

    public function castRay(ray:Ray, distance) {
        return false;
    }

    public function testBoundingBox(box:Box) {
        return ShapePosition.LEFT;
    }

    public function testBoundingBoxandPlane(box:Box, basePlaneId):AbstractShape.BoundingBoxPlane {
        return null;
    }

    public function updateFromMatrix(matrix:Mat4) {
    }
}
