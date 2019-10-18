package example;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import minko.component.PerspectiveCamera;
import minko.component.Picking;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.Loader;
import minko.file.PNGParser;
import minko.geometry.CubeGeometry;
import minko.geometry.QuadGeometry;
import minko.geometry.SphereGeometry;
import minko.material.BasicMaterial;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
import minko.signal.Signal.SignalSlot;
import minko.WebCanvas;
class ExamplePicking {
    public function new() {
        init();
    }

    private var pickingMouseClick:SignalSlot<Node>;
    private var pickingMouseRightClick:SignalSlot<Node>;
    private var pickingMouseOver:SignalSlot<Node>;
    private var pickingMouseOut:SignalSlot<Node>;

    function init() {
        var canvas = WebCanvas.create("Minko Example - Picking", 800, 600);

        var sceneManager = SceneManager.create(canvas);

        // Setup assets
        sceneManager.assets.loader.options.resizeSmoothly = (true);
        sceneManager.assets.loader.options.generateMipmaps = (true);
        sceneManager.assets.loader.options.registerParser("png", function() return new PNGParser());

        sceneManager.assets.loader
        .queue("effect/Basic.effect")
        .queue("effect/Picking.effect");

        var redMaterial:BasicMaterial = BasicMaterial.create();
        redMaterial.diffuseColorRGBA(0xFF0000FF);

        var greenMaterial = BasicMaterial.create();
        greenMaterial.diffuseColorRGBA(0xF0FF00FF);

        var blueMaterial = BasicMaterial.create();
        blueMaterial.diffuseColorRGBA(0x0000FFFF);

        sceneManager.assets.setMaterial("redMaterial", redMaterial)
        .setMaterial("greenMaterial", greenMaterial)
        .setMaterial("blueMaterial", blueMaterial)
        .setGeometry("cube", CubeGeometry.create(sceneManager.assets.context))
        .setGeometry("sphere", SphereGeometry.create(sceneManager.assets.context))
        .setGeometry("quad", QuadGeometry.create(sceneManager.assets.context));

        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 0.0, 4.0), new Vec3(0.0), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())))
        .addComponent(PerspectiveCamera.create(canvas.aspectRatio));

        root.addChild(camera);

        var _ = sceneManager.assets.loader.complete.connect(function(loader:Loader) {
            var cube = Node.createbyLayout("cubeNode", BuiltinLayout.DEFAULT | BuiltinLayout.PICKING)
            .addComponent(Surface.create(sceneManager.assets.geometry("cube"), sceneManager.assets.material("redMaterial"), sceneManager.assets.effect("effect/Basic.effect")))
            .addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.4, 0.0, 0.0) , new Mat4()))) ;

            var sphere = Node.createbyLayout("sphereNode", BuiltinLayout.DEFAULT | BuiltinLayout.PICKING)
            .addComponent(Surface.create(sceneManager.assets.geometry("sphere"), sceneManager.assets.material("greenMaterial"), sceneManager.assets.effect("effect/Basic.effect")))
            .addComponent(Transform.create()) ;

            var quad = Node.createbyLayout("quadNode", BuiltinLayout.DEFAULT | BuiltinLayout.PICKING)
            .addComponent(Surface.create(sceneManager.assets.geometry("quad"), sceneManager.assets.material("blueMaterial"), sceneManager.assets.effect("effect/Basic.effect")))
            .addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.4, 0.0, 0.0), new Mat4()))) ;

            root.addChild(cube).addChild(sphere).addChild(quad);

            root.addComponent(Picking.create(camera, false, true));

            var picking:Picking = cast root.getComponent(Picking);
            pickingMouseClick = picking.mouseClick.connect(function(node:Node) {
                trace("Click: ");
                trace(node.name);
                trace("\n");
            });

            pickingMouseRightClick = picking.mouseRightClick.connect(function(node:Node) {
                trace("Right Click: ");
                trace(node.name);
                trace("\n");
            });

            pickingMouseOver = picking.mouseOver.connect(function(node:Node) {
                trace("Mouse In: ");
                trace(node.name);
                trace("\n");
            });

            pickingMouseOut = picking.mouseOut.connect(function(node:Node) {
                trace("Mouse Out: ");
                trace(node.name);
                trace("\n");
            });
        });

        camera.addComponent(Renderer.create(0x7f7f7fff));

        var resized = canvas.resized.connect(function(canvas, w, h) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (w / h);
        });

        var enterFrame = canvas.enterFrame.connect(function(canvas, time, deltaTime) {
            sceneManager.nextFrame(time, deltaTime);
        });

        sceneManager.assets.loader.load();
        canvas.run();
    }

}
