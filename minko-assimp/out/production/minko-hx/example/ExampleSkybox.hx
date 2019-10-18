package example;
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
import minko.file.JPEGParser;
import minko.file.Loader;
import minko.geometry.CubeGeometry;
import minko.geometry.Geometry;
import minko.geometry.SphereGeometry;
import minko.input.Mouse;
import minko.material.BasicMaterial;
import minko.material.Material;
import minko.render.Effect;
import minko.render.TriangleCulling;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
import minko.utils.RandomNumbers;
import minko.WebCanvas;
class ExampleSkybox {
    private static var SKYBOX_TEXTURE = "texture/cloudySea-diffuse.jpg";
    private static var NUM_OBJECTS = 15;

    public function new() {
        init();
    }

    private function createTransparentObject(scale, rotationY, geom:Geometry, fx:Effect) {
        // Debug.Assert(NUM_OBJECTS > 0);

        var randomAxis = Vec3.normalize(new Vec3( RandomNumbers.nextNumber(), RandomNumbers.nextNumber(), RandomNumbers.nextNumber()), new Vec3());
        var randomAng = 2.0 * Math.PI * RandomNumbers.nextNumber() ;
        var rotateQuat = Quat.axisAngle(randomAxis, randomAng, new Quat());
        var m = Mat4.identity(new Mat4());
        m = GLM.rotate(rotateQuat, new Mat4()) * m;
        m = GLM.translate(new Vec3(1.0, 0.0, 0.0), Mat4.identity(new Mat4())) * m;
        m = GLM.scale(new Vec3(scale,scale,scale), Mat4.identity(new Mat4())) * m;
        var rotateYQuat = Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), rotationY, new Quat());
        m = GLM.rotate(rotateYQuat, new Mat4()) * m;
        var basicMaterial:BasicMaterial = BasicMaterial.create();
        basicMaterial.diffuseColor = (new Vec4(rotationY / (2.0 * Math.PI) * 360, 1.0, 0.5, 0.5));
        basicMaterial.triangleCulling = (TriangleCulling.BACK);
        return Node.create()
        .addComponent(Transform.createbyMatrix4(m))
        .addComponent(Surface.create(geom, basicMaterial, fx));
    }

    function init() {
        var canvas = WebCanvas.create("Minko Example - Skybox");
        var sceneManager = SceneManager.create(canvas);
        var loader = sceneManager.assets.loader;
        loader.options.loadAsynchronously=false;
        loader.options.resizeSmoothly = (true);
        loader.options.generateMipmaps = (true);
        loader.options.registerParser("jpg", function()return new JPEGParser());

        loader.queue(SKYBOX_TEXTURE)
        .queue("effect/Basic.effect")
        .queue("effect/Skybox/Skybox.effect");

        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x7f7f7fff))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(), new Vec3(0, 0, 3), new Vec3(0, 1, 0),  Mat4.identity(new Mat4())),  Mat4.identity(new Mat4()))))
        .addComponent(PerspectiveCamera.create(canvas.aspectRatio));

        var sky = Node.create("sky")
        .addComponent(Transform.createbyMatrix4(GLM.scale(new Vec3(100.0, 100.0, 100.0), new Mat4()) * Mat4.identity(new Mat4())));

       var objects = Node.create("objects").addComponent(Transform.create());
        var _ = sceneManager.assets.loader.complete.connect(function(loader:Loader) {
            var assets = sceneManager.assets;

            sky.addComponent(Surface.create(SphereGeometry.create(assets.context, 16, 16), Material.create().setbyKeyObject(
                {
                    "diffuseLatLongMap": assets.texture(SKYBOX_TEXTURE)
                }), assets.effect("effect/Skybox/Skybox.effect")));

trace("NUM_OBJECTS > 0",NUM_OBJECTS);

            var scale = 1.25 * Math.PI / NUM_OBJECTS;
            var dAngle = 2.0 * Math.PI / NUM_OBJECTS;

           var cubeGeom = CubeGeometry.create(sceneManager.assets.context);
            for (objId in 0...NUM_OBJECTS) {
                objects.addChild(createTransparentObject(scale, objId * dAngle, cubeGeom, assets.effect("effect/Basic.effect")));
            }

            root.addChild(camera)
            .addChild(sky)
            .addChild(objects);
        });

        var resized = canvas.resized.connect(function(canvas, w, h) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (w / h);
        });

        var yaw = 0.0;
        var pitch = Math.PI * .5;
        var minPitch = 0.1;
        var maxPitch = Math.PI - .1;
        var lookAt = new Vec3(0.0, 0.0, 0.0);
        var distance = 4.0;
        var mouse_=canvas.mouse;
        var mouse_wheel=canvas.mouse.wheel;
        var mouseWheel = mouse_wheel.connect(function(m, h, v) {
            distance += v / 10.0 ;
        });
        var mouseMove:SignalSlot3<Mouse, Int, Int> = null;
        var cameraRotationXSpeed = 0.000;
        var cameraRotationYSpeed = 0.000;

        var mouseDown = canvas.mouse.leftButtonDown.connect(function(m:Mouse) {

            mouseMove = canvas.mouse.move.connect(function(UnnamedParameter1, dx, dy) {

                cameraRotationYSpeed = dx * .01;
                cameraRotationXSpeed = dy * -.01;
            });
        });
        var mouseUp = canvas.mouse.leftButtonUp.connect(function(m:Mouse) {
            mouseMove.disconnect();
            mouseMove = null;
        });
        var skyRotation=Quat.axisAngle(new Vec3(0,1,0),0.01,new Quat());
        var  objectsRotation=Quat.axisAngle(new Vec3(0,1,0),-0.02,new Quat());
        var enterFrame = canvas.enterFrame.connect(function(canvas, time, deltaTime) {
            yaw += cameraRotationYSpeed;
            cameraRotationYSpeed *= 0.9;

            pitch += cameraRotationXSpeed;
            cameraRotationXSpeed *= 0.9;

            if (pitch > maxPitch) {
                pitch = maxPitch;
            }
            else if (pitch < minPitch) {
                pitch = minPitch;
            }
            if (distance <= 0.0) {
                distance = 0.1;
            }
            var cameraTransform:Transform = cast camera.getComponent(Transform);
            // GLM.rotate(skyRotation, Mat4.identity(new Mat4()))*cameraTransform.matrix;
            var mat4=Mat4.invert(GLM.lookAt(
                new Vec3(lookAt.x + distance * Math.cos(yaw) * Math.sin(pitch),
                lookAt.y + distance * Math.cos(pitch),
                lookAt.z + distance * Math.sin(yaw) * Math.sin(pitch)
                ),
                lookAt,
                new Vec3(0.0, 1.0, 0.0),
                new Mat4()),
            new Mat4());
             cameraTransform.matrix = mat4 ;

            var skyTransform:Transform = cast sky.getComponent(Transform);
            var objectsTransform:Transform = cast objects.getComponent(Transform);

           skyTransform.matrix = GLM.rotate(skyRotation, Mat4.identity(new Mat4()))*skyTransform.matrix;
           objectsTransform.matrix = GLM.rotate(objectsRotation, Mat4.identity(new Mat4()))* objectsTransform.matrix;

            sceneManager.nextFrame(time, deltaTime);
        });

        loader.load();
        canvas.run();
    }

}
