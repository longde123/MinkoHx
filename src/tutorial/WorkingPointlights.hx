package tutorial;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import minko.component.PerspectiveCamera;
import minko.component.PointLight;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.geometry.QuadGeometry;
import minko.material.BasicMaterial;
import minko.scene.Node;
import minko.WebCanvas;
class WorkingPointlights {
    public function new() {
        init();
    }
    private static var WINDOW_WIDTH = 800;
    private static var WINDOW_HEIGHT = 600;

    function init() {
        var canvas = WebCanvas.create("Minko Tutorial - Working with point lights", WINDOW_WIDTH, WINDOW_HEIGHT);

        var sceneManager = SceneManager.create(canvas);


        sceneManager.assets.loader.queue("effect/Phong.effect");

        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x7f7f7fff))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 1.5, 2.3), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())))
        .addComponent(PerspectiveCamera.create(WINDOW_WIDTH / WINDOW_HEIGHT, Math.PI * 0.25, .1, 1000.0));


        root.addChild(camera);

        var ground = Node.create("ground");
        var leftWall = Node.create("leftWall");
        var rightWall = Node.create("rightWall");
        var backWall = Node.create("backWall");
        var pointLight = Node.create("pointLight");

        var complete = sceneManager.assets.loader.complete.connect(function(loader) {
            var groundBasicMaterial:BasicMaterial = BasicMaterial.create();
            groundBasicMaterial.diffuseColor = (new Vec4(1.0, .5, .5, 1.0));
            ground.addComponent(Surface.create(QuadGeometry.create(sceneManager.assets.context), groundBasicMaterial, sceneManager.assets.effect("effect/Phong.effect")))
            .addComponent(Transform.createbyMatrix4(
                GLM.scale(new Vec3(4.0, 4.0, 4.0), new Mat4()) * GLM.rotate(Quat.axisAngle(new Vec3(1.0, 0.0, 0.0), (-Math.PI / 2), new Quat()), new Mat4())
            ));

            var leftWallBasicMaterial:BasicMaterial = BasicMaterial.create();
            leftWallBasicMaterial.diffuseColor = (new Vec4(.5, .5, .5, 1.0));

            leftWall.addComponent(Surface.create(QuadGeometry.create(sceneManager.assets.context), leftWallBasicMaterial, sceneManager.assets.effect("effect/Phong.effect")))
            .addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4()) *
            GLM.scale(new Vec3(4.0, 4.0, 4.0), new Mat4()) *
            GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), (Math.PI / 2), new Quat()), new Mat4())
            ));
            var rightWallBasicMaterial:BasicMaterial = BasicMaterial.create();
            rightWallBasicMaterial.diffuseColor = (new Vec4(.5, .5, .5, 1.0));
            rightWall.addComponent(Surface.create(QuadGeometry.create(sceneManager.assets.context), rightWallBasicMaterial, sceneManager.assets.effect("effect/Phong.effect")))
            .addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.0, 0.0, 0.0), new Mat4()) *
            GLM.scale(new Vec3(4.0, 4.0, 4.0), new Mat4()) *
            GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), (-Math.PI / 2), new Quat()), new Mat4())
            ));
            var backWallBasicMaterial:BasicMaterial = BasicMaterial.create();
            backWallBasicMaterial.diffuseColor = (new Vec4(.5, .5, .5, 1.0));
            backWall.addComponent(Surface.create(QuadGeometry.create(sceneManager.assets.context), backWallBasicMaterial, sceneManager.assets.effect("effect/Phong.effect")))
            .addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(0.0, 0.0, -1.0), new Mat4()) * GLM.scale(new Vec3(4.0, 4.0, 4.0), new Mat4())));

            pointLight.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-.5, 0.3, 0.0), new Mat4())));
            var pointLightPointLight:PointLight = PointLight.create();
            pointLightPointLight.diffuse = (0.8);
            pointLightPointLight.color = (new Vec3(0.5, 0.5, 1.0));
            pointLight.addComponent(pointLightPointLight);

            root.addChild(ground);
            root.addChild(leftWall);
            root.addChild(rightWall);
            root.addChild(backWall);

            root.addChild(pointLight);
        });

        sceneManager.assets.loader.load();

        var enterFrame = canvas.enterFrame.connect(function(canvas, t, dt) {
            sceneManager.nextFrame(t, dt);
        });

        canvas.run();

    }

}
