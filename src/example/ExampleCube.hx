package example;


import minko.geometry.TeapotGeometry;
import minko.render.GlContext;
import minko.render.VertexBuffer;
import minko.render.Shader;
import minko.geometry.QuadGeometry;
import glm.Quat;
import glm.GLM;
import minko.component.Surface;
import minko.material.BasicMaterial;
import minko.file.Loader;
import minko.AbstractCanvas;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Transform;
import minko.file.PNGParser;
import minko.geometry.CubeGeometry;
import glm.Mat4;
import glm.Vec3;
import minko.scene.Node;
import minko.WebCanvas;
import minko.render.Program;
class ExampleCube {
      public function new() {

        var TEXTURE_FILENAME = "texture/box.png";
        var EFFECT_FILENAME = "effect/Basic.effect";
        var canvas:WebCanvas = WebCanvas.create("Example - Cube");

        var sceneManager:SceneManager = SceneManager.create(canvas);

        var options = sceneManager.assets.loader.options;
        options.resizeSmoothly = (true);
        options.generateMipmaps = (true);
        options.registerParser("png", function() return new PNGParser());


        sceneManager.assets.loader
        .queue(TEXTURE_FILENAME)
        .queue(EFFECT_FILENAME);

        var cubeGeometry = CubeGeometry.create(sceneManager.assets.context);
        sceneManager.assets.setGeometry("cubeGeometry", cubeGeometry);

        var mat4:Mat4=GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0, 1, 0),new Mat4());

        var root = Node.create("root")
        .addComponent(sceneManager);


        var mesh = Node.create("mesh")
         .addComponent(Transform.create());

        var camera = Node.create("camera")
        .addComponent(Renderer.create(0x000000))
        .addComponent(Transform.createbyMatrix4(Mat4.invert(mat4,new Mat4())))
        .addComponent(PerspectiveCamera.create(canvas.aspectRatio));

        root.addChild(mesh);
        root.addChild(camera);

        var _ = sceneManager.assets.loader.complete.connect(function(  loader:Loader)
        {
            var material :BasicMaterial= BasicMaterial.create();
          //  material.diffuseColorRGBA(0xff0000ff);
            material.diffuseMap=sceneManager.assets.texture(TEXTURE_FILENAME);
            mesh.addComponent(Surface.create(sceneManager.assets.geometry("cubeGeometry"), material, sceneManager.assets.effect(EFFECT_FILENAME)));
        });

        var resized = canvas.resized.connect(function(  canvas:AbstractCanvas ,   w,   h)
        {
            var perspectiveCamera:PerspectiveCamera=cast camera.getComponent(PerspectiveCamera);
             perspectiveCamera.aspectRatio=(w / h);
        });

        var cubeRotation=Quat.axisAngle(new Vec3(0,1,0),0.01,new Quat());
        var enterFrame = canvas.enterFrame.connect(function( canvas:AbstractCanvas,   time,   deltaTime)
        {
            var transform:Transform=cast mesh.getComponent(Transform);


            transform.matrix=(GLM.rotate( cubeRotation,  (new Mat4()))*transform.matrix);
            sceneManager.nextFrame(time, deltaTime);
        });

        sceneManager.assets.loader.load();
        canvas.run();
    }
}
