import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import haxe.io.Bytes;
import minko.AbstractCanvas;
import minko.AbstractCanvas.Flags;
import minko.Canvas.CanvasManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.geometry.CubeGeometry;
import minko.input.Keyboard;
import minko.input.Keyboard.Key;
import minko.render.Texture;
import minko.render.light.Light;
import minko.render.pbr.BloomRenderer;
import minko.render.pbr.DeferredLightingRenderer;
import minko.render.pbr.FXAARenderer;
import minko.render.pbr.FullscreenRenderer;
import minko.render.pbr.GBufferDebugRenderer;
import minko.render.pbr.GBufferFallbackRenderer;
import minko.render.pbr.GBufferRenderer;
import minko.render.pbr.PBRForwardRenderer;
import minko.material.PBRMaterial;
import minko.render.pbr.ShadowRenderer;
import minko.render.pipeline.DeferredPBRPath;
import minko.render.pipeline.ForwardPBRPath;
import minko.render.pipeline.PipelineRenderer;
import minko.render.pipeline.PostProcessChain;
import minko.render.pipeline.RenderPath;
import minko.render.pipeline.RenderQueue;
import minko.render.TextureFormat;
import minko.scene.Node;

class PipelineMain {
    static function main() {
        var canvas = CanvasManager.create("Minko HL - Pipeline PBR", 800, 600, Flags.RESIZABLE);
        var context = canvas.context;

        var geometry = CubeGeometry.create(context);
        var material = PBRMaterial.create("pbr-cube");

        // Procedural checkerboard base color map (8x8 checker, 128x128).
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

        var root = Node.create("root");
        var mesh = Node.create("mesh")
            .addComponent(Transform.create())
            .addComponent(Surface.create(geometry, material, null));
        root.addChild(mesh);

        var cameraMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());

        var lightAzimuth = -0.6;
        var lightElevation = -0.9;
        var lightIntensity = 3.0;
        var lightAutoRotate = true;
        var keyLight = Light.directional();
        var lightDirection = new Vec3();
        function updateLight():Void {
            lightDirection = new Vec3(
                Math.cos(lightElevation) * Math.sin(lightAzimuth),
                Math.sin(lightElevation),
                Math.cos(lightElevation) * Math.cos(lightAzimuth)
            );
            keyLight.direction = lightDirection;
            keyLight.color = new Vec3(1.0, 0.95, 0.9);
            keyLight.intensity = lightIntensity;
        }
        updateLight();

