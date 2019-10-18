package tutorial;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.Loader;
import minko.geometry.CubeGeometry;
import minko.geometry.QuadGeometry;
import minko.input.Keyboard;
import minko.material.BasicMaterial;
import minko.render.Effect;
import minko.render.Texture;
import minko.scene.Node;
import minko.utils.MathUtil;
import minko.WebCanvas;
class ApplyingAntialiasingEffect {
    public function new() {
        init();
    }


    private static var WINDOW_WIDTH = 800;
    private static var WINDOW_HEIGHT = 600;

    function init() {
        var canvas = WebCanvas.create("Minko Tutorial - Applying antialiasing effect", WINDOW_WIDTH, WINDOW_HEIGHT);
        var sceneManager = SceneManager.create(canvas);

        sceneManager.assets.loader
        .queue("effect/Basic.effect")
        .queue("effect/FXAA/FXAA.effect");


        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x00000000))
        .addComponent(PerspectiveCamera.create(canvas.aspectRatio))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 0.0, -5.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())));
        root.addChild(camera);

        var renderTarget = Texture.create(canvas.context, MathUtil.clp2(WINDOW_WIDTH), MathUtil.clp2(WINDOW_HEIGHT), false, true);
        renderTarget.upload();

        var ppMaterial = BasicMaterial.create();
        ppMaterial.diffuseMap = (renderTarget);

        var effect:Effect = new Effect();

        var enableFXAA = true;

        var cube = Node.create("cube");

        var renderer = Renderer.create();

        var postProcessingScene = Node.create();

        var complete = sceneManager.assets.loader.complete.connect(function(loader:Loader) {
            trace("Enable FXAA");
            var material = BasicMaterial.create();
            material.diffuseColor = (new Vec4(0.0, 0.0, 1.0, 1.0));

            cube.addComponent(Transform.create());
            cube.addComponent(Surface.create(CubeGeometry.create(canvas.context), material, sceneManager.assets.effect("effect/Basic.effect")));

            root.addChild(cube);

            effect = sceneManager.assets.effect("effect/FXAA/FXAA.effect");

            if (effect == null) {
                throw ("The FXAA effect has not been loaded.");
            }

            effect.data.set("textureSampler", renderTarget);
            effect.data.set("resolution", new Vec2(WINDOW_WIDTH, WINDOW_HEIGHT));
            effect.data.set("invertedDiffuseMapSize", new Vec2(1.0 / renderTarget.width, 1. / renderTarget.height));

            postProcessingScene.addComponent(renderer);
            postProcessingScene.addComponent(Surface.create(QuadGeometry.create(sceneManager.assets.context), ppMaterial, effect));


        var keyDown = canvas.keyboard.keyDown.connect(function(k:Keyboard) {
            if (k.keyIsDown(Key.SPACE)) {
                enableFXAA = !enableFXAA;

                if (enableFXAA) {
                    trace("Enable FXAA");
                    trace("\n");
                }
                else {
                    trace("Disable FXAA");
                    trace("\n");
                }
            }
        });

        var resized = canvas.resized.connect(function(canvas, width, height) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (width / height);

            renderTarget = Texture.create(sceneManager.assets.context, MathUtil.clp2(width), MathUtil.clp2(height), false, true);
            renderTarget.upload();

            ppMaterial.diffuseMap = (renderTarget);
            effect.data.set("textureSampler", renderTarget);
            effect.data.set("resolution", new Vec2(WINDOW_WIDTH, WINDOW_HEIGHT));
            effect.data.set("invertedDiffuseMapSize", new Vec2(1.0 / renderTarget.width, 1.0 / renderTarget.height));

        });

        var enterFrame = canvas.enterFrame.connect(function(canvas, t, dt) {
            var cubeTransform:Transform = cast cube.getComponent(Transform);
            cubeTransform.matrix = (cubeTransform.matrix * GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), .01, new Quat()), new Mat4()));

            if (enableFXAA) {
                sceneManager.nextFrame(t, dt, renderTarget);
                renderer.render(sceneManager.assets.context);
            }
            else {
                sceneManager.nextFrame(t, dt);
            }
        });
        });
        sceneManager.assets.loader.load();

        canvas.run();

    }
}
