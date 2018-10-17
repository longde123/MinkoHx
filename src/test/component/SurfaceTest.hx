package test.component;
import minko.utils.MathUtil;
import minko.render.Texture;
import glm.Vec4;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.geometry.CubeGeometry;
import minko.geometry.Geometry;
import minko.geometry.QuadGeometry;
import minko.geometry.SphereGeometry;
import minko.material.BasicMaterial;
import minko.material.Material;
import minko.scene.Node;
class SurfaceTest extends haxe.unit.TestCase {
    var _sceneManager:SceneManager;


    override public function setup():Void {
        super.setup();
        _sceneManager = SceneManager.create(MinkoTests.canvas);

        var loader = _sceneManager.assets.loader;
        loader.options.loadAsynchronously = (false);
        loader.queue("effect/Basic.effect");
        loader.queue("effect/Phong.effect");
        loader.load();

        var redMaterial = BasicMaterial.create();
        redMaterial.diffuseColor = (new Vec4(1.0, 0.0, 0.0, 1.0));

        var greenMaterial = BasicMaterial.create();
        greenMaterial.diffuseColor = (new Vec4(0.0, 1.0, 0.0, 1.0));

        var blueMaterial = BasicMaterial.create();
        blueMaterial.diffuseColor = (new Vec4(0.0, 0.0, 1.0, 1.0));

        _sceneManager.assets
        .setGeometry("cube", CubeGeometry.create(MinkoTests.canvas.context))
        .setGeometry("sphere", SphereGeometry.create(MinkoTests.canvas.context))
        .setGeometry("quad", QuadGeometry.create(MinkoTests.canvas.context))
        .setMaterial("red", redMaterial)
        .setMaterial("green", greenMaterial)
        .setMaterial("blue", blueMaterial);
    }
    public function testCreate() {

        var s = Surface.create(Geometry.create(), Material.create(), _sceneManager.assets.effect("effect/Basic.effect"));

        assertTrue(true);

    }

