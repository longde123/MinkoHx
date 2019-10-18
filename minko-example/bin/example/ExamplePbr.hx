package example;
import minko.component.ShadowMappingTechnique;
import glm.Quat;
import glm.Mat4;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.Canvas;
import minko.component.AmbientLight;
import minko.component.DirectionalLight;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.JPEGParser;
import minko.file.Loader;
import minko.geometry.CubeGeometry;
import minko.geometry.QuadGeometry;
import minko.geometry.SphereGeometry;
import minko.input.Mouse;
import minko.material.Material;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
import minko.WebCanvas;
class ExamplePbr {
    static private var ENVMAP = "cloudySea";
    static private var MAP_DIFFUSE = "texture/" + ENVMAP + "/" + ENVMAP + "-diffuse.jpg";
    static private var MAP_RADIANCE = "texture/" + ENVMAP + "/" + ENVMAP + "-radiance.jpg";
    static private var MAP_IRRADIANCE = "texture/" + ENVMAP + "/" + ENVMAP + "-irradiance.jpg";


      public function new() {
        var canvas = WebCanvas.create("Minko Example - PBR", 800, 600);
        var sceneManager = SceneManager.create(canvas);
        var root = Node.create("root").addComponent(sceneManager);
        var assets = sceneManager.assets;
        var context = canvas.context;

        context.errorsEnabled = (true);
        //Console.Write(context.driverInfo());
        // Console.Write("\n");

        // setup assets
        var options = assets.loader.options;

        options.resizeSmoothly = (true);
        options.generateMipmaps = (true);
        options.registerParser("jpg", function() return new JPEGParser());
        var tmp = options.clone();
        // tmp.parseMipMaps=(true);
        assets.loader.queue(MAP_DIFFUSE)
        .queue(MAP_IRRADIANCE)
        .setQueue(MAP_RADIANCE, tmp)
        .queue("texture/ground.jpg")
        .queue("effect/Basic.effect")
        .queue("effect/Skybox/Skybox.effect")
        .queue("effect/PBR.effect");
        var mat4:Mat4 = GLM.lookAt(new Vec3(1.0, 1.0, 0.0), new Vec3(), new Vec3(0, 1, 0), new Mat4());
        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x2f2f2fff))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(mat4, new Mat4())))
        .addComponent(PerspectiveCamera.create(800.0 / 600.0, 0.785, 0.1, 50.0));
        root.addChild(camera);
        var mat4_2:Mat4 = GLM.lookAt(new Vec3(1.0, 10.0, 0.0), new Vec3(), new Vec3(0, 1, 0), new Mat4());
        var light = Node.create("light").addComponent(AmbientLight.create(0.4))
        .addComponent(DirectionalLight.create(1.0))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(mat4_2, new Mat4())));

      //  root.addComponent(ShadowMappingTechnique.create(Technique.ESM));

        var directionalLight:DirectionalLight =cast light.getComponent(DirectionalLight);
        directionalLight.enableShadowMapping(512);
        root.addChild(light);


        var _ = assets.loader.complete.connect(function(loader:Loader) {
            var skyboxMaterial=Material.create().setbyKeyObject({ "diffuseLatLongMap":assets.texture(MAP_DIFFUSE), "gammaCorrection":2.2});

            var skybox = Node.create("skybox").addComponent(Surface.create(CubeGeometry.create(context), skyboxMaterial, assets.effect("effect/Skybox/Skybox.effect")));
            root.addChild(skybox);

            var groundMaterial = Material.create();
            groundMaterial.setbyKeyObject(
                {
                    "roughness": 1.0,
                    "metalness": 0.0,
                    "specularColor": new Vec4(0.0, 0.0, 0.0, 1.0),
                    "albedoMap": assets.texture("texture/ground.jpg"),
                    "diffuseMap": assets.texture("texture/ground.jpg"),
                    "albedoColor": new Vec4(.8, .8, .8, 1.0),
                    "irradianceMap": assets.texture(MAP_IRRADIANCE),
                    "radianceMap": assets.texture(MAP_RADIANCE),
                    "gammaCorrection":2.2
                });
            var ground = Node.create("ground");
            ground.layout = BuiltinLayout.DEFAULT | 256;
            ground.addComponent(Surface.create(QuadGeometry.create(sceneManager.canvas.context), groundMaterial, assets.effect("effect/PBR.effect")));


            ground.addComponent(Transform.createbyMatrix4( GLM.translate(new Vec3(0.0, -0.5, 0.0),new Mat4())
            * GLM.rotate(Quat.axisAngle( new Vec3(1.0, 0.0, 0.0),- Math.PI/2,new Quat()),new Mat4())
            * GLM.scale(new Vec3(20.0,20.0,20.0),new Mat4())
            ));


            root.addChild(ground);


            var sphereGeom:SphereGeometry = SphereGeometry.create(sceneManager.canvas.context, 40, 40);
            sphereGeom.computeTangentSpace(false);
            var meshes = Node.create("meshes");
            var numSpheres = 10;
            for (i in 0...numSpheres) {
                for (j in 0... numSpheres) {
                    var mesh = Node.create("mesh");
                    mesh.layout = ( BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW);
                    var mat = Material.create().setbyKeyObject(
                        {
                            "gammaCorrection": 2.2,
                            "albedoColor": new Vec4(1.0, 1.0, 1.0, 1.0),
                            "specularColor": new Vec4(1.0, 1.0, 1.0, 1.0),
                            "metalness": j / (numSpheres - 1),
                            "roughness": i / (numSpheres - 1),
                            "irradianceMap": assets.texture(MAP_IRRADIANCE),
                            "radianceMap": assets.texture(MAP_RADIANCE)
                        }); //,

                    mesh.addComponent(Surface.create(sphereGeom, mat, assets.effect("effect/PBR.effect")));
                    var mat4:Mat4 = GLM.translate(new Vec3((-(numSpheres - 1) * .5 + i) * 1.25, 0.0, ( -(numSpheres - 1) * .5 + j) * 1.25), new Mat4());
                    mesh.addComponent(Transform.createbyMatrix4(mat4));
                    meshes.addChild(mesh);
                }
            }
            root.addChild(meshes);

            var yaw = 0.0;
            var pitch = Math.PI * .5;
            var minPitch = 0.0 + 0.1;
            var maxPitch = Math.PI * .5 - .1;
            var lookAt = new Vec3(0.0, 0.0, 0.0);
            var distance = 10.0;

            // handle mouse signals

            var mouseWheel = canvas.mouse.wheel.connect(function(m, h, v) {
                distance += v / 10.0;
            });


            var mouseMove:SignalSlot3<Mouse, Int, Int> = null;
            var cameraRotationXSpeed = 0.000;
            var cameraRotationYSpeed = 0.000;

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

                var vec3=new Vec3(lookAt.x + distance * Math.cos(yaw) * Math.sin(pitch), lookAt.y + distance * Math.cos(pitch), lookAt.z + distance * Math.sin(yaw) * Math.sin(pitch));

               var transform:Transform= cast camera.getComponent(Transform);
                transform.matrix= Mat4.invert(GLM.lookAt(vec3, lookAt, new Vec3(0.0, 1.0, 0.0),new Mat4()),new Mat4());
                var directionalLight:DirectionalLight=cast light.getComponent(DirectionalLight);
                var perspectiveCamera:PerspectiveCamera=cast camera.getComponent(PerspectiveCamera);
                directionalLight.computeShadowProjection(perspectiveCamera.viewMatrix,perspectiveCamera.projectionMatrix);

                sceneManager.nextFrame(time, deltaTime);
            });

            canvas.run();
        });

        var resized = canvas.resized.connect(function(canvas, w, h) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (w / h);
        });

        sceneManager.assets.loader.load();

    }

}
