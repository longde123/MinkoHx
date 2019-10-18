package tutorial;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.SpotLight;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.Loader;
import minko.geometry.QuadGeometry;
import minko.material.BasicMaterial;
import minko.scene.Node;
import minko.WebCanvas;
class WorkingSpotlights {
    public function new() {
        init();
    }

    private static var WINDOW_WIDTH = 800;
    private static var WINDOW_HEIGHT = 600;

    function init() {
        var canvas = WebCanvas.create("Minko Tutorial - Working with spot lights", WINDOW_WIDTH, WINDOW_HEIGHT);

        var sceneManager = SceneManager.create(canvas);

        sceneManager.assets.loader.queue("effect/Phong.effect");

        var root:Node= Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x7f7f7fff))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 3.0, -5.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())))
        .addComponent(PerspectiveCamera.create(WINDOW_WIDTH / WINDOW_HEIGHT, Math.PI * 0.25, .1, 1000.0));

        root.addChild(camera);

        var ground = Node.create("ground");

        var spotLight = Node.create("spotLight")
        .addComponent(SpotLight.create(.15, .4))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(.1, 2.0, 0.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())));

        var spotLightSpotLight:SpotLight =cast spotLight.getComponent(SpotLight);
        spotLightSpotLight.diffuse = (0.5);

        root.addChild(spotLight);

        var complete = sceneManager.assets.loader.complete.connect(function(loader:Loader) {
            var basicMaterial:BasicMaterial = BasicMaterial.create();
            basicMaterial.diffuseColor = (new Vec4(1.0, .7, .7, 1.0));
            ground.addComponent(Surface.create(QuadGeometry.create(sceneManager.assets.context), basicMaterial, sceneManager.assets.effect("effect/Phong.effect")))
            .addComponent(Transform.createbyMatrix4(GLM.scale(new Vec3(4.0, 4.0, 4.0), new Mat4()) * GLM.rotate(Quat.axisAngle(new Vec3(1.0, 0.0, 0.0), (-Math.PI / 2), new Quat()), new Mat4())));

            root.addChild(ground);
        });

        sceneManager.assets.loader.load();

        var enterFrame = canvas.enterFrame.connect(function(canvas, t, dt) {
            sceneManager.nextFrame(t, dt);
        });

        canvas.run();

    }

}