        var lightEye = new Vec3(-lightDirection.x * 10.0, -lightDirection.y * 10.0, -lightDirection.z * 10.0);
        var lightView = GLM.lookAt(lightEye, new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        var lightProjection = GLM.orthographic(-5.0, 5.0, -5.0, 5.0, 0.1, 30.0, new Mat4());
        var lightViewProjection = lightProjection * lightView;

        var pbr = new PBRForwardRenderer(context);
        var shadow = new ShadowRenderer(context);
        var bloom = new BloomRenderer(context);
        var tonemap = new FullscreenRenderer(context);
        var fxaa = new FXAARenderer(context);
        var gbufferRenderer = new GBufferRenderer(context);
        var gbufferFallback = new GBufferFallbackRenderer(context);
        var deferredLighting = new DeferredLightingRenderer(context);
        var debugView = new GBufferDebugRenderer(context);

        function addScenePost(chain:PostProcessChain):Void {
            chain.add("Bloom", function(frame, input, output) {
                bloom.render(frame.targetPool, input, output, 1.0, 0.5);
            }, TextureFormat.RGBA16F);
            chain.add("Tonemap", function(frame, input, output) {
                tonemap.render(input.color, output, 1.0, 2.2);
            });
            chain.add("FXAA", function(frame, input, output) {
                fxaa.render(input, output);
            });
        }

        var post = new PostProcessChain();
        addScenePost(post);

        var cubeSpinning = true;
        var cubeAngle = 0.0;
        var cubeWorld = Mat4.identity(new Mat4());

        function applyCubeWorld(queue:RenderQueue):Void {
            for (item in queue.opaque) item.worldMatrix = cubeWorld;
            for (item in queue.alphaTest) item.worldMatrix = cubeWorld;
            for (item in queue.transparent) item.worldMatrix = cubeWorld;
        }

        var forwardPath = new ForwardPBRPath();
        forwardPath.postProcess = post;
        forwardPath.shadowRenderer = shadow;
        forwardPath.lightViewProjection = lightViewProjection;
        forwardPath.renderScene = function(queue, frame, target) {
            applyCubeWorld(queue);
            pbr.render(queue, frame, target);
        };

        var useDeferred = false;
        var debugMode = 0;
        var debugNames = ["off", "albedo", "normal", "depth", "lighting", "emissive"];

        var deferredPath = new DeferredPBRPath(
            function(queue, frame, gbuffer) {
                applyCubeWorld(queue);
                if (frame.capabilities != null && frame.capabilities.supportsMRT) {
                    gbufferRenderer.render(queue, frame, gbuffer);
                }
                else {
                    gbufferFallback.render(queue, frame, gbuffer);
                }
            },
            function(frame, gbuffer, output) {
                deferredLighting.render(gbuffer, output, frame);
            },
            null, // no transparent callback: the path copies the scene color itself
            post);

        // Debug views replace the post chain with a single G-buffer view.
        var debugChain = new PostProcessChain();
        debugChain.add("GBufferDebug", function(frame, input, output) {
            debugView.render(deferredPath.gbuffer, debugMode - 1, output, 0.1, 100.0, 10.0, new Vec3(0.0, 0.0, 1.0));
        });

        var path:RenderPath = forwardPath;

        // Optional startup mode so the deferred path and the debug views can be
        // exercised without a keyboard (used by the smoke test):
        //   MINKO_DEMO_MODE=deferred | debug=<0..5>
        var initialMode = Sys.getEnv("MINKO_DEMO_MODE");
        if (initialMode == "deferred") {
            useDeferred = true;
        }
        else if (initialMode != null && StringTools.startsWith(initialMode, "debug=")) {
            useDeferred = true;
            var requested = Std.parseInt(initialMode.substr(6));
            if (requested == null || requested < 0) {
                requested = 0;
            }
            debugMode = requested % debugNames.length;
        }

        var renderWidth = canvas.width;
        var renderHeight = canvas.height;
        var renderer = new PipelineRenderer(context, root, path, renderWidth, renderHeight);
        renderer.pipeline.viewMatrix = cameraMatrix;
        renderer.pipeline.projectionMatrix = GLM.perspective(0.785, renderWidth / renderHeight, 0.1, 100.0, new Mat4());
        renderer.pipeline.cameraPosition = new Vec3(0.0, 0.0, 3.0);
        renderer.pipeline.lights.add(keyLight);
        var fillLight = Light.point();
        fillLight.position = new Vec3(1.5, 1.5, 1.5);
        fillLight.range = 8.0;
        fillLight.intensity = 4.0;
        fillLight.color = new Vec3(0.4, 0.6, 1.0);
        renderer.pipeline.lights.add(fillLight);
        var rimLight = Light.point();
        rimLight.position = new Vec3(-2.0, -0.5, -1.5);
        rimLight.range = 8.0;
        rimLight.intensity = 3.0;
        rimLight.color = new Vec3(1.0, 0.5, 0.3);
        renderer.pipeline.lights.add(rimLight);

        var cubeSpinning = true;
        var cubeAngle = 0.0;

        function status():String {
            return "metallic=" + Math.round(material.get("metallic") * 100) / 100
                + " roughness=" + Math.round(material.get("roughness") * 100) / 100
                + " intensity=" + Math.round(lightIntensity * 100) / 100
                + " spin=" + cubeSpinning + " lightAuto=" + lightAutoRotate
                + " path=" + (useDeferred ? "deferred" : "forward")
                + " debug=" + (debugMode >= 0 && debugMode < debugNames.length ? debugNames[debugMode] : "?");
        }

        function adjustMetallic(delta:Float):Void {
            var value = Math.min(1.0, Math.max(0.0, cast(material.get("metallic"), Float) + delta));
            material.setMetallic(value);
            trace("metallic=" + value);
        }

        function adjustRoughness(delta:Float):Void {
            var value = Math.min(1.0, Math.max(0.0, cast(material.get("roughness"), Float) + delta));
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
                lightIntensity = Math.min(10.0, Math.max(0.0, lightIntensity + 0.5));
                updateLight();
                trace("lightIntensity=" + lightIntensity);
            }
            if (keyboard.keyIsDown(Key._7)) {
                lightIntensity = Math.min(10.0, Math.max(0.0, lightIntensity - 0.5));
                updateLight();
                trace("lightIntensity=" + lightIntensity);
            }
            if (keyboard.keyIsDown(Key.LEFT)) {
                lightAutoRotate = false;
                lightAzimuth -= 0.15;
                updateLight();
                trace("lightAzimuth=" + Math.round(lightAzimuth * 100) / 100);
            }
            if (keyboard.keyIsDown(Key.RIGHT)) {
                lightAutoRotate = false;
                lightAzimuth += 0.15;
                updateLight();
                trace("lightAzimuth=" + Math.round(lightAzimuth * 100) / 100);
            }
            if (keyboard.keyIsDown(Key.UP)) {
                lightAutoRotate = false;
                lightElevation = Math.min(1.4, lightElevation + 0.1);
                updateLight();
                trace("lightElevation=" + Math.round(lightElevation * 100) / 100);
            }
            if (keyboard.keyIsDown(Key.DOWN)) {
                lightAutoRotate = false;
                lightElevation = Math.max(-1.4, lightElevation - 0.1);
                updateLight();
                trace("lightElevation=" + Math.round(lightElevation * 100) / 100);
            }
            if (keyboard.keyIsDown(Key.SPACE)) {
                cubeSpinning = !cubeSpinning;
                lightAutoRotate = !lightAutoRotate;
                trace(status());
            }
            if (keyboard.keyIsDown(Key._0)) {
                material.setMetallic(0.35);
                material.setRoughness(0.35);
                lightIntensity = 3.0;
                lightAzimuth = -0.6;
                lightElevation = -0.9;
                updateLight();
                cubeSpinning = true;
                lightAutoRotate = true;
                trace("RESET " + status());
            }
            if (keyboard.keyIsDown(Key.D)) {
                useDeferred = !useDeferred;
                debugMode = 0;
                trace("path=" + (useDeferred ? "deferred" : "forward"));
            }
            if (keyboard.keyIsDown(Key.G)) {
                debugMode = (debugMode + 1) % debugNames.length;
                if (debugMode > 0 && !useDeferred) {
                    useDeferred = true;
                    trace("path=deferred (debug views need the G-buffer)");
                }
                trace("debug=" + debugNames[debugMode]);
            }
        });

        canvas.resized.connect(function(canvas:AbstractCanvas, w:Int, h:Int) {
            renderWidth = w;
            renderHeight = h;
            renderer.width = w;
            renderer.height = h;
            renderer.pipeline.projectionMatrix = GLM.perspective(0.785, w / h, 0.1, 100.0, new Mat4());
        });

        canvas.enterFrame.connect(function(canvas:AbstractCanvas, time:Float, deltaTime:Float) {
            if (cubeSpinning) {
                cubeAngle += deltaTime * 0.001;
                cubeWorld = GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), cubeAngle, new Quat()), new Mat4());
            }
            if (lightAutoRotate) {
                lightAzimuth += deltaTime * 0.0004;
                updateLight();
                lightEye = new Vec3(-lightDirection.x * 10.0, -lightDirection.y * 10.0, -lightDirection.z * 10.0);
                lightView = GLM.lookAt(lightEye, new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
                lightViewProjection = lightProjection * lightView;
                forwardPath.lightViewProjection = lightViewProjection;
            }

            // Switch paths without rebuilding GL resources: the path build()
            // runs every frame anyway.
            var activePath:RenderPath = useDeferred ? deferredPath : forwardPath;
            if (renderer.pipeline.path != activePath) {
                renderer.pipeline.path = activePath;
            }
            deferredPath.postProcess = debugMode > 0 ? debugChain : post;

            renderer.render(deltaTime);
        });

        trace("Controls: 1/2 metallic -/+  3/4 roughness -/+  5 color  6/7 light intensity -/+  arrows light direction  SPACE toggle spin/auto  0 reset  D forward/deferred  G G-buffer debug view");
        canvas.run();
    }
}







