package test.component;

import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import minko.CloneOption;
import minko.component.BoundingBox;
import minko.component.Surface;
import minko.component.Transform;
import minko.geometry.Geometry;
import minko.material.Material;
import minko.render.VertexBuffer;
import minko.scene.Node;

class BoundingBoxTest extends haxe.unit.TestCase {
    function assertClose(actual:Float, expected:Float) {
        assertTrue(Math.abs(actual - expected) < 0.0001);
    }

    public function testTransformManualUpdate() {
        var transform = Transform.create();
        var bounds = BoundingBox.createbyWHDC(2.0, 4.0, 2.0, new Vec3());
        var node = Node.create().addComponent(transform).addComponent(bounds);
        assertClose(bounds.box.bottomLeft.x, -1.0);
        assertClose(bounds.box.topRight.y, 2.0);

        transform.matrix = GLM.translate(new Vec3(3.0, 0.0, 0.0), Mat4.identity(new Mat4()));
        transform.updateModelToWorldMatrix();
        assertClose(bounds.box.bottomLeft.x, -1.0);
        bounds.update();
        assertClose(bounds.box.bottomLeft.x, 2.0);
        assertClose(bounds.box.topRight.x, 4.0);

        transform.matrix = GLM.rotate(Quat.axisAngle(new Vec3(0.0, 0.0, 1.0), Math.PI / 2.0, new Quat()), Mat4.identity(new Mat4()));
        transform.updateModelToWorldMatrix();
        assertClose(bounds.box.bottomLeft.x, 2.0);
        bounds.update();
        assertClose(bounds.box.bottomLeft.x, -2.0);
        assertClose(bounds.box.topRight.y, 1.0);
    }

    function geometryAt(x:Float):Geometry {
        var geometry = Geometry.create();
        var vertices = VertexBuffer.createbyData(MinkoTests.canvas.context, [x, 20.0, 30.0]);
        vertices.addAttribute("position", 3);
        geometry.addVertexBuffer(vertices);
        return geometry;
    }

    public function testSurfaceAndGeometryManualUpdate() {
        var bounds = BoundingBox.create();
        var surface = Surface.create(geometryAt(1.0), Material.create());
        var node = Node.create().addComponent(bounds).addComponent(surface);
        assertClose(bounds.modelSpaceBox.bottomLeft.x, 1.0);
        surface.geometry = geometryAt(10.0);
        assertClose(bounds.modelSpaceBox.bottomLeft.x, 1.0);
        bounds.update();
        assertClose(bounds.modelSpaceBox.bottomLeft.x, 10.0);
        node.removeComponent(surface);
        assertClose(bounds.modelSpaceBox.bottomLeft.x, 10.0);
        bounds.update();
        assertClose(bounds.modelSpaceBox.bottomLeft.x, 0.0);
        assertClose(bounds.modelSpaceBox.topRight.y, 0.0);
    }

    public function testCloneAndDetach() {
        var source = BoundingBox.createbySize(2.0, new Vec3());
        var deep:BoundingBox = cast source.clone(CloneOption.DEEP);
        var shallow:BoundingBox = cast source.clone(CloneOption.SHALLOW);
        assertTrue(deep.modelSpaceBox != source.modelSpaceBox);
        assertTrue(shallow.modelSpaceBox == source.modelSpaceBox);
        deep.modelSpaceBox.bottomLeft.x = -10.0;
        assertClose(source.modelSpaceBox.bottomLeft.x, -1.0);

        var transform = Transform.create();
        var node = Node.create().addComponent(transform).addComponent(source);
        node.removeComponent(source);
        transform.matrix = GLM.translate(new Vec3(5.0, 0.0, 0.0), Mat4.identity(new Mat4()));
        assertClose(source.box.bottomLeft.x, -1.0);
    }
}
