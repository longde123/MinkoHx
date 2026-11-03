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

// Locate the shadow: ASCII-map (off - on) luma diff for the suite's shadow scene.
class ShadowMapProbe {
    static function main() {
        var canvas = CanvasManager.create("ShadowMapProbe", 64, 64, Flags.RESIZABLE);
        var context = canvas.context;
        var pool = new RenderTargetPool(context);
        var geometry = CubeGeometry.create(context);
        var pbr = new PBRForwardRenderer(context);

        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.4, 0.2, 1.0));
        cubeMat.setRoughness(0.8);
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.9, 0.9, 0.9, 1.0));
        wallMat.setRoughness(0.9);

        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5; cubeWorld.r1c1 = 0.5; cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0; wallWorld.r1c1 = 3.0; wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var light = Light.directional();
        light.intensity = 3.0;
        var lightEye = new Vec3(2.5, 2.0, 2.5);
        var lightView = GLM.lookAt(lightEye, new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        var lightProjection = GLM.orthographic(-4.0, 4.0, -4.0, 4.0, 0.1, 20.0, new Mat4());
        var lvp = lightProjection * lightView;

        var q = new RenderQueue();
        q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
        q.add(new RenderItem(geometry, wallMat, null, wallWorld));

        function render(on:Bool):Bytes {
            var frame = new FrameContext(context, 256, 256);
            frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
            frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
            frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
            frame.lights = new LightSet();
            frame.lights.add(light);
            var shadow = new ShadowRenderer(context);
            if (on) {
                var st = pool.acquireMRT(512, 512, [TextureFormat.RGBA], TextureFormat.Depth24);
                shadow.render(q, frame, st, lvp);
                frame.shadowMap = st;
                frame.lightViewProjection = lvp;
            }
            var target = pool.acquire(256, 256);
            target.bind(context, false);
            context.clear(0.0, 0.0, 0.0, 1.0);
            pbr.render(q, frame, target);
            var bytes = Bytes.alloc(256 * 256 * 4);
            context.readPixels(bytes);
            target.unbind(context);
            pool.release(target);
            return bytes;
        }

        var on = render(true);
        var off = render(false);
        var chars = " .:-=+*#%@";
        for (cy in 0...32) {
            var row = "";
            for (cx in 0...64) {
                var sum = 0.0;
                for (y in cy * 8...(cy + 1) * 8) {
                    for (x in cx * 4...(cx + 1) * 4) {
                        var i = (y * 256 + x) * 4;
                        var l = (0.299 * (off.get(i) - on.get(i)) + 0.587 * (off.get(i + 1) - on.get(i + 1)) + 0.114 * (off.get(i + 2) - on.get(i + 2))) / 255.0;
                        sum += l;
                    }
                }
                var v = sum / 32;
                row += v > 0.005 ? chars.charAt(Math.floor(Math.min(v * 12, 1) * 9.999)) : " ";
            }
            trace(row);
        }
        pbr.dispose();
        pool.dispose();
        Sys.exit(0);
    }
}
