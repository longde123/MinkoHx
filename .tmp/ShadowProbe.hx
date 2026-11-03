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
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.RenderItem;
import minko.render.pipeline.RenderQueue;
import minko.render.target.RenderTargetPool;

// Probe: horizontal luma profile of the shadow test scene (shadows OFF),
// plus wall-only and cube-only variants, to find the left/right asymmetry.
class ShadowProbe {
    static function main() {
        var canvas = CanvasManager.create("ShadowProbe", 64, 64, Flags.RESIZABLE);
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
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0; wallWorld.r1c1 = 3.0; wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        function profile(name:String, withCube:Bool, withWall:Bool) {
            var q = new RenderQueue();
            if (withCube) q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
            if (withWall) q.add(new RenderItem(geometry, wallMat, null, wallWorld));
            var frame = new FrameContext(context, 256, 256);
            frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
            frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
            frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
            frame.lights = new LightSet();
            var light = Light.directional();
            light.intensity = 3.0;
            frame.lights.add(light);

            var target = pool.acquire(256, 256);
            target.bind(context, false);
            context.clear(0.0, 0.0, 0.0, 1.0);
            pbr.render(q, frame, target);
            var bytes = Bytes.alloc(256 * 256 * 4);
            context.readPixels(bytes);
            target.unbind(context);
            pool.release(target);

            // average luma per 16-px column band over the middle rows
            var out = "";
            for (band in 0...16) {
                var sum = 0.0; var n = 0;
                for (y in 64...192) {
                    for (x in band * 16...(band + 1) * 16) {
                        var i = (y * 256 + x) * 4;
                        sum += (0.299 * bytes.get(i) + 0.587 * bytes.get(i + 1) + 0.114 * bytes.get(i + 2)) / 255.0;
                        n++;
                    }
                }
                out += Math.round(sum / n * 100) / 100 + " ";
            }
            trace(name + " " + out);
        }

        profile("full:", true, true);
        profile("wall:", false, true);
        profile("cube:", true, false);

        // full-image ASCII map (16x16 cells), rows top-to-bottom as stored
        var q = new RenderQueue();
        q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
        q.add(new RenderItem(geometry, wallMat, null, wallWorld));
        var frame = new FrameContext(context, 256, 256);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
        frame.lights = new LightSet();
        var light = Light.directional();
        light.intensity = 3.0;
        frame.lights.add(light);
        var target = pool.acquire(256, 256);
        target.bind(context, false);
        context.clear(0.0, 0.0, 0.0, 1.0);
        pbr.render(q, frame, target);
        var bytes = Bytes.alloc(256 * 256 * 4);
        context.readPixels(bytes);
        target.unbind(context);
        pool.release(target);
        var chars = " .:-=+*#%@";
        for (cy in 0...16) {
            var row = "";
            for (cx in 0...16) {
                var sum = 0.0; var n = 0;
                for (y in cy * 16...(cy + 1) * 16) {
                    for (x in cx * 16...(cx + 1) * 16) {
                        var i = (y * 256 + x) * 4;
                        sum += (0.299 * bytes.get(i) + 0.587 * bytes.get(i + 1) + 0.114 * bytes.get(i + 2)) / 255.0;
                        n++;
                    }
                }
                var v = sum / n;
                row += chars.charAt(Math.floor(v * 9.999));
            }
            trace(row);
        }

        pbr.dispose();
        pool.dispose();
        Sys.exit(0);
    }
}
