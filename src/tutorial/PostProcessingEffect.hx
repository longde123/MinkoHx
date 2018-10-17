package tutorial;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.geometry.CubeGeometry;
import minko.geometry.QuadGeometry;
import minko.material.BasicMaterial;
import minko.material.Material;
import minko.render.Effect;
import minko.render.Texture;
import minko.scene.Node;
import minko.utils.MathUtil;
import minko.WebCanvas;
class PostProcessingEffect {
    public function new() {
        init();
    }

    private static var WINDOW_WIDTH = 800;
    private static var WINDOW_HEIGHT = 600;

    function init() {
        var canvas = WebCanvas.create("Minko Tutorial - Creating a simple post-processing effect", WINDOW_WIDTH, WINDOW_HEIGHT);
        var sceneManager = SceneManager.create(canvas);

        sceneManager.assets.loader
        .queue("effect/Basic.effect")
        .queue("effect/Desaturate.effect");

        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x7f7f7fff))
        .addComponent(PerspectiveCamera.create(canvas.aspectRatio))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())));

        root.addChild(camera);

        var cube = Node.create("cube");

        var ppFx:Effect = new Effect();
        var ppRenderer = Renderer.create();
        var ppTarget = Texture.create(sceneManager.assets.context, MathUtil.clp2(WINDOW_WIDTH), MathUtil.clp2(WINDOW_HEIGHT), false, true);
        ppTarget.upload();

        var complete = sceneManager.assets.loader.complete.connect(function(loader) {
            var basicMaterial:BasicMaterial = BasicMaterial.create();
            basicMaterial.diffuseColor = new Vec4(0.0, 0.0, 1.0, 1.0);
            cube.addComponent(Transform.create())
            .addComponent(Surface.create(CubeGeometry.create(sceneManager.assets.context), basicMaterial, sceneManager.assets.effect("effect/Basic.effect")));

            root.addChild(cube);

            ppFx = sceneManager.assets.effect("effect/Desaturate.effect");

            if (ppFx == null) {
                throw ("The post-processing effect has not been loaded.");
            }

            ppFx.data.set("backBuffer", ppTarget);

            var ppScene = Node.create().addComponent(ppRenderer)
            .addComponent(Surface.create(QuadGeometry.create(sceneManager.assets.context), Material.create(), ppFx));
        });
/*
        var resized = canvas.resized.connect(function(canvas, width, height) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (width / height);

            ppTarget = Texture.create(sceneManager.assets.context, MathUtil.clp2(width), MathUtil.clp2(height), false, true);
            ppTarget.upload();
            ppFx.data.set("backBuffer", ppTarget);
        });
*/
        var enterFrame = canvas.enterFrame.connect(function(canvas, t, dt) {
            var transform:Transform = cast cube.getComponent(Transform);
            transform.matrix = (transform.matrix * GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), 0.1, new Quat()), new Mat4()));

            sceneManager.nextFrame(t, dt, ppTarget);
            ppRenderer.render(sceneManager.assets.context);
        });

        sceneManager.assets.loader.load();

        canvas.run();

    }

}
