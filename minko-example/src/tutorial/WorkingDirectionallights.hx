package tutorial;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import minko.component.AmbientLight;
import minko.component.DirectionalLight;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.geometry.SphereGeometry;
import minko.material.PhongMaterial;
import minko.scene.Node;
import minko.WebCanvas;
class WorkingDirectionallights {
    public function new() {
        init();
    }
    private static var WINDOW_WIDTH = 800;
    private static var WINDOW_HEIGHT = 600;

    function init() {
        var canvas = WebCanvas.create("Minko Tutorial - Working with directional lights", WINDOW_WIDTH, WINDOW_HEIGHT);

        var sceneManager = SceneManager.create(canvas);


        sceneManager.assets.loader.queue("effect/Phong.effect");

        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x00000000))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 2, 2.3), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())))
        .addComponent(PerspectiveCamera.create(WINDOW_WIDTH / WINDOW_HEIGHT, Math.PI * 0.25, .1, 1000.0));


        var directionalLight = Node.create("directionalLight")
        .addComponent(DirectionalLight.create())
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(3.0, 2.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())));
        var directionalLightDirectionalLight:DirectionalLight = cast directionalLight.getComponent(DirectionalLight);
        directionalLightDirectionalLight.diffuse = (.8);
        directionalLightDirectionalLight.color = (new Vec3(.7, 1.0, 0.7));

        var ambientLight = Node.create("ambientLight").addComponent(AmbientLight.create(.25));


        var ambientLightAmbientLight:AmbientLight = cast ambientLight.getComponent(AmbientLight);
        ambientLightAmbientLight.color = (new Vec3(1.0, .7, .7));

        root.addChild(directionalLight);
        root.addChild(ambientLight);
        root.addChild(camera);

        var sphere = Node.create("sphere");

        var complete = sceneManager.assets.loader.complete.connect(function(loader) {
            var phongMaterial = PhongMaterial.create();

            phongMaterial.diffuseColorRGBA(0xff0000ff);
            phongMaterial.specularColorRGBA(0xffffffff);
            phongMaterial.shininess = (16.0);

            sphere.addComponent(Transform.create());
            sphere.addComponent(Surface.create(SphereGeometry.create(sceneManager.assets.context, 20), phongMaterial, sceneManager.assets.effect("effect/Phong.effect")));
            root.addChild(sphere);

        });

        sceneManager.assets.loader.load();

        var enterFrame = canvas.enterFrame.connect(function(canvas, t, dt) {
            sceneManager.nextFrame(t, dt);
        });

        canvas.run();

    }

}