    public function testSingleSurface() {
        var node = Node.create("a");

        node.addComponent(Surface.create(_sceneManager.assets.geometry("cube"), _sceneManager.assets.material("red"), _sceneManager.assets.effect("effect/Basic.effect")));

        assertEquals(node.data.get("geometry.length"), 1);
        assertEquals(node.data.get("material.length"), 1);
        assertEquals(node.data.get("effect.length"), 1);
        assertTrue(node.data.hasProperty("geometry[0].position"));
        assertEquals(node.data.get("geometry[0].position"), _sceneManager.assets.geometry("cube").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[0].uv"));
        assertEquals(node.data.get("geometry[0].uv"), _sceneManager.assets.geometry("cube").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[0].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[0].diffuseColor"), new Vec4(1.0, 0.0, 0.0, 1.0)));
    }


    public function testMultipleSurfaces() {
        var node = Node.create("a");

        node.addComponent(Surface.create(_sceneManager.assets.geometry("cube"), _sceneManager.assets.material("red"), _sceneManager.assets.effect("effect/Basic.effect")));

        node.addComponent(Surface.create(_sceneManager.assets.geometry("sphere"), _sceneManager.assets.material("green"), _sceneManager.assets.effect("effect/Basic.effect")));

        assertEquals(node.data.get("geometry.length"), 2);
        assertEquals(node.data.get("material.length"), 2);
        assertEquals(node.data.get("effect.length"), 2);
        assertTrue(node.data.hasProperty("geometry[0].position"));
        assertEquals(node.data.get("geometry[0].position"), _sceneManager.assets.geometry("cube").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[0].uv"));
        assertEquals(node.data.get("geometry[0].uv"), _sceneManager.assets.geometry("cube").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[0].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[0].diffuseColor"), new Vec4(1.0, 0.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[1].position"));
        assertEquals(node.data.get("geometry[1].position"), _sceneManager.assets.geometry("sphere").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[1].uv"));
        assertEquals(node.data.get("geometry[1].uv"), _sceneManager.assets.geometry("sphere").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[1].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[1].diffuseColor"), new Vec4(0.0, 1.0, 0.0, 1.0)));
    }


    public function testRemoveFirstSurface() {
        var node = Node.create("a");

        node.addComponent(Surface.create(_sceneManager.assets.geometry("cube"), _sceneManager.assets.material("red"), _sceneManager.assets.effect("effect/Basic.effect")));
        node.addComponent(Surface.create(_sceneManager.assets.geometry("sphere"), _sceneManager.assets.material("green"), _sceneManager.assets.effect("effect/Basic.effect")));
        node.addComponent(Surface.create(_sceneManager.assets.geometry("quad"), _sceneManager.assets.material("blue"), _sceneManager.assets.effect("effect/Basic.effect")));

        assertEquals(node.data.get("geometry.length"), 3);
        assertEquals(node.data.get("material.length"), 3);
        assertEquals(node.data.get("effect.length"), 3);
        assertTrue(node.data.hasProperty("geometry[0].position"));
        assertEquals(node.data.get("geometry[0].position"), _sceneManager.assets.geometry("cube").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[0].uv"));
        assertEquals(node.data.get("geometry[0].uv"), _sceneManager.assets.geometry("cube").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[0].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[0].diffuseColor"), new Vec4(1.0, 0.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[1].position"));
        assertEquals(node.data.get("geometry[1].position"), _sceneManager.assets.geometry("sphere").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[1].uv"));
        assertEquals(node.data.get("geometry[1].uv"), _sceneManager.assets.geometry("sphere").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[1].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[1].diffuseColor"), new Vec4(0.0, 1.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[2].position"));
        assertEquals(node.data.get("geometry[2].position"), _sceneManager.assets.geometry("quad").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[2].uv"));
        assertEquals(node.data.get("geometry[2].uv"), _sceneManager.assets.geometry("quad").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[2].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[2].diffuseColor"), new Vec4(0.0, 0.0, 1.0, 1.0)));

        node.removeComponent( node.getComponents(Surface)[0]);

        assertEquals(node.data.get("geometry.length"), 2);
        assertEquals(node.data.get("material.length"), 2);
        assertEquals(node.data.get("effect.length"), 2);
        assertTrue(node.data.hasProperty("geometry[0].position"));
        assertEquals(node.data.get("geometry[0].position"), _sceneManager.assets.geometry("sphere").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[0].uv"));
        assertEquals(node.data.get("geometry[0].uv"), _sceneManager.assets.geometry("sphere").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[0].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[0].diffuseColor"), new Vec4(0.0, 1.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[1].position"));
        assertEquals(node.data.get("geometry[1].position"), _sceneManager.assets.geometry("quad").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[1].uv"));
        assertEquals(node.data.get("geometry[1].uv"), _sceneManager.assets.geometry("quad").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[1].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[1].diffuseColor"), new Vec4(0.0, 0.0, 1.0, 1.0)));
    }


    public function testRemoveNthSurface() {
        var node = Node.create("a");

        node.addComponent(Surface.create(_sceneManager.assets.geometry("cube"), _sceneManager.assets.material("red"), _sceneManager.assets.effect("effect/Basic.effect")));
        node.addComponent(Surface.create(_sceneManager.assets.geometry("sphere"), _sceneManager.assets.material("green"), _sceneManager.assets.effect("effect/Basic.effect")));
        node.addComponent(Surface.create(_sceneManager.assets.geometry("quad"), _sceneManager.assets.material("blue"), _sceneManager.assets.effect("effect/Basic.effect")));

        assertEquals(node.data.get("geometry.length"), 3);
        assertEquals(node.data.get("material.length"), 3);
        assertEquals(node.data.get("effect.length"), 3);
        assertTrue(node.data.hasProperty("geometry[0].position"));
        assertEquals(node.data.get("geometry[0].position"), _sceneManager.assets.geometry("cube").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[0].uv"));
        assertEquals(node.data.get("geometry[0].uv"), _sceneManager.assets.geometry("cube").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[0].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[0].diffuseColor"), new Vec4(1.0, 0.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[1].position"));
        assertEquals(node.data.get("geometry[1].position"), _sceneManager.assets.geometry("sphere").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[1].uv"));
        assertEquals(node.data.get("geometry[1].uv"), _sceneManager.assets.geometry("sphere").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[1].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[1].diffuseColor"), new Vec4(0.0, 1.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[2].position"));
        assertEquals(node.data.get("geometry[2].position"), _sceneManager.assets.geometry("quad").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[2].uv"));
        assertEquals(node.data.get("geometry[2].uv"), _sceneManager.assets.geometry("quad").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[2].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[2].diffuseColor"), new Vec4(0.0, 0.0, 1.0, 1.0)));

        node.removeComponent(node.getComponents(Surface)[1]);

        assertEquals(node.data.get("geometry.length"), 2);
        assertEquals(node.data.get("material.length"), 2);
        assertEquals(node.data.get("effect.length"), 2);
        assertTrue(node.data.hasProperty("geometry[0].position"));
        assertEquals(node.data.get("geometry[0].position"), _sceneManager.assets.geometry("cube").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[0].uv"));
        assertEquals(node.data.get("geometry[0].uv"), _sceneManager.assets.geometry("cube").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[0].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[0].diffuseColor"), new Vec4(1.0, 0.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[1].position"));
        assertEquals(node.data.get("geometry[1].position"), _sceneManager.assets.geometry("quad").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[1].uv"));
        assertEquals(node.data.get("geometry[1].uv"), _sceneManager.assets.geometry("quad").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[1].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[1].diffuseColor"), new Vec4(0.0, 0.0, 1.0, 1.0)));
    }


    public function testRemoveLastSurface() {
        var node = Node.create("a");

        node.addComponent(Surface.create(_sceneManager.assets.geometry("cube"), _sceneManager.assets.material("red"), _sceneManager.assets.effect("effect/Basic.effect")));
        node.addComponent(Surface.create(_sceneManager.assets.geometry("sphere"), _sceneManager.assets.material("green"), _sceneManager.assets.effect("effect/Basic.effect")));
        node.addComponent(Surface.create(_sceneManager.assets.geometry("quad"), _sceneManager.assets.material("blue"), _sceneManager.assets.effect("effect/Basic.effect")));

        assertEquals(node.data.get("geometry.length"), 3);
        assertEquals(node.data.get("material.length"), 3);
        assertEquals(node.data.get("effect.length"), 3);
        assertTrue(node.data.hasProperty("geometry[0].position"));
        assertEquals(node.data.get("geometry[0].position"), _sceneManager.assets.geometry("cube").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[0].uv"));
        assertEquals(node.data.get("geometry[0].uv"), _sceneManager.assets.geometry("cube").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[0].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[0].diffuseColor"), new Vec4(1.0, 0.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[1].position"));
        assertEquals(node.data.get("geometry[1].position"), _sceneManager.assets.geometry("sphere").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[1].uv"));
        assertEquals(node.data.get("geometry[1].uv"), _sceneManager.assets.geometry("sphere").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[1].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[1].diffuseColor"), new Vec4(0.0, 1.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[2].position"));
        assertEquals(node.data.get("geometry[2].position"), _sceneManager.assets.geometry("quad").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[2].uv"));
        assertEquals(node.data.get("geometry[2].uv"), _sceneManager.assets.geometry("quad").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[2].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[2].diffuseColor"), new Vec4(0.0, 0.0, 1.0, 1.0)));

        node.removeComponent( node.getComponents(Surface)[2]);

        assertEquals(node.data.get("geometry.length"), 2);
        assertEquals(node.data.get("material.length"), 2);
        assertEquals(node.data.get("effect.length"), 2);
        assertTrue(node.data.hasProperty("geometry[0].position"));
        assertEquals(node.data.get("geometry[0].position"), _sceneManager.assets.geometry("cube").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[0].uv"));
        assertEquals(node.data.get("geometry[0].uv"), _sceneManager.assets.geometry("cube").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[0].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[0].diffuseColor"), new Vec4(1.0, 0.0, 0.0, 1.0)));
        assertTrue(node.data.hasProperty("geometry[1].position"));
        assertEquals(node.data.get("geometry[1].position"), _sceneManager.assets.geometry("sphere").getVertexAttribute("position"));
        assertTrue(node.data.hasProperty("geometry[1].uv"));
        assertEquals(node.data.get("geometry[1].uv"), _sceneManager.assets.geometry("sphere").getVertexAttribute("uv"));
        assertTrue(node.data.hasProperty("material[1].diffuseColor"));
        assertTrue(MathUtil.vec4_equals(node.data.get("material[1].diffuseColor"), new Vec4(0.0, 1.0, 0.0, 1.0)));
    }

    public function testSurfaceSetNewMaterialWithProgramForking() {

            var node = Node.create("a");

            var diffuseMap = Texture.create(_sceneManager.canvas.context, 32, 32);
            diffuseMap.upload();

            node.addComponent(Surface.create(_sceneManager.assets.geometry("cube"), _sceneManager.assets.material("red"), _sceneManager.assets.effect("effect/Basic.effect")));

            _sceneManager.nextFrame(0.0, 0.0);

            var newMaterial = Material.createbyMaterial(_sceneManager.assets.material("red"));
            newMaterial.data.set("diffuseMap", diffuseMap);
            var surface:Surface= cast node.getComponent(Surface);
            surface.material=(newMaterial);

            _sceneManager.nextFrame(0.0, 0.0);

            assertTrue(true);

    }


    public function testSetEffectNoTarget() {
        var surface = Surface.create(_sceneManager.assets.geometry("cube"), BasicMaterial.create(), _sceneManager.assets.effect("effect/Basic.effect"));

        surface.effect=(_sceneManager.assets.effect("effect/Phong.effect"));

        assertEquals(surface.effect, _sceneManager.assets.effect("effect/Phong.effect"));
    }


}
