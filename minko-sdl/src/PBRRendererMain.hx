import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import haxe.io.Bytes;
import minko.AbstractCanvas;
import minko.AbstractCanvas.Flags;
import minko.Canvas.CanvasManager;
import minko.component.PBRRenderer;
import minko.component.PerspectiveCamera;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.geometry.CubeGeometry;
import minko.input.Keyboard;
import minko.input.Keyboard.Key;
import minko.render.Texture;
import minko.render.TextureFormat;
import minko.render.light.Light;
import minko.render.pbr.BloomRenderer;
import minko.render.pbr.FXAARenderer;
import minko.render.pbr.FullscreenRenderer;
import minko.material.PBRMaterial;
import minko.render.pipeline.PostProcessChain;
import minko.scene.Node;

/**
 * PBR forward demo driven by minko.component.PBRRenderer.
 *
 * Unlike PipelineMain this does not own a PipelineRenderer directly: the
 * component subscribes to SceneManager, creates the forward PBR path, and
 * collects camera/surfaces from the scene graph.
 */
class PBRRendererMain {
    static function main() {
        var canvas = CanvasManager.create("Minko HL - PBRRenderer", 800, 600, Flags.RESIZABLE);
        var sceneManager = SceneManager.create(canvas);
        var context = sceneManager.assets.context;

        var geometry = CubeGeometry.create(context);
        var material = PBRMaterial.create("pbr-cube");

        // Procedural checkerboard base color map, same look as PipelineMain.
        var checker = Texture.create(context, 128, 128);
        checker.upload();
        var texData = Bytes.alloc(128 * 128 * 4);
        for (y in 0...128) {
            for (x in 0...128) {
                var cell = ((x >> 4) + (y >> 4)) % 2 == 0;
                var edge = (x % 16 < 2) || (y % 16 < 2);
                var i = (y * 128 + x) * 4;
                texData.set(i, cell ? 235 : 60);
                texData.set(i + 1, cell ? 235 : 60);
                texData.set(i + 2, cell ? 235 : 70);
                texData.set(i + 3, 255);
                if (edge) {
                    texData.set(i, 30);
                    texData.set(i + 1, 30);
                    texData.set(i + 2, 35);
                }
            }
        }
        checker.uploadMipLevel(0, texData);
        material.setBaseColorMap(checker);

        var colorPresets = [
            new Vec4(1.0, 0.55, 0.2, 1.0),
            new Vec4(0.2, 0.8, 0.3, 1.0),
            new Vec4(0.25, 0.45, 1.0, 1.0),
            new Vec4(0.85, 0.25, 0.8, 1.0),
            new Vec4(0.95, 0.95, 0.95, 1.0)
        ];
        var colorIndex = 0;
        material.setBaseColor(colorPresets[colorIndex]);
        material.setMetallic(0.35);
        material.setRoughness(0.35);

        var cameraMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());

        var root = Node.create("root");
        root.addComponent(sceneManager);

        var mesh = Node.create("mesh").addComponent(Transform.create());
        mesh.addComponent(Surface.create(geometry, material, null));

        var camera = Node.create("camera")
            .addComponent(Transform.createbyMatrix4(Mat4.invert(cameraMatrix, new Mat4())))
            .addComponent(PerspectiveCamera.create(canvas.aspectRatio));

        root.addChild(mesh);
        root.addChild(camera);

        var keyLight = Light.directional();
        keyLight.color = new Vec3(1.0, 0.95, 0.9);
        keyLight.intensity = 3.0;

        var fillLight = Light.point();
        fillLight.position = new Vec3(1.5, 1.5, 1.5);
        fillLight.range = 8.0;
        fillLight.intensity = 4.0;
        fillLight.color = new Vec3(0.4, 0.6, 1.0);

        var rimLight = Light.point();
        rimLight.position = new Vec3(-2.0, -0.5, -1.5);
        rimLight.range = 8.0;
        rimLight.intensity = 3.0;
        rimLight.color = new Vec3(1.0, 0.5, 0.3);

        var bloom = new BloomRenderer(context);
        var tonemap = new FullscreenRenderer(context);
        var fxaa = new FXAARenderer(context);

        var post = new PostProcessChain();
        post.add("Bloom", function(frame, input, output) {
            bloom.render(frame.targetPool, input, output, 1.0, 0.5);
        }, TextureFormat.RGBA16F);
        post.add("Tonemap", function(frame, input, output) {
            tonemap.render(input.color, output, 1.0, 2.2);
        });
        post.add("FXAA", function(frame, input, output) {
            fxaa.render(input, output);
        });

