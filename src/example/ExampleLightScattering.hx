package example;
import glm.Vec2;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import minko.Canvas;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.Loader;
import minko.geometry.CubeGeometry;
import minko.geometry.Geometry;
import minko.geometry.QuadGeometry;
import minko.geometry.SphereGeometry;
import minko.material.BasicMaterial;
import minko.render.Effect;
import minko.render.Texture;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
import minko.utils.MathUtil;
import minko.WebCanvas;
class ExampleLightScattering {
    public function new() {
        init();
    }

    private function createRandomCube(geom:Geometry, effect:Effect) {
        var r = MathUtil.sphericalRand(1.0);

        var material = BasicMaterial.create();
        material.diffuseColor =  MathUtil.vec3_vec4((r + 1.0) * .5, 1.0 ) ;

        var node = Node.create()
        .addComponent(Transform.createbyMatrix4(GLM.translate(r * 50.0,  new Mat4()) * GLM.scale(new Vec3(10.0, 10, 10), new Mat4())))
        .addComponent(Surface.create(geom, material, effect));

        return node;
    }

    public function init() {

        var canvas = WebCanvas.create("Minko Example - Light Scattering", 800, 600);
        var sceneManager = SceneManager.create(canvas);
        var root = Node.create("root");
        var assets = sceneManager.assets;
        var context = canvas.context;

        root.addComponent(sceneManager) ;

        context.errorsEnabled = (true);

        // setup assets
        assets.loader
        .queue("effect/LightScattering/EmissionMap.effect")
        .queue("effect/LightScattering/LightScattering.effect")
        .queue("effect/Basic.effect");

        assets.setGeometry("cube", CubeGeometry.create(context));

        // standard
        var renderer = Renderer.create();
        renderer.layoutMask = (renderer.layoutMask & ~BuiltinLayout.DEBUG_ONLY);
        renderer.backgroundColor = (0x23097aff);

        // forward
        var fwdRenderer = Renderer.create();
        var fwdTarget = Texture.create(context, MathUtil.clp2(canvas.width), MathUtil.clp2(canvas.height), false, true);
        fwdTarget.upload();

        // post-processing
        var ppRenderer = Renderer.create();
        var ppScene = Node.create().addComponent(ppRenderer);
        var ppTarget = Texture.create(context, MathUtil.clp2(canvas.width), MathUtil.clp2(canvas.height), false, true);

        ppTarget.upload();

        var ppMaterial = BasicMaterial.create().setbyKeyObject(
            {
                "emissionMap":fwdTarget,
                "backbuffer": ppTarget,
                "decay": 0.96815,
                "weight": 0.58767,
                "exposure": 0.2,
                "density":0.926,
                "numSamples": 128
            });

        // scene
        var debugNode1 = Node.createbyLayout("debug1", BuiltinLayout.DEBUG_ONLY);
        var debugNode2 = Node.createbyLayout("debug2", BuiltinLayout.DEBUG_ONLY);

        var camera = Node.create("camera")
        .addComponent(Transform.createbyMatrix4(
            Mat4.invert(GLM.lookAt(new Vec3(0.0), new Vec3(0.0, 0.0, 1.0), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())
        ))
        .addComponent(PerspectiveCamera.create(800.0 / 600.0, Math.PI * 0.25, .1, 1000.0))
        .addComponent(renderer);
        root.addChild(camera);

        var helio = Node.create("helio").addComponent(Transform.create());
        root.addChild(helio);

        var sun = Node.create("sun");

        var _ = assets.loader.complete.connect(function(loader:Loader) {
            for (i in 0... 100) {
                root.addChild(createRandomCube(assets.geometry("cube"), assets.effect("effect/Basic.effect")));
            }

            var sunMaterial = BasicMaterial.create().setbyKeyObject(
                {
                    "diffuseColor":new Vec4(1.0, 0.32, 0.05, 1.0),
                    "isLightSource":1.0
                });

            helio.addChild(Node.create()
                .addComponent(Transform.createbyMatrix4(
                    GLM.translate(new Vec3(0.0, 0.0, 100.0), Mat4.identity(new Mat4()))
                ))
                .addChild(sun.addComponent(Transform.createbyMatrix4(
                    GLM.scale(new Vec3(10.0, 10, 10), Mat4.identity(new Mat4())
                    )))
                .addComponent(Surface.create(
                    SphereGeometry.create(context),
                    sunMaterial,
                    assets.effect("effect/Basic.effect")
                ))));

            ppScene.addComponent(Surface.create(
                QuadGeometry.create(context),
            ppMaterial,
                assets.effect("effect/LightScattering/LightScattering.effect")));

            // forward
            fwdRenderer = Renderer.create(0x000000ff, fwdTarget, assets.effect("effect/LightScattering/EmissionMap.effect"));
            fwdRenderer.layoutMask=(fwdRenderer.layoutMask & ~BuiltinLayout.DEBUG_ONLY);
            camera.addComponent(fwdRenderer);

            var debugDisplay1 = TextureDebugDisplay.create();
            debugDisplay1.initialize(assets, fwdTarget);
            debugNode1.addComponent(debugDisplay1);
            ppScene.addChild(debugNode1);

            var debugDisplay2 = TextureDebugDisplay.create();
            debugDisplay2.initialize(assets, ppTarget);
            debugDisplay2.material.data.set("spritePosition", new Vec2(10, 440));
            debugNode2.addComponent(debugDisplay2);
            ppScene.addChild(debugNode2);
        });

        var resized = canvas.resized.connect(function(canvas, w, h) {
            var perspectiveCamera:PerspectiveCamera =cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (w / h);
        });

        var enterFrame = canvas.enterFrame.connect(function(canvas, time, deltaTime) {
            var cameraTransform:Transform =cast camera.getComponent(Transform);
            cameraTransform.matrix = GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), 0.001, new Quat()), new Mat4()) * cameraTransform.matrix;
            var helioTransform:Transform =cast helio.getComponent(Transform);
            helioTransform.matrix = GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), 0.001, new Quat()), new Mat4()) * helioTransform.matrix;

            var sunTransform:Transform =cast sun.getComponent(Transform);

            var perspectiveCamera:PerspectiveCamera =cast camera.getComponent(PerspectiveCamera);

            var worldSpaceLightPosition:Vec3 = new Vec3( sunTransform.modelToWorldMatrix.r0c3, sunTransform.modelToWorldMatrix.r1c3, sunTransform.modelToWorldMatrix.r2c3);
            var screenSpaceLightPosition:Vec3 = perspectiveCamera.project(worldSpaceLightPosition);

            screenSpaceLightPosition = new Vec3(screenSpaceLightPosition.x / canvas.width, screenSpaceLightPosition.y / canvas.height, 1.0);
            // std::cout << glm::to_string(screenSpaceLightPosition) << std::endl;

            ppMaterial.data.set("screenSpaceLightPosition",  new Vec2(screenSpaceLightPosition.x,screenSpaceLightPosition.y));

            // Rendering in "black and white" to fwdTarget.
            fwdRenderer.render(context);

            // Rendering the scene normally to ppTarget.
            sceneManager.nextFrame(time, deltaTime, ppTarget);

            // Blending fwdTarget with ppTarget, enabling light scattering.
            ppRenderer.render(context);
        });
        /*
var onmessageSlot = overlay.onmessage().connect((minko.dom.AbstractDOM.Ptr dom, string message) =>
{
var key = message.Substring(0, message.IndexOf("="));
var value = message.Substring(message.IndexOf("=") + 1);

if (key == "numSamples") // unsigned long
{
ppMaterial.data().set(key, Convert.ToUInt32(value));
}
else // float
{
ppMaterial.data().set(key, Convert.ToSingle(value));
}
});

overlay.load("html/interface.html");
*/
        assets.loader.load();
        canvas.run();

    }

}
