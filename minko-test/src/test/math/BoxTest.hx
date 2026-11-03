package test.math;

import glm.Vec3;
import minko.math.Box;
import minko.math.Ray;

class BoxTest extends haxe.unit.TestCase {
    function createBox():Box {
        return Box.createbyVector3(new Vec3(1.0, 1.0, 1.0), new Vec3(-1.0, -1.0, -1.0));
    }

    function assertClose(actual:Float, expected:Float) {
        assertTrue(Math.abs(actual - expected) < 0.0001);
    }

    public function testRayDistance() {
        var distance = createBox().intersectRay(Ray.createbyVector3(new Vec3(0.0, 0.0, 3.0), new Vec3(0.0, 0.0, -1.0)));
        assertTrue(distance != null);
        assertClose(distance, 2.0);
    }

    public function testInsideParallelAndBehind() {
        var box = createBox();
        assertClose(box.intersectRay(Ray.createbyVector3(new Vec3(), new Vec3(0.0, 0.0, -1.0))), 0.0);
        assertClose(box.intersectRay(Ray.createbyVector3(new Vec3(0.0, 0.0, 3.0), new Vec3(0.0, 0.0, -1.0))), 2.0);
        assertTrue(box.intersectRay(Ray.createbyVector3(new Vec3(2.0, 0.0, 3.0), new Vec3(0.0, 0.0, -1.0))) == null);
        assertTrue(box.intersectRay(Ray.createbyVector3(new Vec3(0.0, 0.0, 3.0), new Vec3(0.0, 0.0, 1.0))) == null);
    }

    public function testDiagonalRay() {
        var direction = Vec3.normalize(new Vec3(-1.0, -1.0, -1.0), new Vec3());
        var distance = createBox().intersectRay(Ray.createbyVector3(new Vec3(3.0, 3.0, 3.0), direction));
        assertTrue(distance != null);
        assertClose(distance, 2.0 * Math.sqrt(3.0));
    }
}