        var renderer = PBRRenderer.create();
        root.addComponent(renderer);
        renderer.addLight(keyLight);
        renderer.addLight(fillLight);
        renderer.addLight(rimLight);
        renderer.postProcess = post;

        var lightAzimuth = -0.6;
        var lightElevation = -0.9;
        var lightAutoRotate = true;
        var spinning = true;

        function updateLight():Void {
            keyLight.direction = new Vec3(
                Math.cos(lightElevation) * Math.sin(lightAzimuth),
                Math.sin(lightElevation),
                Math.cos(lightElevation) * Math.cos(lightAzimuth)
            );
        }
        updateLight();

        function adjustMetallic(delta:Float):Void {
            var value = Math.min(1.0, Math.max(0.0, cast(material.get(PBRMaterial.METALLIC), Float) + delta));
            material.setMetallic(value);
            trace("metallic=" + value);
        }

        function adjustRoughness(delta:Float):Void {
            var value = Math.min(1.0, Math.max(0.0, cast(material.get(PBRMaterial.ROUGHNESS), Float) + delta));
            material.setRoughness(value);
            trace("roughness=" + value);
        }

        function cycleColor():Void {
            colorIndex = (colorIndex + 1) % colorPresets.length;
            material.setBaseColor(colorPresets[colorIndex]);
            trace("baseColor preset " + colorIndex);
        }

        canvas.keyboard.keyDown.connect(function(keyboard:Keyboard) {
            if (keyboard.keyIsDown(Key._1)) adjustMetallic(-0.1);
            if (keyboard.keyIsDown(Key._2)) adjustMetallic(0.1);
            if (keyboard.keyIsDown(Key._3)) adjustRoughness(-0.1);
            if (keyboard.keyIsDown(Key._4)) adjustRoughness(0.1);
            if (keyboard.keyIsDown(Key._5)) cycleColor();
            if (keyboard.keyIsDown(Key._6)) {
                keyLight.intensity = Math.min(10.0, Math.max(0.0, keyLight.intensity + 0.5));
                trace("lightIntensity=" + keyLight.intensity);
            }
            if (keyboard.keyIsDown(Key._7)) {
                keyLight.intensity = Math.min(10.0, Math.max(0.0, keyLight.intensity - 0.5));
                trace("lightIntensity=" + keyLight.intensity);
            }
            if (keyboard.keyIsDown(Key.LEFT)) {
                lightAutoRotate = false;
                lightAzimuth -= 0.15;
                updateLight();
            }
            if (keyboard.keyIsDown(Key.RIGHT)) {
                lightAutoRotate = false;
                lightAzimuth += 0.15;
                updateLight();
            }
            if (keyboard.keyIsDown(Key.UP)) {
                lightAutoRotate = false;
                lightElevation = Math.min(1.4, lightElevation + 0.1);
                updateLight();
            }
            if (keyboard.keyIsDown(Key.DOWN)) {
                lightAutoRotate = false;
                lightElevation = Math.max(-1.4, lightElevation - 0.1);
                updateLight();
            }
            if (keyboard.keyIsDown(Key.SPACE)) {
                spinning = !spinning;
                lightAutoRotate = !lightAutoRotate;
                trace("spin=" + spinning + " lightAuto=" + lightAutoRotate);
            }
            if (keyboard.keyIsDown(Key._0)) {
                material.setMetallic(0.35);
                material.setRoughness(0.35);
                keyLight.intensity = 3.0;
                lightAzimuth = -0.6;
                lightElevation = -0.9;
                updateLight();
                colorIndex = 0;
                material.setBaseColor(colorPresets[colorIndex]);
                spinning = true;
                lightAutoRotate = true;
                trace("RESET");
            }
        });

        canvas.resized.connect(function(canvas:AbstractCanvas, width:Int, height:Int) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = width / height;
        });

        var meshTransform:Transform = cast mesh.getComponent(Transform);
        canvas.enterFrame.connect(function(canvas:AbstractCanvas, time:Float, deltaTime:Float) {
            if (spinning) {
                meshTransform.matrix = GLM.rotate(
                    Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), deltaTime * 0.001, new Quat()),
                    new Mat4()
                ) * meshTransform.matrix;
            }
            if (lightAutoRotate) {
                lightAzimuth += deltaTime * 0.0004;
                updateLight();
            }
            sceneManager.nextFrame(time, deltaTime);
        });

        trace("PBRRenderer demo controls: 1/2 metallic -/+  3/4 roughness -/+  5 color  6/7 light intensity -/+  arrows light direction  SPACE toggle spin/auto  0 reset");
        canvas.run();
    }
}
