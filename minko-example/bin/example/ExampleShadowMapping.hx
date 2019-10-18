package example;
import minko.material.Material;
import minko.component.AbstractComponent;
import minko.utils.MathUtil;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import minko.component.AmbientLight;
import minko.component.DirectionalLight;
import minko.component.FrustumDisplay;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.ShadowMappingTechnique;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.AssetLibrary;
import minko.file.Loader;
import minko.geometry.CubeGeometry;
import minko.geometry.QuadGeometry;
import minko.geometry.SphereGeometry;
import minko.geometry.TeapotGeometry;
import minko.input.Keyboard;
import minko.input.Mouse;
import minko.material.BasicMaterial;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
import minko.WebCanvas;


class ExampleShadowMapping {

    private var lightNode:Node;
    private var debugNode:Node ;
    private var projectionAuto:Bool;
    private var directionalLight:DirectionalLight;
    private var directionalLight2:DirectionalLight;

    private var frustums:Array<FrustumDisplay>;

    public function new() {
        lightNode = Node.create();
        debugNode = Node.createbyLayout("debug", BuiltinLayout.DEBUG_ONLY);
        projectionAuto = false;
        directionalLight = DirectionalLight.create(.3);
        directionalLight2 = DirectionalLight.create(.3);
        frustums = [for (i in 0...5) new FrustumDisplay(Mat4.identity(new Mat4()))];
        init();
    }

