package tutorial;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.component.AmbientLight;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.SpotLight;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.JPEGParser;
import minko.geometry.SphereGeometry;
import minko.material.PhongMaterial;
import minko.scene.Node;
import minko.WebCanvas;
class WorkingPhongMaterial {


    private static var WINDOW_WIDTH = 800;
    private static var WINDOW_HEIGHT = 600;

    private static var MYTEXTURE = "texture/diffuseMap.jpg";

    public function new() {
        var canvas = WebCanvas.create("Minko Tutorial - Working with the PhongMaterial", WINDOW_WIDTH, WINDOW_HEIGHT);
        var sceneManager = SceneManager.create(canvas);

        sceneManager.assets.loader.options.registerParser("jpg", function() return new JPEGParser());

        sceneManager.assets.loader.queue("effect/Phong.effect")
        .queue(MYTEXTURE);

        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x00000000))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 1.0, 1.3), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())))
        .addComponent(PerspectiveCamera.create(WINDOW_WIDTH / WINDOW_HEIGHT, Math.PI * 0.25, .1, 1000.0));

        var spotLight = Node.create("spotLight")
        .addComponent(SpotLight.create(.6, .78, 20.0))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(3.0, 5.0, 1.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())));
        var s1:SpotLight = cast spotLight.getComponent(SpotLight);
        s1.diffuse = (0.5);

        var ambientLight = Node.create("ambientLight").addComponent(AmbientLight.create(.2));
        var a1:AmbientLight = cast ambientLight.getComponent(AmbientLight);
        a1.color = (new Vec3(1.0, 1.0, 1.0));

        root.addChild(ambientLight);
        root.addChild(spotLight);
        root.addChild(camera);

        var complete = sceneManager.assets.loader.complete.connect(function(loader) {
            var phongMaterial = PhongMaterial.create();

            phongMaterial.diffuseMap = (sceneManager.assets.texture(MYTEXTURE));
            phongMaterial.specularColor = (new Vec4(.4, .8, 1.0, 1.0));
            phongMaterial.shininess = (2.0);

            var mesh = Node.create("mesh")
            .addComponent(Transform.createbyMatrix4(GLM.scale(new Vec3(1.1, 1.1, 1.1), new Mat4())))
            .addComponent(Surface.create(SphereGeometry.create(sceneManager.assets.context, 20), phongMaterial, sceneManager.assets.effect("effect/Phong.effect")));

            root.addChild(mesh);
        });

        sceneManager.assets.loader.load();

        var enterFrame = canvas.enterFrame.connect(function(canvas, t, dt) {
            sceneManager.nextFrame(t, dt);
        });

        canvas.run();

    }

}
