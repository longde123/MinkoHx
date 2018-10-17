package example;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import minko.AbstractCanvas;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.Loader;
import minko.geometry.CubeGeometry;
import minko.geometry.Geometry;
import minko.material.BasicMaterial;
import minko.render.Effect;
import minko.scene.Node;
import minko.utils.MathUtil;
import minko.WebCanvas;
class ExampleBenchmarkCube {
    public function new() {
        init();
    }

    private function createRandomCube(root:Node, geom:Geometry, effect:Effect) {
        var node = Node.create();
        var r = MathUtil.sphericalRand(1.0);
        var material = BasicMaterial.create();

        material.diffuseColor = (MathUtil.vec3_vec4((r + 1.0) * .5, 1.0));

        node.addComponent(Transform.createbyMatrix4(GLM.translate(r * 50.0, new Mat4()) * GLM.scale(new Vec3(.2, .2, .2), new Mat4())));
        node.addComponent(Surface.create(geom, material, effect));

        root.addChild(node);
    }

    public function init():Void {


        var canvas = WebCanvas.create("Minko Example - Benchmark Cube");
        var sceneManager = SceneManager.create(canvas);
        var root = Node.create("root").addComponent(sceneManager);

        sceneManager.assets.loader.queue("effect/Basic.effect");
        sceneManager.assets.setGeometry("cube", CubeGeometry.create(sceneManager.assets.context));

        var mesh = Node.create("mesh");

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x7f7f7fff))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 0.0, 150.0), new Vec3(0.0), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())))
        .addComponent(PerspectiveCamera.create(canvas.aspectRatio));

        var meshes = Node.create();

        root.addChild(camera);
        root.addChild(meshes);

        var numFrames = 0;
        var t = 0;
        var p = 0;
        var ready = false;

        var loaderComplete = sceneManager.assets.loader.complete.connect(function(loader:Loader) {
            ready = true;
        });

        var enterFrame = canvas.enterFrame.connect(function(canvas:AbstractCanvas, time, deltaTime) {
            var cameraTransform:Transform = cast camera.getComponent(Transform);
            cameraTransform.matrix = (GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), 0.01, new Quat()), new Mat4()) * cameraTransform.matrix);

            if (!ready) {
                return;
            }

            if (canvas.framerate > 30.0) {
                t++;
            }
            else {
                p++;
            }

            if (t > 10) {
                t = 0;
                p = 0;

                for (i in 0...10) {
                    createRandomCube(meshes, sceneManager.assets.geometry("cube"), sceneManager.assets.effect("effect/Basic.effect"));
                }
            }

            if (p > 10 ){
                while(meshes.children.length > 100) {
                    var node:Node=meshes.children[0];
                    meshes.removeChild(node);
                    node.dispose();
                    node=null;
                }
                t = 0;
                p = 0;
            }

            if (++numFrames % 100 == 0) {
                var renderer:Renderer = cast camera.getComponent(Renderer);
                trace("num meshes = ");
                trace(meshes.children.length);
                trace(", num draw calls = ");
                trace(renderer.numDrawCalls);
                trace(", framerate = ");
                trace(canvas.framerate);
                trace("\n");
            }

            sceneManager.nextFrame(time, deltaTime);
        });

        var resized = canvas.resized.connect(function(canvas, w, h) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (w / h);
        });

        sceneManager.assets.loader.load();
        canvas.run();

    }

}