    private function initializeShadowMapping(root:Node, assets:AssetLibrary) {
        root.addComponent(ShadowMappingTechnique.create(Technique.ESM));

        directionalLight.enableShadowMapping(512);
      directionalLight2.enableShadowMapping(256);

        lightNode = Node.create("light").addComponent(AmbientLight.create())
        .addComponent(directionalLight)
        .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(1.0, 1.0, 1.0), new Vec3(0.0), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())));
        root.addChild(lightNode);

        if (directionalLight.shadowMappingEnabled) {
            var debugDisplay = TextureDebugDisplay.create();

            debugDisplay.initialize(assets, directionalLight.shadowMap);
            debugNode.addComponent(debugDisplay);
        }

        var lightNode2 = Node.create().addComponent(directionalLight2)
         .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(-1.0, 1.0, 0.5), new Vec3(0.0), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())));
        root.addChild(lightNode2);
    }

    function init() {
        trace("Press [C]\tto show the camera frustum\n");
        trace("Press [L]\tto show the shadow cascade frustums\n");
        trace("Press [R]\tto toggle the shadow cascade splits debug rendering\n");
        trace("Press [A]\tto toggle the first light shadows\n");
        trace("Press [Z]\tto toggle the second light shadows");
        trace("\n");

        var canvas = WebCanvas.create("Minko - Shadow Mapping Example", 800, 600);
        var sceneManager = SceneManager.create(canvas);
        var debugDisplay = false;

        var loader = sceneManager.assets.loader;
        loader.queue("effect/Phong.effect");
        loader.queue("effect/debug/ShadowMappingDebug.effect");

        var root = Node.create("root").addComponent(sceneManager);

        var debugRenderer = Renderer.create();
        debugRenderer.layoutMask = (BuiltinLayout.DEBUG_ONLY);
        debugRenderer.clearBeforeRender = (false);
        var renderer = Renderer.create(0x1f1f1fff);
        var camera_mat=Mat4.invert(GLM.lookAt(new Vec3(0.0, 8.0, 8.0), new Vec3(0.0), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4());
        var camera = Node.create("camera")
        .addComponent(renderer)
        .addComponent(debugRenderer)
        .addComponent(Transform.createbyMatrix4(camera_mat))
        .addComponent(PerspectiveCamera.create(canvas.aspectRatio, .785, .1, 100.0));

        root.addChild(camera);
        root.addChild(debugNode);

        var teapot = Node.create();

        var _ = sceneManager.assets.loader.complete.connect(function(loader:Loader) {
            renderer.effect = (sceneManager.assets.effect("effect/Phong.effect"));

            var cubeBasicMaterial = BasicMaterial.create();
            cubeBasicMaterial.diffuseColor = new Vec4(1.0, .3, .3, 1.0);

            var cube = Node.createbyLayout("cube", BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW)
            .addComponent(Surface.create(CubeGeometry.create(sceneManager.assets.context), cubeBasicMaterial))
            .addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.5, .5, 0.0), Mat4.identity(new Mat4()))));
            root.addChild(cube);
            var sphereBasicMaterial = BasicMaterial.create();
            sphereBasicMaterial.diffuseColor = new Vec4(.3, .3, 1.0, 1.0);
            var sphere = Node.createbyLayout("sphere", BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW)
            .addComponent(Surface.create(SphereGeometry.create(sceneManager.assets.context, 40), sphereBasicMaterial))
            .addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.5, .5, 0.0), Mat4.identity(new Mat4()))));
            root.addChild(sphere);

            var teapotBasicMaterial = BasicMaterial.create();
            teapotBasicMaterial.diffuseColor = new Vec4(.3, 1.0, .3, 1.0);
            teapot = Node.createbyLayout("teapot", BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW)
            .addComponent(Surface.create(TeapotGeometry.create(sceneManager.assets.context).computeNormals(), teapotBasicMaterial))
            .addComponent(Transform.createbyMatrix4(GLM.scale(new Vec3(.3, .3, .3), (new Mat4()))));
            root.addChild(teapot);

            var groundBasicMaterial = BasicMaterial.create();
            groundBasicMaterial.diffuseColorRGBA(0xffffffff);
            var ground_mat=GLM.rotate(Quat.axisAngle(new Vec3(1.0, 0.0, 0.0), -MathUtil.half_pi, new Quat()), new Mat4() )  * GLM.scale(new Vec3(100.0, 100, 100),  new Mat4() );
            var ground = Node.createbyLayout("ground", BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW)
            .addComponent(Surface.create(QuadGeometry.create(sceneManager.assets.context), groundBasicMaterial))
            .addComponent(Transform.createbyMatrix4(ground_mat));
            root.addChild(ground);

            initializeShadowMapping(root, sceneManager.assets);

            var perspective:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            var cameraTransform:Transform = cast camera.getComponent(Transform);
            cameraTransform.updateModelToWorldMatrix();
            var directionalLight_target_Transform:Transform = cast directionalLight.target.getComponent(Transform);
            directionalLight_target_Transform.updateModelToWorldMatrix();
            directionalLight.computeShadowProjection(perspective.viewMatrix, perspective.projectionMatrix);
             var directionalLight2_target_Transform:Transform = cast directionalLight2.target.getComponent(Transform);
            directionalLight2_target_Transform.updateModelToWorldMatrix();
            directionalLight2.computeShadowProjection(perspective.viewMatrix, perspective.projectionMatrix);
        });

        var yaw = -0.8;
        var pitch = 0.9; //float(M_PI) * .5f;
        // float pitch = float(M_PI) * .5f;
        var minPitch = 0.0 + 0.1;
        var maxPitch = Math.PI * .5 - .1;
        // auto maxPitch = float(M_PI) - .1f;
        var lookAt = new Vec3(0.0, 0.0, 0.0);
        var distance = 6.0;
        var minDistance = 1.0;
        var maxDistance = 40.0;
        var zoomSpeed = 0.0;
        var mouseMove:SignalSlot3<Mouse, Int, Int>;
        var cameraRotationXSpeed = 0.0;
        var cameraRotationYSpeed = 0.0;
        var cameraMoved = true;

        var keyDown = canvas.keyboard.keyDown.connect(function(k:Keyboard) {
            if (k.keyIsDown(Key.R)) {
                if (renderer.effect == sceneManager.assets.effect("effect/Phong.effect")) {
                    renderer.effect = (sceneManager.assets.effect("effect/debug/ShadowMappingDebug.effect"));
                }
                else {
                    renderer.effect = (sceneManager.assets.effect("effect/Phong.effect"));
                }
            }
            if (k.keyIsDown(Key.C)) {
                var p:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);

                if (debugNode.existsComponent(cast frustums[4])) {
                    debugNode.removeComponent(cast  frustums[4]);
                }
                else {
                    frustums[4] = FrustumDisplay.create(p.viewProjectionMatrix);
                    debugNode.addComponent(cast  frustums[4]);
                }
            }
            if (k.keyIsDown(Key.L)) {
                var p:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
                var colors:Array<Vec4> = [new Vec4(1.0, 0.0, 0.0, .1),
                new Vec4(0.0, 1.0, 0.0, .1),
                new Vec4(0.0, 0.0, 1.0, .1),
                new Vec4(1.0, 1.0, 0.0, .1)];

                for (i in 0... directionalLight.numShadowCascades) {
                    if (frustums[i]!=null && debugNode.existsComponent(cast frustums[i])) {
                        debugNode.removeComponent(cast frustums[i]);
                        debugDisplay = false;
                        cameraMoved = true;
                    }
                    else {
                        var directionalLight_target_Transform:Transform = cast directionalLight.target.getComponent(Transform);
                        frustums[i] = FrustumDisplay.create(directionalLight.shadowProjections[i] * Mat4.invert(directionalLight_target_Transform.modelToWorldMatrix, new Mat4()));
                        frustums[i].material.diffuseColor = (colors[i]);
                        debugNode.addComponent(frustums[i]);
                        debugDisplay = true;
                    }

                }
            }
            if (k.keyIsDown(Key.A)) {
                if (directionalLight.shadowMappingEnabled) {
                    directionalLight.disableShadowMapping(k.keyIsDown(Key.SHIFT));
                }
                else {
                    directionalLight.enableShadowMapping();
                    cameraMoved = true;
                }
            }
            if (k.keyIsDown(Key.Z)) {
                if (directionalLight2.shadowMappingEnabled) {
                    directionalLight2.disableShadowMapping(k.keyIsDown(Key.SHIFT));
                }
                else {
                    directionalLight2.enableShadowMapping();
                    cameraMoved = true;
                }
            }
        });

        var resized = canvas.resized.connect(function(canvas, w, h) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (w / h);
            cameraMoved = true;
        });
        // handle mouse signals
        var mouseWheel = canvas.mouse.wheel.connect(function(m, h, v) {
            zoomSpeed -= v * .1 ;
        });



        var mouseDown = canvas.mouse.leftButtonDown.connect(function(m) {
            mouseMove = canvas.mouse.move.connect(function(UnnamedParameter1, dx, dy) {
                cameraRotationYSpeed = dx * .02 ;
                cameraRotationXSpeed = dy * -.02 ;
            });
        });

        var mouseUp = canvas.mouse.leftButtonUp.connect(function(m) {
            mouseMove.disconnect();
            mouseMove = null;

        });

        var enterFrame = canvas.enterFrame.connect(function(canvas, time, deltaTime) {
            distance += zoomSpeed;
            zoomSpeed *= 0.9 ;
            if (Math.abs(zoomSpeed) > 0.01) {
                if (distance < minDistance) {
                    distance = minDistance;
                }
                else if (distance > maxDistance) {
                    distance = maxDistance;
                }
                cameraMoved = true;
            }

            if (Math.abs(cameraRotationYSpeed) > 0.001) {
                yaw += cameraRotationYSpeed;
                cameraRotationYSpeed *= 0.9 ;
                cameraMoved = true;
            }

            if (Math.abs(cameraRotationXSpeed) > 0.001) {
                pitch += cameraRotationXSpeed;
                cameraRotationXSpeed *= 0.9 ;
                cameraMoved = true;
                if (pitch > maxPitch) {
                    pitch = maxPitch;
                }
                else if (pitch < minPitch) {
                    pitch = minPitch;
                }
            }

            var p:PerspectiveCamera =cast camera.getComponent(PerspectiveCamera);
            directionalLight.computeShadowProjection(p.viewMatrix, p.projectionMatrix, 40.0);
             directionalLight2.computeShadowProjection(p.viewMatrix, p.projectionMatrix, 40.0);

            if (cameraMoved) {
                var cameraTransform:Transform = cast camera.getComponent(Transform);
              cameraTransform.matrix = (Mat4.invert(GLM.lookAt(new Vec3(lookAt.x + distance * Math.cos(yaw) * Math.sin(pitch), lookAt.y + distance * Math.cos(pitch), lookAt.z + distance * Math.sin(yaw) * Math.sin(pitch)), lookAt, new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4()));
            }
            var teapotTransform:Transform = cast teapot.getComponent(Transform);
            teapotTransform.matrix = (GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), -0.02, new Quat()), Mat4.identity(new Mat4())) * teapotTransform.matrix);

            sceneManager.nextFrame(time, deltaTime);
        });
        sceneManager.assets.loader.load();
        canvas.run();

    }

}
