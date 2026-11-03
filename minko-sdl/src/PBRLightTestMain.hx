import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import minko.AbstractCanvas;
import minko.AbstractCanvas.Flags;
import minko.Canvas.CanvasManager;
import minko.component.DirectionalLight;
import minko.component.PerspectiveCamera;
import minko.component.PBRRenderer;
import minko.component.PointLight;
import minko.component.SceneManager;
import minko.component.SpotLight;
import minko.component.Surface;
import minko.component.Transform;
import minko.geometry.CubeGeometry;
import minko.input.Keyboard;
import minko.input.Keyboard.Key;
import minko.material.PBRMaterial;
import minko.render.pbr.ShadowRenderer;
import minko.scene.Node;

/**
 * Scene-graph light test for PBRRenderer.
 *
 * Three objects are lit by a directional light, an orbiting point light and a
 * moving spot light. All three lights are LightComponent instances collected
 * automatically by PBRRenderer.
 */
class PBRLightTestMain {
    static function main() {
        var canvas = CanvasManager.create("Minko HL - PBR light test", 900, 620, Flags.RESIZABLE);
        var sceneManager = SceneManager.create(canvas);
        var context = sceneManager.assets.context;

        var geometry = CubeGeometry.create(context);

        var root = Node.create("root");
        root.addComponent(sceneManager);

        var cameraMatrix = GLM.lookAt(new Vec3(0.0, 1.2, 5.8), new Vec3(0.0, 0.1, 0.0),
            new Vec3(0.0, 1.0, 0.0), new Mat4());
        var camera = Node.create("camera")
            .addComponent(Transform.createbyMatrix4(Mat4.invert(cameraMatrix, new Mat4())))
            .addComponent(PerspectiveCamera.create(canvas.aspectRatio));
        root.addChild(camera);

        var groundMaterial = PBRMaterial.create("ground");
        groundMaterial.setBaseColor(new Vec4(0.32, 0.33, 0.36, 1.0));
        groundMaterial.setMetallic(0.0);
        groundMaterial.setRoughness(0.65);
        var ground = Node.create("ground")
            .addComponent(Transform.createbyMatrix4(scaleAndTranslate(8.0, 0.08, 8.0, 0.0, -1.2, 0.0)))
            .addComponent(Surface.create(geometry, groundMaterial, null));
        root.addChild(ground);

        var materials:Array<PBRMaterial> = [];
        var objects:Array<Node> = [];
        var colors = [
            new Vec4(0.92, 0.35, 0.22, 1.0),
            new Vec4(0.30, 0.72, 0.95, 1.0),
            new Vec4(0.55, 0.86, 0.35, 1.0)
        ];
        for (i in 0...3) {
            var material = PBRMaterial.create("object-" + i);
            material.setBaseColor(colors[i]);
            material.setMetallic(0.15 + i * 0.15);
            material.setRoughness(0.35 + i * 0.12);
            materials.push(material);

            var node = Node.create("object-" + i)
                .addComponent(Transform.createbyMatrix4(scaleAndTranslate(0.9, 0.9, 0.9, (i - 1) * 1.55, -0.55, 0.0)))
                .addComponent(Surface.create(geometry, material, null));
            objects.push(node);
            root.addChild(node);
        }

        var dirNode = Node.create("directional")
            .addComponent(Transform.createbyMatrix4(directionTransform(new Vec3(-0.5, -1.0, -0.6))))
            .addComponent(DirectionalLight.create(new Vec3(1.0, 0.95, 0.85), 2.0));
        root.addChild(dirNode);

        var pointNode = Node.create("point")
            .addComponent(Transform.createbyMatrix4(translation(2.2, 1.4, 1.8)))
            .addComponent(PointLight.create(new Vec3(0.3, 0.6, 1.0), 6.0, 7.0).setCastShadow(true));
        root.addChild(pointNode);

        var spotNode = Node.create("spot")
            .addComponent(Transform.createbyMatrix4(spotTransform(new Vec3(-2.4, 2.4, 2.4), new Vec3())))
            .addComponent(SpotLight.create(new Vec3(1.0, 0.35, 0.2), 8.0, 10.0, 0.88, 0.62).setCastShadow(true));
        root.addChild(spotNode);

        var renderer = PBRRenderer.create();
        root.addComponent(renderer);
        renderer.shadowRenderer = new ShadowRenderer(context);
        renderer.enableLocalShadows = true;
        renderer.spotShadowSize = 512;
        renderer.pointShadowSize = 512;

        var animate = true;
        var pointAngle = 0.0;
        var spotAngle = 0.0;
        var directionalAzimuth = -0.6;

        function updateDirectional():Void {
            var direction = new Vec3(
                Math.cos(directionalAzimuth) * 0.55,
                -1.0,
                Math.sin(directionalAzimuth) * 0.55
            );
            var transform:Transform = cast dirNode.getComponent(Transform);
            transform.matrix = directionTransform(direction);
        }

        function updatePoint(time:Float):Void {
            var x = Math.cos(pointAngle) * 2.3;
            var z = 1.8 + Math.sin(pointAngle) * 1.3;
            var transform:Transform = cast pointNode.getComponent(Transform);
            transform.matrix = translation(x, 1.4 + Math.sin(time * 0.0012) * 0.25, z);
        }

        function updateSpot():Void {
            var target = new Vec3(Math.cos(spotAngle) * 1.2, -0.4, Math.sin(spotAngle) * 1.2);
            var transform:Transform = cast spotNode.getComponent(Transform);
            transform.matrix = spotTransform(new Vec3(-2.4, 2.4, 2.4), target);
        }

        canvas.keyboard.keyDown.connect(function(keyboard:Keyboard) {
            if (keyboard.keyIsDown(Key._1)) {
                var light = cast(dirNode.getComponent(DirectionalLight), DirectionalLight);
                light.intensity = Math.min(8.0, Math.max(0.0, light.intensity + 0.4));
                trace("directional=" + light.intensity);
            }
            if (keyboard.keyIsDown(Key._2)) {
                var light = cast(pointNode.getComponent(PointLight), PointLight);
                light.intensity = Math.min(30.0, Math.max(0.0, light.intensity + 1.5));
                trace("point=" + light.intensity);
            }
            if (keyboard.keyIsDown(Key._3)) {
                var light = cast(spotNode.getComponent(SpotLight), SpotLight);
                light.intensity = Math.min(40.0, Math.max(0.0, light.intensity + 2.0));
                trace("spot=" + light.intensity);
            }
            if (keyboard.keyIsDown(Key.SPACE)) {
                animate = !animate;
                trace("animate=" + animate);
            }
            if (keyboard.keyIsDown(Key._0)) {
                animate = true;
                directionalAzimuth = -0.6;
                pointAngle = 0.0;
                spotAngle = 0.0;
                cast(dirNode.getComponent(DirectionalLight), DirectionalLight).intensity = 2.0;
                cast(pointNode.getComponent(PointLight), PointLight).intensity = 6.0;
                cast(spotNode.getComponent(SpotLight), SpotLight).intensity = 8.0;
                updateDirectional();
                updatePoint(0.0);
                updateSpot();
                trace("RESET");
            }
        });

        canvas.resized.connect(function(canvas:AbstractCanvas, width:Int, height:Int) {
            var cameraComponent:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            cameraComponent.aspectRatio = width / height;
        });

        var objectTransforms:Array<Transform> = [];
        for (node in objects) {
            objectTransforms.push(cast node.getComponent(Transform));
        }

        canvas.enterFrame.connect(function(canvas:AbstractCanvas, time:Float, deltaTime:Float) {
            if (animate) {
                directionalAzimuth += deltaTime * 0.00025;
                pointAngle += deltaTime * 0.0007;
                spotAngle += deltaTime * 0.0005;
                updateDirectional();
                updatePoint(time);
                updateSpot();
                for (i in 0...objectTransforms.length) {
                    objectTransforms[i].matrix = scaleAndTranslate(0.9, 0.9, 0.9,
                        (i - 1) * 1.55, -0.55, 0.0)
                        * GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), time * 0.0008 + i, new Quat()), new Mat4());
                }
            }
            sceneManager.nextFrame(time, deltaTime);
        });

        updateDirectional();
        updatePoint(0.0);
        updateSpot();

        trace("PBR light test controls: 1 directional +  2 point +  3 spot +  SPACE toggle animation  0 reset");
        canvas.run();
    }

    static function translation(x:Float, y:Float, z:Float):Mat4 {
        var matrix = Mat4.identity(new Mat4());
        matrix.r0c3 = x;
        matrix.r1c3 = y;
        matrix.r2c3 = z;
        return matrix;
    }

    static function scaleAndTranslate(sx:Float, sy:Float, sz:Float, x:Float, y:Float, z:Float):Mat4 {
        var matrix = Mat4.identity(new Mat4());
        matrix.r0c0 = sx;
        matrix.r1c1 = sy;
        matrix.r2c2 = sz;
        matrix.r0c3 = x;
        matrix.r1c3 = y;
        matrix.r2c3 = z;
        return matrix;
    }

    static function directionTransform(direction:Vec3):Mat4 {
        return GLM.lookAt(new Vec3(), direction, new Vec3(0.0, 1.0, 0.0), new Mat4());
    }

    static function spotTransform(eye:Vec3, target:Vec3):Mat4 {
        return GLM.lookAt(eye, target, new Vec3(0.0, 1.0, 0.0), new Mat4());
    }
}
