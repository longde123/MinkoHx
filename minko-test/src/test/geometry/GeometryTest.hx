package test.geometry;

import minko.geometry.Geometry;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;
import minko.utils.VectorHelper;
class GeometryTest extends haxe.unit.TestCase {


    public function testCreate() {
        var g = Geometry.createbyName();

        assertTrue(true);
    }


    public function testAddVertexBuffer() {
        var g = Geometry.createbyName();
        var vertices = [0.0, .5, 0.0, .5, -.5, .0, -.5, -.5, 0.0];
        var vb = VertexBuffer.createbyData(MinkoTests.canvas.context, vertices);

        vb.addAttribute("position", 3);

        g.addVertexBuffer(vb);

        assertTrue(Lambda.has(g.vertexBuffers, vb));
    }


    public function testRemoveVertexBuffer() {
        var g = Geometry.createbyName();
        var vertices = [0.0, .5, 0.0, .5, -.5, .0, -.5, -.5, 0.0];
        var vb = VertexBuffer.createbyData(MinkoTests.canvas.context, vertices);

        vb.addAttribute("position", 3);

        g.addVertexBuffer(vb);
        g.removeVertexBuffer(vb);

        assertFalse(Lambda.has(g.vertexBuffers, vb));
    }


    public function testRemoveVertexBufferByAttributeName() {
        var g = Geometry.createbyName();
        var vertices = [0.0, .5, 0.0, .5, -.5, .0, -.5, -.5, 0.0];
        var vb = VertexBuffer.createbyData(MinkoTests.canvas.context, vertices);

        vb.addAttribute("position", 3);

        g.addVertexBuffer(vb);
        g.removeVertexBufferbyName("position");

        assertFalse(Lambda.has(g.vertexBuffers, vb));
    }


    public function testHasVertexBuffer() {
        var g = Geometry.createbyName();
        var vertices = [0.0, .5, 0.0, .5, -.5, .0, -.5, -.5, 0.0];
        var vb = VertexBuffer.createbyData(MinkoTests.canvas.context, vertices);

        vb.addAttribute("position", 3);

        g.addVertexBuffer(vb);

        assertTrue(g.hasVertexBuffer(vb));
    }


    public function testHasVertexAttribute() {
        var g = Geometry.createbyName();
        var vertices = [0.0, .5, 0.0, .5, -.5, .0, -.5, -.5, 0.0];
        var vb = VertexBuffer.createbyData(MinkoTests.canvas.context, vertices);

        vb.addAttribute("position", 3);

        g.addVertexBuffer(vb);

        assertTrue(g.hasVertexAttribute("position"));
    }


    public function testVertexBufferAddedInData() {
        var g = Geometry.createbyName();
        var vertices = [0.0, .5, 0.0, .5, -.5, .0, -.5, -.5, 0.0];
        var vb = VertexBuffer.createbyData(MinkoTests.canvas.context, vertices);

        vb.addAttribute("position", 3);

        g.addVertexBuffer(vb);

        assertTrue(g.data.hasProperty("position"));
        assertEquals(g.data.get("position"), vb.attribute("position"));
    }


    public function testVertexBufferRemovedFromData() {
        var g = Geometry.createbyName();
        var vertices = [0.0, .5, 0.0, .5, -.5, .0, -.5, -.5, 0.0];
        var vb = VertexBuffer.createbyData(MinkoTests.canvas.context, vertices);

        vb.addAttribute("position", 3);

        g.addVertexBuffer(vb);
        g.removeVertexBuffer(vb);

        assertFalse(g.data.hasProperty("position"));
    }


    public function testVertexAttributeOffset() {
        var numVertices = 3;
        var data = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
        var vb = VertexBuffer.createbyData(MinkoTests.canvas.context, data);

        vb.addAttribute("a", 1);
        vb.addAttribute("b", 2);

        var counter = 0.0;
        for (i in 0... numVertices) {
            var vertexsize = vb.vertexSize;
            for (attribute in vb.attributes) {
                for (j in 0...attribute.size) {
                    var value = vb.data[i * vertexsize + attribute.offset + j];
                    assertEquals(value, counter);
                    counter++;
                }
            }
        }
    }


    public function testNumVerticesAfterAddVertexBufferAndRemoveVertexBuffer() {
        var g = Geometry.createbyName();

        var vertices = VectorHelper.initializedList(18, 0.0);
        var vb = VertexBuffer.createbyData(MinkoTests.canvas.context, vertices);

        vb.addAttribute("position", 3, 0);
        vb.addAttribute("normal", 3, 3);

        g.addVertexBuffer(vb);
        g.removeVertexBuffer(vb);

        var newVertices = VectorHelper.initializedList(24, 0.0);
        var newVb = VertexBuffer.createbyData(MinkoTests.canvas.context, newVertices);

        for (attribute in vb.attributes) {
            newVb.addAttribute(attribute.name, attribute.size, attribute.offset);
        }

        g.addVertexBuffer(newVb);

        assertEquals(g.numVertices, 4);
    }


