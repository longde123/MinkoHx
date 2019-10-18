package example;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import minko.component.AmbientLight;
import minko.component.DirectionalLight;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.AssetLibrary;
import minko.file.JPEGParser;
import minko.file.Loader;
import minko.file.PNGParser;
import minko.geometry.QuadGeometry;
import minko.geometry.SphereGeometry;
import minko.input.Keyboard;
import minko.input.Mouse;
import minko.material.FogTechnique;
import minko.material.Material;
import minko.material.WaterMaterial;
import minko.scene.Node;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal3.SignalSlot3;
import minko.WebCanvas;
class ExampleWater {
    public function new() {
        init();
    }

    private static var CAMERA_LIN_SPEED = 0.05 ;
    private static var CAMERA_ANG_SPEED = Math.PI * 2.0 / 180.0;
    private static var flowMapCycle = 0.25;

    private var keyDown:SignalSlot<Keyboard>;

// #define FLOW_MAP // comment to deactivate flowmap
// #define ENABLE_REFLECTION // comment to deactivate reflections
    function init() {
        var canvas = WebCanvas.create("Minko Example - Water");
        var sceneManager = SceneManager.create(canvas);
        var assets:AssetLibrary = sceneManager.assets;

        canvas.context.errorsEnabled = (true);

        assets.loader.options.resizeSmoothly = (true);
        assets.loader.options.generateMipmaps = (true);
        assets.loader.options.registerParser("png", function() return new PNGParser());
        assets.loader.options.registerParser("jpg", function() return new JPEGParser());

        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x7f7f7fff))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(), new Vec3(3.0, 3.0, 3.0), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())))
        .addComponent(PerspectiveCamera.create(canvas.aspectRatio));

        var fxLoader = Loader.createbyLoader(sceneManager.assets.loader).queue("effect/Phong.effect");

        var fxComplete = fxLoader.complete.connect(function(l:Loader) {
            assets.loader.queue("texture/skybox_texture-diffuse.jpg")
            .queue("effect/Skybox/Skybox.effect")
            .queue("texture/normalmap.png")
            .queue("effect/Water/Water.effect")
            .load();
            // ->queue("texture/flowmap.png")
            // ->queue("texture/water_dudv.jpg")
            // ->queue("texture/noise.png")
            // ->queue("effect/Reflection/PlanarReflection.effect");
        });


        var _ = assets.loader.complete.connect(function(loader:Loader) {
#if ENABLE_REFLECTION
		var reflectionComponent = Reflection.create(sceneManager.assets(), 2048, 2048, 0x00000000);
		camera.addComponent(reflectionComponent);
#end

            root.addChild(camera);

            var fogColor = new Vec4(.9, .9, .9, 1.0);

            var sky = Node.create()
            .addComponent(Surface.create(
                SphereGeometry.create(assets.context, 16, 16),
                Material.create().setbyKeyObject({
                    "diffuseLatLongMap": assets.texture("texture/skybox_texture-diffuse.jpg"),
                    "gammaCorrection": 2.2,
                    "fogColor": fogColor,
                    "sunDirection": new Vec3(1., 0., 0.),
                    "reileighCoefficient": 1.,
                    "mieCoefficient": .053,
                    "mieDirectionalG": .75,
                    "turbidity":1.
                }),
                assets.effect("effect/Skybox/Skybox.effect")
            ));
            root.addChild(sky);


            var waterMaterial:WaterMaterial = WaterMaterial.createWaves(5);


// #ifdef FLOW_MAP
//         waterMaterial->noiseMap(assets->texture("texture/noise.png"));
//         waterMaterial->flowMap(assets->texture("texture/flowmap.png"));
//         waterMaterial->flowMapCycle(flowMapCycle);
//         waterMaterial->flowMapOffset1(0.f);
//         waterMaterial->flowMapOffset2(flowMapCycle / 2.f);
// #endif
//
// #ifdef ENABLE_REFLECTION
//         waterMaterial->dudvMap(sceneManager->assets()->texture("texture/water_dudv.jpg"));
//         waterMaterial->reflectionMap(camera->components<Reflection>()[0]->getRenderTarget());
//         waterMaterial->reflectivity(0.4f);
//         waterMaterial->dudvFactor(0.02f);
//         waterMaterial->dudvSpeed(0.00015f);
//         waterMaterial->diffuseColor(0x052540FF);
// #else
//         waterMaterial->diffuseColor(0x306090D0);
// #endif

            waterMaterial.normalMap = (assets.texture("texture/normalmap.png"));
            waterMaterial.diffuseColorRGBA(0x001033FF);

            // waterMaterial->flowMapScale(1.f);
            waterMaterial.shininess = (64.0);
            waterMaterial.specularColorRGBA(0xFFFFFF33);

// #ifdef FLOW_MAP
//         waterMaterial->setAmplitude(0, 0.06f);
//         waterMaterial->setAmplitude(1, 0.0173f);
//         waterMaterial->setAmplitude(2, 0.0312f);
//         waterMaterial->setAmplitude(3, 0.0287f);
//         waterMaterial->setAmplitude(4, 0.0457f);
// #else
            waterMaterial.setAmplitude(0, 1.43);
            waterMaterial.setAmplitude(1, .373);
            waterMaterial.setAmplitude(2, .112);
            waterMaterial.setAmplitude(3, .187);
            waterMaterial.setAmplitude(4, 1.0);
// #endif
            waterMaterial.setWaveLength(0, 50.0);
            waterMaterial.setWaveLength(1, 17.7);
            waterMaterial.setWaveLength(2, 13.13);
            waterMaterial.setWaveLength(3, 40.17);
            waterMaterial.setWaveLength(4, 100.0);

            waterMaterial.setSpeed(0, 7.4);
            waterMaterial.setSpeed(1, 8.8);
            waterMaterial.setSpeed(2, 3.2);
            waterMaterial.setSpeed(3, 4.6);
            waterMaterial.setSpeed(4, 6.0);

            waterMaterial.setDirection(0, new Vec2(1.0, 1.0));
            waterMaterial.setDirection(1, new Vec2(0.1, 1.0));
            waterMaterial.setCenter(2, new Vec2(1000.0, -1000.0));
            waterMaterial.setCenter(3, new Vec2(1000.0, 1000.0));
            waterMaterial.setDirection(4, new Vec2(1.0, 0.0));

            waterMaterial.setSharpness(0, .5);
            waterMaterial.setSharpness(1, .5);
            waterMaterial.setSharpness(2, .3);
            waterMaterial.setSharpness(3, .5);
            waterMaterial.setSharpness(4, .5);

            var waves = Node.create("waves")
            .addComponent(Transform.createbyMatrix4(GLM.rotate(Quat.axisAngle(new Vec3(1.0, 0.0, 0.0), -Math.PI / 2.0, new Quat()), new Mat4())))
            .addComponent(Surface.create(QuadGeometry.create(assets.context, 200, 200, 1000, 1000), waterMaterial.setbyKeyObject(
                {
                    "fogTechnique": FogTechnique.LIN,
                    "fogBounds":new Vec2(300.0, 500.0),
                    "fogColor": fogColor,
                    "uvScale":new Vec2(2.0, 2.0),
                    "environmentMap2d": assets.texture("texture/skybox_texture-diffuse.jpg"),
                    "gammaCorrection": 2.2
                }), assets.effect("effect/Water/Water.effect")));
            // { "normalMap", assets->texture("texture/normalmap.png")->sampler() },
            // assets->effect("effect/Phong.effect")
            root.addChild(waves);

            root.addChild(Node.create().addComponent(DirectionalLight.create(0.8, .8))
            .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(-.8, 1.0, 0.0), new Vec3(0.0), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4()))));
            root.addChild(Node.create().addComponent(AmbientLight.create(0.1)));
        });

        var resized = canvas.resized.connect(function(canvas, w, h) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (w / h);
        });

        var yaw = 0.3;
        // float pitch = 1.3f;//float(M_PI) * .5f;
        var pitch = Math.PI * .5;
        var minPitch = 0.0 + 0.1;
        // auto maxPitch = float(M_PI) * .5f - .1f;
        var maxPitch = Math.PI - .1;
        var lookAt = new Vec3(0.0, 2.0, 0.0);
        var distance = 3.0;
        var minDistance = 1.0;
        var zoomSpeed = 0.0;

        var mouseWheel = canvas.mouse.wheel.connect(function(m, h, v) {
            zoomSpeed -= v * .1;
        });

        var mouseMove:SignalSlot3<Mouse, Int, Int> = null;
        var cameraRotationXSpeed = 0.0;
        var cameraRotationYSpeed = 0.0;

        var mouseDown = canvas.mouse.leftButtonDown.connect(function(m) {
            mouseMove = canvas.mouse.move.connect(function(UnnamedParameter1, dx, dy) {
                cameraRotationYSpeed = dx * .01;
                cameraRotationXSpeed = dy * -.01;
            });
        });

        var mouseUp = canvas.mouse.leftButtonUp.connect(function(m) {
            mouseMove.disconnect();
            mouseMove = null;
        });

        var enterFrame = canvas.enterFrame.connect(function(canvas, time, deltaTime) {
            distance += zoomSpeed;
            zoomSpeed *= 0.9;
            if (distance < minDistance) {
                distance = minDistance;
            }

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
            var cameraTransform:Transform = cast camera.getComponent(Transform);
            cameraTransform.matrix = (Mat4.invert(GLM.lookAt(
                new Vec3(lookAt.x + distance * Math.cos(yaw) * Math.sin(pitch), lookAt.y + distance * Math.cos(pitch), lookAt.z + distance * Math.sin(yaw) * Math.sin(pitch)),
                lookAt, new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4()));

            sceneManager.nextFrame(time, deltaTime);
        });

        fxLoader.load();
        canvas.run();
    }

}
