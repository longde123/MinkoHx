import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.io.Bytes;
import minko.AbstractCanvas.Flags;
import minko.Canvas.CanvasManager;
import minko.geometry.CubeGeometry;
import minko.render.TextureFormat;
import minko.render.light.Light;
import minko.render.light.LightSet;
import minko.render.pbr.PBRForwardRenderer;
import minko.render.pbr.PBRMaterial;
import minko.render.pbr.ShadowRenderer;
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.RenderItem;
import minko.render.pipeline.RenderQueue;
import minko.render.target.RenderTargetPool;

class ShadowTest {
    static function main() {
        var canvas = CanvasManager.create("ShadowTest", 64, 64, Flags.RESIZABLE);
        var context = canvas.context;
        var pool = new RenderTargetPool(context);
        var geometry = CubeGeometry.create(context);

        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.4, 0.2, 1.0));
        cubeMat.setRoughness(0.8);
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.9, 0.9, 0.9, 1.0));
        wallMat.setRoughness(0.9);

        var cubeWorld = Mat4.identity(new Mat4());
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0; wallWorld.r1c1 = 3.0; wallWorld.r2c2 = 0.1;
        wallWorld.r0c3 = 0.0; wallWorld.r1c3 = 0.0; wallWorld.r2c3 = -1.3;

        var light = Light.directional();
        light.intensity = 3.0;
        var lightEye = new Vec3(2.5, 2.0, 2.5);
        var lightView = GLM.lookAt(lightEye, new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        var lightProjection = GLM.orthographic(-4.0, 4.0, -4.0, 4.0, 0.1, 20.0, new Mat4());
        var lightViewProjection = lightProjection * lightView;

        var pbr = new PBRForwardRenderer(context);
        var shadow = new ShadowRenderer(context);
        var shadowTarget = pool.acquireMRT(512, 512, [TextureFormat.RGBA], TextureFormat.Depth24);

        function buildQueue():RenderQueue {
            var q = new RenderQueue();
            q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
            q.add(new RenderItem(geometry, wallMat, null, wallWorld));
            return q;
        }

        function render(shadowsOn:Bool):Array<Float> {
            var queue = buildQueue();
            var frame = new FrameContext(context, 256, 256);
            frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
            frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
            frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
            frame.lights = new LightSet();
            frame.lights.add(light);
            if (shadowsOn) {
                shadow.render(queue, frame, shadowTarget, lightViewProjection);
                frame.shadowMap = shadowTarget;
                frame.lightViewProjection = lightViewProjection;
            }
            var target = pool.acquire(256, 256);
            target.bind(context, false);
            context.clear(0.0, 0.0, 0.0, 1.0);
            pbr.render(queue, frame, target);
            var bytes = Bytes.alloc(256 * 256 * 4);
            context.readPixels(bytes);
            target.unbind(context);
            pool.release(target);
            // luma of left band (shadow falls here) vs right band (lit wall)
            var leftSum = 0.0; var rightSum = 0.0; var leftN = 0; var rightN = 0;
            for (y in 0...256) {
                for (x in 0...256) {
                    var i = (y * 256 + x) * 4;
                    var luma = (0.299 * bytes.get(i) + 0.587 * bytes.get(i + 1) + 0.114 * bytes.get(i + 2)) / 255.0;
                    if (x > 8 && x < 92 && y > 8 && y < 248) { leftSum += luma; leftN++; }
                    if (x > 164 && x < 248 && y > 8 && y < 248) { rightSum += luma; rightN++; }
                }
            }
            return [leftSum / leftN, rightSum / rightN];
        }

        var on = render(true);
        var off = render(false);

        shadow.dispose();
        pbr.dispose();
        pool.release(shadowTarget);
        pool.dispose();

        trace("SHADOW_ON  left=" + f(on[0]) + " right=" + f(on[1]));
        trace("SHADOW_OFF left=" + f(off[0]) + " right=" + f(off[1]));
        var pass = on[0] < off[0] - 0.03 && on[1] > on[0] * 1.3 && off[0] > off[1] * 0.8;
        trace("SHADOW_TEST " + (pass ? "PASS" : "FAIL"));
        Sys.exit(0);
    }

    static function f(v:Float):String {
        return Math.round(v * 1000) / 1000 + "";
    }
}