    public function testComputeNotExistingNormals() {
        var context = MinkoTests.canvas.context;

        var expectedNormalData = [0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0];

        var geometryData = [0.5, 0.5, -0.5, 1.0, 0.0, -0.5, 0.5, 0.5, 0.0, 1.0, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, -0.5, 1.0, 0.0, -0.5, 0.5, -0.5, 0.0, 0.0, -0.5, 0.5, 0.5, 0.0, 1.0, -0.5, -0.5, 0.5, 0.0, 0.0, 0.5, -0.5, -0.5, 1.0, 1.0, 0.5, -0.5, 0.5, 1.0, 0.0, -0.5, -0.5, -0.5, 0.0, 1.0, 0.5, -0.5, -0.5, 1.0, 1.0, -0.5, -0.5, 0.5, 0.0, 0.0, 0.5, -0.5, -0.5, 0.0, 1.0, -0.5, 0.5, -0.5, 1.0, 0.0, 0.5, 0.5, -0.5, 0.0, 0.0, -0.5, 0.5, -0.5, 1.0, 0.0, 0.5, -0.5, -0.5, 0.0, 1.0, -0.5, -0.5, -0.5, 1.0, 1.0, -0.5, 0.5, 0.5, 0.0, 0.0, -0.5, -0.5, 0.5, 0.0, 1.0, 0.5, 0.5, 0.5, 1.0, 0.0, -0.5, -0.5, 0.5, 0.0, 1.0, 0.5, -0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 0.5, 1.0, 0.0, -0.5, -0.5, 0.5, 1.0, 1.0, -0.5, 0.5, -0.5, 0.0, 0.0, -0.5, -0.5, -0.5, 0.0, 1.0, -0.5, 0.5, -0.5, 0.0, 0.0, -0.5, -0.5, 0.5, 1.0, 1.0, -0.5, 0.5, 0.5, 1.0, 0.0, 0.5, -0.5, -0.5, 1.0, 1.0, 0.5, 0.5, -0.5, 1.0, 0.0, 0.5, 0.5, 0.5, 0.0, 0.0, 0.5, 0.5, 0.5, 0.0, 0.0, 0.5, -0.5, 0.5, 0.0, 1.0, 0.5, -0.5, -0.5, 1.0, 1.0];

        var i = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35];

        var geometry = Geometry.createbyName();

        var vertexBuffer = VertexBuffer.createbyData(context, geometryData);

        vertexBuffer.addAttribute("position", 3, 0);
        vertexBuffer.addAttribute("uv", 2, 3);

        geometry.addVertexBuffer(vertexBuffer);

        geometry.indices=(IndexBuffer.createbyData(context, i));

        geometry.computeNormals();
        var vertexBuffer:VertexBuffer = cast geometry.vertexBuffer("normal");
        var normalData = vertexBuffer.data;

        assertEquals(normalData.length, expectedNormalData.length);
        assertTrue(VectorHelper.equals(normalData, expectedNormalData));
    }


    public function testComputeExistingNormals() {
        var context = MinkoTests.canvas.context;

        var geometryData = [0.5, 0.5, -0.5, 0.0, -1.0, 0.0, 1.0, 0.0, -0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 1.0, 1.0, 0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 0.0, -0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 0.0, -0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 0.0, 0.0, 0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 1.0, 1.0, 0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 1.0, 0.0, -0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 0.0, 1.0, 0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 1.0, 1.0, -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 0.0, 0.0, 0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 1.0, -0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 0.0, 0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 0.0, -0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 0.0, 0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 1.0, -0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 1.0, -0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 0.0, -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.0, -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 1.0, 0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.0, -0.5, -0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 1.0, -0.5, 0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 0.0, -0.5, -0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 1.0, -0.5, 0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 0.0, -0.5, -0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 1.0, -0.5, 0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 0.0, 0.5, -0.5, -0.5, 1.0, 0.0, 0.0, 1.0, 1.0, 0.5, 0.5, -0.5, 1.0, 0.0, 0.0, 1.0, 0.0, 0.5, 0.5, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.5, -0.5, 0.5, 1.0, 0.0, 0.0, 0.0, 1.0, 0.5, -0.5, -0.5, 1.0, 0.0, 0.0, 1.0, 1.0];

        var expectedNormalData = [0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 0.0, -0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 1.0, 1.0, 0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 0.0, -0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 0.0, -0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 0.0, 0.0, 0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 1.0, 1.0, 0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 1.0, 0.0, -0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 0.0, 1.0, 0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 1.0, 1.0, -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 0.0, 0.0, 0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 1.0, -0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 0.0, 0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 0.0, -0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 0.0, 0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 1.0, -0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 1.0, -0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 0.0, -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.0, -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 1.0, 0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.0, -0.5, -0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 1.0, -0.5, 0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 0.0, -0.5, -0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 1.0, -0.5, 0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 0.0, -0.5, -0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 1.0, -0.5, 0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 0.0, 0.5, -0.5, -0.5, 1.0, 0.0, 0.0, 1.0, 1.0, 0.5, 0.5, -0.5, 1.0, 0.0, 0.0, 1.0, 0.0, 0.5, 0.5, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.5, -0.5, 0.5, 1.0, 0.0, 0.0, 0.0, 1.0, 0.5, -0.5, -0.5, 1.0, 0.0, 0.0, 1.0, 1.0];

        var i = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35];

        var geometry = Geometry.createbyName();

        var vertexBuffer = VertexBuffer.createbyData(context, geometryData);

        vertexBuffer.addAttribute("position", 3, 0);
        vertexBuffer.addAttribute("normal", 3, 3);
        vertexBuffer.addAttribute("uv", 2, 6);

        geometry.addVertexBuffer(vertexBuffer);

        geometry.indices=(IndexBuffer.createbyData(context, i));

        geometry.computeNormals();
        var vertexBuffer:VertexBuffer = cast geometry.vertexBuffer("normal");
        var normalData = vertexBuffer.data;

        assertEquals(normalData.length, expectedNormalData.length);
        assertTrue(VectorHelper.equals(normalData, expectedNormalData));
    }


}
