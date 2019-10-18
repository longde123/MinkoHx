package example;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import minko.AbstractCanvas.Flags;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.AssetLibrary;
import minko.geometry.QuadGeometry;
import minko.material.BasicMaterial;
import minko.render.CompareMode;
import minko.render.StencilOperation;
import minko.render.TriangleCulling;
import minko.scene.Node;
import minko.utils.RandomNumbers;
import minko.WebCanvas;
class ExampleStencil {
    public function new() {
        init();
    }

    private function generateColor():Vec4 {
        return new Vec4(RandomNumbers.nextNumber(), RandomNumbers.nextNumber(), RandomNumbers.nextNumber(), 0.5);
    }

    private function generateHexColor():Int {
        var color = generateColor();

        var r = Math.floor(255.0 * color.x);
        var g = Math.floor(255.0 * color.y);
        var b = Math.floor(255.0 * color.z);
        var a = Math.floor(255.0 * color.w);

        return ((r << 24) | (g << 16) | (b << 8) | a);
    }

    private function generateStars(numStars:Int, assets:AssetLibrary) {
        if (assets == null) {
            throw ("assets");
        }

       var starNodes:Array<Node>=[];

        for (i in 0...numStars) {
            var basicMaterial:BasicMaterial = BasicMaterial.create();
            basicMaterial.diffuseColor = (generateColor());
            basicMaterial.colorMask = (true);
            basicMaterial.depthMask = (false);
            basicMaterial.depthFunction = (CompareMode.ALWAYS);
            basicMaterial.stencilFunction = (CompareMode.EQUAL);
            basicMaterial.stencilReference = (1);
            basicMaterial.stencilMask = (0xff);
            basicMaterial.stencilFailOperation = (StencilOperation.KEEP);
            starNodes[i] = Node.create("star_" + (i))
            .addComponent(Transform.create())
            .addComponent(Surface.create(assets.geometry("smallStar"), basicMaterial, assets.effect("effect/Basic.effect")));

            var minX = -1.0;
            var rangeX = 1.0 - minX;
            var minY = -1.0;
            var rangeY = 1.0 - minY;
            var starNodesTransform:Transform =cast starNodes[i].getComponent(Transform);

             starNodesTransform.matrix = (GLM.translate(new Vec3(minX + (RandomNumbers.nextNumber()) * rangeX, minY + (RandomNumbers.nextNumber() ) * rangeY, 0.0), new Mat4())
             * GLM.rotate(Quat.axisAngle(new Vec3(0.0, 0.0, 1.0), 2.0 * Math.PI * (RandomNumbers.nextNumber()), new Quat()), new Mat4())
             * starNodesTransform.matrix * GLM.scale(new Vec3(0.25, 0.25, 0.25), new Mat4()));
        }
        return starNodes;
    }

    function init() {
        var canvas = WebCanvas.create("Minko Example - Stencil", 800, 600, Flags.RESIZABLE | Flags.STENCIL);
        var sceneManager = SceneManager.create(canvas);
        var assets = sceneManager.assets;

        // setup assets
        sceneManager.assets
        .setGeometry("bigStar", StarGeometry.create(sceneManager.assets.context, 5, 0.5, 0.325))
        .setGeometry("smallStar", StarGeometry.create(sceneManager.assets.context, 5, 0.5, 0.25))
        .setGeometry("quad", QuadGeometry.create(sceneManager.assets.context));

        sceneManager.assets.loader.queue("effect/Basic.effect");

        var numSmallStars = 30;
        var smallStars:Array<Node> = [];

        var root = Node.create("root").addComponent(sceneManager);

        var camera = Node.create("camera")
        .addComponent(Renderer.create(generateHexColor()))
        .addComponent(PerspectiveCamera.create(canvas.aspectRatio))
        .addComponent(Transform.create());

        var cameraTransform:Transform = cast camera.getComponent(Transform);
        cameraTransform.matrix = (Mat4.invert(GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(0.0), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4()));


        var bigStarNode = Node.create("bigStarNode").addComponent(Transform.create());

        var quadNode = Node.create("quadNode").addComponent(Transform.create());

        root.addChild(camera);

        var _ = sceneManager.assets.loader.complete.connect(function(loader) {
            var bigStarNodeBasicMaterial:BasicMaterial = BasicMaterial.create();
            bigStarNodeBasicMaterial.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));
            bigStarNodeBasicMaterial.colorMask = (false);
            bigStarNodeBasicMaterial.depthMask = (false);
            bigStarNodeBasicMaterial.depthFunction = (CompareMode.ALWAYS);
            bigStarNodeBasicMaterial.stencilFunction = (CompareMode.NEVER);
            bigStarNodeBasicMaterial.stencilReference = (1);
            bigStarNodeBasicMaterial.stencilMask = (0xff);
            bigStarNodeBasicMaterial.stencilFailOperation = (StencilOperation.REPLACE);
            bigStarNodeBasicMaterial.triangleCulling = (TriangleCulling.BACK);
            bigStarNode.addComponent(Surface.create(assets.geometry("bigStar"), bigStarNodeBasicMaterial, assets.effect("effect/Basic.effect")));
            var bigStarNodeTransform:Transform = cast bigStarNode.getComponent(Transform);
            bigStarNodeTransform.matrix = (GLM.scale(new Vec3(2.5, 2.5, 2.5), new Mat4()) * bigStarNodeTransform.matrix);
            var quadNodeBasicMaterial:BasicMaterial = BasicMaterial.create();
            quadNodeBasicMaterial.diffuseColor = (generateColor());
            quadNodeBasicMaterial.colorMask = (true);
            quadNodeBasicMaterial.depthMask = (false);
            quadNodeBasicMaterial.depthFunction = (CompareMode.ALWAYS);
            quadNodeBasicMaterial.stencilFunction = (CompareMode.EQUAL);
            quadNodeBasicMaterial.stencilReference = (1);
            quadNodeBasicMaterial.stencilMask = (0xff);
            quadNodeBasicMaterial.stencilFailOperation = (StencilOperation.KEEP);
            quadNodeBasicMaterial.triangleCulling = (TriangleCulling.BACK);
            quadNode.addComponent(Surface.create(assets.geometry("quad"), quadNodeBasicMaterial, assets.effect("effect/Basic.effect")));

            var quadNodeTransform:Transform =cast quadNode.getComponent(Transform);
            quadNodeTransform.matrix = (GLM.scale(new Vec3(4, 4, 4), new Mat4()) * bigStarNodeTransform.matrix);

            smallStars= generateStars(numSmallStars, sceneManager.assets);

            // stencil writing pass
             root.addChild(bigStarNode);
            // stencil fetching pass
            root.addChild(quadNode);

            for (star in smallStars) {
               root.addChild(star);
            }
        });

        var enterFrame = canvas.enterFrame.connect(function(canvas, time, deltaTime) {

            var bigStarNodeTransform:Transform =cast bigStarNode.getComponent(Transform);
            bigStarNodeTransform.matrix = GLM.rotate(Quat.axisAngle(new Vec3(0.0, 0.0, 1.0), .001, new Quat()), new Mat4()) * bigStarNodeTransform.matrix;

            for (star in smallStars) {
                var starTransform:Transform =cast star.getComponent(Transform);
                starTransform.matrix = starTransform.matrix * GLM.rotate(Quat.axisAngle(new Vec3(0.0, 0.0, 1.0), -0.025, new Quat()), new Mat4());
            }
            sceneManager.nextFrame(time, deltaTime);
        });

        sceneManager.assets.loader.load();
        canvas.run();
    }

}
