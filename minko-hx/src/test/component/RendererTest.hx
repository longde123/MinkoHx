package test.component;
import glm.Vec4;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.geometry.CubeGeometry;
import minko.material.BasicMaterial;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
class RendererTest extends haxe.unit.TestCase {

    private function testCreate() {
        Renderer.create();
        assertTrue(true);
    }

    private function testAddAndRemoveSurfaces() {
        var fx = MinkoTests.loadEffect("effect/Basic.effect");
        var renderer = Renderer.create();
        var root = Node.create()
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(renderer);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var s1 = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        var s2 = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        var s3 = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        root.addComponent(s1);
        root.addComponent(s2);
        root.addComponent(s3);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 3);

        root.removeComponent(s1);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 2);

        root.removeComponent(s2);
        root.removeComponent(s3);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 0);
    }


    private function testAddAndRemoveSurfaceBubbleUp() {
        var fx = MinkoTests.loadEffect("effect/Basic.effect");
        var renderer = Renderer.create();
        var root = Node.create("root")
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(renderer);

        var surfaceNode = Node.create("surfaceNode");
        root.addChild(surfaceNode);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var s1 = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        surfaceNode.addComponent(s1);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 1);

        surfaceNode.removeComponent(s1);
        surfaceNode.addComponent(s1);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 1);
    }


    private function testOneSurfaceLayoutMaskFail() {
        var fx = MinkoTests.loadEffect("effect/Basic.effect");
        var renderer = Renderer.create();
        var root = Node.create()
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(renderer);

        var surfaceNode = Node.create();
        root.addChild(surfaceNode);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var surface = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        surface.layoutMask = (BuiltinLayout.DEBUG_ONLY);
        surfaceNode.addComponent(surface);

        renderer.render(MinkoTests.canvas.context);

        assertEquals(renderer.numDrawCalls, 0);
    }

    private function testOneSurfaceLayoutMaskPass() {
        var fx = MinkoTests.loadEffect("effect/Basic.effect");
        var renderer = Renderer.create();
        var root = Node.create()
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(renderer);

        var surfaceNode = Node.create();
        root.addChild(surfaceNode);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var surface = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        surface.layoutMask = (BuiltinLayout.DEFAULT);
        surfaceNode.addComponent(surface);

        renderer.render(MinkoTests.canvas.context);

        assertEquals(renderer.numDrawCalls, 1);
    }

    private function testDeferredPassDrawCallCount() {
        var fx = MinkoTests.loadEffect("effect/deferred/OneForwardPassOneDeferredPass.effect");
        var renderer = Renderer.create();
        var root = Node.create()
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(renderer);


        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));


        var s1 = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        var s2 = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        var s3 = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        root.addComponent(s1);
        root.addComponent(s2);
        root.addComponent(s3);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 4);
        root.removeComponent(s1);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 3);
        root.removeComponent(s2);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 2);
        root.removeComponent(s3);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 0);
    }

    private function testRendererLayoutMaskChanged() {
        var fx = MinkoTests.loadEffect("effect/Basic.effect");
        var renderer = Renderer.create();
        var root = Node.create()
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(renderer);


        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));


        var s = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material, fx);

        root.addComponent(s);
        renderer.render(MinkoTests.canvas.context);
        assertEquals(renderer.numDrawCalls, 1);

        renderer.layoutMask=(0);

        renderer.render(MinkoTests.canvas.context);

        assertEquals(renderer.numDrawCalls, 0);
    }

    private function testPriority() {
        var renderer1 = Renderer.create(0, null, null, "default", 2.0);
        var renderer2 = Renderer.create(0, null, null, "default", 1.0);
        var renderer3 = Renderer.create(0, null, null, "default", 0.0);
        var sceneManager = SceneManager.create(MinkoTests.canvas);
        var root = Node.create()
        .addComponent(sceneManager)
        .addComponent(renderer3)
        .addComponent(renderer1)
        .addComponent(renderer2);

        var i = 0;

        var _ = renderer1.renderingBegin.connect(function(r:Renderer) {
            assertEquals(i, 0);
            i++;
        });

        var __ = renderer2.renderingBegin.connect(function(r:Renderer) {
            assertEquals(i, 1);
            i++;
        });

        var ___ = renderer3.renderingBegin.connect(function(r:Renderer) {
            assertEquals(i, 2);
            i++;
        });

        sceneManager.nextFrame(0.0, 0.0);

        assertEquals(i, 3);
    }

    private function testSetEffect() {
        var basic = MinkoTests.loadEffect("effect/Basic.effect");
        var phong = MinkoTests.loadEffect("effect/Phong.effect");
        var renderer = Renderer.create(0, null, basic);
        var sceneManager = SceneManager.create(MinkoTests.canvas);
        var root = Node.create().addComponent(sceneManager).addComponent(PerspectiveCamera.create(1.0)).addComponent(renderer);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var s = Surface.create(CubeGeometry.create(MinkoTests.canvas.context), material);

        root.addComponent(s);

        sceneManager.nextFrame(0.0, 0.0);
        for (sortPropertiesToDrawCalls in renderer.drawCallPool.drawCalls) {

            for (drawCall in sortPropertiesToDrawCalls.first) {
                assertEquals(drawCall.pass, basic.technique("default")[0]);
            }
            for (drawCall in sortPropertiesToDrawCalls.second) {
                assertEquals(drawCall.pass, basic.technique("default")[0]);
            }
        }

        renderer.effect = (phong);
        sceneManager.nextFrame(0.0, 0.0);

        for (sortPropertiesToDrawCalls in renderer.drawCallPool.drawCalls) {

            for (drawCall in sortPropertiesToDrawCalls.first) {
                assertEquals(drawCall.pass, phong.technique("default")[0]);
            }
            for (drawCall in sortPropertiesToDrawCalls.second) {
                assertEquals(drawCall.pass, phong.technique("default")[0]);
            }

        }
    }
}
