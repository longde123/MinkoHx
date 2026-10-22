import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import minko.AbstractCanvas;
import minko.AbstractCanvas.Flags;
import minko.Canvas.CanvasManager;
import minko.audio.SDLSoundParser;
import minko.audio.Sound;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.JPEGParser;
import minko.file.Loader;
import minko.file.PNGParser;
import minko.geometry.CubeGeometry;
import minko.input.Keyboard;
import minko.input.Keyboard.Key;
import minko.material.BasicMaterial;
import minko.scene.Node;

class Main {
    static inline var TEXTURE_FILENAME = "texture/diffuseMap.jpg";
    static inline var EFFECT_FILENAME = "effect/Basic.effect";
    static inline var SOUND_FILENAME = "sound/beep.wav";

    static function main() {
        var canvas = CanvasManager.create("Minko HL - Cube", 800, 600, Flags.RESIZABLE);
        var sceneManager = SceneManager.create(canvas);

        var options = sceneManager.assets.loader.options;
        var assetRoot = "../minko-example/asset";
        options.includePaths = [assetRoot, assetRoot + "/effect", "."];
        options.loadAsynchronously = false;
        options.resizeSmoothly = true;
        options.generateMipmaps = true;
        options.registerParser("png", function() return new PNGParser());
        options.registerParser("jpg", function() return new JPEGParser());
        options.registerParser("jpeg", function() return new JPEGParser());
        options.registerParser("wav", function() return new SDLSoundParser());
        options.registerParser("ogg", function() return new SDLSoundParser());

        sceneManager.assets.loader.error.connect(function(loader:Loader, error:String) {
            trace("Asset error: " + error);
        });

        sceneManager.assets.loader
            .queue(TEXTURE_FILENAME)
            .queue(EFFECT_FILENAME)
            .queue(SOUND_FILENAME);

        var cubeGeometry = CubeGeometry.create(sceneManager.assets.context);
        sceneManager.assets.setGeometry("cubeGeometry", cubeGeometry);

        var mat4:Mat4 = GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0, 1, 0), new Mat4());

        var root = Node.create("root").addComponent(sceneManager);

        var mesh = Node.create("mesh").addComponent(Transform.create());

        var camera = Node.create("camera")
            .addComponent(Renderer.create(0x000000))
            .addComponent(Transform.createbyMatrix4(Mat4.invert(mat4, new Mat4())))
            .addComponent(PerspectiveCamera.create(canvas.aspectRatio));

        root.addChild(mesh);
        root.addChild(camera);

        var beep:Sound = null;
        sceneManager.assets.loader.complete.connect(function(loader:Loader) {
            var material = BasicMaterial.create();
            material.diffuseMap = sceneManager.assets.texture(TEXTURE_FILENAME);
            mesh.addComponent(Surface.create(
                sceneManager.assets.geometry("cubeGeometry"),
                material,
                sceneManager.assets.effect(EFFECT_FILENAME)
            ));
            beep = sceneManager.assets.sound(SOUND_FILENAME);
        });

        canvas.keyboard.keyDown.connect(function(keyboard:Keyboard) {
            if (beep != null && keyboard.keyIsDown(Key.SPACE)) beep.play(1);
        });

        canvas.resized.connect(function(canvas:AbstractCanvas, w:Int, h:Int) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = w / h;
        });

        var cubeRotation = Quat.axisAngle(new Vec3(0, 1, 0), 0.01, new Quat());
        canvas.enterFrame.connect(function(canvas:AbstractCanvas, time:Float, deltaTime:Float) {
            var transform:Transform = cast mesh.getComponent(Transform);
            transform.matrix = GLM.rotate(cubeRotation, new Mat4()) * transform.matrix;
            sceneManager.nextFrame(time, deltaTime);
        });

        sceneManager.assets.loader.load();
        canvas.run();
    }
}
