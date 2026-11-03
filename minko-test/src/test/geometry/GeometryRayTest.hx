package test.geometry;

import glm.Vec2;
import glm.Vec3;
import minko.geometry.Geometry;
import minko.math.Ray;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;

class GeometryRayTest extends haxe.unit.TestCase {
    function assertClose(actual:Float, expected:Float) {
        assertTrue(Math.abs(actual - expected) < 0.0001);
    }

    function createGeometry(data:Array<Float>, indices:Array<Int>, interleaved:Bool):Geometry {
        var geometry = Geometry.create();
        var vertices = VertexBuffer.createbyData(MinkoTests.canvas.context, data);
        if (interleaved) {
            vertices.addAttribute("padding", 1, 0);
            vertices.addAttribute("position", 3, 1);
            vertices.addAttribute("uv", 2, 4);
            vertices.addAttribute("normal", 3, 7);
            vertices.addAttribute("tail", 1, 10);
            vertices.vertexSize = 11;
        }
        else {
            vertices.addAttribute("position", 3);
        }
        geometry.addVertexBuffer(vertices);
        geometry.indices = IndexBuffer.createbyData(MinkoTests.canvas.context, indices);
        return geometry;
    }

    function vertex(x:Float, y:Float, z:Float, u:Float, v:Float):Array<Float> {
        return [99.0, x, y, z, u, v, 0.0, 0.0, 1.0, 88.0, 77.0];
    }

    public function testHitWithInterleavedAttributes() {
        var data = vertex(-1.0, -1.0, 0.0, 0.0, 0.0)
            .concat(vertex(1.0, -1.0, 0.0, 1.0, 0.0))
            .concat(vertex(0.0, 1.0, 0.0, 0.0, 1.0));
        var geometry = createGeometry(data, [0, 0, 0, 0, 1, 2], true);
        var hit = geometry.intersectRay(Ray.createbyVector3(new Vec3(0.0, 0.0, 2.0), new Vec3(0.0, 0.0, -1.0)));
        assertTrue(hit != null);
        assertClose(hit.distance, 2.0);
        assertEquals(hit.triangle, 3);
        assertClose(hit.position.x, 0.0);
        assertClose(hit.position.z, 0.0);
        assertClose(hit.uv.x, 0.25);
        assertClose(hit.uv.y, 0.5);
        assertClose(hit.normal.z, 1.0);

        var position = new Vec3();
        var uv = new Vec2();
        var normal = new Vec3();
        assertTrue(geometry.castRay(Ray.createbyVector3(new Vec3(0.0, 0.0, 2.0), new Vec3(0.0, 0.0, -1.0)), 0.0, 0, position, uv, normal));
        assertClose(uv.x, 0.25);
        assertClose(normal.z, 1.0);
    }

    public function testNearestMissAndOptionalAttributes() {
        var data = [
            -1.0, -1.0, -2.0, 1.0, -1.0, -2.0, 0.0, 1.0, -2.0,
            -1.0, -1.0, 0.0, 1.0, -1.0, 0.0, 0.0, 1.0, 0.0
        ];
        var geometry = createGeometry(data, [0, 1, 2, 3, 4, 5], false);
        var hit = geometry.intersectRay(Ray.createbyVector3(new Vec3(0.0, 0.0, 2.0), new Vec3(0.0, 0.0, -1.0)));
        assertClose(hit.distance, 2.0);
        assertEquals(hit.triangle, 3);
        assertTrue(hit.uv == null);
        assertTrue(hit.normal == null);
        assertTrue(geometry.intersectRay(Ray.createbyVector3(new Vec3(5.0, 0.0, 2.0), new Vec3(0.0, 0.0, -1.0))) == null);
        assertTrue(geometry.intersectRay(Ray.createbyVector3(new Vec3(0.0, 0.0, -2.0), new Vec3(0.0, 0.0, 1.0))) == null);
        assertTrue(geometry.intersectRay(Ray.createbyVector3(new Vec3(0.0, 0.0, 2.0), new Vec3(1.0, 0.0, 0.0))) == null);
    }

    public function testCenterUsesAttributeOffset() {
        var data = vertex(2.0, 0.0, 0.0, 0.0, 0.0)
            .concat(vertex(4.0, 0.0, 0.0, 0.0, 0.0))
            .concat(vertex(2.0, 3.0, 0.0, 0.0, 0.0));
        var geometry = createGeometry(data, [0, 1, 2], true);
        geometry.computeCenterPosition();
        assertClose(geometry.centerPosition.x, 3.0);
        assertClose(geometry.centerPosition.y, 1.5);
        assertClose(geometry.centerPosition.z, 0.0);
    }
}
