package tutorial;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import minko.component.AmbientLight;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.PNGParser;
import minko.geometry.CubeGeometry;
import minko.material.PhongMaterial;
import minko.scene.Node;
import minko.WebCanvas;
class WorkingAmbientlights {
    public function new() {
        init();
    }

    private static var MYTEXTURE = "texture/box.png";
    private static var WINDOW_WIDTH = 800;
    private static var WINDOW_HEIGHT = 600;

    function init() {
        var canvas = WebCanvas.create("Minko Tutorial - Working with ambient  lights", WINDOW_WIDTH, WINDOW_HEIGHT);

        var sceneManager = SceneManager.create(canvas);

        sceneManager.assets.loader.options.registerParser("png", function() return new PNGParser());

        sceneManager.assets.loader.queue(MYTEXTURE).queue("effect/Phong.effect");

        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x00000000))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 1.5, 2.3), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())))
        .addComponent(PerspectiveCamera.create(WINDOW_WIDTH / WINDOW_HEIGHT, Math.PI * 0.25, .1, 1000.0));


        var ambientLight = Node.create("ambientLight").addComponent(AmbientLight.create(.5));

        var ambientLightAmbientLight:AmbientLight = cast ambientLight.getComponent(AmbientLight);
        ambientLightAmbientLight.color = new Vec3(1.0, 0.7, 0.7);


        root.addChild(ambientLight);
        root.addChild(camera);

        var cube = Node.create("cube");

        var complete = sceneManager.assets.loader.complete.connect(function(loader) {
            cube.addComponent(Transform.create());
            var phongMaterial:PhongMaterial = PhongMaterial.create();
            phongMaterial.diffuseMap = (sceneManager.assets.texture(MYTEXTURE));
            cube.addComponent(Surface.create(CubeGeometry.create(sceneManager.assets.context), phongMaterial, sceneManager.assets.effect("effect/Phong.effect")));
            root.addChild(cube);

        });

        sceneManager.assets.loader.load();

        var enterFrame = canvas.enterFrame.connect(function(canvas, t, dt) {
            var transform:Transform = cast cube.getComponent(Transform);
            transform.matrix = transform.matrix * GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), .01, new Quat()), new Mat4());

            sceneManager.nextFrame(t, dt);
        });

        canvas.run();

    }

}
